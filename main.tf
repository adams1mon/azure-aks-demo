terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group
  location = var.resource_location
}

resource "azurerm_kubernetes_cluster" "cluster" {
  name                = var.cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.cluster_name

  default_node_pool {
    name       = "default"
    vm_size    = var.vm_type
    enable_auto_scaling = true
    node_count = var.initial_node_count
    min_count = var.min_node_count
    max_count = var.max_node_count
  }

  identity {
    type = "SystemAssigned"
  }
}

##################### adding an ingress controller with helm #####################
provider "helm" {
  kubernetes {
    host                    = azurerm_kubernetes_cluster.cluster.kube_config.0.host
    client_certificate      = base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.client_certificate)
    client_key              = base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.client_key)
    cluster_ca_certificate  = base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.cluster_ca_certificate)
  }
}

# create static public ip address to be used by the ingress
resource "azurerm_public_ip" "ingress_ip" {
  name                         = "nginx-ingress-public-ip"
  location                     = azurerm_kubernetes_cluster.cluster.location
  resource_group_name          = azurerm_kubernetes_cluster.cluster.node_resource_group
  allocation_method            = "Static"
  domain_name_label            = var.ingress_dns_label
  sku                          = "Standard" # must be a standard tier for ingress controllers
}

# add an ingress controller
# install nginx ingress controller using helm chart
resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://helm.nginx.com/stable"
  chart      = "nginx-ingress"

  # says that endpoint is not configured
  # name       = "ingress-nginx"
  # repository = "https://kubernetes.github.io/ingress-nginx/"
  # chart      = "ingress-nginx"
  
  depends_on = [
    azurerm_kubernetes_cluster.cluster
  ]

  set {
    name  = "controller.replicaCount"
    value = var.ingress_replicas
  }

  set {
    name  = "controller.service.loadBalancerIP"
    value = azurerm_public_ip.ingress_ip.ip_address
  }

  # these don't work :(
  # set {
  #   name = "namespace"
  #   value = "ingress-nginx"
  # }

  # set {
  #   name = "create-namespace"
  #   value = ""
  # }
}

# TODO: create separate kubernetes namespace for the ingress controller pods
