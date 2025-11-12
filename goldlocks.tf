# ---------------------------------------
# Helm Install - Goldilocks
# ---------------------------------------
resource "helm_release" "goldilocks" {
  name       = "goldilocks"
  repository = "https://charts.fairwinds.com/stable"
  chart      = "goldilocks"
  namespace  = kubernetes_namespace.goldilocks.metadata[0].name
  version    = "6.3.4"  # check for latest at https://charts.fairwinds.com/stable

  values = [
    file("monitor/goldilocks-values.yaml")
  ]

  depends_on = [
    kubectl_manifest.metrics_server
  ]
}
