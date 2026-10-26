terraform {
  required_version = ">= 1.3.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.50.0"
    }
  }
}

provider "google" {
  project = "hogwarts-castle-defense"
  region  = "us-central1"
  zone    = "us-central1-a"
}
