resource "local_file" "kubeconfig" {
  depends_on   = [azurerm_kubernetes_cluster.cluster]
  filename     = "${path.root}/confidential/kubeconfig"
  content      = azurerm_kubernetes_cluster.cluster.kube_config_raw
}

resource "null_resource" "export_kubeconfig_env" {
  
  depends_on = [
    local_file.kubeconfig
  ]

  provisioner "local-exec" {
    command = "export KUBECONFIG=${path.root}/confidential/kubeconfig"
  }
}