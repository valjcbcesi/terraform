# Déclaration de la variable pour l'ID du projet GCP
variable "project_id" {
  description = "ID unique de mon projet Google Cloud"
  type        = string
}

# Déclaration de la variable pour la région
variable "region" {
  description = "La région GCP dans laquelle déployer les ressources (ex: europe-west9 pour Paris)"
  type        = string
}