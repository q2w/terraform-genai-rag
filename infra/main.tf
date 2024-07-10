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

module "terraform_genai_rag_vertexai" {
  source     = "./modules/vertexai"
  project_id = var.project_id
}

module "terraform_genai_rag_sa" {
  source        = "github.com/q2w/terraform-google-service-accounts//modules/simple-sa"
  project_id    = var.project_id
  name          = var.terraform_genai_rag_sa_name
  project_roles = var.terraform_genai_rag_sa_project_roles
}

module "terraform_genai_rag_database" {
  source                       = "github.com/q2w/terraform-google-sql-db//modules/postgresql"
  project_id                   = var.project_id
  region                       = var.region
  name                         = var.terraform_genai_rag_database_name
  db_name                      = var.terraform_genai_rag_database_db_name
  database_version             = var.terraform_genai_rag_database_database_version
  disk_size                    = var.terraform_genai_rag_database_disk_size
  database_flags               = var.terraform_genai_rag_database_database_flags
  deletion_protection          = var.terraform_genai_rag_database_deletion_protection
  user_deletion_policy         = var.terraform_genai_rag_database_user_deletion_policy
  database_deletion_policy     = var.terraform_genai_rag_database_database_deletion_policy
  enable_default_user          = var.terraform_genai_rag_database_enable_default_user
  tier                         = var.terraform_genai_rag_database_tier
  user_labels                  = var.terraform_genai_rag_database_user_labels
  user_name                    = var.terraform_genai_rag_database_user_name
  enable_google_ml_integration = var.terraform_genai_rag_database_enable_google_ml_integration
  database_integration_roles   = var.terraform_genai_rag_database_database_integration_roles
}

module "terraform_genai_rag_secret" {
  source                   = "github.com/q2w/terraform-google-secret-manager"
  project_id               = var.project_id
  secrets                  = [{ name : var.terraform_genai_rag_secret_secrets[0].name, secret_data : module.terraform_genai_rag_database.generated_user_password }]
  secret_accessors_list    = [module.terraform_genai_rag_sa.iam_email]
  user_managed_replication = var.terraform_genai_rag_secret_user_managed_replication
}

module "terraform_genai_rag_retrieval" {
  source          = "github.com/q2w/terraform-google-cloud-run//modules/v2"
  service_name    = var.terraform_genai_rag_retrieval_service_name
  location        = var.region
  project_id      = var.project_id
  service_account = module.terraform_genai_rag_sa.email
  template_labels = var.terraform_genai_rag_retrieval_template_labels
  volumes         = [{ name : var.terraform_genai_rag_retrieval_volumes[0].name, cloud_sql_instance : { instances : module.terraform_genai_rag_database.instance_connection_name } }]
  containers      = var.terraform_genai_rag_retrieval_containers
}

module "terraform_genai_rag_frontend" {
  source          = "github.com/q2w/terraform-google-cloud-run//modules/v2"
  service_name    = var.terraform_genai_rag_frontend_service_name
  location        = var.region
  project_id      = var.project_id
  service_account = module.terraform_genai_rag_sa.email
  template_labels = var.terraform_genai_rag_frontend_template_labels

  containers = [
    {
      container_image : var.terraform_genai_rag_frontend_containers[0].container_image,
      env_vars : merge(
        module.terraform_genai_rag_sa.env_vars,
        { "BACKEND_SERVICE_ENDPOINT" : module.terraform_genai_rag_retrieval.service_uri },
        var.terraform_genai_rag_frontend_containers[0].env_vars
      )
    }
  ]
  members = var.terraform_genai_rag_frontend_members
}