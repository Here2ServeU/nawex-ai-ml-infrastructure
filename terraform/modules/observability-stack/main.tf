terraform {
  required_version = ">= 1.6"
  required_providers {
    helm       = { source = "hashicorp/helm", version = ">= 2.13" }
    kubernetes = { source = "hashicorp/kubernetes", version = ">= 2.30" }
  }
}

resource "kubernetes_namespace" "observability" {
  metadata {
    name = "observability"
    labels = {
      "pod-security.kubernetes.io/enforce" = "restricted"
    }
  }
}

resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.kube_prometheus_stack_version
  namespace  = kubernetes_namespace.observability.metadata[0].name

  values = [yamlencode({
    grafana = {
      adminPassword = var.grafana_admin_password
      defaultDashboardsEnabled = true
      sidecar = {
        dashboards = { enabled = true, searchNamespace = "ALL", label = "grafana_dashboard" }
        datasources = { enabled = true }
      }
    }
    prometheus = {
      prometheusSpec = {
        retention                                = "15d"
        retentionSize                            = "45GB"
        ruleSelectorNilUsesHelmValues            = false
        serviceMonitorSelectorNilUsesHelmValues  = false
        podMonitorSelectorNilUsesHelmValues      = false
        scrapeInterval                           = "30s"
        evaluationInterval                       = "30s"
        storageSpec = {
          volumeClaimTemplate = {
            spec = {
              accessModes      = ["ReadWriteOnce"]
              storageClassName = var.storage_class
              resources        = { requests = { storage = "50Gi" } }
            }
          }
        }
        resources = {
          requests = { cpu = "500m", memory = "2Gi" }
          limits   = { memory = "4Gi" }
        }
      }
    }
    alertmanager = {
      alertmanagerSpec = {
        storage = {
          volumeClaimTemplate = {
            spec = {
              accessModes      = ["ReadWriteOnce"]
              storageClassName = var.storage_class
              resources        = { requests = { storage = "5Gi" } }
            }
          }
        }
      }
    }
  })]
}

resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  version    = var.loki_version
  namespace  = kubernetes_namespace.observability.metadata[0].name

  values = [yamlencode({
    deploymentMode = "SingleBinary"
    loki = {
      auth_enabled = false
      commonConfig = { replication_factor = 1 }
      storage = { type = "filesystem" }
      schemaConfig = {
        configs = [{
          from         = "2024-01-01"
          store        = "tsdb"
          object_store = "filesystem"
          schema       = "v13"
          index        = { prefix = "index_", period = "24h" }
        }]
      }
    }
    singleBinary = {
      replicas = 1
      persistence = {
        enabled          = true
        size             = "20Gi"
        storageClassName = var.storage_class
      }
    }
  })]
}

resource "helm_release" "tempo" {
  name       = "tempo"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "tempo"
  version    = var.tempo_version
  namespace  = kubernetes_namespace.observability.metadata[0].name
}
