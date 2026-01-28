# Migration Guide: From databricks_grant to databricks_grants

## Overview

Migrating from individual `databricks_grant` resources to consolidated `databricks_grants` resources.

**Before (Current State):**
- 5 individual `databricks_grant` resources
- One resource per principal per catalog

**After (Target State):**
- 2 consolidated `databricks_grants` resources
- One resource per catalog with dynamic `grant` blocks

## Why Migrate?

| Aspect | databricks_grant (individual) | databricks_grants (consolidated) |
|--------|------------------------------|----------------------------------|
| Resources in state | 1 per grant (e.g., 50+) | 1 per catalog (e.g., 5) |
| Terraform Cloud usage | Higher | ~95% reduction |
| Plan/apply speed | Slower with many resources | Faster |
| Manageability | More verbose | Cleaner with YAML config |

## Migration Strategy

### Challenge: Many-to-One Mapping

Terraform's `moved` blocks only support 1-to-1 resource moves. Since we're moving multiple `databricks_grant` resources into a single `databricks_grants` resource, we'll use a **state import strategy**.

---

## Step-by-Step Migration

### Step 0: Extract Existing Grants to YAML

Before modifying your Terraform configuration, extract the existing grants from your state file and generate the consolidated `catalog_grants.yaml` configuration.

**Run the extraction script:**

```bash
# From your Terraform directory
python3 extract-grants.py
```

This will:
1. Read your `terraform.tfstate` file
2. Extract all `databricks_grant` resources
3. Generate `catalog_grants.yaml` organized by catalog

**Example output:**
```
🔍 Extracting grants from: terraform.tfstate
📝 Output file: catalog_grants.yaml

✅ Successfully created: catalog_grants.yaml

📋 Summary of extracted grants:
analytics: 1 grant(s)
strada: 4 grant(s)
```

**Manual alternative (if you can't run the script):**

```bash
# Using terraform show and jq
terraform show -json | jq '
  .values.root_module.resources[] |
  select(.type == "databricks_grant") |
  {
    catalog: .values.catalog,
    principal: .values.principal,
    privileges: .values.privileges
  }
' > grants.json
# Then convert to YAML format manually
```

**Verify the generated YAML:**

```bash
cat catalog_grants.yaml
```

Expected format:
```yaml
analytics:
  - principal: grp_analysts
    privileges:
      - USE_CATALOG

strada:
  - principal: grp_data_engineers
    privileges:
      - CREATE_SCHEMA
      - USE_CATALOG
  # ... more grants
```

---

### Step 1: Add New Configuration to Existing Code

Add the `databricks_grants` resources to your existing `main.tf` **alongside** the current `databricks_grant` resources:

```hcl
# Existing: Keep individual resources for now
resource "databricks_grant" "strada_grp_data_engineers" {
  catalog     = "strada"
  principal   = "grp_data_engineers"
  privileges  = ["USE_CATALOG", "CREATE_SCHEMA"]
}
# ... (keep all existing individual grant resources)

# NEW: Add consolidated resources
locals {
  catalog_grants = yamldecode(file("${path.module}/catalog_grants.yaml"))
}

resource "databricks_grants" "strada" {
  catalog = "strada"

  dynamic "grant" {
    for_each = local.catalog_grants["strada"]

    content {
      principal  = grant.value.principal
      privileges = grant.value.privileges
    }
  }
}

resource "databricks_grants" "analytics" {
  catalog = "analytics"

  dynamic "grant" {
    for_each = local.catalog_grants["analytics"]

    content {
      principal  = grant.value.principal
      privileges = grant.value.privileges
    }
  }
}
```

Run:
```bash
terraform init
terraform plan
```

Expected result: Plan shows **10 add** (5 new grants) + **0 change** (existing grants).

---

### Step 2: Import Existing State into New Resources

Since `databricks_grant` and `databricks_grants` manage the same underlying API objects, we need to import the existing state into the new resources.

For each catalog, remove all old individual resources from state and add the new consolidated resource:

```bash
# For strada catalog: Remove old individual resources from state
terraform state rm 'databricks_grant.strada_grp_data_engineers'
terraform state rm 'databricks_grant.strada_grp_data_scientists'
terraform state rm 'databricks_grant.strada_grp_bi_users'
terraform state rm 'databricks_grant.strada_spn_ingestion'

# For analytics catalog: Remove old individual resource from state
terraform state rm 'databricks_grant.analytics_grp_analysts'
```

Then import the new consolidated resources:

```bash
# Import the consolidated resources
terraform import 'databricks_grants.strada' 'catalog/strada'
terraform import 'databricks_grants.analytics' 'catalog/analytics'
```

---

### Step 3: Remove Old Resource Definitions

Now remove all the individual `databricks_grant` resource blocks from your `main.tf`, keeping only the new `databricks_grants` resources.

Your `main.tf` should now look like:

```hcl
terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.0"
    }
  }
}

provider "databricks" {
  host  = var.databricks_host
  token = var.databricks_token
}

locals {
  catalog_grants = yamldecode(file("${path.module}/catalog_grants.yaml"))
}

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
```

---

### Step 4: Verify the Migration

Run a plan to confirm everything is in sync:

```bash
terraform plan
```

Expected result: **No changes.** Your infrastructure is now managed by the consolidated resources.

---

### Step 5: Commit the Changes

```bash
git add .
git commit -m "Migrate from databricks_grant to databricks_grants

- Consolidated individual grant resources into catalog-level resources
- Reduced state size from 5 resources to 2 resources
- Added catalog_grants.yaml for centralized grant configuration"
```

---

## Alternative: Zero-Downtime Migration Script

For production environments with many catalogs, use this script:

```bash
#!/bin/bash
# migrate-to-grants.sh

# List all your catalogs here
CATALOGS=("strada" "analytics")

for catalog in "${CATALOGS[@]}"; do
  echo "Processing catalog: $catalog"

  # Find all grant resources for this catalog
  grants=$(terraform state list | grep "databricks_grant.${catalog}_")

  # Remove old individual resources from state
  while IFS= read -r grant; do
    echo "Removing from state: $grant"
    terraform state rm "$grant"
  done <<< "$grants"

  # Import consolidated resource
  echo "Importing: databricks_grants.$catalog"
  terraform import "databricks_grants.$catalog" "catalog/$catalog"
done

echo "Migration complete. Run 'terraform plan' to verify."
```

---

## Rollback Plan

If you need to rollback:

1. Restore the individual `databricks_grant` resource definitions
2. Remove the `databricks_grants` resources from state:
   ```bash
   terraform state rm 'databricks_grants.strada'
   terraform state rm 'databricks_grants.analytics'
   ```
3. Import the individual resources:
   ```bash
   terraform import 'databricks_grant.strada_grp_data_engineers' 'catalog/strada/grp_data_engineers'
   # ... repeat for all individual grants
   ```

---

## Validation Checklist

- [ ] Ran `python3 extract-grants.py` to generate `catalog_grants.yaml`
- [ ] Reviewed and verified generated `catalog_grants.yaml` contains all existing grants
- [ ] Added `databricks_grants` resources to configuration
- [ ] Backed up current state: `terraform state pull > backup.tfstate`
- [ ] Removed old `databricks_grant` resources from state
- [ ] Imported new `databricks_grants` resources
- [ ] Removed old `databricks_grant` definitions from code
- [ ] Ran `terraform plan` with no changes
- [ ] Tested access in Databricks workspace
