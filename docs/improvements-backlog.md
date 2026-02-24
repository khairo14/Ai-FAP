# FundVance AI — Improvements Backlog

**Created:** February 23, 2026  
**Last updated:** February 25, 2026  
**Status:** Active

---

## Priority Order (by effort — low to high)

| Priority | Item | DB Change? | Effort | Status |
|---|---|---|---|---|
| 1 | Onboarding copy fix | ❌ No | Trivial | ✅ Done |
| 2 | Automated greetings (name + time) | ❌ No | Low | ✅ Done |
| 3 | Dashboard account balance icons | ❌ No | Low | ✅ Done |
| 4 | Code quality / fix all warnings | ❌ No | Low | ✅ Done |
| 5 | Subscription tracker sensitivity fix | ❌ No | Low | ✅ Done |
| 6 | Tags on expenses + income | ✅ New columns | Low–Medium | ✅ Done |
| 7 | Favourite merchants (shortcuts) | ❌ No (SharedPrefs) | Low–Medium | ✅ Done |
| 8 | Migration file consolidation | Admin only (reset) | Low–Medium | ☐ — ready to run (all blocking items done) |
| 9 | Theme system | ❌ No | Medium | ✅ Done |
| 10 | Advanced settings screen | ❌ No | Medium | ✅ Done |
| 11 | User profile screen | ❌ No | Medium | ✅ Done |
| 12 | Quick add buttons (frequent expenses) | ❌ No (SharedPrefs) | Medium | ✅ Done |
| 13 | AI for debt management | ❌ No | Medium | ✅ Done |
| 14 | AI for goal setting | ❌ No | Medium | ✅ Done |
| 15 | AI for reports | ❌ No | Medium–High | ✅ Done |
| 16 | Recurring &amp; scheduling (expenses + income + debt + goals + budgets) | ✅ New columns on 3 tables | High | ✅ Done |
| 17 | Vance mascot | ❌ No | High | ☐ |
| — | RevenueCat v9 upgrade + subscription fix | ❌ No | Medium | ✅ Done |

---

## 1. Theme System ✅

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

## 3. Advanced Settings Screen ✅

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

**Files created/modified:**
- `lib/features/settings/screens/settings_screen.dart` ✅ — full 5-section settings UI
- `lib/features/settings/settings_provider.dart` ✅ — ChangeNotifier, 10 preferences in SharedPreferences
- `lib/shared/services/biometric_service.dart` ✅ — wraps local_auth (fingerprint/Face ID)
- `lib/shared/widgets/biometric_gate.dart` ✅ — lock screen on startup + app resume
- `lib/shared/services/local_notification_service.dart` ✅ — schedules budget, weekly, recurring notifications via flutter_local_notifications
- `lib/shared/widgets/hideable_amount.dart` ✅ — tap-to-reveal balance widget
- `lib/features/home/home_screen.dart` ✅ — all balance amounts use HideableAmount; notification toggles passed to NotificationProvider
- `lib/features/notifications/notification_provider.dart` ✅ — refreshAlerts() accepts budget/goal/recurring filter flags
- `lib/features/expenses/screens/expense_list_screen.dart` ✅ — compact list mode (smaller padding + icon)
- `lib/shared/services/connectivity_service.dart` ✅ — tracks wifi vs mobile; exposes isWifiConnected
- `lib/features/connectivity/connectivity_provider.dart` ✅ — canSync(wifiOnly) gate
- `lib/main.dart` ✅ — LocalNotificationService.initialize() + BiometricGate wraps app home
- `android/app/src/main/AndroidManifest.xml` ✅ — USE_BIOMETRIC + USE_FINGERPRINT permissions
- `android/app/src/main/kotlin/.../MainActivity.kt` ✅ — FlutterFragmentActivity (required by local_auth)

---

## 4. Dashboard Account Balances — Correct Icons ✅ Done

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

