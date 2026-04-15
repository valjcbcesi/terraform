# =================================
# Bucket Cloud Storage
# Doc : google_storage_bucket
# ================================
resource "google_storage_bucket" "wordpress_bucket" {
  # Le nom d'un bucket doit être unique au monde sur tout Google Cloud.
  name          = "${var.project_id}-wp-bucket"
  location      = var.region
  
  # Forcer la destruction du bucket même s'il contient des fichiers.
  force_destroy = true

  # On unifie les droits d'accès au niveau du bucket
  uniform_bucket_level_access = true
}