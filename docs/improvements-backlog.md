# FundVance AI — Improvements Backlog

**Created:** February 23, 2026  
**Status:** Planning

---

## Priority Order (by effort — low to high)

| Priority | Item | DB Change? | Effort | Status |
|---|---|---|---|---|
| 1 | Onboarding copy fix | ❌ No | Trivial | ✅ Done |
| 2 | Automated greetings (name + time) | ❌ No | Low | ✅ Done |
| 3 | Dashboard account balance icons | ❌ No | Low | ✅ Done |
| 4 | Code quality / fix all warnings | ❌ No | Low | ✅ Done |
| 5 | Tags on expenses + income | ✅ New columns | Low–Medium | ✅ Done |
| 6 | Favourite merchants (shortcuts) | ❌ No (SharedPrefs) | Low–Medium | ✅ Done |
| 7 | Recurring expense scheduling | ✅ Edge Function + pg_cron | High | ☐ |
| 8 | Migration file consolidation | Admin only (reset) | Low–Medium | ☐ — do after 5–7 |
| 9 | Theme system | ❌ No | Medium | ☐ |
| 10 | Advanced settings screen | ❌ No | Medium | ☐ |
| 11 | User profile screen | ❌ No | Medium | ☐ |
| 12 | Quick add buttons (frequent expenses) | ❌ No (SharedPrefs) | Medium | ☐ |
| 13 | Vance mascot | ❌ No | High | ☐ |

---

## 1. Theme System

**What:** Give users control over the app's visual style with 3 free themes and 3 premium themes.

### Free Themes
- **Light** — current default (white / teal seed)
- **Dark** — true dark background (`#121212`), teal accent
- **Cream** — warm off-white (`#FAF7F2`) background, amber/warm-teal accent; easy on the eyes, paper-like feel

### Premium Themes (gated behind Pro)
- **Midnight** — deep navy + gold accents; premium/luxury feel
- **Forest** — deep green base + earthy brown accents; calm, nature-inspired
- **Rose** — soft blush + mauve accents; clean, modern, popular with lifestyle users

### Implementation Notes
- `ThemeProvider` (ChangeNotifier) stores selected theme ID in `SharedPreferences`
- Each theme is a `ThemeData` factory in `app_themes.dart`
- Premium themes: wrap selection in `PremiumActionGate` — free users see lock overlay on tap
- `PremiumProvider` gating must be updated to include `premiumThemes` as a gated feature
- Persist choice across restarts; default to system light/dark

**Files to create/modify:**
- `lib/core/theme/app_themes.dart` — new, 6 `ThemeData` definitions
- `lib/features/settings/theme_provider.dart` — new ChangeNotifier
- `lib/features/settings/screens/theme_selection_screen.dart` — new
- `lib/main.dart` — consume `ThemeProvider` for `MaterialApp.theme`
- `lib/features/premium/premium_provider.dart` — add `premiumThemes` gate

---

## 2. User Profile Screen

**What:** A dedicated profile/account screen showing user info and account management actions.

### Content
- Avatar / initials circle (tap to change photo)
- Display name (editable inline)
- Email address (read-only)
- Member since date
- Current subscription tier badge (Free / Pro)
- Currency selector (move from scattered locations to here)
- Sign out button
- Delete account option (with confirmation + data wipe)

### Implementation Notes
- Pull data from `AuthProvider` + Supabase `profiles` table
- Profile photo: upload to Supabase Storage bucket `avatars`
- Already have `profiles` table from Phase 1 migration

**Files to create/modify:**
- `lib/features/profile/screens/profile_screen.dart` — new
- `lib/features/profile/profile_provider.dart` — new (or extend `AuthProvider`)
- Navigation drawer entry for Profile (already shows email; link to this screen)

---

## 3. Advanced Settings Screen

**What:** Replace the current "Coming Soon" stub with a real, functional settings screen.

### Sections

#### Notifications
- Toggle: Budget alert notifications
- Toggle: Goal milestone notifications
- Toggle: Weekly summary notification
- Toggle: Recurring expense reminders
- Time picker: Preferred notification time

