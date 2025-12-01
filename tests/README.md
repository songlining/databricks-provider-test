# Databricks Grants Tests

This directory contains Terraform tests for the catalog grants configuration.

## Running Tests

### Run All Tests
```bash
terraform test
```

### Run Specific Test File
```bash
terraform test -filter=tests/catalog_grants.tftest.hcl
```

### Run Specific Test Case
```bash
terraform test -filter=tests/catalog_grants.tftest.hcl -verbose
```

## Test Structure

- **catalog_grants.tftest.hcl**: Mock tests that validate the grants configuration without calling the Databricks API
- **validation.tftest.hcl**: Configuration validation tests

## Mock Provider

The tests use Terraform's built-in mock provider functionality to simulate the Databricks provider without requiring actual API credentials or connectivity.

## What's Being Tested

1. **Structure Validation**: Ensures all expected principals are present in the grants configuration
2. **Privilege Validation**: Verifies that all privileges are valid Databricks catalog privileges
3. **Dynamic Block Expansion**: Confirms the dynamic blocks work correctly
4. **Multi-Catalog Pattern**: Tests the for_each pattern for managing multiple catalogs
5. **Resource Efficiency**: Validates that we're using consolidated resources (1 per catalog) instead of multiple individual grant resources

## Benefits of This Approach

- **Cost Reduction**: Instead of creating 50+ individual `databricks_grant` resources, we create 1 `databricks_grants` resource per catalog
- **Easier Management**: All grants for a catalog are defined in one place
- **Better Maintainability**: Changes to grants are simpler to track and review
- **No API Required**: Tests run without Databricks connectivity

## Example Resource Count Comparison

### Old Approach (Individual Grants)
```
50 databricks_grant resources = 50 Terraform Cloud resources
```

### New Approach (Consolidated Grants)
```
1 databricks_grants resource per catalog = 1 Terraform Cloud resource
(regardless of how many grants inside)
```

For a catalog with 10 grants, this is a **90% reduction** in resource count!
