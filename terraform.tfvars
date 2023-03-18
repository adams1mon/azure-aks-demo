resource_group = "aks-test"
cluster_name = "aks-test"
default_node_count = 1

# should have min. 2 vCPUs
# see 
# https://learn.microsoft.com/en-us/azure/virtual-machines/sizes-b-series-burstable
# https://learn.microsoft.com/en-us/azure/aks/quotas-skus-regions#restricted-vm-sizes
vm_type = "standard_b2s" 