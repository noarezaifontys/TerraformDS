terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

data "azurerm_resource_group" "main" {
  name = "Dataplatform-Group-Monitoring"
}

resource "azurerm_kubernetes_cluster" "aks" {
  # depends_on = [azurerm_kubernetes_cluster.aks]
  name                = "my-aks-cluster"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  dns_prefix          = "myaksdns"

  default_node_pool {
  name                = "default"
  vm_size             = "Standard_DS3_v2"
  os_disk_size_gb     = 50
  type                = "VirtualMachineScaleSets"
  auto_scaling_enabled = true
  min_count           = 1
  max_count           = 15
  }

  identity {
    type = "SystemAssigned"
  }

  oidc_issuer_enabled = true
  role_based_access_control_enabled = true

  network_profile {
    network_plugin = "azure"
  }

  tags = {
    Environment = "dev"
  }
  
}

data "azurerm_kubernetes_cluster" "aks_data" {
  name                = azurerm_kubernetes_cluster.aks.name
  resource_group_name = azurerm_kubernetes_cluster.aks.resource_group_name
}

# Define Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-mon-innovationlab"
  location = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]
}

#Define security group ===============================================================================================================================
resource "azurerm_network_security_group" "AKSsg" {
  name                = "SecurityGroupGeneral"
  location = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
}

# #Define security rules
# resource "azurerm_network_security_rule" "AgentToFleet" {
#       name                        = "AgentToFleet"
#       priority                    = 100
#       direction                   = "Inbound"
#       access                      = "Allow"
#       protocol                    = "Tcp"
#       source_port_range           = "*"
#       destination_port_range      = "8220"
#       source_address_prefix       = "*"
#       destination_address_prefix  = "*"
#       resource_group_name         = data.azurerm_resource_group.main.name
#       network_security_group_name = azurerm_network_security_group.AKSsg.name
# }
# resource "azurerm_network_security_rule" "AgentToElastic" {
#       name                        = "AgentToElastic"
#       priority                    = 101
#       direction                   = "Inbound"
#       access                      = "Allow"
#       protocol                    = "Tcp"
#       source_port_range           = "*"
#       destination_port_range      = "9200"
#       source_address_prefix       = "*"
#       destination_address_prefix  = "*"
#       resource_group_name         = data.azurerm_resource_group.main.name
#       network_security_group_name = azurerm_network_security_group.AKSsg.name
# }
# resource "azurerm_network_security_rule" "AgentToLogtash" {
#       name                        = "AgentToLogtash"
#       priority                    = 102
#       direction                   = "Inbound"
#       access                      = "Allow"
#       protocol                    = "Tcp"
#       source_port_range           = "*"
#       destination_port_range      = "5044"
#       source_address_prefix       = "*"
#       destination_address_prefix  = "*"
#       resource_group_name         = data.azurerm_resource_group.main.name
#       network_security_group_name = azurerm_network_security_group.AKSsg.name
# }
# resource "azurerm_network_security_rule" "AgentToKibanaWhenFleet" {
#       name                        = "AgentToKibanaWhenFleet"
#       priority                    = 103
#       direction                   = "Inbound"
#       access                      = "Allow"
#       protocol                    = "Tcp"
#       source_port_range           = "*"
#       destination_port_range      = "5601"
#       source_address_prefix       = "*"
#       destination_address_prefix  = "*"
#       resource_group_name         = data.azurerm_resource_group.main.name
#       network_security_group_name = azurerm_network_security_group.AKSsg.name
# }
# resource "azurerm_network_security_rule" "FleetToElastic" {
#       name                        = "FleetToElastic"
#       priority                    = 104
#       direction                   = "Inbound"
#       access                      = "Allow"
#       protocol                    = "Tcp"
#       source_port_range           = "*"
#       destination_port_range      = "9200"
#       source_address_prefix       = "*"
#       destination_address_prefix  = "*"
#       resource_group_name         = data.azurerm_resource_group.main.name
#       network_security_group_name = azurerm_network_security_group.AKSsg.name
# }
resource "azurerm_network_security_rule" "ssh_sr" {
      name                        = "ssh"
      priority                    = 105
      direction                   = "Inbound"
      access                      = "Allow"
      protocol                    = "Tcp"
      source_port_range           = "*"
      destination_port_range      = "22"
      source_address_prefix       = "*"
      destination_address_prefix  = "*"
      resource_group_name         = data.azurerm_resource_group.main.name
      network_security_group_name = azurerm_network_security_group.AKSsg.name
}