**Implementation Notes (COMPLETED 2026-02-24):**
- Added `IconHelper.accountTypeIcon(String? category)` static method returning `(IconData, Color)` record — covers all 10 account types including PayPal, Apple Pay, Google Pay
- Removed duplicate inline `switch` from `home_screen.dart`; now uses `IconHelper.accountTypeIcon(account.accountTypeCategory)`
- Removed `_getAccountIcon()` and `_getAccountIconColor()` from `accounts_screen.dart`; replaced with a single `IconHelper.accountTypeIcon()` call + `displayColor` local variable (preserves grey tint for inactive accounts)
- Removed `_getCategoryIcon()` from `add_account_dialog.dart`; replaced with `IconHelper.accountTypeIcon(category).$1`
- `icon_helper.dart` imported in `accounts_screen.dart` and `add_account_dialog.dart`

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

## 6. Code Quality — Fix All Warnings & Info Diagnostics ✅ Done

**Known issues to resolve:**

- ✅ `connectivity_provider.dart` line 17 — `catchError` handler must return `SyncResult` *(fixed)*
- ✅ `dashboard_service.dart` — 4 `curly_braces_in_flow_control_structures` info lints *(fixed 2026-02-23)*
- ✅ `home_screen.dart` — `mounted` used in `_QuickStartCard` → `context.mounted` *(fixed 2026-02-23)*
- ✅ `flutter analyze` — **0 issues** as of 2026-02-24 *(zero errors, zero warnings, zero info)*
- ✅ `rethrow` audit — all `debugPrint` calls are in `catch` blocks, intentional error logging, no bare `rethrow` without context found
- ✅ `print()` / `debugPrint()` audit — all occurrences are namespaced error handlers (e.g. `[SyncService]`, `[RecurringScheduler]`); none are leftover development traces
- ✅ `unused_import` — none found (`dart fix --apply` returned "Nothing to fix")
- ✅ `avoid_unnecessary_null_checks` — none found
- ✅ `dart fix --apply` — ran 2026-02-24, "Nothing to fix"

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

> **✅ All blocking items (Tags, Favourite Merchants, Recurring Scheduling) are now complete — consolidation is ready to run.**

### Current state — 33 files → ~12 canonical files

| System | Original file | Patch files to absorb |
|---|---|---|
| UUID extension | `000001_enable_uuid_extension` | — (standalone, no patches) |
| Profiles | `000002_create_profiles_table` | `20260222000001_add_stripe_fields_to_profiles`, `20260224000001_add_subscription_status_to_profiles` |
| Categories / Expense Categories | `000003_create_categories_table` | `000010_enhance_categories_table`, `20260220000005_rename_categories_to_expense_categories` |
| Expenses | `000004_create_expenses_table` | `000011_add_account_to_expenses`, `20260213000001_add_expense_account_balance_trigger`, `20260221000001_add_recurring_frequency`, `20260223000002_add_tags_to_expenses`, `20260224000004_add_recurring_scheduler_fields` *(expense columns only)* |
| Budgets | `000005_create_budgets_table` | `20260225000001_add_carry_forward_to_budgets` |
| Income system | `000006_create_income_system` | `20260220000001_add_account_to_income`, `20260220000002_income_account_balance_trigger`, `20260224000004_add_recurring_scheduler_fields` *(income_records columns only)* |
| Account system | `000007_create_account_system` | `000012_create_default_accounts`, `000013_fix_accounts_update_policy`, `000014_add_deleted_accounts_select_policy`, `20260214000001_fix_per_account_currency_override`, `20260223000001_clean_account_types` |
| Transfer system | `000008_create_transfer_system` | `20260220000003_transfer_balance_triggers`, `20260220000004_fix_transfer_balance_triggers` |
| Tax system | `000009_create_tax_system` | — (no patches) |
| Merchant overrides | `20260221000003_create_merchant_category_overrides` | — (standalone) |
| Goals system | `20260221000004_create_goals_system` | `20260224000003_add_account_to_goal_contributions` |
| Debt management | `20260221000005_create_debt_management` | `20260224000002_add_account_to_debt_payments`, `20260224000004_add_recurring_scheduler_fields` *(debts columns only)* |

