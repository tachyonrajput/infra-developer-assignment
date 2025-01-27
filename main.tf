provider "kubernetes" {
  config_path = "~/.kube/config"
}

locals {
  applications = [
    {
      name          = "foo"
      image         = "hashicorp/http-echo"
      args          = "-listen=:8081 -text=\"I am foo\""
      port          = 8081
      traffic_weight = 25
      replicas      = 2
    },
    {
      name          = "bar"
      image         = "hashicorp/http-echo"
      args          = "-listen=:8082 -text=\"I am bar\""
      port          = 8082
      traffic_weight = 25
      replicas      = 3
    },
    {
      name          = "boom"
      image         = "hashicorp/http-echo"
      args          = "-listen=:8083 -text=\"I am boom\""
      port          = 8083
      traffic_weight = 50
      replicas      = 4
    }
  ]
}

resource "kubernetes_deployment" "app" {
  for_each = { for app in local.applications : app.name => app }

  metadata {
    name = each.value.name
  }

  spec {
    replicas = each.value.replicas
  
    selector {
      match_labels = {
        app = each.value.name
      }
    }

    template {
      metadata {
        labels = {
          app = each.value.name
        }
      }

      spec {
        container {
          name  = each.value.name
          image = each.value.image

          args = split(" ", each.value.args)

          port {
            container_port = each.value.port
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "app" {
  for_each = { for app in local.applications : app.name => app }

  metadata {
    name = each.value.name
  }

  spec {
    selector = {
      app = each.value.name
    }

    port {
      port        = each.value.port
      target_port = each.value.port
    }
  }
}

