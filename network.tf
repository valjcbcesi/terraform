# ================================
# VPC (Virtual Private Cloud)
# Doc : google_compute_network
# ==========================================
resource "google_compute_network" "vpc-network" {
  name                    = "wordpress-vpc"
  # On met false car on veut créer notre propre sous-réseau (subnet) personnalisé
  auto_create_subnetworks = false
}

# ==============================
# Subnet (Sous-réseau)
# Doc : google_compute_subnetwork
# ===============================
resource "google_compute_subnetwork" "subnet" {
  name          = "wordpress-subnet"
  ip_cidr_range = "192.168.10.0/24" # Plage d'adresses IP pour nos machines
  region        = var.region
  network       = google_compute_network.vpc-network.id
}

# ==========================================
# Router
# Doc: google_compute_router
# Nécessaire pour faire fonctionner le Cloud NAT
# ===============================================
resource "google_compute_router" "router" {
  name    = "wordpress-router"
  region  = google_compute_subnetwork.subnet.region
  network = google_compute_network.vpc-network.id
}

# =======================================
# NAT (Network Address Translation)
# Doc: google_compute_router_nat
# Permet aux machines sans IP publique d'accéder à internet
# ==========================================================
resource "google_compute_router_nat" "nat" {
  name                               = "wordpress-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# =====================
# Firewall SSH
# Doc : google_compute_firewall
# Autorise le trafic entrant sur le port 22
# ==========================================
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc-network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_tags = ["ssh"]

  # 0.0.0.0/0 signifie que la connexion est autorisée depuis n'importe où
  source_ranges = ["0.0.0.0/0"] 
}

# ==========================================================
# Firewall HTTP
# Autorise le trafic entrant sur le port 80 pour le web
# ======================================================
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = google_compute_network.vpc-network.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  source_tags = ["web"]
  source_ranges = ["0.0.0.0/0"]
}

# ===============================
# Global private address
# Doc: google_compute_global_address
# On réserve une plage d'IP interne pour les services gérés par Google (Base de données)
# =======================================================================================
resource "google_compute_global_address" "private_ip_alloc" {
  name          = "private-ip-alloc"
  # Ces IPs serviront à faire un lien direct entre mon réseau et celui de Google
  purpose       = "VPC_PEERING"
  # On veut des IP Internes, pas publique
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc-network.id
}

# =====================================
# Service Networking connection
# Doc: google_service_networking_connection
# Relie notre VPC au réseau de Google pour que notre BDD ait une IP privée
# =========================================================================
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc-network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
}