#### Data & Backup
- Button: Export all data as CSV
- Button: Clear local SQLite cache
- Toggle: Auto-sync on wifi only

#### Security
- Toggle: Biometric lock (FaceID / fingerprint) on app open
- Toggle: Hide balances by default (privacy mode)
- Button: Change password (deep-link to Supabase reset email)

#### Appearance
- Theme selector (link to Theme Selection Screen — item 1 above)
- Toggle: Show currency symbol vs. code
- Toggle: Compact transaction list

#### About
- App version
- Privacy policy link
- Terms of service link
- Rate the app

**Files to create/modify:**
- `lib/features/settings/screens/settings_screen.dart` — replace stub
- `lib/features/settings/settings_provider.dart` — new ChangeNotifier
- Store preferences in `SharedPreferences`

---

## 4. Dashboard Account Balances — Correct Icons

**Current issue:** All account cards show the same generic bank icon regardless of account type.

**Fix:** Map each account type/category to the correct icon and color:

| Account Type/Category | Icon | Color |
|---|---|---|
| Bank / Checking / Savings | `account_balance` | Blue |
| E-Wallet / GCash / PayMaya | `account_balance_wallet` | Teal |
| Online Bank | `language` | Indigo |
| Credit Card / Line of Credit | `credit_card` | Orange |
| Cash | `payments` | Green |
| Crypto Wallet | `currency_bitcoin` | Amber |
| Investment Account | `trending_up` | Purple |
| PayPal | `paypal` / `payment` | Dark Blue |
| Apple Pay | `phone_iphone` | Black |
| Google Pay | `g_mobiledata` | Red |

**Files to modify:**
- `lib/core/utils/icon_helper.dart` — ensure all account type IDs map to distinct icons/colors
- `lib/features/accounts/widgets/` (account card widget) — apply `IconHelper` properly
- `lib/features/home/home_screen.dart` — account balance section uses correct icon

---

## 5. Automated Greetings — Name + Time-Based

**Current issues:**
- Shows email address instead of display name in the greeting
- Greeting text is static ("Good morning!" all day)

**Fix:**
- Pull `displayName` from `profiles` table (or fall back to email prefix before `@`)
- Time-based greeting:
  - 05:00–11:59 → "Good morning"
  - 12:00–16:59 → "Good afternoon"
  - 17:00–20:59 → "Good evening"
  - 21:00–04:59 → "Good night"
- Show first name only (split on space, take index 0)
- Example: "Good afternoon, Khairo! 👋"

**Files to modify:**
- `lib/features/home/home_screen.dart` — `_buildWelcomeSection()` method
- `lib/features/auth/auth_provider.dart` — expose `displayName` getter

---

## 6. Code Quality — Fix All Warnings & Info Diagnostics

**Known issues to resolve:**

- ✅ `connectivity_provider.dart` line 17 — `catchError` handler must return `SyncResult` *(fixed)*
- ✅ `dashboard_service.dart` — 4 `curly_braces_in_flow_control_structures` info lints (bare `continue` in `if` without braces) *(fixed 2026-02-23)*
- ✅ `home_screen.dart` — `mounted` used in `_QuickStartCard` (a `StatelessWidget`) → changed to `context.mounted` *(fixed 2026-02-23)*
- ✅ `flutter analyze` — **0 issues** as of 2026-02-23 *(zero errors, zero warnings, zero info)*
- ☐ Audit all `rethrow` in service files replaced with typed catches where needed
- ☐ Remove any `print()` / `debugPrint()` calls left from development
- ☐ Resolve any `unused_import` warnings across all feature files
- ☐ Fix any `avoid_unnecessary_null_checks` lints
- ☐ Run `dart fix --apply` across the entire `lib/` directory

---

## 7. Onboarding Screen — Copy Fix

**Current:** Slide 2 reads "Track Every Dollar"  
**Change to:** "Track Every Money"

**File to modify:**
- `lib/features/onboarding/onboarding_screen.dart` — update page 2 title string

---

## 8. AI Mascot / Bot Character — "Vance"

**Concept:** An in-app AI character that makes the experience interactive, friendly, and memorable — serving as the face of the AI engine behind FundVance.

