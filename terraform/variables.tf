locals {
  env-dev = var.deployenv == "DEV"
  env-prod = var.deployenv == "PROD"
  dbg-noredis = var.debug == "no-redis"
}

variable "deployenv" {
  default = "DEV"
  description = "Deployment environment to target (DEV/PROD) - affects resource types and scale"
  type = string
}

variable "debug" {
  #default = "no-redis"
  default = null
  description = "Debug flag for various scenarios, e.g. no-redis for no redis deployment"
  type = string
}

#-- name of the application (resource names will all be prefixed with this string)
variable "prefix" {
  default = "bcmazfs"
  description = "Prefix to use for selected resources."
  type = string
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
  default = "westus2"
#  type = list(string)
  type = string
}

variable "address_space" {
  default = ["10.0.0.0/16"]
  description = "Batch pool VNET network address range"
  type = list
}

variable "compute_subnet_cidr" {
  default = ["10.0.16.0/20"]
  description = "Batch compute subnet"
  type = list
}

# compute_hosts_max should match size of compute_subnet CIFR above.  Here 16 * 256
variable "compute_nhosts_max" {
  default = 4094 # less 0 and broadcast
  description = "Max number of compute hosts to support"
  type = number
}

variable "bastion_subnet_cidr" {
  default = ["10.0.0.0/24"]
  description = "Batch compute subnet CIDR"
  type = list
}

variable "infra_subnet_cidr" {
  default = ["10.0.4.0/22"]
  description = "Batch compute subnet"
  type = list
}

variable "start_task" {
  default = "AzFinSimStartTask.sh"
  description = "Azure Batch Start Task Name"
  type = string
}

variable "vm_size" {
  default = "Standard_D8s_v3"
  type = string
}
variable "max_tasks_per_node" {
  default = "8"
  type = string
}
