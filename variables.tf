variable "subscription_id" {
  description = "Azure Subscription ID (wordt gevraagd bij uitvoeren)"
  type        = string
}

variable "admin_username_keycloak" {
  type        = string
  description = "Username for the admin account"
  default     = ""
}

variable "admin_password_keycloak" {
  type        = string
  description = "Password for the admin account"
  default     = ""
}