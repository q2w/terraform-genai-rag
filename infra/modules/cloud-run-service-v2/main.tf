resource "google_cloud_run_v2_service" "main" {
  provider                   = google-beta
  name                       = var.service_name
  location                   = var.location
  project                    = var.project_id


  template {
    service_account = var.service_account_email
    labels = var.labels

    scaling {
      max_instance_count = var.max_instance_count
      min_instance_count = var.min_instance_count
    }

    dynamic "vpc_access" {
      for_each = var.vpc_access_connector_ids
      content  {
        connector = vpc_access.value
        egress = var.vpc_access_egress
        }
    }

    dynamic "volumes" {
      for_each = var.volumes
      content {
        name = volumes.value["name"]

        dynamic "cloud_sql_instance" {
          for_each = volumes.value.cloud_sql_instance[*]
          content {
            instances = [cloud_sql_instance.value["instances"]]
          }
        }
      }
    }


    containers {
      image = var.image

      dynamic "startup_probe" {
        for_each = var.startup_probe != null ? [1] : []
        content {
          failure_threshold     = var.startup_probe.failure_threshold
          initial_delay_seconds = var.startup_probe.initial_delay_seconds
          timeout_seconds       = var.startup_probe.timeout_seconds
          period_seconds        = var.startup_probe.period_seconds
          dynamic "http_get" {
            for_each = var.startup_probe.http_get != null ? [1] : []
            content {
              path = var.startup_probe.http_get.path
              dynamic "http_headers" {
                for_each = var.startup_probe.http_get.http_headers != null ? var.startup_probe.http_get.http_headers : []
                content {
                  name  = http_headers.value["name"]
                  value = http_headers.value["value"]
                }
              }
            }
          }
        }
      }
#      ports {
#        container_port = var.port
#      }
      dynamic "env" {
        for_each = var.env_vars
        content {
          name  = env.value["name"]
          value = env.value["value"]
        }
      }

      dynamic "env" {
        for_each = var.env_secret_vars
        content {
          name = env.value["name"]
          dynamic "value_source" {
            for_each = env.value.value_source
            content {
              secret_key_ref {
                secret = value_source.value.secret_key_ref["secret"]
                version  = value_source.value.secret_key_ref["version"]
              }
            }
          }
        }
      }

      dynamic "volume_mounts" {
        for_each = var.volume_mounts
        content {
          name       = volume_mounts.value["name"]
          mount_path = volume_mounts.value["mount_path"]
        }
      }
    }
  }   // template
}

resource "google_cloud_run_service_iam_member" "authorize" {
  count    = length(var.members)
  location = google_cloud_run_v2_service.main.location
  project  = google_cloud_run_v2_service.main.project
  service  = google_cloud_run_v2_service.main.name
  role     = "roles/run.invoker"
  member   = var.members[count.index]
}