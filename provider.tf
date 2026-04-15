# Configuration du provider Google avec les variables de notre projet
provider "google" {
  project = var.project_id
  region  = var.region
}