# Define Subnet for AKS
resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# # Define Subnet for Agents
# resource "azurerm_subnet" "agent_subnet" {
#   name                 = "agent-subnet"
#   resource_group_name  = data.azurerm_resource_group.main.name
#   virtual_network_name = azurerm_virtual_network.vnet.name
#   address_prefixes     = ["10.0.2.0/24"]
# }

#Associate subnet with Security Group
resource "azurerm_subnet_network_security_group_association" "aks_subnet_nsg_assoc" {
  subnet_id                 = azurerm_subnet.aks_subnet.id
  network_security_group_id = azurerm_network_security_group.AKSsg.id
}

# #Associate subnet with Security Group
# resource "azurerm_subnet_network_security_group_association" "agents_subnet_nsg_assoc" {
#   subnet_id                 = azurerm_subnet.agent_subnet.id
#   network_security_group_id = azurerm_network_security_group.AKSsg.id
# }

# # Create a public IP address fleetVM
# resource "azurerm_public_ip" "fleet_public_ip" {
#   name = "FleetPubIP"
#   resource_group_name = data.azurerm_resource_group.main.name
#   location = "West Europe"
#   allocation_method = "Static"
# }

# # Create a public IP address agentVM
# resource "azurerm_public_ip" "agent_public_ip" {
#   name = "AgentPubIP"
#   resource_group_name = data.azurerm_resource_group.main.name
#   location = "West Europe"
#   allocation_method = "Static"
# }

# # Setup SSH
# resource "local_file" "create_ssh_folder" {
#   filename = "./ssh/.placeholder"
#   content  = ""
# }

# # Generate SSH Key for Fleet VM
# resource "tls_private_key" "fleet_vm_key" {
#   algorithm = "RSA"
#   rsa_bits  = 2048
# }

# resource "local_file" "fleet_vm_private_key" {
#   depends_on = [local_file.create_ssh_folder]
#   filename   = "./ssh/fleet_vm_id_rsa"
#   content    = tls_private_key.fleet_vm_key.private_key_pem
#   file_permission = "0600"
# }

# resource "local_file" "fleet_vm_public_key" {
#   depends_on = [local_file.create_ssh_folder]
#   filename   = "./ssh/fleet_vm_id_rsa.pub"
#   content    = tls_private_key.fleet_vm_key.public_key_openssh
# }

# # Generate SSH Key for Agent VM
# resource "tls_private_key" "agent_vm_key" {
#   algorithm = "RSA"
#   rsa_bits  = 2048
# }

# resource "local_file" "agent_vm_private_key" {
#   depends_on = [local_file.create_ssh_folder]
#   filename   = "./ssh/agent_vm_id_rsa"
#   content    = tls_private_key.agent_vm_key.private_key_pem
#   file_permission = "0600"
# }

# resource "local_file" "agent_vm_public_key" {
#   depends_on = [local_file.create_ssh_folder]
#   filename   = "./ssh/agent_vm_id_rsa.pub"
#   content    = tls_private_key.agent_vm_key.public_key_openssh
# }

# Setup Agent & Fleet VM + network interfaces 

# # Network Interface for the AKS VM
# resource "azurerm_network_interface" "fleet_vm_nic" {
#   name                = "fleet-vm-nic"
#   location            = data.azurerm_resource_group.main.location
#   resource_group_name = data.azurerm_resource_group.main.name

#   ip_configuration {
#     name                          = "internal"
#     subnet_id                     = azurerm_subnet.aks_subnet.id
#     private_ip_address_allocation = "Dynamic"
#     public_ip_address_id          = azurerm_public_ip.fleet_public_ip.id
#   }
# }

# # AKS VM
# resource "azurerm_linux_virtual_machine" "fleet_vm" {
#   name                = "fleet-vm"
#   location            = data.azurerm_resource_group.main.location
#   resource_group_name = data.azurerm_resource_group.main.name
#   size                = "Standard_B1s"
#   admin_username      = "azureuser"
#   admin_ssh_key {
#     username   = "azureuser"
#     public_key = tls_private_key.fleet_vm_key.public_key_openssh
#   }
#   network_interface_ids = [azurerm_network_interface.fleet_vm_nic.id]

