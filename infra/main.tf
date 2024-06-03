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

module "project-services" {
  source                      = "terraform-google-modules/project-factory/google//modules/project_services"
  version                     = "15.0.0"
  disable_services_on_destroy = false

  project_id  = var.project_id
  enable_apis = var.enable_apis

  activate_apis = [
    "aiplatform.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudapis.googleapis.com",
    "cloudbuild.googleapis.com",
    "compute.googleapis.com",
    "config.googleapis.com",
    "iam.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "serviceusage.googleapis.com",
    "sqladmin.googleapis.com",
    "storage-api.googleapis.com",
    "storage.googleapis.com",
  ]
}

module "terraform-genai-rag-sa" {
  source = "github.com/terraform-google-modules/terraform-google-service-accounts//modules/simple-sa?ref=master"
  project_id = var.project_id
  name = "genai-rag-run-sa-name"
  project_roles = [
    "roles/cloudsql.instanceUser",
    "roles/cloudsql.client",
    "roles/run.invoker",
    "roles/aiplatform.user",
    "roles/iam.serviceAccountTokenCreator"
  ]
}

module "terraform-genai-rag-database" {
  source = "github.com/terraform-google-modules/terraform-google-sql-db//modules/postgresql?ref=v17.0.1"
  project_id = var.project_id
  region = var.region
  name = var.db_instance_name
  db_name = var.db_name
  database_version = "POSTGRES_15"
  disk_size = 10
  database_flags = [ {
    name  = "cloudsql.iam_authentication"
    value = "on"
  }, {
    name  = "cloudsql.enable_google_ml_integration"
    value = "on"
  }]
  deletion_protection = var.deletion_protection
  user_deletion_policy = "ABANDON"
  database_deletion_policy = "ABANDON"
  enable_default_user = true
  tier = "db-custom-1-3840"
  user_labels = var.labels
  user_name = var.db_user_name
}

module "terraform-genai-rag-secret" {
  source = "github.com/GoogleCloudPlatform/terraform-google-secret-manager?ref=main"
  project_id = var.project_id
  secrets = [ { name: "genai-cloud-sql-password", secret_data: module.terraform-genai-rag-database.generated_user_password} ]
  secret_accessors_list = [ "serviceAccount:${module.terraform-genai-rag-sa.email}"]
  user_managed_replication = {
    genai-cloud-sql-password = [
      {
        location = var.region
        kms_key_name = null
      }
    ]
  }
}

module "terraform-genai-rag-retrieval" {
  source = "./modules/cloud-run-service-v2"
  service_name = "retrieval-service"
  location = var.region
  project_id = var.project_id
  service_account_email = module.terraform-genai-rag-sa.email
  labels = var.labels
  image = var.retrieval_container
  volumes = [ { name: "cloudsql", cloud_sql_instance: { instances: module.terraform-genai-rag-database.instance_connection_name }}]
  volume_mounts = [ { name: "cloudsql", mount_path: "/cloudsql"}]
  env_vars = [
     { name  = "APP_HOST", value = "0.0.0.0" },
     { name  = "APP_PORT", value = "8080" },
     { name  = "DB_KIND", value = "cloudsql-postgres" },
     { name  = "DB_PROJECT", value = var.project_id },
     { name  = "DB_REGION", value = var.region },
     { name  = "DB_INSTANCE", value = var.db_instance_name },
     { name  = "DB_NAME", value = var.db_name },
     { name  = "DB_USER", value = var.db_user_name }
  ]

  env_secret_vars = [
    {
      name = "DB_PASSWORD",
      value_source = toset([{ secret_key_ref: { "secret": "genai-cloud-sql-password", "version": "latest"}}])
    }
  ]
}


module "terraform-genai-rag-frontend" {
  source = "./modules/cloud-run-service-v2"
  service_name = "frontend"
  location = var.region
  project_id = var.project_id
  service_account_email = module.terraform-genai-rag-sa.email
  labels = var.labels
  image = var.frontend_container
  env_vars = [
    { name: "SERVICE_URL", value: module.terraform-genai-rag-retrieval.service_url },
    { name: "SERVICE_ACCOUNT_EMAIL", value: module.terraform-genai-rag-sa.email },
    { name  = "ORCHESTRATION_TYPE", value = "langchain-tools" },
    { name  = "DEBUG", value = "False"}
  ]
  members = [ "allUsers"]
}

data "google_service_account_id_token" "oidc" {
  target_audience = module.terraform-genai-rag-retrieval.service_url
}

# # Trigger the database init step from the retrieval service
# # Manual Run: curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" {run_service}/data/import

# tflint-ignore: terraform_unused_declarations
data "http" "database_init" {
  url    = "${module.terraform-genai-rag-retrieval.service_url}/data/import"
  method = "GET"
  request_headers = {
    Accept = "application/json"
    Authorization = "Bearer ${data.google_service_account_id_token.oidc.id_token}" }

  depends_on = [
    module.terraform-genai-rag-retrieval,
    module.terraform-genai-rag-database,
    data.google_service_account_id_token.oidc,
  ]
}