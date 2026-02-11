# Database Migrations and Seeders

This directory contains all database schema migrations and seed data for the FundVance AI project.

## Directory Structure

```
database/
├── migrations/          # Schema changes in chronological order
│   ├── 001_enable_uuid_extension.sql
│   ├── 002_create_profiles_table.sql
│   ├── 003_create_categories_table.sql
│   ├── 004_create_expenses_table.sql
│   ├── 005_create_budgets_table.sql
│   └── 006_add_soft_delete.sql
└── seeders/            # Default data
    └── 001_seed_default_categories.sql
```

## How to Run Migrations

### Initial Setup (First Time)
Run migrations in order in **Supabase SQL Editor**:

1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Create a new query
4. Copy and paste each migration file content **in order** (001, 002, 003...)
5. Click **Run** for each migration
6. After all migrations complete, run the seeder files

### Updating Existing Database
If your database is already set up, only run the new migration files you haven't run yet.

**Example:** If you're at migration 003, run migrations 004 and 005.

## Migration Files

- **001_enable_uuid_extension.sql** - Enables UUID generation
- **002_create_profiles_table.sql** - User profiles with currency support
- **003_create_categories_table.sql** - Expense categories with hierarchy
- **003_create_categories_table.sql** - Categories with hierarchy support
- **004_create_expenses_table.sql** - Main expenses tracking
- **005_create_budgets_table.sql** - Budget management with daily/weekly/monthly/yearly periods
- **006_add_soft_delete.sql** - Soft delete support (trash/restore functionality)

## Seeder Files

- **001_seed_default_categories.sql** - Inserts 11 default categories (7 main + 4 food subcategories)

## Important Notes

- Always backup your database before running migrations
- Run migrations in order (by number prefix)
- Never modify old migration files - create new ones for changes
- Test migrations in development before running in production
- Check for errors in Supabase SQL Editor after each migration

## Current Schema Version

**Version:** 006
**Last Updated:** February 12, 2026
**Tables:** profiles, categories, expenses, budgets (4 tables)
**Features:** Soft delete with 30-day auto-cleanup