#   source_image_reference {
#     publisher = "Canonical"
#     offer     = "ubuntu-24_04-lts"
#     sku       = "server"
#     version   = "latest"
#   }

#   os_disk {
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#     disk_size_gb         = 30
#   }
# }

# # Network Interface for the Agent VM
# resource "azurerm_network_interface" "agent_vm_nic" {
#   name                = "agent-vm-nic"
#   location            = data.azurerm_resource_group.main.location
#   resource_group_name = data.azurerm_resource_group.main.name

#   ip_configuration {
#     name                          = "internal"
#     subnet_id                     = azurerm_subnet.agent_subnet.id
#     private_ip_address_allocation = "Dynamic"
#     public_ip_address_id          = azurerm_public_ip.agent_public_ip.id
#   }
# }

# # Agent VM
# resource "azurerm_linux_virtual_machine" "agent_vm" {
#   name                = "agent-vm"
#   location            = data.azurerm_resource_group.main.location
#   resource_group_name = data.azurerm_resource_group.main.name
#   size                = "Standard_B1s"
#   admin_username      = "azureuser"
#   admin_ssh_key {
#     username   = "azureuser"
#     public_key = tls_private_key.agent_vm_key.public_key_openssh
#   }
#   network_interface_ids = [azurerm_network_interface.agent_vm_nic.id]

#   source_image_reference {
#     publisher = "Canonical"
#     offer     = "ubuntu-24_04-lts"
#     sku       = "server"
#     version   = "latest"
#   }

#   os_disk {
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#     disk_size_gb         = 30
#   }
# }

# Deploy Elasticsearch, Kibana and Logstash on the Kubernetes cluster =========================================================================================================

# providers
provider "kubernetes" {
  config_path = "C:\\Users\\rezai\\.kube\\config" #your kube config (usually: C:\\users\\name\\.kube\\config)
  host                   = data.azurerm_kubernetes_cluster.aks_data.kube_config[0].host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.aks_data.kube_config[0].client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.aks_data.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks_data.kube_config[0].cluster_ca_certificate)
}

# subscription
resource "null_resource" "set_subscription" {
  provisioner "local-exec" {
    command = "az account set --subscription ${var.subscription_id}"
  }
}

# getting the azure credentials
resource "null_resource" "aks_get_credentials" {
  provisioner "local-exec" {
    command = "az aks get-credentials --resource-group ${data.azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.aks.name} --overwrite-existing"
  }
  depends_on = [azurerm_kubernetes_cluster.aks]
}

resource "null_resource" "wait_for_elasticsearch_pod" {
  provisioner "local-exec" {
    command = <<EOT
    kubectl wait --for=condition=ready pod -n default -l app=elasticsearch-alt --timeout=1200s
    EOT
  }
  depends_on = [kubernetes_deployment.elasticsearch2]
}

resource "null_resource" "wait_for_kibana_pod" {
  depends_on = [kubernetes_deployment.kibana2]

  provisioner "local-exec" {
    command = <<EOT
      kubectl wait --for=condition=ready pod -n default -l app=kibana-alt --timeout=1200s
    EOT
  }
}

# using the .sh files
data "external" "enrollment_token" {
  program = ["bash", "${path.module}/elastic-enrollment-token.sh"]
  depends_on = [null_resource.wait_for_elasticsearch_pod]
}

data "external" "elastic_password" {
  program = ["bash", "${path.module}/elastic-password.sh"]
  depends_on = [null_resource.wait_for_elasticsearch_pod]
}

data "external" "verification_code" {
  program = ["bash", "${path.module}/kibana-verification-code.sh"]
  depends_on = [null_resource.wait_for_kibana_pod]
}

output "enrollment_token" {
  value = data.external.enrollment_token.result
}
output "elastic_password" {
  value = data.external.elastic_password.result
}

output "verification_code" {
  value = data.external.verification_code.result
}

# making the Persistent Volume Claim to initalize containers
resource "kubernetes_persistent_volume_claim" "elk_pvc" {
  metadata {
    name      = "elk-pvc"
    namespace = "default"
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "5Gi"
      }
    }

    storage_class_name = "azurefile-csi"
  }

  depends_on = [
    azurerm_kubernetes_cluster.aks,
    null_resource.aks_get_credentials,
  ]
}