> **Note on `20260224000004_add_recurring_scheduler_fields`:** This single file touches three tables (`expenses`, `income_records`, `debts`). When consolidating, split its contents into the three respective canonical files above.

> **Note on Favourite Merchants:** No DB migration exists — storage is `SharedPreferences` only. No row needed.

**Result:** 33 files → 12 clean canonical files.

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

## 13. Recurring & Scheduling — Expenses, Income, Debt, Goals, Budgets ✅ Done

**What:** Automatically create expense and income records on a set schedule, send debt payment due reminders, nudge goal contributions, and notify on budget period rollover.

**Implemented 2026-02-24:**

| Feature | DB Flags | Form UI | Scheduler | Notifications |
|---|---|---|---|---|
| **Expenses** | `is_recurring`, `recurring_frequency`, `last_auto_created_at`, `is_paused`, `recurring_end_date` ✅ | Toggle + frequency + end-date picker + pause toggle ✅ | ✅ `RecurringSchedulerService._runExpenses()` | ✅ Day-before reminder |
| **Income** | `is_recurring`, `recurrence_pattern`, `next_occurrence`, `last_auto_created_at`, `is_paused` ✅ | Toggle + pattern picker + pause toggle ✅ | ✅ `RecurringSchedulerService._runIncome()` | ✅ Auto-create |
| **Debt** | `payment_due_day`, `payment_reminder_days`, `auto_log_payment` ✅ | Due day + reminder days dropdown + auto-log toggle ✅ | ✅ `RecurringSchedulerService._runDebt()` | ✅ X-day-before reminder |
| **Goals** | — (uses existing contribution data) | — | ✅ `RecurringSchedulerService._runGoals()` — nudge on 5th of month | ✅ Contribution nudge notification |
| **Budgets** | `period` ✅ | — | ✅ `RecurringSchedulerService._runBudgets()` — 1st of month | ✅ Period-start notification |

**New files:**
- `lib/shared/services/recurring_scheduler_service.dart` — unified scheduler, all 5 sub-runners
- `lib/features/settings/screens/scheduled_screen.dart` — 3-tab screen (Expenses / Income / Reminders)

**New DB migration:** `20260224000004_add_recurring_scheduler_fields.sql`

**Settings entry:** "Scheduled & Reminders" ListTile in Notifications section navigates to `ScheduledScreen`.

---

## 14. Subscription Tracker Sensitivity Fix

> **⚠️ What "Subscriptions" means here:** This screen tracks **recurring expense charges** in your spending history — things like Netflix, Spotify, gym memberships, electricity bills, insurance premiums. It works by scanning your logged expenses and finding merchants that charge you on a regular cycle (weekly, bi-weekly, monthly). **This has nothing to do with the app's own FundVance Pro subscription** (that is managed separately by RevenueCat / Stripe). If you see "No subscriptions detected", it means the algorithm hasn't found enough repeated expense entries from the same merchant yet — log the same bill a couple of months in a row and it will start appearing.

**What:** The detection sensitivity is currently too low — users with expense history still see "No subscriptions detected" because the algorithm requires at least 2 matching intervals. New users or users who haven't logged the same merchant 2+ times in the history window won't see results. Additionally, the detection is only triggered when `generateInsights()` is called from the analytics flow.

### Improvements
- **Lower minimum occurrences threshold:** Detect after 1 occurrence if the interval matches a known pattern (30 ± 3 days, 7 ± 1 day, etc.)
- **Dedicated subscription scan:** `SubscriptionDetectionService` runs independently of `SmartInsightsService`; called on `SubscriptionTrackerScreen` load directly against all expense history
- **Onboarding prompt:** When no subscriptions are detected, show a "How it works" card explaining that the screen tracks recurring *expense* charges (not the app subscription), and suggests logging a few months of bills to unlock detection
- **Manual override:** Allow users to manually mark an expense as a subscription from the expense detail screen

