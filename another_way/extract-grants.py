#!/usr/bin/env python3
"""
Extract existing databricks_grant resources from Terraform state
and generate a consolidated catalog_grants.yaml file.
"""

import json
import sys
from pathlib import Path


def main():
    script_dir = Path(__file__).parent
    state_file = script_dir / "terraform.tfstate"
    output_file = script_dir / "catalog_grants.yaml"

    print(f"🔍 Extracting grants from: {state_file}")
    print(f"📝 Output file: {output_file}\n")

    # Check if state file exists
    if not state_file.exists():
        print("❌ Error: State file not found at {state_file}")
        print("   Run this script from the directory containing terraform.tfstate")
        sys.exit(1)

    # Load the Terraform state file
    with open(state_file) as f:
        state = json.load(f)

    # Extract all databricks_grant resources and group by catalog
    catalog_grants = {}

    for resource in state.get("resources", []):
        if resource.get("type") == "databricks_grant":
            for instance in resource.get("instances", []):
                attrs = instance.get("attributes", {})
                catalog = attrs.get("catalog")

                if not catalog:
                    continue

                principal = attrs.get("principal")
                privileges = sorted(attrs.get("privileges", []))

                if catalog not in catalog_grants:
                    catalog_grants[catalog] = []

                catalog_grants[catalog].append({
                    "principal": principal,
                    "privileges": privileges
                })

    # Sort catalogs and grants within each catalog
    sorted_catalogs = dict(sorted(catalog_grants.items()))
    for catalog in sorted_catalogs:
        sorted_catalogs[catalog] = sorted(
            sorted_catalogs[catalog],
            key=lambda x: x["principal"]
        )

    # Write to YAML file
    with open(output_file, "w") as f:
        for catalog, grants in sorted_catalogs.items():
            f.write(f"{catalog}:\n")
            for grant in grants:
                f.write(f"  - principal: {grant['principal']}\n")
                f.write(f"    privileges:\n")
                for priv in grant['privileges']:
                    f.write(f"      - {priv}\n")
            f.write("\n")

    print("✅ Successfully created: catalog_grants.yaml\n")
    print("📋 Summary of extracted grants:")
    for catalog, grants in sorted_catalogs.items():
        print(f"   {catalog}: {len(grants)} grant(s)")

    print("\n🔎 Preview of generated YAML:")
    print("   " + "─" * 40)
    with open(output_file) as f:
        for line in f:
            print("   " + line.rstrip())
    print("   " + "─" * 40)

    print("\n✨ Next steps:")
    print("   1. Review the generated catalog_grants.yaml")
    print("   2. Add this file to your configuration")
    print("   3. Run 'terraform plan' to verify")
    print("   4. Continue with the migration steps in MIGRATION.md")


if __name__ == "__main__":
    main()
