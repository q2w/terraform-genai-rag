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

module "terraform-genai-rag-vertexai" {
  source                      = "terraform-google-modules/project-factory/google//modules/project_services"
  version                     = "15.0.0"
  project_id  = var.project_id

  disable_services_on_destroy = var.terraform-genai-rag-vertexai-disable_services_on_destroy

  enable_apis = var.terraform-genai-rag-vertexai-enable_apis
  activate_apis = var.terraform-genai-rag-vertexai-activate_apis
}

module "terraform-genai-rag-sa" {
  source = "github.com/terraform-google-modules/terraform-google-service-accounts//modules/simple-sa?ref=master"
  project_id = var.project_id
  name = var.terraform-genai-rag-sa-name
  project_roles = var.terraform-genai-rag-sa-project_roles
}

module "terraform-genai-rag-database" {
  source = "github.com/terraform-google-modules/terraform-google-sql-db//modules/postgresql?ref=v17.0.1"
  project_id = var.project_id
  region = var.region
  name = var.terraform-genai-rag-database-name
  db_name = var.terraform-genai-rag-database-db_name
  database_version = var.terraform-genai-rag-database-database_version
  disk_size = var.terraform-genai-rag-database-disk_size
  database_flags = var.terraform-genai-rag-database-database_flags
  deletion_protection = var.terraform-genai-rag-database-deletion_protection
  user_deletion_policy = var.terraform-genai-rag-database-user_deletion_policy
  database_deletion_policy = var.terraform-genai-rag-database-database_deletion_policy
  enable_default_user = var.terraform-genai-rag-database-enable_default_user
  tier = var.terraform-genai-rag-database-tier
  user_labels = var.labels
  user_name = var.terraform-genai-rag-database-user_name
}

module "terraform-genai-rag-secret" {
  source = "github.com/GoogleCloudPlatform/terraform-google-secret-manager?ref=main"
  project_id = var.project_id
  secrets = [ { name: var.terraform-genai-rag-secret-secrets-name, secret_data: module.terraform-genai-rag-database.generated_user_password} ]
  secret_accessors_list = [ "serviceAccount:${module.terraform-genai-rag-sa.email}"]
  user_managed_replication = var.terraform-genai-rag-secret-user_managed_replication
}

module "terraform-genai-rag-retrieval" {
  source = "./modules/cloud-run-service-v2"
  service_name = var.terraform-genai-rag-retrieval-service_name
  location = var.region
  project_id = var.project_id
  service_account_email = module.terraform-genai-rag-sa.email
  labels = var.labels
  image = var.terraform-genai-rag-retrieval-image
  volumes = [ { name: var.terraform-genai-rag-retrieval-volumes-name, cloud_sql_instance: { instances: module.terraform-genai-rag-database.instance_connection_name }}]
  volume_mounts = [ { name: var.terraform-genai-rag-retrieval-volumes-name, mount_path: var.terraform-genai-rag-retrieval-volumes-mount_path}]
  env_vars = var.terraform-genai-rag-retrieval-env_vars
  env_secret_vars = var.terraform-genai-rag-retrieval-env_secret_vars
  startup_probe = var.terraform-genai-rag-retrieval-startup_probe
}


module "terraform-genai-rag-frontend" {
  source = "./modules/cloud-run-service-v2"
  service_name = var.terraform-genai-rag-frontend-service_name
  location = var.region
  project_id = var.project_id
  service_account_email = module.terraform-genai-rag-sa.email
  labels = var.labels
  image = var.terraform-genai-rag-frontend-image
  env_vars = [
    { name: "SERVICE_URL", value: module.terraform-genai-rag-retrieval.service_url },
    { name: "SERVICE_ACCOUNT_EMAIL", value: module.terraform-genai-rag-sa.email },
    { name  = "ORCHESTRATION_TYPE", value = "langchain-tools" },
    { name  = "DEBUG", value = "False"}
  ]
  members = var.terraform-genai-rag-frontend-members
}