# making the Persistent Volume Claim for ELK data
resource "kubernetes_persistent_volume_claim" "elk_data_pvc" {
  metadata {
    name      = "elk-data-pvc"
    namespace = "default"
  }
  spec {
    access_modes      = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "10Gi"
      }
    }
    storage_class_name = "azurefile-csi"
  }
    depends_on = [
    azurerm_kubernetes_cluster.aks,
    null_resource.aks_get_credentials,
  ]
}

# making the Persistent Volume Claim for ELK logs
resource "kubernetes_persistent_volume_claim" "elk_logs_pvc" {
  metadata {
    name      = "elk-logs-pvc"
    namespace = "default"
  }
  spec {
    access_modes      = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "5Gi"
      }
    }
    storage_class_name = "azurefile-csi"
  }
    depends_on = [
    azurerm_kubernetes_cluster.aks,
    null_resource.aks_get_credentials,
  ]
}

# deploying the persitent volumes
resource "kubernetes_config_map" "logstash_config2" {
  depends_on = [kubernetes_persistent_volume_claim.elk_pvc]
  metadata {
    name = "logstash-pipeline-config"
  }

  data = {
    "logstash.conf" = <<-EOT
      input {
        beats {
          port => 5044
        }
      }

      output {
        elasticsearch {
          hosts => ["http://elasticsearch-alt:9200"]
          index => "logstash-%%{+YYYY.MM.dd}"
        }
      }
    EOT
  }
}
#================================================================================================================================================#
resource "kubernetes_config_map" "elasticsearch_config" {
  metadata {
    name = "elasticsearch-config"
    namespace = "default"
  }

  data = {
    "elasticsearch.yml" = <<EOT
    cluster.name: "elk-cluster"
    node.name: "elasticsearch"
    network.host: "0.0.0.0"
    http.port: 9200
    discovery.seed_hosts: ["elasticsearch.default.svc.cluster.local"]
    path.data: /usr/share/elasticsearch/data
    path.logs: /usr/share/elasticsearch/logs
    xpack.security.enabled: false
    xpack.security.enrollment.enabled: false
    EOT
  }
}

# resource "kubernetes_config_map" "kibana_config" {
#   metadata {
#     name      = "kibana-config"
#     namespace = "default"
#   }
 
#   data = {
#     "kibana.yml" = <<EOT
# xpack.security.enabled: false
# elasticsearch.ssl.verificationMode: none
# EOT
#   }
# }

resource "kubernetes_config_map" "logstash_config" {
  metadata {
    name = "logstash-config"
    namespace = "default"
  }

  data = {
    "logstash.yml" = <<EOT
http.host: "0.0.0.0"
xpack.monitoring.enabled: false
    EOT
  }
}
#================================================================================================================================
resource "kubernetes_deployment" "elasticsearch" {
  metadata {
    name      = "elasticsearch"
    namespace = "default"
    labels = { app = "elasticsearch" }
  }

  spec {
    replicas = 1

    selector {
      match_labels = { app = "elasticsearch" }
    }

    template {
      metadata { labels = { app = "elasticsearch" } }

      spec {
        container {
          name  = "elasticsearch"
          image = "docker.elastic.co/elasticsearch/elasticsearch:8.16.1"

          port { container_port = 9200 }

          env {
            name  = "discovery.type"
            value = "single-node"
          }

          resources {
            requests = {
              cpu    = "1000m"  # request 1 CPU
              memory = "2Gi"    # request 2 GiB RAM
            }
            limits = {
              cpu    = "2000m"  # cap at 2 CPU
              memory = "4Gi"    # cap at 4 GiB RAM
            }
          }

          volume_mount {
            name       = "elasticsearch-config"
            mount_path = "/usr/share/elasticsearch/config/elasticsearch.yml"
            sub_path   = "elasticsearch.yml"
          }
        }	

        volume {
          name = "elasticsearch-config"
          config_map {
            name = kubernetes_config_map.elasticsearch_config.metadata[0].name
          }
        }
        
      }
    }
  }
}

