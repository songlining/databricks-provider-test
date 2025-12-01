variable "databricks_host" {
  description = "Databricks workspace URL"
  type        = string
  default     = ""
}

variable "databricks_token" {
  description = "Databricks authentication token"
  type        = string
  sensitive   = true
  default     = ""
}

variable "additional_catalog_grants" {
  description = "Additional catalog grants to merge with the default configuration"
  type = map(list(object({
    principal  = string
    privileges = list(string)
  })))
  default = {}
}
