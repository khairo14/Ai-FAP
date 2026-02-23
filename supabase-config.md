# Supabase Configuration - FundVanceAI

## Project Details

**Project Name:** FundVanceAI  
**Project ID:** vczxtjxerczfisubjlff  
**Project URL:** https://vczxtjxerczfisubjlff.supabase.co  
**Dashboard:** https://supabase.com/dashboard/project/vczxtjxerczfisubjlff

---

## API Keys

> ⚠️ **Keys are stored in `.env` (gitignored) — never commit real keys.**
> Copy `.env.example` to `.env` and fill in your values.

### Anon/Public Key (Safe for client-side)
Stored in `.env` as `SUPABASE_ANON_KEY`  
✅ Use this in Flutter app  
✅ Safe to expose in mobile apps  
⚠️ Protected by Row Level Security (RLS)

### Service Role Key (KEEP SECRET!)
Stored in `.env` as `SUPABASE_SERVICE_ROLE_KEY`  
❌ **NEVER** commit this to Git  
❌ **NEVER** use in client-side code  
✅ Only use in backend/Edge Functions  
✅ Bypasses RLS - has full database access

---

## Environment Variables

Credentials are stored in:
- **`.env`** - Your local development (ignored by Git)
- **`.env.example`** - Template for other developers

---

## Quick Links

- **SQL Editor:** https://supabase.com/dashboard/project/vczxtjxerczfisubjlff/editor
- **Table Editor:** https://supabase.com/dashboard/project/vczxtjxerczfisubjlff/editor
- **Authentication:** https://supabase.com/dashboard/project/vczxtjxerczfisubjlff/auth/users
- **Storage:** https://supabase.com/dashboard/project/vczxtjxerczfisubjlff/storage/buckets
- **API Docs:** https://supabase.com/dashboard/project/vczxtjxerczfisubjlff/api
- **Logs:** https://supabase.com/dashboard/project/vczxtjxerczfisubjlff/logs-explorer

---

## Next Steps

1. ✅ Credentials saved in `.env`
2. ⬜ Execute database schema (see PHASE1_SETUP.md)
3. ⬜ Create Flutter project
4. ⬜ Test Supabase connection
5. ⬜ Set up authentication

---

## Security Checklist

- [x] `.env` added to `.gitignore`
- [x] Service role key kept secret
- [ ] Row Level Security (RLS) policies created
- [ ] API rate limiting configured
- [ ] Authentication enabled

---

## Supabase CLI Setup

```bash
# Login to Supabase
supabase login

# Link to this project
supabase link --project-ref vczxtjxerczfisubjlff

# Pull remote schema
supabase db pull

# Run migrations
supabase db push
```

---

**Created:** February 11, 2026  
**Last Updated:** February 11, 2026
