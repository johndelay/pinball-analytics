#!/usr/bin/env python3
"""
Reorganize pinball-analytics repository structure
Moves files into logical folders while preserving Git history
"""

import os
import shutil
from pathlib import Path

def create_directory_structure():
    """Create the new directory structure"""
    directories = [
        'docs',
        'workflows',
    ]
    
    for directory in directories:
        Path(directory).mkdir(exist_ok=True)
        print(f"✓ Created directory: {directory}/")

def move_file(source, destination):
    """Move a file if it exists"""
    if os.path.exists(source):
        # Create destination directory if it doesn't exist
        dest_dir = os.path.dirname(destination)
        if dest_dir:
            Path(dest_dir).mkdir(parents=True, exist_ok=True)
        
        shutil.move(source, destination)
        print(f"✓ Moved: {source} → {destination}")
        return True
    else:
        print(f"⚠ Skipped (not found): {source}")
        return False

def reorganize_repository():
    """Main reorganization logic"""
    print("=" * 60)
    print("Reorganizing pinball-analytics repository")
    print("=" * 60)
    print()
    
    # Create new directories
    print("Creating directory structure...")
    create_directory_structure()
    print()
    
    # Move documentation files to docs/
    print("Moving documentation files to docs/...")
    doc_files = [
        'DB Setup Instructions.md',
        'N8N_SETUP_INSTRUCTIONS.md',
        'FUTURE_WORK_ERROR_HANDLING.md',
    ]
    
    for doc_file in doc_files:
        move_file(doc_file, f'docs/{doc_file}')
    print()
    
    # Move workflow files to workflows/
    print("Moving workflow files to workflows/...")
    workflow_files = [
        'Pinball Leaderboard Ingestion (Production - Working).json',
        'grafana_keppy_demo.json',
    ]
    
    for workflow_file in workflow_files:
        move_file(workflow_file, f'workflows/{workflow_file}')
    
    # Move n8n_components workflows
    print("\nMoving n8n_components files to workflows/...")
    n8n_workflows = [
        'n8n_components/snapshot_leaderboard_history.json',
        'n8n_components/N8n_Pinball_Weekly_Bar_Owner_Report_FIXED.json',
        'n8n_components/Pinball_daily_email_summary.json',
    ]
    
    for workflow_file in n8n_workflows:
        filename = os.path.basename(workflow_file)
        move_file(workflow_file, f'workflows/{filename}')
    
    # Remove empty n8n_components directory
    if os.path.exists('n8n_components') and not os.listdir('n8n_components'):
        os.rmdir('n8n_components')
        print("✓ Removed empty directory: n8n_components/")
    print()
    
    print("=" * 60)
    print("Reorganization complete!")
    print("=" * 60)
    print()
    print("New structure:")
    print("""
pinball-analytics/
├── README.md
├── CLAUDE.md
├── bootstrap_db.sh
├── .env
├── .gitignore
├── database/
│   ├── init/
│   │   ├── 01_schema_tables.sql
│   │   ├── 02_constraints_indexes.sql
│   │   ├── 03_seed_data.sql
│   │   ├── 04_history_tracking.sql
│   │   └── 05_daily_stats_table.sql
│   └── functions/
│       └── 01_update_combined_leaderboard_function.sql
├── docs/                                    ← CREATED
│   ├── DB Setup Instructions.md
│   ├── N8N_SETUP_INSTRUCTIONS.md
│   └── FUTURE_WORK_ERROR_HANDLING.md
└── workflows/                               ← CREATED
    ├── Pinball Leaderboard Ingestion (Production - Working).json
    ├── Pinball_daily_email_summary.json
    ├── N8n_Pinball_Weekly_Bar_Owner_Report_FIXED.json
    ├── snapshot_leaderboard_history.json
    └── grafana_keppy_demo.json
""")
    
    print("\nNext steps:")
    print("1. Review the changes")
    print("2. Stage and commit:")
    print("   git add -A")
    print("   git commit -m 'Reorganize repository structure into docs/ and workflows/ folders'")
    print("3. Push to GitHub:")
    print("   git push origin main")
    print()
    print("Note: The files you created today (PROJECT_DOCUMENTATION.md, etc.)")
    print("      should be copied from /mnt/user-data/outputs/ separately")

if __name__ == "__main__":
    # Confirm before running
    print("This script will reorganize your pinball-analytics repository.")
    print("It will move files into docs/ and workflows/ folders.")
    print()
    
    response = input("Continue? (yes/no): ").strip().lower()
    
    if response in ['yes', 'y']:
        print()
        reorganize_repository()
    else:
        print("Aborted.")
