# Quick Start Guide

Get started with the optimized Databricks grants configuration in 5 minutes.

## Prerequisites

- Terraform 1.7.0 or later (for testing features)
- Databricks workspace access
- Databricks personal access token or service principal credentials

## Step 1: Review the Configuration

This project uses a **YAML-based configuration** for easier management of grants. All catalog grants are defined in `catalog_grants.yaml`, making it simple to edit without touching Terraform code.

Open `catalog_grants.yaml` and review the grants configuration:

```yaml
strada:
  - principal: grp_data_engineers
    privileges:
      - USE_CATALOG
      - CREATE_SCHEMA
  - principal: grp_data_scientists
    privileges:
      - USE_CATALOG
  # ... more grants
```

The configuration is loaded in `main.tf`:

```hcl
locals {
  catalog_grants = yamldecode(file("${path.module}/catalog_grants.yaml"))
}
```

## Step 2: Customize for Your Environment

Edit `catalog_grants.yaml` to match your needs:

```yaml
your_catalog_name:
  - principal: your_group_or_service_principal
    privileges:
      - USE_CATALOG  # Add required privileges
```

### Common Privileges

- `USE_CATALOG` - Basic catalog access
- `CREATE_SCHEMA` - Create schemas in catalog
- `USE_SCHEMA` - Use existing schemas
- `CREATE_TABLE` - Create tables
- `SELECT` - Read table data
- `MODIFY` - Modify table data

## Step 3: Configure Authentication

### Option A: Environment Variables (Recommended)

```bash
export DATABRICKS_HOST="https://your-workspace.cloud.databricks.com"
export DATABRICKS_TOKEN="your-token-here"
```

### Option B: Variables File

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your credentials
```

### Option C: AWS Instance Profile / Azure Managed Identity

If running in cloud environment, the provider can use native authentication:

```hcl
provider "databricks" {
  # Will automatically use instance profile or managed identity
}
```

## Step 4: Initialize Terraform

```bash
terraform init
```

Expected output:
```
Initializing the backend...
Initializing provider plugins...
- Finding databricks/databricks versions matching "~> 1.0"...
- Installing databricks/databricks v1.x.x...

Terraform has been successfully initialized!
```

## Step 5: Run Tests (Optional but Recommended)

Validate your configuration without touching Databricks:

```bash
terraform test
```

Expected output:
```
tests/catalog_grants.tftest.hcl... ok
tests/validation.tftest.hcl... ok

Success! 2 passed, 0 failed.
```

## Step 6: Preview Changes

```bash
terraform plan
```

Review the output to ensure:
- ✅ Correct catalog names
- ✅ Expected principals
- ✅ Appropriate privileges
- ✅ Only desired resources being created

## Step 7: Apply Configuration

```bash
terraform apply
```

Type `yes` when prompted to confirm.

## Step 8: Verify Outputs

After successful apply, check the outputs:

```bash
terraform output
```

Example output:
```
catalog_grants_configuration = {
  "strada" = [
    {
      "principal" = "grp_data_engineers"
      "privileges" = ["USE_CATALOG", "CREATE_SCHEMA"]
    },
    # ...
  ]
}

total_grants_count = 4

all_catalog_grants_ids = {
  "strada" = "strada"
}
```

## Common Tasks

### Adding a New Principal

1. Edit `catalog_grants.yaml` and add to the catalog's grant list:
   ```yaml
   strada:
     - principal: grp_new_team
       privileges:
         - USE_CATALOG
   ```

2. Apply changes:
   ```bash
   terraform apply
   ```

### Adding a New Catalog

1. Add to `catalog_grants.yaml`:
   ```yaml
   new_catalog:
     - principal: grp_team
       privileges:
         - USE_CATALOG
   ```

2. Apply changes:
   ```bash
   terraform apply
   ```

### Modifying Privileges

1. Update the privileges list in `catalog_grants.yaml`:
   ```yaml
   strada:
     - principal: grp_data_engineers
       privileges:
         - USE_CATALOG
         - CREATE_SCHEMA
         - USE_SCHEMA  # Added USE_SCHEMA
   ```

2. Apply changes:
   ```bash
   terraform apply
   ```

### Removing a Grant

1. Remove the grant block from `catalog_grants.yaml`
2. Apply changes:
   ```bash
   terraform apply
   ```

## Troubleshooting

### Error: "databricks_host provider configuration option is required"

**Solution**: Set Databricks credentials via environment variables or terraform.tfvars

### Error: "Invalid privileges"

**Solution**: Check that all privileges are:
- Valid Databricks privileges
- Uppercase (e.g., `USE_CATALOG` not `use_catalog`)
- Appropriate for the resource type (catalog, schema, table)

### Test Failures

**Solution**: Run tests with verbose output:
```bash
terraform test -verbose
```

Review the error messages for specific validation failures.

### Plan Shows Unexpected Changes

**Solution**: Check that:
1. Principal names match exactly (case-sensitive)
2. Privileges are in the correct format
3. No duplicate principals exist for the same catalog

### Error: "Error in function call" or YAML parsing errors

**Solution**: Validate your YAML syntax:
- Ensure proper indentation (use spaces, not tabs)
- Check that lists use the `- ` prefix
- Verify no trailing spaces or special characters
- Test YAML syntax online at yamllint.com if needed

## Best Practices

### 1. Use Naming Conventions

Prefix principals for clarity:
- `grp_` for groups
- `spn_` for service principals
- `usr_` for individual users

### 2. Group Related Privileges

Instead of:
```yaml
strada:
  - principal: grp_team
    privileges:
      - USE_CATALOG
  - principal: grp_team
    privileges:
      - CREATE_SCHEMA
```

Use:
```yaml
strada:
  - principal: grp_team
    privileges:
      - USE_CATALOG
      - CREATE_SCHEMA
```

### 3. Run Tests Before Applying

Always run `terraform test` before `terraform apply` to catch issues early.

### 4. Use Version Control

Commit your configuration to git:
```bash
git add catalog_grants.yaml main.tf variables.tf outputs.tf
git commit -m "Configure Databricks catalog grants"
git push
```

### 5. Document Your Grants

Add comments explaining why specific privileges are granted:
```yaml
strada:
  - principal: spn_ingestion
    # Ingestion service needs to create schemas and tables
    privileges:
      - USE_CATALOG
      - CREATE_SCHEMA
```

## Next Steps

- Review [COMPARISON.md](./COMPARISON.md) to understand the cost savings
- Check [README.md](./README.md) for detailed documentation
- Explore the [tests/](./tests/) directory for validation examples
- Scale to multiple catalogs using the `databricks_grants.catalogs` resource

## Getting Help

- **Databricks Provider**: https://registry.terraform.io/providers/databricks/databricks/latest/docs
- **Terraform Testing**: https://developer.hashicorp.com/terraform/language/tests
- **Unity Catalog Privileges**: https://docs.databricks.com/data-governance/unity-catalog/manage-privileges/

## Summary

You now have an optimized Databricks grants configuration that:
- ✅ Reduces resource count by ~97%
- ✅ Lowers Terraform Cloud costs significantly
- ✅ Simplifies grant management
- ✅ Includes comprehensive tests
- ✅ Follows best practices

Happy granting! 🚀
