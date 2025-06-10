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


resource "google_cloud_run_service" "quizlet_frontend" {
  name     = "quizlet-frontend"
  location = "us-central1"

  template {
    spec {
      containers {
        image = "gcr.io/quizzapp-456810/quizlet-frontend:latest"
        ports {
          container_port = 3000
        }
        env {
          name  = "NEXT_PUBLIC_API_URL"
          value = google_cloud_run_service.quizlet_backend.status[0].url
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

resource "google_cloud_run_service_iam_member" "frontend_invoker" {
  service  = google_cloud_run_service.quizlet_frontend.name
  location = google_cloud_run_service.quizlet_frontend.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

output "frontend_url" {
  description = "URL of the deployed frontend Cloud Run service."
  value       = google_cloud_run_service.quizlet_frontend.status[0].url
}


