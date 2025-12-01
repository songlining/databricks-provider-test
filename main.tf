terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.0"
    }
  }
}

provider "databricks" {
  # Configure provider authentication here
  # host  = var.databricks_host
  # token = var.databricks_token
}

# Local configuration for catalog grants
# Grants are defined in catalog_grants.yaml for easier management
locals {
  catalog_grants = yamldecode(file("${path.module}/catalog_grants.yaml"))
}

# Single resource managing all grants for the strada catalog
# This replaces multiple individual databricks_grant resources
resource "databricks_grants" "catalog_strada" {
  catalog = "strada"

  dynamic "grant" {
    for_each = local.catalog_grants["strada"]

    content {
      principal  = grant.value.principal
      privileges = grant.value.privileges
    }
  }
}

# Example: Dynamic creation of grants resources for all catalogs
# This pattern allows you to scale to multiple catalogs efficiently
resource "databricks_grants" "catalogs" {
  for_each = local.catalog_grants

  catalog = each.key

  dynamic "grant" {
    for_each = each.value

    content {
      principal  = grant.value.principal
      privileges = grant.value.privileges
    }
  }
}
