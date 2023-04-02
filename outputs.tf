resource "local_file" "kubeconfig" {
  depends_on   = [azurerm_kubernetes_cluster.cluster]
  filename     = "${path.root}/${var.kubeconfig_output_path}"
  content      = azurerm_kubernetes_cluster.cluster.kube_config_raw
}