**Files to modify:**
- `lib/shared/services/smart_insights_service.dart` — lower detection threshold, expose standalone detection method
- `lib/features/analytics/screens/subscription_tracker_screen.dart` — call dedicated service + show explainer empty state
- `lib/features/expenses/screens/expense_detail_screen.dart` — add "Mark as subscription" option

**Implementation Notes (COMPLETED 2026-02-23):**
- Extended detection window from 3 months (92 days) to 6 months (183 days)
- `generateInsights()` now fetches a dedicated 6-month dataset for `_recurringInsights()` instead of reusing current-month expenses — this was the primary reason "No subscriptions detected" appeared even with history
- Amount similarity: changed from `amounts.every(within 20%)` (100% strict) to 75% of transactions within 25% of median — one promo price or discount month no longer breaks detection
- Fixed gap dead zone: bi-weekly ended at day 19, monthly started at day 22 — gaps of 20–21 days were silently dropped; new ranges: weekly 3–11, bi-weekly 12–20, monthly 21–40
- Added **yearly** detection (330–400 day avg gap) for annual insurance, Adobe, domain renewals
- `_fetchExpenses()` now falls back to SQLite cache filtered by date string when offline (previously returned `[]` silently)

---

## 15. AI for Debt Management

**What:** Add AI-driven coaching to the existing Debt Manager — personalized payoff recommendations, what-if scenario suggestions, and motivational milestone insights.

**Current state:** `DebtService` computes snowball/avalanche schedules and monthly payment amounts. The UI shows payoff progress. There is no AI coaching or contextual advice.

### Features
- **Payoff strategy recommendation:** Based on interest rates and balances, `DebtAIService.recommendStrategy()` picks snowball vs avalanche and explains *why* in plain language ("Avalanche saves you ₱12,400 in interest vs snowball")
- **What-if suggestions:** "If you add ₱500/month to this debt, you'd be debt-free 8 months earlier"
- **Income-aware prompts:** Cross-references `IncomeProvider` stats — if income increased this month, prompt "You earned ₱3,000 more than usual — consider a one-time debt payment"
- **Milestone celebrations:** Smart insight when a debt reaches 25 / 50 / 75 / 100% paid off
- **Debt-free date:** Show projected payoff date on every debt card with a countdown

### Implementation
- `DebtAIService` (`lib/shared/services/debt_ai_service.dart`) — on-device heuristics, no external API
- `DebtAICard` widget in `DebtDetailScreen` — collapsible coaching card similar to `SpendingDigestCard`
- Strategy comparison table: snowball vs avalanche total interest paid + months difference
- All logic on-device; gated as **Premium** feature

**Files to create/modify:**
- `lib/shared/services/debt_ai_service.dart` — new service
- `lib/features/debts/screens/debt_detail_screen.dart` — add `DebtAICard`
- `lib/features/debts/screens/debt_list_screen.dart` — show projected payoff date on cards

---

## 16. AI for Goal Setting

**What:** Add AI-driven coaching to the existing Goals system — smart target suggestions, contribution pacing, and progress insights.

**Current state:** `GoalService` handles contributions and progress tracking. The UI shows progress bars and contribution history. There is no AI pacing or advice.

### Features
- **Smart target suggestion:** When creating a goal, `GoalAIService.suggestTarget()` estimates a realistic amount based on the goal name keyword ("Emergency Fund" → 3–6× monthly expenses; "Vacation" → prompts for destination budget)
- **Monthly contribution pacing:** Given target, current amount, and deadline, compute required monthly contribution and compare against available income surplus
- **At-risk alert:** If the user hasn't contributed in 30 days, generate a coaching insight: "You're ₱2,400 behind pace for your Vacation goal — a ₱800 catch-up this month gets you back on track"
- **Milestone celebrations:** At 25 / 50 / 75 / 100% — celebratory insight card with confetti animation
- **Surplus redirect prompt:** After the month closes, if actual spend < budget, prompt "You saved ₱1,200 vs your budget — move it to your Emergency Fund?"

