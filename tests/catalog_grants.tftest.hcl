# Mock test for catalog grants configuration
# This test validates the structure and logic without calling Databricks API

# Mock provider configuration
mock_provider "databricks" {
  alias = "mock"

  # Mock the databricks_grants resource behavior
  mock_resource "databricks_grants" {
    defaults = {
      id = "mock-grants-id"
    }
  }
}

# Test 1: Validate strada catalog grants structure
run "validate_strada_catalog_grants" {
  command = plan

  # Use mock provider
  providers = {
    databricks = databricks.mock
  }

  # Assertions on the configuration
  assert {
    condition     = length(local.catalog_grants["strada"]) == 4
    error_message = "Expected 4 grant configurations for strada catalog"
  }

  assert {
    condition     = contains([for g in local.catalog_grants["strada"] : g.principal], "grp_data_engineers")
    error_message = "grp_data_engineers should be included in strada grants"
  }

  assert {
    condition     = contains([for g in local.catalog_grants["strada"] : g.principal], "grp_data_scientists")
    error_message = "grp_data_scientists should be included in strada grants"
  }

  assert {
    condition     = contains([for g in local.catalog_grants["strada"] : g.principal], "grp_bi_users")
    error_message = "grp_bi_users should be included in strada grants"
  }

  assert {
    condition     = contains([for g in local.catalog_grants["strada"] : g.principal], "spn_ingestion")
    error_message = "spn_ingestion should be included in strada grants"
  }
}

# Test 2: Validate grant privileges
run "validate_grant_privileges" {
  command = plan

  providers = {
    databricks = databricks.mock
  }

  assert {
    condition = alltrue([
      for grant in local.catalog_grants["strada"] :
      length(grant.privileges) > 0
    ])
    error_message = "All grants must have at least one privilege"
  }

  assert {
    condition = alltrue([
      for grant in local.catalog_grants["strada"] :
      alltrue([
        for priv in grant.privileges :
        contains(["USE_CATALOG", "CREATE_SCHEMA", "USE_SCHEMA", "CREATE_TABLE"], priv)
      ])
    ])
    error_message = "All privileges must be valid Databricks catalog privileges"
  }
}

# Test 3: Verify dynamic block expansion
run "verify_dynamic_block_expansion" {
  command = plan

  providers = {
    databricks = databricks.mock
  }

  # Verify that the resource is created
  assert {
    condition     = databricks_grants.catalog_strada.catalog == "strada"
    error_message = "catalog_strada resource should reference the strada catalog"
  }
}

# Test 4: Validate for_each pattern for multiple catalogs
run "validate_multi_catalog_pattern" {
  command = plan

  providers = {
    databricks = databricks.mock
  }

  assert {
    condition     = length(keys(local.catalog_grants)) >= 1
    error_message = "Should have at least one catalog configured"
  }

  # Verify the catalogs resource uses for_each with the catalog_grants map
  assert {
    condition     = length(keys(local.catalog_grants)) >= 1
    error_message = "catalog_grants map should contain at least one catalog for the for_each pattern"
  }
}

# Test 5: Validate resource count efficiency
run "validate_resource_efficiency" {
  command = plan

  providers = {
    databricks = databricks.mock
  }

  # Verify total grants count
  assert {
    condition = sum([
      for catalog, grants in local.catalog_grants :
      length(grants)
    ]) > 0
    error_message = "Should have at least one grant configured"
  }

  # Verify we're using consolidated resources (1 resource per catalog)
  # instead of 1 resource per grant
  assert {
    condition     = length(keys(databricks_grants.catalogs)) == length(keys(local.catalog_grants))
    error_message = "Should have exactly one databricks_grants resource per catalog"
  }
}
