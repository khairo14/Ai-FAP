# Supabase Setup Guide

## Quick Setup Commands

### 1. Install Supabase CLI
```bash
npm install -g supabase
```

### 2. Login to Supabase
```bash
supabase login
```

### 3. Initialize Project (if needed)
```bash
supabase init
```

### 4. Link to Your Supabase Project
```bash
supabase link --project-ref YOUR_PROJECT_REF_ID
```

**To find your Project Ref ID:**
1. Go to your Supabase dashboard
2. Navigate to Settings > General
3. Copy the "Reference ID" (not the full URL)

### 5. Apply Migrations
```bash
supabase db push
```

### 6. Check Database Status
```bash
supabase db status
```

## Manual Seeder Execution

After running migrations, execute seeders manually in the Supabase SQL Editor in this order:

1. `001_seed_default_categories.sql`
2. `002_seed_income_categories.sql`  
3. `003_seed_account_types.sql`
4. `004_seed_transfer_categories.sql`
5. `005_seed_tax_presets.sql`

## Verify Setup

After running migrations and seeders, verify with these queries:

```sql
-- Check all tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Check seeded categories
SELECT name, category_type, is_system 
FROM categories 
WHERE user_id IS NULL;

-- Check account types
SELECT code, name, category 
FROM account_types 
WHERE is_active = true;
```

## Troubleshooting

- **Error: "Project not linked"**: Run `supabase link` again
- **Permission errors**: Ensure you're logged in with correct permissions
- **Migration conflicts**: Check for existing tables in Supabase dashboard

---

**Your Project Details:**
- Project Name: FundVance AI
- Database: PostgreSQL (Supabase)
- Migration Version: 012