### Implementation
- `GoalAIService` (`lib/shared/services/goal_ai_service.dart`) — on-device heuristics
- `GoalAICard` widget in `GoalDetailScreen` — pacing summary + action suggestion
- Keyword map for target suggestions (dictionary of goal name patterns → amount formulas)
- All logic on-device; gated as **Premium** feature

**Files to create/modify:**
- `lib/shared/services/goal_ai_service.dart` — new service
- `lib/features/goals/screens/goal_detail_screen.dart` — add `GoalAICard`
- `lib/features/goals/screens/goal_form_screen.dart` — add smart target suggestion

**Implementation Notes (COMPLETED 2026-02-24):**
- `GoalAIService` — on-device heuristics; `recommendContribution()` computes required monthly savings given target, current amount, and deadline; compares against income surplus from `IncomeProvider`
- At-risk detection: if `daysSinceLastContribution > 30`, generates a catch-up coaching message with exact shortfall amount
- Milestone celebrations: insight card triggered at 25 / 50 / 75 / 100% progress
- Surplus redirect prompt: after month closes, if spend < budget, suggests moving surplus to the highest-priority goal
- Keyword map for smart target suggestions: "Emergency Fund" → 3–6× monthly expenses, "Vacation" / "Travel" → prompts for destination estimate, "Car" / "House" → down-payment heuristic
- `GoalAICard` stateless widget in `GoalDetailScreen` — collapsible card showing pacing summary, days-behind alert, and one action suggestion
- All logic on-device; gated as **Premium** feature

---

## 17. AI for Reports

**What:** Enhance the existing weekly/monthly report with AI-generated narrative summaries, anomaly callouts, and forward-looking recommendations — turning raw numbers into actionable insights.

**Current state:** `WeeklyReportScreen` shows spending totals, category breakdown, daily chart, goals snapshot, and debt snapshot. `ReportPdfService` generates a branded PDF. There is no narrative or AI layer.

### Features
- **AI executive summary:** 4–6 sentence NLG paragraph at the top of the report summarising the period, biggest spending category, vs last period, and one recommendation — generated by `ReportAIService.generateSummary()` using template-based NLG (same approach as `SpendingDigestService`)
- **Anomaly callouts:** Highlight categories where spending was >20% above the 3-month average with a ⚠️ badge
- **Trend arrows:** ↑ / ↓ / → arrow + % change next to each category vs prior period
- **Forward recommendation:** One bold action item at the bottom: "Based on this month, reducing Dining Out by 15% would free ₱1,800 for savings"
- **PDF integration:** Inject the AI summary paragraph and anomaly callouts into the PDF output from `ReportPdfService`
- **Premium gate:** AI summary section gated behind `PremiumActionGate`

### Implementation
- `ReportAIService` (`lib/shared/services/report_ai_service.dart`) — on-device template-based NLG; consumes `ReportData` DTO already used by `ReportPdfService`
- `ReportAISummaryCard` widget — collapsible card at top of `WeeklyReportScreen`
- Trend comparison computed against prior 4-week window
- `ReportPdfService` updated to include AI paragraph in PDF header section

**Files to create/modify:**
- `lib/shared/services/report_ai_service.dart` — new service
- `lib/shared/services/report_pdf_service.dart` — inject AI summary + anomaly callouts
- `lib/features/reports/weekly_report_screen.dart` — add `ReportAISummaryCard` + trend arrows