resource "kubernetes_deployment" "kibana" {
  metadata {
    name      = "kibana"
    namespace = "default"
    labels    = { app = "kibana" }
  }

  spec {
    replicas = 1

    selector {
      match_labels = { app = "kibana" }
    }

    template {
      metadata { labels = { app = "kibana" } }

      spec {
        container {
          name  = "kibana"
          image = "docker.elastic.co/kibana/kibana:8.16.1"

          port { container_port = 5601 }

          env {
            name  = "ELASTICSEARCH_URL"
            value = "http://elasticsearch.default.svc.cluster.local:9200"
          }
          env {
            name  = "xpack.security.enrollment.enabled"
            value = "true"
          }

          resources {
            requests = {
              cpu    = "500m"   # request 0.5 CPU
              memory = "1Gi"    # request 1 GiB RAM
            }
            limits = {
              cpu    = "1000m"  # cap at 1 CPU
              memory = "2Gi"    # cap at 2 GiB RAM
            }
          }
        #   volume_mount {
        #     name       = "kibana-config"
        #     mount_path = "/usr/share/kibana/config/kibana.yml"
        #     sub_path   = "kibana.yml"
        #   }
        # }
        #   volume {
        #   name = "kibana-config"
        #   config_map {
        #     name = kubernetes_config_map.kibana_config.metadata[0].name
        #   }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "logstash" {
  metadata {
    name      = "logstash"
    namespace = "default"
    labels    = { app = "logstash" }
  }

  spec {
    replicas = 1

    selector {
      match_labels = { app = "logstash" }
    }

    template {
      metadata { labels = { app = "logstash" } }

      spec {
        container {
          name  = "logstash"
          image = "docker.elastic.co/logstash/logstash:8.16.1"

          port { container_port = 5044 }

          resources {
            requests = {
              cpu    = "500m"   # request 0.5 CPU
              memory = "1Gi"    # request 1 GiB RAM
            }
            limits = {
              cpu    = "1000m"  # cap at 1 CPU
              memory = "2Gi"    # cap at 2 GiB RAM
            }

          }
          volume_mount {
            name       = "logstash-config"
            mount_path = "/usr/share/logstash/config/logstash.yml"
            sub_path   = "logstash.yml"
          }
        }	

        volume {
          name = "logstash-config"
          config_map {
            name = kubernetes_config_map.logstash_config.metadata[0].name
          }
        }
      }
    }
  }
}

# Use loadbalancer to expose Elasticsearch, Kibana and Logstash with their respective ports ====================================================================================================
resource "kubernetes_service" "elasticsearch" {
  metadata {
    name      = "elasticsearch"
    namespace = "default"
  }

  spec {
    type = "LoadBalancer"

    selector = {
      app = "elasticsearch"
    }

    port {
      port        = 9200
      target_port = 9200
    }
  }
}

resource "kubernetes_service" "kibana" {
  metadata {
    name      = "kibana"
    namespace = "default"
  }

  spec {
    type = "LoadBalancer"

    selector = {
      app = "kibana"
    }

    port {
      port        = 5601
      target_port = 5601
    }
  }
}

resource "kubernetes_service" "logstash" {
  metadata {
    name      = "logstash"
    namespace = "default"
  }

  spec {
    type = "LoadBalancer"

    selector = {
      app = "logstash"
    }

    port {
      port        = 9600
      target_port = 9600
    }
  }
}

# ELK Stack Classic Kubernetes Resources ===============================================================================================
# Elasticsearch-alt with data and logs buiten outside the container
resource "kubernetes_deployment" "elasticsearch2" {
  depends_on = [
    kubernetes_persistent_volume_claim.elk_data_pvc,
    kubernetes_persistent_volume_claim.elk_logs_pvc,
  ]

  metadata {
    name   = "elasticsearch-alt"
    labels = { app = "elasticsearch-alt" }
  }

  spec {
    replicas = 1

    selector { match_labels = { app = "elasticsearch-alt" } }

    template {
      metadata { labels = { app = "elasticsearch-alt" } }
      spec {
        container {
          name  = "elasticsearch"
          image = "docker.elastic.co/elasticsearch/elasticsearch:8.7.0"

          port { container_port = 9200 }

          env {
            name  = "discovery.type"
            value = "single-node"
          }

          volume_mount {
            name       = "elasticsearch-data"
            mount_path = "/usr/share/elasticsearch/data"
          }
          volume_mount {
            name       = "elasticsearch-logs"
            mount_path = "/usr/share/elasticsearch/logs"
          }
          volume_mount {
            name       = "elasticsearch-config"
            mount_path = "/usr/share/elasticsearch/config/elasticsearch.yml"
            sub_path   = "elasticsearch.yml"
          }
        }

        volume {
          name = "elasticsearch-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.elk_data_pvc.metadata[0].name
          }
        }
        volume {
          name = "elasticsearch-logs"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.elk_logs_pvc.metadata[0].name
          }
        }
        volume {
          name = "elasticsearch-config"
          config_map {
            name = kubernetes_config_map.elasticsearch_config.metadata[0].name
          }
        }
      }
    }
  }
}

# Kibana-alt with persistent data mount
resource "kubernetes_deployment" "kibana2" {
  depends_on = [
    kubernetes_persistent_volume_claim.elk_data_pvc,
  ]

  metadata {
    name   = "kibana-alt"
    labels = { app = "kibana-alt" }
  }

  spec {
    replicas = 1

    selector { match_labels = { app = "kibana-alt" } }

    template {
      metadata { labels = { app = "kibana-alt" } }
      spec {
        container {
          name  = "kibana"
          image = "docker.elastic.co/kibana/kibana:8.7.0"

          port { container_port = 5601 }

          env {
            name  = "ELASTICSEARCH_HOSTS"
            value = "http://elasticsearch-alt:9200"
          }

          volume_mount {
            name       = "kibana-data"
            mount_path = "/usr/share/kibana/data"
          }
          # volume_mount {
          #   name       = "kibana-config"
          #   mount_path = "/usr/share/kibana/config"
          # }

        }

        volume {
          name = "kibana-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.elk_data_pvc.metadata[0].name
          }
        }
        # volume {
        #   name = "kibana-config"
        #   config_map {
        #     name = kubernetes_config_map.kibana_config.metadata[0].name
        #   }
        # }
      }
    }
  }
}

# Logstash-alt with  pipeline and data/log mounts
resource "kubernetes_deployment" "logstash2" {
  depends_on = [
    kubernetes_persistent_volume_claim.elk_data_pvc,
    kubernetes_persistent_volume_claim.elk_logs_pvc,
    kubernetes_config_map.logstash_config2,
  ]

  metadata {
    name   = "logstash-alt"
    labels = { app = "logstash-alt" }
  }

  spec {
    replicas = 1

    selector { match_labels = { app = "logstash-alt" } }

    template {
      metadata { labels = { app = "logstash-alt" } }
      spec {
        container {
          name  = "logstash"
          image = "docker.elastic.co/logstash/logstash:8.7.0"

          port { container_port = 5044 }

          volume_mount {
            name       = "logstash-pipeline"
            mount_path = "/usr/share/logstash/pipeline"
          }
          volume_mount {
            name       = "logstash-data"
            mount_path = "/usr/share/logstash/data"
          }
          volume_mount {
            name       = "logstash-logs"
            mount_path = "/usr/share/logstash/logs"
          }
          volume_mount {
            name       = "logstash-config"
            mount_path = "/usr/share/logstash/config/logstash.yml"
            sub_path   = "logstash.yml"
          }
        }

        volume {
          name = "logstash-pipeline"
          config_map {
            name = kubernetes_config_map.logstash_config2.metadata[0].name
          }
        }
        volume {
          name = "logstash-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.elk_data_pvc.metadata[0].name
          }
        }
        volume {
          name = "logstash-logs"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.elk_logs_pvc.metadata[0].name
          }
        }
        volume {
          name = "logstash-config"
          config_map {
            name = kubernetes_config_map.logstash_config.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "elasticsearch_alt" {
  depends_on = [kubernetes_persistent_volume_claim.elk_pvc]
  metadata {
    name      = "elasticsearch-alt"
    namespace = "default"
  }

  spec {
    type = "ClusterIP"
    selector = {
      app = "elasticsearch-alt"
    }

    port {
      port        = 9200
      target_port = 9200
    }
  }
}

resource "kubernetes_service" "kibana_alt" {
  depends_on = [kubernetes_persistent_volume_claim.elk_pvc]
  metadata {
    name      = "kibana-alt"
    namespace = "default"
  }

  spec {
    type = "ClusterIP"
    selector = {
      app = "kibana-alt"
    }

    port {
      port        = 5601
      target_port = 5601
    }
  }
}

resource "kubernetes_service" "logstash_alt" {
  depends_on = [kubernetes_persistent_volume_claim.elk_pvc]
  metadata {
    name      = "logstash-alt"
    namespace = "default"
  }

  spec {
    type = "ClusterIP"
    selector = {
      app = "logstash-alt"
    }

    port {
      port        = 5044
      target_port = 5044
    }
  }
}