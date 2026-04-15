# =============================
# Compte de service par défaut
# ==============================
# On récupère les infos du compte de service par défaut de Compute Engine
data "google_compute_default_service_account" "default" {
}

# =====================================
# Instance avec lien vers le script
# Doc : google_compute_instance_template
# ======================================
resource "google_compute_instance_template" "wordpress_template" {
  name         = "wordpress-template"
  machine_type = "e2-micro" # Machine économique pour le TP

  # Système d'exploitation
  disk {
    source_image = "debian-cloud/debian-13"
    auto_delete  = true
    boot         = true
  }

  # Configuration réseau
  network_interface {
    network    = google_compute_network.vpc-network.id
    subnetwork = google_compute_subnetwork.subnet.id
    # Pas de "access_config" = pas d'IP publique = pas de trafic sur mon GCP = economies de credit
  }

  # Lien vers le script de démarrage
  # On utilise templatefile au lieu de file, en lui passant l'IP privée de la DB
  metadata_startup_script = templatefile("scripts/startup.sh", {
    db_ip = google_sql_database_instance.main_db_instance.private_ip_address
  })

  # On attache le compte de service par défaut
  service_account {
    email  = data.google_compute_default_service_account.default.email
    scopes = ["cloud-platform"]
  }
}

# ===============================================
# Health Check
# Doc : google_compute_health_check
# ===============================================
resource "google_compute_health_check" "wordpress_hc" {
  name               = "wordpress-health-check"
  check_interval_sec = 10 # Vérifie toutes les 10 secondes
  timeout_sec        = 5

  # On vérifie si le serveur web répond bien sur le port 80
  http_health_check {
    port         = 80
    request_path = "/"
  }
}

# ==========================================
# Instance Group Manager qui gère la réparation automatique et l'autoscaling
# Doc : google_compute_instance_group_manager
# ==========================================
resource "google_compute_instance_group_manager" "wordpress_mig" {
  name               = "wordpress-mig"
  base_instance_name = "wordpress-vm" # Nom de base des futures machines
  zone               = "${var.region}-a" # On place le groupe dans une zone

  # On lui dit d'utiliser le template
  version {
    instance_template = google_compute_instance_template.wordpress_template.id
  }

  named_port {
    name = "http"
    port = 80
  }

  # Si le Health Check échoue, le groupe détruit la VM et en recrée une neuve
  auto_healing_policies {
    health_check      = google_compute_health_check.wordpress_hc.id
    # On laisse 5 min à la VM pour démarrer et installer WordPress avant de la tester
    initial_delay_sec = 300
  }
}

# ==============================
# Autoscaler
# Doc : google_compute_autoscaler
# ================================
resource "google_compute_autoscaler" "wordpress_autoscaler" {
  name   = "wordpress-autoscaler"
  zone   = "${var.region}-a"
  target = google_compute_instance_group_manager.wordpress_mig.id

  autoscaling_policy {
    min_replicas    = 1 # Il y aura toujours au moins 1 VM allumée
    max_replicas    = 3 # S'il y a trop de trafic, Google pourra allumer jusqu'à 3 VMs
    cooldown_period = 60

    # L'autoscaler ajoutera une machine si le CPU global dépasse 60% d'utilisation
    cpu_utilization {
      target = 0.6
    }
  }
}