**Implementation Notes (COMPLETED 2026-02-24):**
- `ReportInsightsService` (`lib/shared/services/report_insights_service.dart`) — fully synchronous; no DB re-query; receives pre-loaded `List<Expense>` + `List<Income>` from providers; generates: narrative summary, period-over-period spend change, income vs spend comparison, top category callout, biggest spend day, savings rate observation
- `_ReportAICard` stateless widget added to `WeeklyReportScreen` — rendered from loaded provider data, no async calls in the widget tree
- Custom date range picker: date icon in AppBar opens `showDateRangePicker`; selected range highlighted; `SegmentedButton` adds a dynamic "Custom" tab when a custom range is active
- `_IncomeSummaryCard` added — shows gross income, net (income − expenses), and source breakdown for the selected period
- Prior-period comparison: same duration immediately before the selected range is computed and passed to AI + shown as `_ChangeBadge` (+/−%) on the income and top-category cards
- Bug fix: `_TopCategoriesCard` uses `e.categoryName` from the model join first, falls back to `expenseProvider.getCategoryName()` — fixes categories showing as "Unknown"
- Bug fix: `_DailyBreakdownCard` `SizedBox` height bumped 140 → 160 to prevent bar chart overflow
- Lint fix: all bare `if` statements in the file now have braces

---

## 18. RevenueCat v9 Upgrade + Subscription Detection Fix (Technical)

**What:** Upgrade `purchases_flutter` from v8 to v9 to fix a Kotlin serialization crash, migrate the API, and fix Android/iOS subscription detection.

**Background:**
- `purchases_flutter: ^8.0.0` crashed on Android with `getJsonNameIndexOrThrow` — RevenueCat's backend started returning new enum values that the v8 Kotlin deserializer couldn't handle
- After upgrade, `PurchaseResult` class name conflicted with the SDK's own export — renamed to `PremiumPurchaseResult`
- `purchasePackage()` removed in v9 — replaced with `Purchases.purchase(PurchaseParams.package(package))`
- RevenueCat purchase/restore never wrote to Supabase `profiles.is_premium`, so `_verifySubscription()` (which reads Supabase via Stripe sync) always returned false on Android/iOS even after a successful purchase
- Race condition: on app restart `PremiumProvider.initialize()` ran before `PremiumService.logIn()` tied the RC SDK to the Supabase user ID — anonymous RC user had no entitlement

**Implementation Notes (COMPLETED 2026-02-24):**
- `pubspec.yaml`: `purchases_flutter: ^9.12.2`
- `premium_service.dart`: renamed to `PremiumPurchaseResult`; `purchase()` uses `Purchases.purchase(PurchaseParams.package(p))`; `restore()` has `kIsWeb` guard; `PurchasesErrorHelper` catch replaces wrong enum approach
- `main.dart`: after `PremiumService.configure()`, immediately calls `await PremiumService.logIn(existingUser.id)` if a Supabase session already exists — prevents race condition
- `auth_provider.dart`: `_init()` initial branch also calls `PremiumService.logIn()` as belt-and-suspenders
- `premium_provider.dart` mobile path: RevenueCat primary → Supabase `profiles` fallback if RC shows no entitlement
- `stripe_service.dart`: new `markPremiumFromRevenueCat()` — directly writes `is_premium = true` (and `premium_expires_at`) to `profiles` table after any successful RC `purchase()` or `restore()`
- `premium_provider.dart`: `purchase()` and `restore()` both call `markPremiumFromRevenueCat()` after success
- `paywall_screen.dart`: shows "Unable to load subscription plans" error card with Retry button when RC offerings fail to load
- `profile_screen.dart`: `_verifySubscription()` uses `verifyStripePayment()` (reads Supabase profile) — unchanged; works because RC writes are now synced to Supabase

**Known limitation:** RevenueCat is using a Test Store key (`test_TphBgpXyklOdIrTsqMDJshUJYpw`) — not connected to real Google Play or App Store. For production, real platform apps must be configured in the RC dashboard with proper service account credentials.