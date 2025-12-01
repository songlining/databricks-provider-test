# Configuration validation tests
# These tests validate the Terraform configuration logic without provider interaction

variables {
  databricks_host  = "https://mock.databricks.com"
  databricks_token = "mock-token"
}

# Test: Validate locals configuration structure
run "validate_locals_structure" {
  command = plan

  # Override provider to prevent actual API calls
  override_resource {
    target = databricks_grants.catalog_strada
  }

  override_resource {
    target = databricks_grants.catalogs
  }

  assert {
    condition     = can(local.catalog_grants)
    error_message = "local.catalog_grants must be defined"
  }

  assert {
    condition     = can(local.catalog_grants["strada"])
    error_message = "strada catalog must be defined in local.catalog_grants"
  }
}

# Test: Validate principal naming convention
run "validate_principal_naming" {
  command = plan

  override_resource {
    target = databricks_grants.catalog_strada
  }

  override_resource {
    target = databricks_grants.catalogs
  }

  assert {
    condition = alltrue([
      for grant in local.catalog_grants["strada"] :
      can(regex("^(grp_|spn_|usr_)", grant.principal))
    ])
    error_message = "All principals should follow naming convention: grp_ (groups), spn_ (service principals), or usr_ (users)"
  }
}

# Test: Validate no duplicate principals per catalog
run "validate_no_duplicate_principals" {
  command = plan

  override_resource {
    target = databricks_grants.catalog_strada
  }

  override_resource {
    target = databricks_grants.catalogs
  }

  assert {
    condition     = length([for grant in local.catalog_grants["strada"] : grant.principal]) == length(distinct([for grant in local.catalog_grants["strada"] : grant.principal]))
    error_message = "No duplicate principals should exist for the same catalog"
  }
}

# Test: Validate privileges are uppercase
run "validate_privilege_format" {
  command = plan

  override_resource {
    target = databricks_grants.catalog_strada
  }

  override_resource {
    target = databricks_grants.catalogs
  }

  assert {
    condition = alltrue([
      for grant in local.catalog_grants["strada"] :
      alltrue([
        for priv in grant.privileges :
        priv == upper(priv)
      ])
    ])
    error_message = "All privileges must be uppercase"
  }
}

# Test: Validate at least one privilege per grant
run "validate_minimum_privileges" {
  command = plan

  override_resource {
    target = databricks_grants.catalog_strada
  }

  override_resource {
    target = databricks_grants.catalogs
  }

  assert {
    condition = alltrue([
      for grant in local.catalog_grants["strada"] :
      length(grant.privileges) >= 1
    ])
    error_message = "Each grant must have at least one privilege"
  }
}

# Test: Calculate resource savings
run "calculate_resource_savings" {
  command = plan

  override_resource {
    target = databricks_grants.catalog_strada
  }

  override_resource {
    target = databricks_grants.catalogs
  }

  assert {
    condition = length(keys(local.catalog_grants)) < sum([
      for catalog, grants in local.catalog_grants :
      length(grants)
    ])
    error_message = "Consolidated approach should use fewer resources than individual grants"
  }

  assert {
    condition = ((sum([
      for catalog, grants in local.catalog_grants :
      length(grants)
      ]) - length(keys(local.catalog_grants))) / sum([
      for catalog, grants in local.catalog_grants :
      length(grants)
    ]) * 100) > 50
    error_message = "Expected >50% resource savings"
  }
}
