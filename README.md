# Databricks Catalog Grants - Optimized Configuration

This repository demonstrates an optimized approach for managing Databricks catalog grants that significantly reduces Terraform Cloud resource counts and associated costs.

## Problem Statement

The traditional approach of creating individual `databricks_grant` resources results in:
- 50+ individual Terraform resources per catalog
- High Terraform Cloud costs (charged per resource)
- Complex state management
- Difficult-to-maintain configurations

## Solution

This implementation uses:
1. **YAML-based configuration**: Grants defined in `catalog_grants.yaml` for easy editing without touching Terraform code
2. **Consolidated `databricks_grants` resource**: Single resource per catalog instead of multiple individual grant resources
3. **Dynamic blocks**: Manage multiple grants within one resource
4. **Centralized configuration**: All grant definitions loaded from YAML for better maintainability

## Resource Count Comparison

### Before (Traditional Approach)
```hcl
resource "databricks_grant" "strada_data_engineers_use" {
  catalog    = "strada"
  principal  = "grp_data_engineers"
  privileges = ["USE_CATALOG"]
}

resource "databricks_grant" "strada_data_engineers_create" {
  catalog    = "strada"
  principal  = "grp_data_engineers"
  privileges = ["CREATE_SCHEMA"]
}

# ... 48 more individual resources
# Total: 50 Terraform Cloud resources
```

### After (Optimized Approach)
```hcl
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

# Total: 1 Terraform Cloud resource (contains all 50 grants)
```

**Result: 98% reduction in resource count** (50 resources → 1 resource)

## File Structure

```
.
├── catalog_grants.yaml  # YAML configuration for all catalog grants
├── main.tf              # Main Terraform configuration (loads YAML)
├── variables.tf         # Variable definitions
├── outputs.tf           # Output definitions
├── README.md            # This file
├── QUICKSTART.md        # Quick start guide
└── tests/               # Test directory
    ├── README.md                    # Test documentation
    ├── catalog_grants.tftest.hcl   # Mock provider tests
    └── validation.tftest.hcl       # Configuration validation tests
```

## Configuration Structure

### Defining Grants

All grants are defined in `catalog_grants.yaml`:

```yaml
strada:
  - principal: grp_data_engineers
    privileges:
      - USE_CATALOG
      - CREATE_SCHEMA
  - principal: grp_data_scientists
    privileges:
      - USE_CATALOG
  - principal: grp_bi_users
    privileges:
      - USE_CATALOG
  - principal: spn_ingestion
    privileges:
      - USE_CATALOG
      - CREATE_SCHEMA

# Add more catalogs here
# analytics:
#   - principal: grp_analysts
#     privileges:
#       - USE_CATALOG
```

The YAML file is loaded in `main.tf`:

```hcl
locals {
  catalog_grants = yamldecode(file("${path.module}/catalog_grants.yaml"))
}
```

### Resource Definition

The configuration creates resources using two patterns:

1. **Single catalog** (explicit):
```hcl
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
```

2. **Multiple catalogs** (for_each pattern):
```hcl
resource "databricks_grants" "catalogs" {
  for_each = local.catalog_grants
  catalog  = each.key

  dynamic "grant" {
    for_each = each.value
    content {
      principal  = grant.value.principal
      privileges = grant.value.privileges
    }
  }
}
```

## Usage

### Initialize Terraform
```bash
terraform init
```

### Validate Configuration
```bash
terraform validate
```

### Run Tests
```bash
terraform test
```

### Plan Changes
```bash
terraform plan
```

### Apply Configuration
```bash
terraform apply
```

## Testing

The project includes comprehensive tests that run without requiring Databricks API access:

1. **Mock Provider Tests** (`tests/catalog_grants.tftest.hcl`)
   - Validates grant structure
   - Verifies privilege validity
   - Tests dynamic block expansion
   - Validates multi-catalog patterns

2. **Configuration Validation Tests** (`tests/validation.tftest.hcl`)
   - Principal naming convention checks
   - Duplicate principal detection
   - Privilege format validation
   - Resource savings calculation

