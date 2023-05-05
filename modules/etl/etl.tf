resource "kubernetes_deployment_v1" "etl" {
  metadata {
    name       = "etl-${local.name_suffix}"
    namespace  = kubernetes_namespace_v1.namespace.metadata.0.name
    labels     = {
      "app"    = "${var.resource_tags["project"]}"
    }
  }
  spec {
    replicas = 1
      spec {
        container {
          image = "localhost:5000/etl"
          name  = "etl"
        env {
          name  = "DATABASE_HOST"
          value_from {
            secret_key_ref {
              name = "postgres-secret-${local.name_suffix}"
              key = "DBHost"
            }
          }
        }
        env {
          name  = "DATABASE_USER"
          value_from {
            secret_key_ref {
              name = "postgres-secret-${local.name_suffix}"
              key  = "DBUser"
            }
          }
        }  
        env {
          name  = "DATABASE_PASSWORD"
          value_from {
            secret_key_ref {
              name = "postgres-secret-${local.name_suffix}"
              key  = "DBPassword"
            }
          }
        }           
        env {
          name  = "DATABASE_NAME"
          value_from {
            secret_key_ref {
              name = "postgres-secret-${local.name_suffix}"
              key  = "DBName"
            }
          }
        }           
        env {
          name  = "DATABASE_PORT"
          value_from {
            secret_key_ref {
              name = "postgres-secret-${local.name_suffix}"
              key  = "DBPort"
            }
          }
        }           

        }
      }
    }
}
