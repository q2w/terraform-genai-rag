/**
 * Copyright 2021 Google LLC
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

// service
variable "project_id" {
  description = "The project ID to deploy to"
  type        = string
}

variable "service_name" {
  description = "The name of the Cloud Run service to create"
  type        = string
}

variable "location" {
  description = "Cloud Run service deployment location"
  type        = string
}

variable "image" {
  description = "GCR hosted image URL to deploy"
  type        = string
}

variable "encryption_key" {
  description = "CMEK encryption key self-link expected in the format projects/PROJECT/locations/LOCATION/keyRings/KEY-RING/cryptoKeys/CRYPTO-KEY."
  type        = string
  default     = null
}

variable "service_account_email" {
  type        = string
  description = "Service Account email needed for the service"
  default     = ""
}

variable "port" {
  type = number
  default = 80
}

variable "env_vars" {
  type = list(object({
    value = string
    name  = string
  }))
  description = "Environment variables (cleartext)"
  default     = []
}

variable "members" {
  type        = list(string)
  description = "Users/SAs to be given invoker access to the service"
  default     = []
}

variable "vpc_access_connector_ids" {
  type = set(string)
  default = []
}

variable "max_instance_count" {
  type = number
  default = 2
}

variable "min_instance_count" {
  type = number
  default = 1
}

variable "vpc_access_egress" {
  type = string
  default = "ALL_TRAFFIC"
}

variable "instance_connection_name" {
  type = string
  default = ""
}

variable "labels" {
  type = map(string)
}

variable "volumes" {
  type = list(object({
    name = string
    cloud_sql_instance = optional(object({
      instances = optional(string)
    }))
  }))
  description = "[Beta] Volumes needed for environment variables (when using secret)"
  default     = []
}

variable "volume_mounts" {
  type = list(object({
    name       = string
    mount_path = string
  }))
  default = []
}

variable "env_secret_vars" {
  type = list(object({
    name = string
    value_source = set(object({
      secret_key_ref = map(string)
    }))
  }))
  description = "[Beta] Environment variables (Secret Manager)"
  default     = []
}

variable "startup_probe" {
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
  default     = null
  description = <<-EOF
    Startup probe of application within the container.
    All other probes are disabled if a startup probe is provided, until it succeeds.
    Container will not be added to service endpoints if the probe fails.
    More info: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#container-probes
  EOF
}