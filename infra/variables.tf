/**
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# --------------------------------------------------
# VARIABLES
# Set these before applying the configuration
# --------------------------------------------------

variable "project_id" {
  type        = string
  description = "Google Cloud Project ID"
  default = "abhiwa-test-30112023"
}

variable "region" {
  type        = string
  description = "Google Cloud Region"
  default     = "us-central1"
}

variable "labels" {
  type        = map(string)
  description = "A map of labels to apply to contained resources."
  default     = { "genai-rag" = true }
}

variable "terraform-genai-rag-database-deletion_protection" {
  type        = string
  description = "Whether or not to protect Cloud SQL resources from deletion when solution is modified or changed."
  default     = false
}

variable "terraform-genai-rag-frontend-image" {
  type        = string
  description = "The public Artifact Registry URI for the frontend container"
  default     = "us-docker.pkg.dev/google-samples/containers/jss/rag-frontend-service:v0.0.1"
}

variable "terraform-genai-rag-retrieval-image" {
  type        = string
  description = "The public Artifact Registry URI for the retrieval container"
  default     = "us-docker.pkg.dev/google-samples/containers/jss/rag-retrieval-service:v0.0.2"
}

variable "terraform-genai-rag-database-name" {
  type = string
  default = "genai-rag-db"
}

variable "terraform-genai-rag-database-db_name" {
  type = string
  default = "assistantdemo"
}

variable "terraform-genai-rag-database-user_name" {
  type = string
  default = "default"
}

variable "terraform-genai-rag-vertexai-disable_services_on_destroy" {
  type = string
  default = false
}

variable "terraform-genai-rag-vertexai-enable_apis" {
  type        = string
  description = "Whether or not to enable underlying apis in this solution. ."
  default     = true
}

variable "terraform-genai-rag-vertexai-activate_apis" {
  type = list(string)
  default = [
    "aiplatform.googleapis.com"
  ]
}

variable "terraform-genai-rag-sa-name" {
  type = string
  default = "terraform-genai-rag-sa-name"
}

variable "terraform-genai-rag-sa-project_roles" {
  type = list(string)
  default = [
    "roles/cloudsql.instanceUser",
    "roles/cloudsql.client",
    "roles/run.invoker",
    "roles/aiplatform.user",
    "roles/iam.serviceAccountTokenCreator"
  ]
}

variable "terraform-genai-rag-database-database_version" {
  type = string
  default = "POSTGRES_15"
}

variable "terraform-genai-rag-database-disk_size" {
  type = number
  default = 10
}

variable "terraform-genai-rag-database-database_flags" {
  type = list(object({ name : string, value : string }))
  default =   [ {
    name  = "cloudsql.iam_authentication"
    value = "on"
  }, {
    name  = "cloudsql.enable_google_ml_integration"
    value = "on"
  }]
}

variable "terraform-genai-rag-database-user_deletion_policy" {
  type = string
  default = "ABANDON"
}

variable "terraform-genai-rag-database-database_deletion_policy" {
  type = string
  default = "ABANDON"
}

variable "terraform-genai-rag-database-enable_default_user" {
  type = bool
  default = true
}

variable "terraform-genai-rag-database-tier" {
  type = string
  default =   "db-custom-1-3840"
}

variable "terraform-genai-rag-secret-secrets-name" {
  type = string
  default = "genai-cloud-sql-password"
}

variable "terraform-genai-rag-secret-user_managed_replication" {
  type = map(list(object({ location = string, kms_key_name = string })))
  default = {
    genai-cloud-sql-password = [
      {
        location = "us-central1"
        kms_key_name = null
      }
    ]
  }
}

variable "terraform-genai-rag-retrieval-volumes-name" {
  type = string
  default = "cloudsql"
}

variable "terraform-genai-rag-retrieval-volumes-mount_path" {
  type = string
  default = "/cloudsql"
}

variable "terraform-genai-rag-retrieval-env_vars" {
  type = list(object({name: string, value: string}))
  default = [
    { name  = "APP_HOST", value = "0.0.0.0" },
    { name  = "APP_PORT", value = "8080" },
    { name  = "DB_KIND", value = "cloudsql-postgres" },
    { name  = "DB_PROJECT", value = "abhiwa-test-30112023" },
    { name  = "DB_REGION", value = "us-central1" },
    { name  = "DB_INSTANCE", value = "genai-rag-db" },
    { name  = "DB_NAME", value = "assistantdemo" },
    { name  = "DB_USER", value = "default" }
  ]
}

variable "terraform-genai-rag-retrieval-env_secret_vars" {
  type = list(object({name: string, value_source = set(object({
    secret_key_ref = map(string)
  }))}))
  default = [
    {
      name = "DB_PASSWORD",
      value_source = [{ secret_key_ref: { "secret": "genai-cloud-sql-password", "version": "latest"}}]
    }
  ]
}

variable "terraform-genai-rag-retrieval-service_name" {
  type = string
  default = "retrieval-service"
}

variable "terraform-genai-rag-frontend-service_name" {
  type = string
  default = "frontend"
}

variable "terraform-genai-rag-frontend-members" {
  type = list(string)
  default = [ "allUsers"]
}

variable "terraform-genai-rag-retrieval-startup_probe" {
  type = object({
    failure_threshold     = optional(number, null)
    initial_delay_seconds = optional(number, null)
    timeout_seconds       = optional(number, null)
    period_seconds        = optional(number, null)
    http_get = optional(object({
      path = optional(string)
      http_headers = optional(list(object({
        name  = string
        value = string
      })), null)
    }), null)
  })
  default = {
    http_get = {
      path = "/data/import"
    }
    initial_delay_seconds = 30
    timeout_seconds       = 15
    period_seconds        = 20
    failure_threshold     = 10
  }
}