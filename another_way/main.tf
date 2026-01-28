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

# ============================================================================
# Individual databricks_grant resources for the "strada" catalog
# Each resource represents a single grant to a single principal
# ============================================================================

# Grant: grp_data_engineers -> USE_CATALOG, CREATE_SCHEMA on strada catalog
resource "databricks_grant" "strada_grp_data_engineers" {
  catalog = "strada"

  principal  = "grp_data_engineers"
  privileges = ["USE_CATALOG", "CREATE_SCHEMA"]
}

# Grant: grp_data_scientists -> USE_CATALOG on strada catalog
resource "databricks_grant" "strada_grp_data_scientists" {
  catalog = "strada"

  principal  = "grp_data_scientists"
  privileges = ["USE_CATALOG"]
}

# Grant: grp_bi_users -> USE_CATALOG on strada catalog
resource "databricks_grant" "strada_grp_bi_users" {
  catalog = "strada"

  principal  = "grp_bi_users"
  privileges = ["USE_CATALOG"]
}

# Grant: spn_ingestion -> USE_CATALOG, CREATE_SCHEMA on strada catalog
resource "databricks_grant" "strada_spn_ingestion" {
  catalog = "strada"

  principal  = "spn_ingestion"
  privileges = ["USE_CATALOG", "CREATE_SCHEMA"]
}

# ============================================================================
# Individual databricks_grant resources for the "analytics" catalog
# ============================================================================

# Grant: grp_analysts -> USE_CATALOG on analytics catalog
resource "databricks_grant" "analytics_grp_analysts" {
  catalog = "analytics"

  principal  = "grp_analysts"
  privileges = ["USE_CATALOG"]
}
