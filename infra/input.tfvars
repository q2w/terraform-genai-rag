project_id = "abhiwa-test-30112023"
region     = "us-central1"

terraform_genai_rag_sa_name = "terraform-genai-rag-sa-name"
terraform_genai_rag_sa_project_roles = [
  "roles/cloudsql.instanceUser",
  "roles/cloudsql.client",
  "roles/run.invoker",
  "roles/aiplatform.user",
  "roles/iam.serviceAccountTokenCreator",
  "roles/secretmanager.secretAccessor"
]

terraform_genai_rag_database_deletion_protection      = false
terraform_genai_rag_database_user_deletion_policy     = "ABANDON"
terraform_genai_rag_database_database_deletion_policy = "ABANDON"
terraform_genai_rag_database_name                     = "genai-rag-db"
terraform_genai_rag_database_db_name                  = "assistantdemo"
terraform_genai_rag_database_user_name                = "default"
terraform_genai_rag_database_database_version         = "POSTGRES_15"
terraform_genai_rag_database_disk_size                = 10
terraform_genai_rag_database_database_flags = [{
  name  = "cloudsql.iam_authentication"
  value = "on"
  }, {
  name  = "cloudsql.enable_google_ml_integration"
  value = "on"
}]
terraform_genai_rag_database_enable_default_user          = true
terraform_genai_rag_database_tier                         = "db-custom-1-3840"
terraform_genai_rag_database_enable_google_ml_integration = true
terraform_genai_rag_database_database_integration_roles   = ["roles/aiplatform.user"]
terraform_genai_rag_database_user_labels                  = { "genai-rag" = true }

terraform_genai_rag_secret_secrets = [{ name : "genai-cloud-sql-password" }]
terraform_genai_rag_secret_user_managed_replication = {
  genai-cloud-sql-password = [
    {
      location     = "us-central1"
      kms_key_name = null
    }
  ]
}

terraform_genai_rag_retrieval_volumes = [{ name : "cloudsql" }]
terraform_genai_rag_retrieval_containers = [{
  container_image : "us-docker.pkg.dev/google-samples/containers/jss/rag-retrieval-service:v0.0.2",
  env_vars : {
    "APP_HOST" : "0.0.0.0",
    "APP_PORT" : "8080",
    "DB_KIND" : "cloudsql-postgres",
    "DB_PROJECT" : "abhiwa-test-30112023",
    "DB_REGION" : "us-central1",
    "DB_INSTANCE" : "genai-rag-db",
    "DB_NAME" : "assistantdemo",
    "DB_USER" : "default"
  },
  env_secret_vars : {
    "DB_PASSWORD" : { "secret" : "genai-cloud-sql-password", "version" : "latest" }
  },
  volume_mounts = [{ name : "cloudsql", mount_path : "/cloudsql" }],
  startup_probe = {
    http_get = {
      path = "/data/import"
    }
    initial_delay_seconds = 30
    timeout_seconds       = 15
    period_seconds        = 20
    failure_threshold     = 10
  }
}]
terraform_genai_rag_retrieval_service_name    = "retrieval-service"
terraform_genai_rag_retrieval_template_labels = { "genai-rag" = true }

terraform_genai_rag_frontend_template_labels = { "genai-rag" = true }
terraform_genai_rag_frontend_service_name    = "frontend"
terraform_genai_rag_frontend_members         = ["allUsers"]
terraform_genai_rag_frontend_containers      = [{ container_image : "us-docker.pkg.dev/google-samples/containers/jss/rag-frontend-service:v0.0.1", env_vars : {} }]