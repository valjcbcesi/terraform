# ==============================
# SQL Database Instance
# Doc : google_sql_database_instance
# ==========================================
resource "google_sql_database_instance" "main_db_instance" {
  name             = "wordpress-db-instance-2" # Ajout -2 car gcp a reservé le nom de la 1ere BDD lors du précédent test
  region           = var.region
  database_version = "MYSQL_8_0" # Version classique pour WordPress
  
  # On doit ajouter cette référence pour une IP privée
  depends_on = [google_service_networking_connection.private_vpc_connection]

  # Ajout pour autoriser la destruction
  deletion_protection = false

  settings {
    tier = "db-f1-micro"

    ip_configuration {
      ipv4_enabled                                  = false # On désactive l'IP publique par sécurité
      private_network                               = google_compute_network.vpc-network.id
      enable_private_path_for_google_cloud_services = true
    }
  }
}

# =========================
# SQL Database
# Doc : google_sql_database
# ==========================
resource "google_sql_database" "wordpress_db" {
  name     = "wordpress" # Le nom de la base que WordPress utilisera
  instance = google_sql_database_instance.main_db_instance.name
}

# ======================
# SQL User
# Doc : google_sql_user
# ======================
resource "google_sql_user" "wordpress_user" {
  name     = "wp_user"
  instance = google_sql_database_instance.main_db_instance.name
  
  password = "un_bien_joli_mot_de_passe" 
}