### Running Tests
```bash
# Run all tests
terraform test

# Run specific test file
terraform test -filter=tests/validation.tftest.hcl

# Verbose output
terraform test -verbose
```

## Benefits

1. **Cost Reduction**: ~98% reduction in Terraform Cloud resource count
2. **YAML Configuration**: Easy-to-edit grants without touching Terraform code
3. **Easier Management**: All grants for a catalog in one place
4. **Better Maintainability**: Simple YAML structure for updates
5. **Separation of Concerns**: Data (YAML) separated from infrastructure code (HCL)
6. **Improved State Management**: Fewer state file entries
7. **Faster Operations**: Fewer resources to manage and update
8. **Clear Audit Trail**: Easy to see all grants per catalog
9. **Non-Terraform User Friendly**: YAML is more accessible than HCL

## Scaling to Multiple Catalogs

To add a new catalog, simply add it to `catalog_grants.yaml`:

```yaml
strada:
  # existing grants
  - principal: grp_data_engineers
    privileges:
      - USE_CATALOG
      - CREATE_SCHEMA

analytics:
  - principal: grp_analysts
    privileges:
      - USE_CATALOG

# Add more catalogs as needed
```

The `databricks_grants.catalogs` resource will automatically handle the new catalog.

## Principal Naming Convention

Follow these prefixes for principals:
- `grp_` - Groups (e.g., `grp_data_engineers`)
- `spn_` - Service Principals (e.g., `spn_ingestion`)
- `usr_` - Individual Users (e.g., `usr_john_doe`)

## Valid Catalog Privileges

Common catalog-level privileges include:
- `USE_CATALOG` - Allows using the catalog
- `CREATE_SCHEMA` - Allows creating schemas in the catalog
- `USE_SCHEMA` - Allows using schemas in the catalog
- `CREATE_TABLE` - Allows creating tables in the catalog

Refer to [Databricks documentation](https://docs.databricks.com/data-governance/unity-catalog/manage-privileges/privileges.html) for the complete list.

## YAML Configuration Best Practices

When editing `catalog_grants.yaml`:

1. **Use consistent indentation**: 2 spaces (no tabs)
2. **Use list syntax**: Always use `- ` prefix for list items
3. **Add comments**: Document why specific privileges are granted
   ```yaml
   # Production ingestion service
   - principal: spn_ingestion
     privileges:
       - USE_CATALOG
       - CREATE_SCHEMA
   ```
4. **Group related grants**: Keep all grants for a catalog together
5. **Validate syntax**: Use `yamllint` or online YAML validators if unsure
6. **Test after changes**: Run `terraform validate` and `terraform test` after editing

## Cost Impact Example

### Scenario: 70 Datasets with Average 10 Grants Each

**Before (Individual Resources)**:
- Total resources: 70 datasets × 10 grants = 700 resources
- Terraform Cloud cost: ~$70/month (assuming $0.10 per resource)

**After (Consolidated Resources)**:
- Total resources: 70 catalogs × 1 grant resource = 70 resources
- Terraform Cloud cost: ~$7/month
- **Savings: $63/month (90% reduction)**

## Migration from Individual Grants

To migrate from individual `databricks_grant` resources:

1. Export current grants configuration
2. Convert to the locals map structure
3. Remove old individual grant resources from state: `terraform state rm 'databricks_grant.*'`
4. Import the new consolidated resource: `terraform import databricks_grants.catalogs[\"strada\"] strada`
5. Run `terraform plan` to verify

## Contributing

When adding new grants:
1. Update `catalog_grants.yaml` with new grants or catalogs
2. Follow the principal naming convention (use prefixes: `grp_`, `spn_`, `usr_`)
3. Ensure privileges are uppercase and valid
4. Maintain proper YAML indentation (2 spaces, no tabs)
5. Run tests before committing: `terraform test`
6. Validate YAML syntax if needed

## Support

For issues or questions:
- Check the [Databricks Provider Documentation](https://registry.terraform.io/providers/databricks/databricks/latest/docs)
- Review the test files for validation examples
- Consult the Terraform Cloud documentation for resource counting details