### Name & Identity
- **Name:** Vance (derived from FundVance)
- **Personality:** Smart but approachable, encouraging without being preachy, has a light sense of humor about money habits
- **Tone:** Like a financially savvy friend, not a corporate advisor

### Visual Design Options

**Option A — Geometric Fox** ✅ CHOSEN
A stylized fox with teal/mint geometric shapes. Foxes symbolize cleverness and resourcefulness — perfect for a financial AI. Simple enough to animate, distinctive as an icon.

**Option B — Abstract Bot** *(alternative, not selected)*
A rounded square robot head with a coin-slot smile, teal visor/eyes, minimalist. Feels tech-forward and fits the "AI" branding well.

**Option C — Owl** *(alternative, not selected)*
An owl with glasses holding a coin or chart. Classic symbol of wisdom, highly recognizable for finance. Can look both cute and authoritative.

### Expressions / States
Vance should have at least 5 expression states used contextually:
1. **Neutral / Idle** — default, friendly smile
2. **Happy / Celebration** — goal reached, budget on track, savings milestone
3. **Alert / Concerned** — budget overspent, bill due, anomaly detected
4. **Thinking / Analyzing** — loading insights, scanning receipt
5. **Sleeping / Offline** — no data yet, offline mode

### Where Vance Appears
- **Onboarding** — guides the user through setup slides (replaces static icons)
- **Home screen** — small avatar next to the greeting ("Vance says: you're on track this week!")
- **Empty states** — instead of a plain icon, Vance sits in the empty expense/budget/goals list with a contextual tip
- **Smart Insights** — Vance "delivers" each insight card (avatar + speech bubble layout)
- **Spending Digest** — Vance narrates the monthly summary
- **Premium paywall** — Vance holds a "Pro" badge inviting the upgrade
- **Celebration moments** — full-screen Vance animation when a goal is reached or budget stays clean for a month

### Technical Approach
- **Format:** Lottie animations (`.json`) via `lottie: ^3.x` package — small file size, smooth, scalable
- **Fallback:** Static SVG/PNG asset for states where animation isn't needed
- **Assets location:** `assets/mascot/vance_idle.json`, `vance_happy.json`, etc.
- **Widget:** `VanceMascot` widget wrapping `LottieBuilder.asset()` with a `state` enum parameter

### Design Brief (for designer handoff)
- Style: Flat vector, 2-3 color palette (teal primary, white, dark navy)
- No gradients — must look clean at 32px icon size up to full-screen
- Should work on both light and dark backgrounds
- Deliverables needed: 5 Lottie animation files + SVG source files

---

## 9. Migration File Consolidation

**Goal:** Fold all patch/fix/alter migrations back into their originating "create" file so the schema can be understood and re-run from a clean set of canonical files — one file per system.

> **⚠️ Do after items 5–7** — Tags, Favourite Merchants, and Recurring Scheduling each add new migrations. Consolidate all of them together once those 3 are complete.

### Current state — 26 files + 3 pending from items 5–7

| System | Original file | Patch files to absorb |
|---|---|---|
| UUID extension | `000001_enable_uuid_extension` | — (standalone, no patches) |
| Profiles | `000002_create_profiles_table` | `20260222000001_add_stripe_fields_to_profiles` |
| Categories / Expense Categories | `000003_create_categories_table` | `000010_enhance_categories_table`, `20260220000005_rename_categories_to_expense_categories` |
| Expenses | `000004_create_expenses_table` | `000011_add_account_to_expenses`, `20260213000001_add_expense_account_balance_trigger`, `20260221000001_add_recurring_frequency` |
| Budgets | `000005_create_budgets_table` | — (no patches) |
| Income system | `000006_create_income_system` | `20260220000001_add_account_to_income`, `20260220000002_income_account_balance_trigger` |
| Account system | `000007_create_account_system` | `000012_create_default_accounts`, `000013_fix_accounts_update_policy`, `000014_add_deleted_accounts_select_policy`, `20260214000001_fix_per_account_currency_override` |
| Transfer system | `000008_create_transfer_system` | `20260220000003_transfer_balance_triggers`, `20260220000004_fix_transfer_balance_triggers` |
| Tax system | `000009_create_tax_system` | — (no patches) |
| Merchant overrides | `20260221000003_create_merchant_category_overrides` | — (standalone) |
| Goals system | `20260221000004_create_goals_system` | — (standalone) |
| Debt management | `20260221000005_create_debt_management` | — (standalone) |
| **Tags** (item 5) | new migration to be created | — (absorb into Expenses row) |
| **Favourite merchants** (item 6) | new migration to be created | — (standalone new table) |
| **Recurring scheduling** (item 7) | new Edge Function + pg_cron migration | — (standalone) |

