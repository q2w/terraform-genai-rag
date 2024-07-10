module "terraform_genai_rag_vertexai" {
  source                      = "terraform-google-modules/project-factory/google//modules/project_services"
  version                     = "15.0.0"
  project_id                  = var.project_id
  disable_services_on_destroy = false
  activate_apis               = ["aiplatform.googleapis.com"]
}