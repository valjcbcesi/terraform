# ==========================================
# Adresse Globale
# Doc : google_compute_global_address
# =======================================================
resource "google_compute_global_address" "lb_ipv4" {
  name = "wordpress-lb-ip"
}

# ==========================================
# Backend
# Doc : google_compute_backend_service
# ==================================================================================
resource "google_compute_backend_service" "wordpress_backend" {
  name                  = "wordpress-backend"
  protocol              = "HTTP"
  port_name             = "http" # Port utilisé par l'Instance Group
  load_balancing_scheme = "EXTERNAL" # C'est un Load Balancer public
  
  # On lui donne le même Health Check
  health_checks = [google_compute_health_check.wordpress_hc.id]

  # On connecte le Backend au MIG
  backend {
    group = google_compute_instance_group_manager.wordpress_mig.instance_group
  }
}

# ==========================================
# URL map
# Doc : google_compute_url_map
# ==========================================
resource "google_compute_url_map" "wordpress_url_map" {
  name            = "wordpress-url-map"
  # Par défaut, tout le trafic va vers notre backend WordPress
  default_service = google_compute_backend_service.wordpress_backend.id 
}

# ==========================================
# Cible HTTP Proxy
# Doc : google_compute_target_http_proxy
# ==========================================
resource "google_compute_target_http_proxy" "wordpress_http_proxy" {
  name    = "wordpress-http-proxy"
  url_map = google_compute_url_map.wordpress_url_map.id
}

# ==========================================
# Forwarding rule
# Doc : google_compute_global_forwarding_rule
# ============================================
resource "google_compute_global_forwarding_rule" "wordpress_forwarding_rule" {
  name                  = "wordpress-forwarding-rule"
  target                = google_compute_target_http_proxy.wordpress_http_proxy.id
  port_range            = "80" # On écoute sur le port web standard
  ip_address            = google_compute_global_address.lb_ipv4.id
  load_balancing_scheme = "EXTERNAL"
}