**Result:** 26 + 3 new files → ~13 clean canonical files.

### Process

1. **Backup** — copy the entire `supabase/migrations/` folder to `supabase/migrations_backup/` (git-ignored); delete once the new files are confirmed correct
2. **Consolidate** — for each system above, merge all patch SQL into the original create file in logical order (table creation → indexes → RLS → triggers → seed data)
3. **Verify** — run `supabase db reset` locally against the consolidated files; confirm all tables, columns, triggers, and RLS policies match the current live schema exactly
4. **Delete patches** — remove the absorbed patch files; only the canonical files remain
5. **Confirm & clean up** — once verified, delete `migrations_backup/`

### Rules for merging
- `ADD COLUMN IF NOT EXISTS` from patch files → convert to column in the original `CREATE TABLE` definition
- `ALTER POLICY` / `CREATE POLICY` fixes → replace the original policy block
- New triggers added in patches → add to the triggers section of the original file
- `DROP` + `CREATE` rewrites in patches → apply the final version only, remove intermediate states
- Keep SQL comments explaining *why* each field/trigger/policy exists

### Important
- This is **local/dev only** — the database can be wiped and re-run from scratch
- Do **not** apply to a live Supabase project without running `supabase migration repair` first
- The backup folder should be `.gitignore`d (`supabase/migrations_backup/`)

---

## 10. Tags on Expenses

**What:** Let users attach one or more short tags (e.g. `#work`, `#family`, `#trip-bali`) to any expense for flexible cross-category grouping and filtering.

**Current state:** `notes` field already exists on expenses. Tags are completely absent from the DB, model, and UI.

### Implementation

- **DB:** Add a `tags text[]` column (Postgres array) to the `expenses` table via a new migration
- **Model:** Add `List<String> tags` to `Expense` + `fromJson` / `toJson` / `copyWith`
- **Service:** Pass `tags` through `createExpense` / `updateExpense`
- **Form UI:** Tag input chip field below the Notes field — user types a tag and presses Enter/comma to add it; chips shown with an × to remove
- **Filter/search:** Allow filtering the expense list by tag
- **Display:** Show tag chips on the expense detail card

**Files to create/modify:**
- `supabase/migrations/` — new migration: `ALTER TABLE expenses ADD COLUMN IF NOT EXISTS tags text[] DEFAULT '{}'`
- `lib/shared/models/expense.dart` — add `tags` field
- `lib/shared/services/expense_service.dart` — pass `tags` through create/update
- `lib/features/expenses/expense_provider.dart` — add `tags` to `addExpense` / `updateExpense`
- `lib/features/expenses/screens/expense_form_screen.dart` — tag chip input widget
- `lib/features/expenses/screens/expense_list_screen.dart` — tag filter option

---

## 11. Favourite Merchants (Shortcuts)

**What:** Let users pin specific merchants as favourites so they appear at the top of the merchant suggestions list — making logging repeat expenses faster.

**Current state:** `recentMerchants` (top 10 from expense history) already exists in `ExpenseProvider`. There is no way to explicitly pin/favourite a merchant.

### Implementation

- **Storage:** Store favourited merchant names as a `List<String>` in `SharedPreferences` (no DB change needed)
- **Provider:** Add `favouriteMerchants` getter + `toggleFavourite(String merchant)` method to `ExpenseProvider`
- **Form UI:** In the merchant suggestions dropdown, show a ★ icon next to each suggestion; tap to toggle favourite. Favourited merchants are pinned to the top of the suggestions list, with a divider before recent ones.
- **Management:** Long-press on a suggestion chip to remove a favourite

