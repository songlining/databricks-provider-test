# Alternative Migration Approach

This directory contains an approach for migrating from individual `databricks_grant` resources to consolidated `databricks_grants` resources.

## Why This Directory Exists

This directory demonstrates the **state import approach** for statefile migration, which is useful when:
- You have an existing Terraform state with many individual `databricks_grant` resources
- You want to preserve your existing infrastructure without recreating resources
- You need a safe migration path that doesn't disrupt active grants

## What's Inside

- [`extract-grants.py`](extract-grants.py) - Python script to extract existing grants from your Terraform state and generate the consolidated YAML configuration
- [`MIGRATION.md`](MIGRATION.md) - Detailed step-by-step migration guide
- [`catalog_grants.yaml`](catalog_grants.yaml) - Sample consolidated grants configuration
- [`main.tf`](main.tf) - Terraform configuration using the new `databricks_grants` pattern
- [`variables.tf`](variables.tf) - Variable definitions
- [`outputs.tf`](outputs.tf) - Output definitions

## Quick Start

If you have an existing Terraform state with `databricks_grant` resources:

1. Copy your `terraform.tfstate` to this directory
2. Run the extraction script:
   ```bash
   python3 extract-grants.py
   ```
3. Follow the [MIGRATION.md](MIGRATION.md) guide for complete migration steps

## When to Use This Approach

Use this migration approach if you:
- Have existing `databricks_grant` resources in your state
- Want to consolidate them into `databricks_grants` resources
- Need to maintain infrastructure continuity during migration

## When to Use the Main Directory

Use the main directory's approach if you:
- Are starting fresh without existing state
- Want to see the final optimized configuration
- Are learning the consolidated grants pattern

## Related Documentation

- Main README: [../README.md](../README.md) - Overview of the optimized grants pattern
- Migration Guide: [MIGRATION.md](MIGRATION.md) - Detailed migration instructions
- Comparison: [../COMPARISON.md](../COMPARISON.md) - Before/after comparison
