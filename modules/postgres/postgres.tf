resource "kubernetes_secret_v1" "postgres-secret" {
      metadata {
        name               = "postgres-secret-${local.name_suffix}"
        namespace          = kubernetes_namespace_v1.namespace.metadata.0.name
        labels             = {
          "sensitive"      = "true"
          "app"            = "${var.resource_tags["project"]}"
        }
      }
      binary_data = {
        "DBHost"     = ""
        "DBUser"     = ""
        "DBPassword" = ""
        "DBSchema"   = ""
        "DBName"     = ""
      }
    }


resource "kubernetes_persistent_volume_v1" "postgres-pv-volume" {
  metadata {
    name               = "postgres-pv-volume-${local.name_suffix}"
    labels             = {
      "app"            = "${var.resource_tags["project"]}"
    }
  }
  spec {
    capacity           = {
      storage          = "20Gi"
    }
    access_modes       = ["ReadWriteMany"]
    # Need this or K8s (minikube) will try to dynamically create a pv for the pvc
    storage_class_name = "manual"
    persistent_volume_source {
      local {
        path           = "/data/pg-db-pv-volume/"
      }
    }
    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key        = "kubernetes.io/hostname"
            operator   = "In"
            values     = [ "minikube" ]
          }
        }
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "postgres-pv-claim" {
  metadata {
    name               = "postgres-pv-claim-${local.name_suffix}"
    namespace          = kubernetes_namespace_v1.namespace.metadata.0.name
    labels             = {
      "app"            = "${var.resource_tags["project"]}"
    }
  }
  spec {
    access_modes       = ["ReadWriteMany"]
    # Need this or K8s (minikube) will try to dynamically create a pv for the pvc
    storage_class_name = "manual"
    resources {
      requests         = {
        storage        = "19Gi"
      }
    }
  }
}


resource "kubernetes_pod_v1" "postgres" {
  metadata {
    name       = "postgres-${local.name_suffix}"
    namespace  = kubernetes_namespace_v1.namespace.metadata.0.name
    labels     = {
      "app"    = "${var.resource_tags["project"]}"
    }
  }
  spec {
    container {
      image = "postgres"
      name  = "db"
      env {
        name  = "PGDATA"
        value = "/var/lib/postgresql/data"
      }
      env {
        name  = "POSTGRES_DB"
        value_from {
          secret_key_ref {
            name = "postgres-secret-${local.name_suffix}"
            key = "DBName"
          }
        }
      }
      env {
        name  = "POSTGRES_USER"
        value_from {
          secret_key_ref {
            name = "postgres-secret-${local.name_suffix}"
            key  = "DBUser"
          }
        }
      }  
      env {
        name  = "POSTGRES_PASSWORD"
        value_from {
          secret_key_ref {
            name = "postgres-secret-${local.name_suffix}"
            key  = "DBPassword"
          }
        }
      }  
      port {
        container_port = 5432
      }
      # lifecycle {
      #   post_start {
      #     exec {
      #       command = ["/bin/sh","-c","sleep 20 && PGPASSWORD=$POSTGRES_PASSWORD psql -w -d $POSTGRES_DB -U $POSTGRES_USER -c 'CREATE TABLE IF NOT EXISTS gendercounts (id SERIAL PRIMARY KEY,gender TEXT, count INT4);'"]
      #     }
      #   }
      # }
    }
    volume {
      name = "postgres-db-data"
      persistent_volume_claim {
        claim_name = kubernetes_persistent_volume_claim_v1.postgres-pv-claim.metadata.0.name
      }
    }
  }
}

resource "kubernetes_service" "postgres-service" {
  metadata {
    name       = "postgres-service-${local.name_suffix}"
    namespace  = kubernetes_namespace_v1.namespace.metadata.0.name
    labels     = {
      "app"    = "${var.resource_tags["project"]}"
    }
  }
  spec {
    selector = {
      app    = "${var.resource_tags["project"]}"
    }
    # If you want to make sure that connections from a particular client are passed to the same Pod each time
    # Select the session affinity based on the client's IP addresses
    # https://kubernetes.io/docs/reference/networking/virtual-ips/#session-affinity
    session_affinity = "ClientIP"
    # NodePort, the Kubernetes control plane allocates a port.
    # Each node proxies that port (the same port number on every Node) into your Service. 
    # Using a NodePort gives you the freedom to set up your own load balancing solution, 
    # to configure environments that are not fully supported by Kubernetes, 
    # or even to expose one or more nodes' IP addresses directly.
    # https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport
    type = "NodePort"
    port {
      port        = 5432
      target_port = 5432
    }
  }
}
