terraform {
  required_version = ">= 0.15"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project     = "quizzapp-456810"
  region      = "us-central1"
  credentials = file("credentials.json")
}

resource "google_cloud_run_service" "quizlet_backend" {
  name     = "quizlet-backend"
  location = "us-central1"

  template {
    spec {
      containers {
        image = "gcr.io/quizzapp-456810/quizlet-backend:latest"
        ports {
          container_port = 8080
        }
        env {
          name = "CREDENTIALS_JSON"
          value_from {
            secret_key_ref {
              name = "my-credentials-json"
              key  = "latest"
            }
          }
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

resource "google_cloud_run_service_iam_member" "public_invoker" {
  service  = google_cloud_run_service.quizlet_backend.name
  location = google_cloud_run_service.quizlet_backend.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

output "cloud_run_url" {
  description = "URL of the deployed Cloud Run service."
  value       = google_cloud_run_service.quizlet_backend.status[0].url
}


# provider "google-beta" {
#   project     = "quizzapp-456810"
#   credentials = file("credentials.json")
#   region      = "us-central1"
# }

# jeszcze do tej aplikacji trzeba włączyć email authentication w firebase i nie da sie tego odblokować w terraformie

# Włączenie wymaganych API: App Engine i Firestore
# resource "google_project_service" "appengine" {
#   service = "appengine.googleapis.com"
#   project = "quizzapp-456810"
# }

# resource "google_project_service" "firestore" {
#   service = "firestore.googleapis.com"
#   project = "quizzapp-456810"
# }

# App engine - ustaw na ownera, nie można chyba potem usunąć, ręcznie to w sumei ustawiałam

# resource "google_app_engine_application" "default" {
#   project     = "quizzapp-456810"
#   location_id = "us-central1"

#   depends_on = [google_project_service.appengine]
# }

# terraform destroy nie działa trzeba ręcznie usunąć
# resource "google_firestore_database" "QuizzApp" {
#   project     = "quizzapp-456810"
#   name        = "(default)"
#   location_id = "us-central1"
#   type        = "FIRESTORE_NATIVE"

#   depends_on = [
#     google_project_service.firestore,
#   ]
# }

# output "firestore_database_id" {
#   description = "ID domyślnej bazy danych Firestore."
#   value       = google_firestore_database.QuizzApp.name
# }

# Frontend bucket
resource "google_storage_bucket" "frontend" {
  name          = "quizlet-frontend-456810"  
  location      = "US"
  force_destroy = true

  website {
    main_page_suffix = "index.html"
    not_found_page   = "index.html"
  }
}

# Make bucket public
resource "google_storage_bucket_iam_member" "public_access" {
  bucket = google_storage_bucket.frontend.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

output "frontend_url" {
  value = "https://storage.googleapis.com/${google_storage_bucket.frontend.name}/index.html"
}
