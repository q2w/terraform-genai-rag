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
}

variable "region" {
  type        = string
  description = "Google Cloud Region"
}

# vertexai input variables

# service account variables
variable "terraform_genai_rag_sa_name" {
  type = string
}

variable "terraform_genai_rag_sa_project_roles" {
  type = list(string)
}

# Database variables
variable "terraform_genai_rag_database_deletion_protection" {
  type        = string
  description = "Whether or not to protect Cloud SQL resources from deletion when solution is modified or changed."
}

variable "terraform_genai_rag_database_name" {
  type = string
}

variable "terraform_genai_rag_database_db_name" {
  type = string
}

variable "terraform_genai_rag_database_user_name" {
  type = string
}

variable "terraform_genai_rag_database_database_version" {
  type = string
}

variable "terraform_genai_rag_database_disk_size" {
  type = number
}

variable "terraform_genai_rag_database_database_flags" {
  type = list(object({ name : string, value : string }))
}

variable "terraform_genai_rag_database_user_deletion_policy" {
  type = string
}

variable "terraform_genai_rag_database_database_deletion_policy" {
  type = string
}

variable "terraform_genai_rag_database_enable_default_user" {
  type = bool
}

variable "terraform_genai_rag_database_tier" {
  type = string
}

variable "terraform_genai_rag_database_enable_google_ml_integration" {
  type = bool
}

variable "terraform_genai_rag_database_database_integration_roles" {
  type = list(string)
}

variable "terraform_genai_rag_database_user_labels" {
  type        = map(string)
  description = "A map of labels to apply to contained resources."
}

# variables for secret-manager
variable "terraform_genai_rag_secret_secrets" {
  type = list(map(string))
}

variable "terraform_genai_rag_secret_user_managed_replication" {
  type = map(list(object({ location = string, kms_key_name = string })))
}

# variables for terraform-genai-rag-retrieval
variable "terraform_genai_rag_retrieval_volumes" {
  type = list(object({
  name = string }))
}

variable "terraform_genai_rag_retrieval_containers" {
  type = list(object({ container_image : string, env_vars : map(string), env_secret_vars : map(object({
    secret  = string
    version = string
    })), volume_mounts : list(object({ name : string, mount_path : string })), startup_probe : object({
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
  }) }))
}

variable "terraform_genai_rag_retrieval_service_name" {
  type = string
}

variable "terraform_genai_rag_retrieval_template_labels" {
  type        = map(string)
  description = "A map of labels to apply to contained resources."
}

# variables for frontend
variable "terraform_genai_rag_frontend_template_labels" {
  type        = map(string)
  description = "A map of labels to apply to contained resources."
}

variable "terraform_genai_rag_frontend_service_name" {
  type = string
}

variable "terraform_genai_rag_frontend_members" {
  type = list(string)
}

variable "terraform_genai_rag_frontend_containers" {
  type = list(object({ container_image : string, env_vars : map(string) }))
}