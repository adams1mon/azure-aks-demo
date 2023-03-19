resource "local_file" "kubeconfig" {
  depends_on   = [azurerm_kubernetes_cluster.cluster]
  filename     = "${path.root}/confidential/kubeconfig"
  content      = azurerm_kubernetes_cluster.cluster.kube_config_raw
}