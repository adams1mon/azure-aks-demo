resource "local_file" "kubeconfig" {
  depends_on   = [azurerm_kubernetes_cluster.cluster]
  filename     = "kubeconfig"
  content      = azurerm_kubernetes_cluster.cluster.kube_config_raw
}

resource "null" "export_kubeconfig_env" {
  
  depends_on = [
    local_file.kubeconfig
  ]

  provisioner "local-exec" {
    command = "export KUBECONFIG=$${PWD}/kubeconfig"
  }
}