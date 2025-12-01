output "catalog_grants_configuration" {
  description = "The catalog grants configuration being applied"
  value       = local.catalog_grants
}

output "strada_catalog_grants_id" {
  description = "The ID of the strada catalog grants resource"
  value       = databricks_grants.catalog_strada.id
}

output "all_catalog_grants_ids" {
  description = "Map of all catalog grants resource IDs"
  value = {
    for catalog, grants_resource in databricks_grants.catalogs :
    catalog => grants_resource.id
  }
}

output "total_grants_count" {
  description = "Total number of grants configured across all catalogs"
  value = sum([
    for catalog, grants in local.catalog_grants :
    length(grants)
  ])
}
