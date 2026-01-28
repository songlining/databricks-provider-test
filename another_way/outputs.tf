# Output showing how many individual grant resources are created
output "total_grant_resources" {
  description = "Total number of individual databricks_grant resources"
  value       = 5
}

# Individual grant resource IDs for the strada catalog
output "strada_grant_ids" {
  description = "IDs of individual grant resources for the strada catalog"
  value = {
    grp_data_engineers  = databricks_grant.strada_grp_data_engineers.id
    grp_data_scientists = databricks_grant.strada_grp_data_scientists.id
    grp_bi_users        = databricks_grant.strada_grp_bi_users.id
    spn_ingestion       = databricks_grant.strada_spn_ingestion.id
  }
}

# Individual grant resource IDs for the analytics catalog
output "analytics_grant_ids" {
  description = "IDs of individual grant resources for the analytics catalog"
  value = {
    grp_analysts = databricks_grant.analytics_grp_analysts.id
  }
}

# All grant resources combined
output "all_grant_resources" {
  description = "All individual databricks_grant resource IDs"
  value = {
    strada    = databricks_grant.strada_grp_data_engineers.id
    strada_ds = databricks_grant.strada_grp_data_scientists.id
    strada_bi = databricks_grant.strada_grp_bi_users.id
    strada_sp = databricks_grant.strada_spn_ingestion.id
    analytics = databricks_grant.analytics_grp_analysts.id
  }
}

# Comparison note
output "approach_comparison" {
  description = "Note about this approach vs databricks_grants"
  value       = "This approach uses individual databricks_grant resources (5 total) instead of consolidated databricks_grants resources with dynamic blocks."
}
