# API pour le réseau et les machines virtuelles
resource "google_project_service" "compute" {
  project = var.project_id
  service = "compute.googleapis.com"
}

# API pour la base de données SQL
resource "google_project_service" "sql" {
  project = var.project_id
  service = "sqladmin.googleapis.com"
}

# API pour les connexions privées
resource "google_project_service" "servicenetworking" {
  project = var.project_id
  service = "servicenetworking.googleapis.com"
}

# API pour Google Cloud Storage
resource "google_project_service" "storage_api" {
  project = var.project_id
  service = "storage.googleapis.com"
}