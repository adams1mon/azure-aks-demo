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
    node_count = var.default_node_count
    vm_size    = var.vm_type

    # TODO: configure auto-scaling
  }

  auto_scaler_profile {
    
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

# add the nginx ingress controller
# create static public ip address to be used by nginx ingress
resource "azurerm_public_ip" "nginx_ingress" {
  name                         = "nginx-ingress-public-ip"
  location                     = azurerm_kubernetes_cluster.cluster.location
  resource_group_name          = azurerm_kubernetes_cluster.cluster.node_resource_group
  allocation_method            = "Static"
  domain_name_label            = var.ingress_dns_label
  sku                          = "Standard" # must be a standard tier for ingress controllers
}

# install nginx ingress controller using helm chart
resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://helm.nginx.com/stable"
  chart      = "nginx-ingress"

  depends_on = [
    azurerm_kubernetes_cluster.cluster
  ]

  set {
    name  = "controller.replicaCount"
    value = var.ingress_replicas
  }

  # TODO: test if source IP preservation works

  # set {
  #   name  = "controller.service.externalTrafficPolicy"
  #   value = "Local"
  # }

  set {
    name  = "controller.service.loadBalancerIP"
    value = azurerm_public_ip.nginx_ingress.ip_address
  }
}

# TODO: create separate kubernetes namespace for the ingress controller pods