**Files to create/modify:**
- `lib/features/expenses/expense_provider.dart` — `favouriteMerchants`, `toggleFavourite()`
- `lib/features/expenses/screens/expense_form_screen.dart` — update suggestions UI with star icons and pinned section

**Implementation Notes (COMPLETED 2026-02-23):**
- `_kFavouritesKey = 'favourite_merchants'` stored in `SharedPreferences`
- `_favouriteMerchants` loaded in `initialize()` alongside recent merchants
- `toggleFavourite(merchant)` trims, adds/removes from list, persists, and calls `notifyListeners()`
- Expense form merchant suggestions rebuilt: favourites section (★ filled chips, tap to unfavourite) shown first, then a divider, then recent-only chips each with a ★ outline icon (tap to pin to favourites)
- Both sections hidden entirely when there are no favourites and no recent merchants

---

## 12. Quick Add Buttons (Frequent Expenses)

**What:** A row of one-tap shortcut buttons on the home screen for the user's most-logged expense types — tap once to open the expense form pre-filled with that merchant, category, and typical amount.

**Current state:** Nothing. User must always open the full form and fill everything from scratch.

### Implementation

- **Data source:** Derive the top 5 most-frequent (merchant + category) pairs from the last 30 days of expenses automatically; users can also manually pin a shortcut
- **UI:** Horizontal scrollable row of outlined chips/cards on the home screen below the greeting; each shows the merchant name, category icon, and last-used amount
- **Action:** Tap opens `ExpenseFormScreen` pre-filled with `merchant`, `categoryId`, `amount`, and `accountId` from the shortcut
- **Management:** Long-press to unpin a shortcut

**Files to create/modify:**
- `lib/features/home/home_screen.dart` — add quick-add row widget
- `lib/features/home/widgets/quick_add_row.dart` — new widget
- `lib/features/expenses/expense_provider.dart` — `frequentExpenseShortcuts` getter (derived from expense history)

---

## 13. Recurring Expense Scheduling (Auto-Create)

**What:** Automatically create an expense record on a set schedule (daily, weekly, monthly, yearly) so regular bills and subscriptions are logged without manual entry.

**Current state:** Expenses have `is_recurring` and `recurring_frequency` flags in the DB and model, and the form has a recurring toggle. However, **no scheduling service exists** — the flags are stored but no records are ever created automatically.

### Implementation

#### Scheduler service
- `RecurringSchedulerService` — on app startup, checks for expenses where `is_recurring = true` and creates new records if the next due date has passed
- Due-date logic: `lastAutoCreatedAt + frequency_interval <= today`
- The newly created expense copies all fields from the template (amount, merchant, category, account, payment method) with `date = today`
- Writes the new expense via `ExpenseService.createExpense()`

#### Notifications
- Day-before reminder via `flutter_local_notifications`: "Subscription due tomorrow: Netflix (₱899)"
- On-creation toast: "Auto-logged: Spotify ₱169"

#### UI additions
- Recurring expense list in Settings or a dedicated "Scheduled" tab — shows all recurring templates with next-due date, amount, and a pause/delete option
- "Pause" flag on the expense record (new DB column: `is_paused boolean DEFAULT false`)

#### DB changes
- New column: `last_auto_created_at timestamptz` — tracks when the last auto-copy was made
- New column: `is_paused boolean DEFAULT false` — lets user pause a recurring series without deleting it
- New column: `recurring_end_date date` — optional hard stop date for the series

**Files to create/modify:**
- `supabase/migrations/` — new migration adding 3 columns to `expenses`
- `lib/shared/services/recurring_scheduler_service.dart` — new service
- `lib/shared/models/expense.dart` — add `lastAutoCreatedAt`, `isPaused`, `recurringEndDate`
- `lib/shared/services/expense_service.dart` — update create/update signatures
- `lib/features/expenses/expense_provider.dart` — expose `recurringExpenses` getter
- `lib/features/expenses/screens/expense_form_screen.dart` — add end-date picker + pause toggle to recurring section
- `lib/features/settings/screens/settings_screen.dart` — add "Scheduled Expenses" entry
- `lib/main.dart` — call `RecurringSchedulerService.runIfNeeded()` on startup