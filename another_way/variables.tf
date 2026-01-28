variable "databricks_host" {
  description = "The Databricks host URL"
  type        = string
  sensitive   = true
}

variable "databricks_token" {
  description = "The Databricks authentication token"
  type        = string
  sensitive   = true
}
