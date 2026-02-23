# Product Roadmap

## Development Timeline

---

## Phase 0: Pre-Development (Month 0)
**Duration:** 2-3 weeks
**Status:** Planning

### Objectives
- Finalize product specifications
- Assemble development team
- Set up infrastructure
- Create initial designs

### Deliverables
- ✅ Complete documentation
- ☐ Technical architecture approved
- ☐ UI/UX designs (wireframes + mockups)
- ☐ Development environment setup
- ☐ Project management tools configured
- ☐ Initial budget and timeline locked

### Team Requirements
- 1 Product Manager
- 2 Backend Developers
- 2 Mobile Developers
- 1 AI/ML Engineer
- 1 UI/UX Designer
- 1 QA Engineer

---

## Phase 1: Foundation & Core Infrastructure (Months 1-2)
**Duration:** 8 weeks
**Status:** ✅ COMPLETED (Week 8)
**Focus:** Build the technical foundation

### Backend Development (Supabase)
**Week 1-2:** ✅ COMPLETED
- ✅ Database schema design (4 tables: profiles, categories, expenses, budgets)
- ✅ PostgreSQL with Row Level Security (RLS)
- ✅ Authentication system (PKCE flow)
- ✅ Basic CRUD endpoints (auto-generated REST API)

**Week 3-4:** ✅ COMPLETED
- ✅ User management system (profiles auto-created on signup)
- ✅ Expense data models with all fields
- ✅ Category system (11 default categories)
- ✅ RLS policies for data security

**Week 5-6:** ✅ COMPLETED
- ✅ Database optimization (8 indexes for performance)
- ✅ Soft delete system with trash functionality
- ✅ Budget tracking implementation
- ☐ Cloud storage setup for receipts
- ☐ File upload handling
- ☐ API documentation

**Week 7-8:** ✅ COMPLETED
- ✅ Basic analytics dashboard
- ✅ Income tracking system with categories
- ✅ Wallet/Bank account management with category-based organization
- ✅ Auto-creation of 12 default accounts on user signup
- ✅ Account grouping by 7 categories (Bank, E-Wallet, Online Bank, Credit, Cash, Crypto, Investment)
- ✅ Dynamic currency system (profile default with smart account updates)
- ✅ Enhanced category management (add/delete)
- ✅ Improved dashboard with proper navigation
- ✅ Budget calculation with income consideration
- ☐ Per-account currency selection (TODO - Week 9)
- ☐ Integration testing
- ☐ Performance optimization
- ☐ Security audit
- ☐ Deployment pipeline

### Mobile Development (Flutter 3.38.9)
**Week 1-2:** ✅ COMPLETED
- ✅ Project setup (Flutter + Material Design 3)
- ✅ Navigation structure (go_router)
- ✅ Authentication screens (login, signup, password reset)
- ✅ Basic UI components

**Week 3-4:** ✅ COMPLETED
- ✅ Home dashboard with currency selector
- ✅ Expense list view with filters
- ✅ Add/Edit expense form (all fields)
- ✅ Category selection (with icons)

**Week 5-6:** ✅ COMPLETED
- ✅ State management (Provider pattern)
- ✅ Supabase API integration
- ✅ Error handling with user feedback
- ✅ Currency support (30 currencies)
- ✅ Budget CRUD operations
- ✅ Soft delete with trash and restore
- ✅ Undo functionality (5-second window)

**Week 7-8:** ✅ COMPLETED
- ✅ Basic analytics dashboard
- ✅ Income tracking with categories
- ✅ Wallet/Bank account management with 7 category groups
- ✅ 12 default accounts auto-created on signup (2 bank, 2 online bank, 4 e-wallet, 1 credit, 1 cash, 1 crypto, 1 investment)
- ✅ Category-based account organization and display
- ✅ Simplified add account dialog (category selection)
- ✅ Enhanced category management
- ✅ Improved navigation and dashboard
- ✅ Budget calculation with income
- ✅ Complete dashboard redesign with modern UI
- ✅ Multi-currency support across all features
- ✅ Account type differentiation with icons and colors
- ✅ Enhanced expense form with auto-payment method
- ✅ Improved expense list with modern card layout
- ✅ IconHelper utility for icon/color management
- ✅ Recent Activity with merchant names and category icons
- ✅ Tappable account cards with navigation
- ✅ Database triggers for automatic balance updates
- ✅ Account edit functionality with balance adjustments
- ✅ HomeProvider for dashboard state management
- ✅ DashboardService for centralized data fetching
- ✅ FinancialHealthCard widget (UI ready)
- ✅ IncomeExpensesChart widget (UI ready)
- ✅ Account transfers with currency conversion (live exchange rates via open.er-api.com)
- ✅ Tax calculation for income (presets + user-defined defaults)
- ✅ Per-account currency override
- ✅ Edit/update account functionality
- ✅ Account deletion with soft-delete and restore
- ✅ Category management (expense/income/both type selector, CRUD)
- ✅ Offline mode (SQLite cache, pending-ops sync queue, connectivity monitoring, offline banner UI)
- ✅ Data synchronization (auto-sync on reconnect via SyncService)
- ☐ Performance optimization
- ☐ Comprehensive testing

### Deliverables
- ✅ Backend API (Supabase v1)
- ✅ Database schema (13 migrations with comprehensive financial system)
- ✅ Authentication system (email/password with auto-profile creation)
- ✅ Mobile app foundation (Flutter Material 3)
- ✅ Complete expense CRUD with account tracking
- ✅ Dynamic currency system (profile default, smart account updates)
- ✅ Category management (21 system categories + custom)
- ✅ Budget tracking (create, edit, delete, monitor)
- ✅ Soft delete system (trash, restore, undo, auto-cleanup)
- ✅ Basic analytics dashboard
- ✅ Income tracking system with categories
- ✅ Account management (12 types across 7 categories)
- ✅ Auto-creation of default accounts on signup
- ✅ Category-based account organization
- ✅ Enhanced category management
- ✅ Improved dashboard & navigation
- ✅ Budget calculation with income
- ✅ Complete dashboard redesign with modern UI
- ✅ Multi-currency financial summaries
- ✅ Account type differentiation system
- ✅ Enhanced expense/budget forms with colorful icons
- ✅ IconHelper utility for consistent icon rendering
- ✅ Recent Activity with merchant display
- ✅ Database triggers for balance automation
- ✅ Account edit with balance adjustments
- ✅ State management with HomeProvider
- ✅ DashboardService for data aggregation
- ✅ Financial health & chart widgets
- ✅ Account transfers with live exchange rates
- ✅ Tax calculation integration (presets + user defaults)
- ✅ Per-account currency selection
- ✅ Category CRUD with type selector (expense/income/both)
- ☐ CI/CD pipeline

---

## Phase 1 Extension: Enhanced Financial Management (Week 8-10)
**Duration:** 3 weeks  
**Status:** ✅ COMPLETED (Feb 2026)
**Focus:** Complete financial picture with income, accounts, and improved UX

### Income Tracking System
**Week 8:**
- Income data model and database table
- Income categories (Salary, Freelance, Investments, Business, Others)
- Income service (CRUD operations)
- Income provider (state management)
- Add/Edit income form (amount, source, category, date, description)
- Income list view with filtering and sorting

### Wallet & Bank Account Management
**Week 8:** ✅ COMPLETED
- ✅ Account data model with category support (name, type, balance, bank, institution)
- ✅ Account service with CRUD operations and category joins
- ✅ Account provider with state management
- ✅ Account types table (12 types: Checking, Savings, Online Bank, PayPal, Apple Pay, Google Pay, GCash, Credit Card, Line of Credit, Cash, Crypto Wallet, Investment Account)
- ✅ 7 account categories (Bank, E-Wallet, Online Bank, Credit, Cash, Crypto, Investment)
- ✅ Account list view with category grouping and balance display
- ✅ Add account dialog with category selection
- ✅ Auto-creation of all 12 account types on signup (migration 012)
- ✅ Account selection in expense/income forms
- ✅ Balance tracking and automatic updates
- ✅ Dynamic currency from user profile with smart updates
- ✅ Edit account form (name, description, initial balance, currency)
- ✅ Per-account currency override option
- ✅ Account deletion and soft-delete restore (DeletedAccountsScreen)

### Enhanced Category Management
**Week 9:** ✅ COMPLETED
- ✅ Custom category creation with type selector (Expense / Income / Both)
- ✅ Category deletion with options (reassign or delete expenses)
- ✅ Category editing (name, icon, color, type)
- ✅ Category organization with subcategory support
- ✅ Unified categories screen with 3 sections (Expense / Income / Transfer)
- ☐ Import/export category templates

### Improved Dashboard & Navigation
**Week 9:**
- Main navigation drawer/bottom nav
- Dashboard redesign with financial overview
- Income vs Expenses comparison
- Account balances summary
- Quick action buttons (Add Expense, Add Income, Transfer)
- Recent transactions view
- Monthly financial health indicator

### Budget Calculation with Income
**Week 10:**
- Income-based budget recommendations
- Budget as percentage of income option
- Net income calculation (income - expenses)
- Budget vs actual with income context
- Savings goals based on income
- Budget alerts and notifications
- Financial ratio calculations (savings rate, expense ratio)

### Enhanced Analytics
**Week 10:**
- Income vs Expense trends
- Account balance history
- Category-wise income breakdown
- Net worth tracking
- Financial health metrics
- Income source diversification analysis
- Spending efficiency ratios

### Deliverables
- ✅ Income tracking (add, edit, categorize)
- ✅ Account management (wallets, banks, balances)
- ✅ Enhanced category system (custom creation/deletion)
- ✅ Improved navigation and dashboard
- ✅ Income-aware budget calculations
- ✅ Enhanced analytics with income data
- ✅ Financial overview and health metrics

---

## Phase 2: AI Features & Automation (Months 3-4)
**Duration:** 8 weeks
**Status:** ✅ COMPLETED (Feb 2026)
**Focus:** AI-powered automation and intelligence

### Receipt Scanner (AI-Powered) ✅
- ✅ Camera and gallery image capture (`image_picker ^1.1.2`)
- ✅ On-device OCR via Google ML Kit (`google_mlkit_text_recognition ^0.13.0`)
- ✅ Amount extraction with priority-keyword regex + largest-amount fallback
- ✅ Date recognition with 4 regex patterns
- ✅ Merchant identification (first meaningful non-numeric line)
- ✅ Line-item extraction from raw OCR text
- ✅ Confidence scoring (0.0–1.0) based on field extraction success
- ✅ Receipt review screen — edit all extracted fields before saving
- ✅ Auto-populate expense form from scan result
- ✅ Android permissions (CAMERA, READ_MEDIA_IMAGES)
- ✅ iOS usage descriptions (camera + photo library)

### Smart Categorization (Keyword-Based) ✅
- ✅ `AutoCategorizationService` with 9-category keyword maps
- ✅ Merchant-name keyword matching
- ✅ Item-name keyword matching as fallback
- ✅ Category ID resolution against live Supabase categories
- ✅ Wired into receipt scan flow — category pre-selected on review screen

### Automated Insights & Recommendations ✅
- ✅ `SmartInsightsService` — on-device heuristic engine (no cloud calls)
- ✅ Budget alerts (overspend + approaching threshold)
- ✅ Anomaly detection (per-category Z-score-style comparison)
- ✅ Trend analysis (month-over-month spend direction)
- ✅ Recurring expense detection (weekly / bi-weekly / monthly gap analysis)
- ✅ Milestone insights (categories where spending improved)
- ✅ 5 `InsightType` values × 4 `InsightSeverity` levels
- ✅ `SmartInsightsScreen` — tabbed UI (Insights + Recurring tabs)
- ✅ `_SmartInsightsBanner` on Analytics Dashboard
- ✅ Navigation drawer entry for Smart Insights

### Spending Digest & Notification Centre ✅
- ✅ `SpendingDigestService` — template-based NLG monthly summary (5–6 sentences)
- ✅ `SpendingDigestCard` — collapsible AI digest on Home screen (lazy-loaded)
- ✅ `AppNotification` model (6 `NotificationType` values, 4 severity levels)
- ✅ `NotificationProvider` — in-memory store with read/dismiss/clear all
- ✅ `NotificationsScreen` — swipe-to-dismiss tiles, unread dot indicator
- ✅ Bell icon with red-dot badge on Home app bar
- ✅ Navigation drawer Notifications entry with live unread badge

### Manual Entry Enhancements ✅
- ✅ `recurringFrequency` field added to `expenses` table (daily/weekly/bi-weekly/monthly/yearly)
- ✅ Merchant autocomplete — recent-merchant chips auto-fill merchant + category in expense form
- ✅ Recurring frequency dropdown in expense form (shown when recurring toggle is on)
- ✅ Recurring badge on expense cards (shows frequency label in blue)
- ✅ "Repeat Today" quick action in expense card popup menu (opens pre-filled form)
- ✅ `recentMerchants` getter + `getCategoryForMerchant()` helper in `ExpenseProvider`

### Deliverables
- ✅ On-device receipt scanner (Google ML Kit OCR)
- ✅ Auto-categorization from merchant/item keywords (9 categories)
- ✅ Smart Insights engine — 5 insight types, on-device heuristics
- ✅ Recurring expense detection algorithm
- ✅ Spending Digest — NLG monthly summary shown on Home
- ✅ Notification Centre — in-app alerts with badge count
- ✅ Analytics dashboard integration (insights banner + smart insights screen)
- ✅ Manual entry enhancements (merchant suggestions, recurring scheduler, quick repeat)

---

## Phase 3: AI Features & Intelligence (Months 5-6)
**Duration:** 8 weeks
**Status:** ✅ COMPLETED (Feb 2026)
**Focus:** On-device AI capabilities — personalization, advanced insights, budget intelligence

### Personalization Engine ✅
- ✅ `merchant_category_overrides` Supabase table with RLS + index
- ✅ `PersonalizationService` — singleton with in-memory cache + DB read/write
  - `getOverride(merchant)` — lookup personalized category for a merchant
  - `saveOverride(merchant, categoryId)` — upsert learned override (use_count tracked)
  - `preload()` — pre-warm all overrides for the session (called at expense form open)
  - `deleteOverride(merchant)`, `clearCache()` (sign-out cleanup)
- ✅ Wired into `ExpenseFormScreen`:
  - On merchant field unfocus → try personalization override first, then keyword fallback
  - "Personalized suggestion" indicator shows when DB override is applied
  - On form save → if user changed category manually → saves new override to DB
  - Category dropdown tracks `_userPickedCategory` flag for accurate override detection

### Smart Categorization Improvements ✅
- ✅ Two-tier category suggestion on merchant unfocus:
  1. Personalized DB override (user-specific, learned from corrections)
  2. Keyword rule-based fallback (`AutoCategorizationService`)
- ✅ Personalization indicator chip below category field
- ✅ `PersonalizationService.preload()` called at expense form init (no per-keystroke DB calls)

### Advanced Insights Engine ✅
- ✅ Two new `InsightType` values: `savingsOpportunity`, `spendingPattern`
- ✅ Two new insight generators in `SmartInsightsService`:
  - `_savingsOpportunities()` — finds over-budget categories, quantifies monthly savings potential,
    reports top 3 by overspend amount with "Save $X/mo on Y" messages
  - `_spendingPatternInsights()` — detects concentration risk (top 3 categories = 75%+ of spend)
    and highlights when a single category exceeds 35% of total spend

### Budget Suggestions (50/30/20 Rule Engine) ✅
- ✅ `BudgetSuggestionService` — on-device engine, no external AI
  - Fetches 3-month expense history + income estimate from Supabase
  - Maps categories to Needs (50%) / Wants (30%) buckets by name
  - Allocates proportionally within each bucket; caps overspending to rule limits
  - Rounds suggestions to nearest $5 for clean budgets
  - Marks categories that already have a budget (→ "Update" badge)
- ✅ `BudgetSuggestionScreen`:
  - Income input with auto-detect from `IncomeProvider` stats
  - Inline 50/30/20 rule explainer with bucket legend
  - Suggestions grouped by Needs / Wants; each tile shows 3-mo avg vs suggested amount
  - Checkbox selection per category — toggle individual or Select All / Deselect All
  - "Apply N Budgets" button — bulk create or update budgets via `BudgetProvider`
  - Savings goal tile (20% recommendation, non-budget category)
- ✅ `BudgetListScreen` entry points:
  - AppBar `✨` action button → BudgetSuggestionScreen
  - Persistent AI suggestion banner above the budget list

### Deliverables
- ✅ Smart categorization with personalization engine (user correction learning)
- ✅ Advanced AI insights — savings opportunities + spending concentration patterns
- ✅ Budget suggestions (50/30/20 rule engine with historical analysis)
- ✅ Personalization engine — DB-backed override table, zero latency via cache

---

## Phase 4: Premium Features (Months 7-8)
**Duration:** 8 weeks
**Focus:** Monetization features

### Goal Planner
**Week 1-2:**
- Goal creation UI
- Goal types (savings, debt, purchase)
- Timeline calculator
- Progress tracking

**Week 3-4:**
- AI-powered suggestions
- Spending adjustment recommendations
- Milestone celebrations
- Goal reminders

### Debt Management
**Week 1-2:**
- Debt tracking
- Multiple debt support
- Interest calculation
- Payment scheduling

**Week 3-4:**
- Payoff strategies (snowball/avalanche)
- What-if scenarios
- Optimization recommendations
- Progress visualization

### Subscription Tracker
**Week 1-2:**
- Auto-detection algorithm
- Recurring charge identification
- Subscription database

**Week 3-4:**
- Renewal reminders
- Cost analysis
- Usage tracking
- Cancellation helpers

### Weekly Reports
**Week 5-6:**
- Report generation system
- Email templates
- PDF export
- Customization options

**Week 7-8:**
- Push notification summaries
- Monthly deep dive
- Trends and insights
- Action items

### Multi-Account Support (Premium)
**Week 5-8:**
- Bank connection (Plaid integration)
- Account linking
- Transaction import
- Multi-currency support

### Deliverables
- ✅ Goal planner (GoalListScreen, GoalFormScreen, GoalDetailScreen + contributions)
- ✅ Debt payoff tools (DebtListScreen, DebtFormScreen, DebtDetailScreen + snowball/avalanche simulator)
- ✅ Subscription tracker (auto-detection via SmartInsightsService, cost analysis)
- ✅ Weekly / monthly reports (spending summary, top categories, daily chart, goals & debt snapshot)
- ⏳ Multi-account support (Plaid integration deferred to Phase 5)

**Phase 4 Implementation Notes (completed):**
- DB migrations: `goals`, `goal_contributions`, `debts`, `debt_payments` tables with RLS, triggers, soft-delete
- GoalService + GoalProvider; DebtService (snowball/avalanche simulation) + DebtProvider
- Navigation drawer updated with PLANNING section (Goals, Debt Manager, Subscriptions, Reports)
- GoalProvider + DebtProvider registered in main.dart MultiProvider

---

## Phase 5: Polish & Beta Launch (Months 9-10)
**Duration:** 8 weeks
**Status:** 🚧 IN PROGRESS — Feature-complete, pending launch prep
**Focus:** Exports, premium paywall, push notifications, UI polish, offline mode, launch prep

### Export & Reporting (COMPLETED 2026-02-21)
- ✅ `pdf: ^3.10.8` + `printing: ^5.12.0` packages added
- ✅ `ReportPdfService` — branded A4 PDF generator (`lib/shared/services/report_pdf_service.dart`):
  - Teal-branded header with period range + generated date
  - Spending summary (total, transaction count, daily average)
  - Top-8 categories with proportional progress bars
  - Daily spending table with percentage column
  - Goals snapshot with overall progress bar
  - Debt snapshot section (only rendered when active debts > 0)
  - Page numbers in footer; `Printing.sharePdf()` — web downloads, mobile share sheet, desktop save
- ✅ `WeeklyReportScreen` — PDF export icon in AppBar with loading spinner + error SnackBar

### Premium Implementation (COMPLETED 2026-02-23)
**Week 3-4:**
- ✅ Subscription system (RevenueCat — mobile iOS/Android via `purchases_flutter ^8.2.1`)
- ✅ Payment processing (Stripe — web/desktop via `flutter_stripe` + Supabase Edge Function)
- ✅ Free trial logic (14-day trial baked into Stripe checkout session)
- ✅ Upgrade prompts (`PremiumGate` / `PremiumActionGate` overlays on all gated screens)

**Week 5-6:**
- ✅ Paywall UI (`PaywallScreen` — monthly $4.99 / annual $39.99 with savings badge)
- ✅ Pricing display (plan cards with feature list + trial callout)
- ✅ Restore purchases (RevenueCat `restorePurchases()` button on paywall)
- ✅ Receipt validation (RevenueCat server-side entitlement check via `CustomerInfo`)

**Premium Gating (COMPLETED 2026-02-23):**
- ✅ `PremiumGate` widget — full-screen lock overlay with upgrade CTA (Smart Insights, Subscription Tracker, Debt Payoff Planner)
- ✅ `PremiumActionGate` widget — inline button gate for action-level gating
- ✅ PDF export gated in Reports screen (lock icon → paywall on tap)
- ✅ Goals capped at 3 for free users (dialog on limit hit → paywall)
- ✅ Navigation drawer shows "Pro Feature" / "Pro PDF export" subtitles on gated items

**Implementation Notes:**
- Dual payment path: RevenueCat handles mobile subscriptions; Stripe handles web/desktop via `create-checkout-session` Edge Function
- `StripeConfig` holds publishable key + price IDs (`price_1T3J4M...` monthly, annual)
- `PremiumProvider` detects platform and routes to RevenueCat or Stripe accordingly
- `PremiumGate` / `PremiumActionGate` consume `PremiumProvider.isPremium` via `Consumer`

### Push Notifications (COMPLETED 2026-02-21)
**Approach:** OS-level local notifications via `flutter_local_notifications: ^17.2.4` + `timezone: ^0.9.4` — no Firebase required.
- ✅ Android: `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`, `VIBRATE` permissions + boot receiver + 3 notification channels
- ✅ iOS: `DarwinInitializationSettings` — permission request at runtime; `FlutterAppDelegate` already conforms to `UNUserNotificationCenterDelegate`
- ✅ `NotificationService` (`lib/shared/services/notification_service.dart`):
  - `checkBudgetAlert()` — fires OS notification when category spend ≥ 90% of budget
  - `checkGoalMilestone()` — notifies at 25/50/75/100% progress
  - `scheduleWeeklySummary()` — exact repeating alarm every Sunday 09:00
- ✅ `BudgetProvider.loadBudgets()` calls `_checkAlerts()` → triggers budget notifications with category name resolver
- ✅ `GoalProvider.addContribution()` calls `NotificationService.checkGoalMilestone()` after refresh
- ✅ `main.dart` calls `NotificationService.init()` + `scheduleWeeklySummary()` before `runApp()`

### Final Polish (COMPLETED 2026-02-23)
**Week 5-6:**
- ✅ Animations and screen transitions (Material 3 `ZoomPageTransitionsBuilder` globally; `FadeInWidget`, `FadeSlideItem`, `AnimatedContentSwitcher`, `SlidePageRoute`, `FadeScalePageRoute` utilities in `app_transitions.dart`)
- ✅ Loading shimmer states (`shimmer: ^3.0.0` — `ShimmerHomeDashboard`, `ShimmerListScreen`, `ShimmerCardScreen` applied to Home, Expenses, Income, Budgets, Goals, Debts screens)
- ✅ Empty states — expense list redesigned with icon blob + `FilledButton` CTA
- ✅ Error messages standardization (`AppErrorView` widget + `AppSnackBar` context extension — applied to all main list/card screens replacing inconsistent inline error Columns)
- ✅ Onboarding flow — 4-page `OnboardingScreen` with animated dots (completed earlier)

**Offline Mode (COMPLETED 2026-02-23):**
- ✅ `sqflite: ^2.3.3+1` + `path: ^1.9.1` + `uuid: ^4.5.1` + `connectivity_plus: ^6.1.4` added
- ✅ `LocalDatabase` (`lib/shared/services/local_database.dart`) — SQLite singleton:
  - Cache tables: `expenses`, `income_records`, `budgets` (id, user_id, payload JSON, synced_at)
  - `pending_ops` queue table (operation, table_name, record_id, payload, attempts)
  - Helpers: `upsertRow`, `upsertRows`, `getRows`, `getRow`, `deleteRow`, `enqueuePendingOp`, `getPendingOps`, `deletePendingOp`, `pendingOpsCount`
- ✅ `ConnectivityService` (`lib/shared/services/connectivity_service.dart`) — singleton wrapping `connectivity_plus`; broadcasts `Stream<bool>` (online/offline); wifi/mobile/ethernet/vpn = online
- ✅ `ConnectivityProvider` (`lib/features/connectivity/connectivity_provider.dart`) — `ChangeNotifier`; triggers `SyncService.syncPending()` automatically on reconnect
- ✅ `SyncService` (`lib/shared/services/sync_service.dart`) — drains `pending_ops` queue against Supabase (INSERT upsert, UPDATE patch, DELETE soft-delete); max 3 attempts per op
- ✅ `OfflineBanner` (`lib/shared/widgets/offline_banner.dart`) — animated `SizeTransition` banner at top of Home screen; shows pending op count when offline
- ✅ `ExpenseService` — offline-aware: reads cache SQLite on offline/error; writes enqueue to `pending_ops`; UUID generated locally for offline records
- ✅ `IncomeService` — same offline-aware pattern as `ExpenseService`
- ✅ `TransferService` — same offline-aware pattern; also handles offline `getTransfers()` and `createTransfer()` from SQLite cache
- ✅ `main.dart` wired: `ConnectivityService.instance.initialize()` before runApp; `ConnectivityProvider` in `MultiProvider`

**Week 7-8:**
- ⏳ Security audit
- ⏳ Performance testing
- ⏳ App store assets
- ⏳ Marketing materials

**Offline Mode Bugfixes (COMPLETED 2026-02-23):**
- ✅ **Black screen after adding expense (back press)** — `ExpenseListScreen` `PopScope` was `canPop: true` + microtask double-pop, causing a second `Navigator.pop` on an already-disposed context (removing the Home screen). Fixed: `canPop: false` + single `Navigator.pop(_dataChanged)` in `onPopInvokedWithResult`.
- ✅ **"Unknown Category" on offline-created records** — Offline creates store bare flat JSON; `fromJson` expected nested join objects (`expense_categories`, `income_categories`, `transfer_category`, etc.). Added private `_enrichExpenses()`, `_enrichWithCategories()`, and `_enrichTransfers()` helpers in each service that join against cached SQLite tables before deserializing.
- ✅ **Dashboard shows $0 / stale data when offline** — `HomeProvider` had `if (_isOffline) return;` early-returns in `loadDashboardData()` and all 5 sub-loaders, and `DashboardService` had no SQLite fallback at all. Fix: removed all offline early-returns from `HomeProvider`; rewrote all 4 `DashboardService` methods with online-try + SQLite-fallback computing totals, account summaries, recent transactions, and income-vs-expense chart data from cached SQLite rows.
- ✅ **Dashboard doesn't update after creating a transaction offline** — `TransfersScreen` never returned a result on pop. Added `_dataChanged` flag + `PopScope(canPop: false)` to `TransfersScreen`. `home_screen.dart` bottom-sheet "Add Expense" now `await`s the push result and calls `loadDashboardData(showLoading: false)` when `result == true`.
- ✅ **`ExpenseProvider` not loading data offline** — `initialize()` and `loadExpenses()` had offline early-returns. Removed; methods now call `loadCategories()` + `loadExpenses()` from SQLite when offline (stats load skipped offline since stats require Supabase aggregations).

### Onboarding (COMPLETED 2026-02-21)
- ✅ `shared_preferences: ^2.3.3` added for "seen" flag
- ✅ `OnboardingScreen` (`lib/features/onboarding/onboarding_screen.dart`):
  - 4 pages: Welcome, Track Every Dollar, Plan & Grow, You're Ready
  - Animated dot indicator (active dot stretches to pill shape)
  - Skip button (hidden on last page)
  - Last page: "Create Free Account" → `SignUpScreen`, "Already have account" → `LoginScreen`
  - Completion stored: `SharedPreferences.setBool('onboarding_complete', true)`
- ✅ `main.dart` reads flag before `runApp()`; routes to `OnboardingScreen` on first launch
- ✅ `HomeScreen`: `_QuickStartCard` (shown when `recentTransactions.isEmpty`) with "Add Expense" + "Set a Goal" CTAs

### Beta Testing
**Week 1-2:**
- ⏳ Recruit 100 beta testers
- ⏳ TestFlight/Play Store Beta
- ⏳ Feedback collection
- ⏳ Bug tracking

**Week 3-4:**
- ⏳ Fix critical bugs
- ⏳ UI/UX improvements
- ⏳ Performance optimization
- ⏳ Accessibility enhancements

### Pre-Launch
**Week 7-8:**
- ⏳ App store submission
- ⏳ Landing page launch
- ⏳ Social media setup
- ⏳ Press kit preparation
- ⏳ Beta feedback implementation

### Deliverables
- ✅ PDF report export (spending + categories + goals + debt)
- ✅ Local push notifications (budget alerts, goal milestones, weekly summary)
- ✅ Onboarding flow (4-page first-launch experience with guided CTAs)
- ✅ UI polish: empty states, quick-start card, polished expense list
- ✅ Premium paywall (RevenueCat mobile + Stripe web/desktop, 14-day trial)
- ✅ Premium gating on all Pro features (Smart Insights, Debt Planner, Subscriptions, PDF export, Goals cap)
- ✅ Screen animations & transitions (Material 3 Zoom globally, `SlidePageRoute`, `FadeScalePageRoute`, `FadeInWidget`, `AnimatedContentSwitcher`)
- ✅ Loading shimmer states (`shimmer ^3.0.0` — Home, Expenses, Income, Budgets, Goals, Debts)
- ✅ Error message standardization (`AppErrorView` + `AppSnackBar` extension)
- ✅ Offline mode (SQLite cache + pending-ops sync queue + auto-sync on reconnect + `OfflineBanner` UI + offline bugfixes: black screen, unknown category, dashboard accuracy)
- ☐ Beta tested with 100 users
- ☐ All critical bugs fixed
- ☐ App store approved
- ☐ Launch materials ready

**Phase 5 Implementation Notes:**
- PDF export: `ReportData` DTO decouples screen data from PDF logic; works on all platforms
- Push notifications: local-only (no Firebase) via `flutter_local_notifications` + `timezone`; all triggers are client-side for budget/goal events
- Onboarding: `SharedPreferences` flag ensures it only shows once; routing logic lives in `main.dart`
- Premium: RevenueCat (`purchases_flutter`) handles mobile; Stripe Edge Function handles web/desktop; `PremiumProvider` routes accordingly
- Premium gating: `PremiumGate` (full-screen overlay) + `PremiumActionGate` (inline) used across Smart Insights, Debt, Subscriptions, Reports, Goals
- Offline mode: `ConnectivityService` → `ConnectivityProvider` → auto-syncs via `SyncService` on reconnect; `ExpenseService`/`IncomeService`/`TransferService` serve SQLite cache when offline; `DashboardService` computes all metrics from SQLite when offline; `OfflineBanner` shows pending count in Home; enrichment helpers (`_enrichExpenses`, `_enrichWithCategories`, `_enrichTransfers`) resolve category/account names from cached tables before deserialization
- Multi-account (Plaid) support deferred to Phase 7 as premium feature
- Next up: security audit, performance testing, app store assets, beta launch preparation

---

## Phase 6: Public Launch (Month 11)
**Duration:** 4 weeks
**Focus:** Launch and growth

### Week 1: Soft Launch
- iOS App Store launch
- Android Play Store launch
- Friends and family promotion
- Monitor for critical issues

### Week 2: Marketing Push
- Social media campaigns
- Product Hunt launch
- Tech blog outreach
- Influencer partnerships

### Week 3: User Acquisition
- Paid advertising (Facebook, Google)
- App store optimization
- Referral program activation
- Content marketing

### Week 4: Optimization
- Analyze user behavior
- Fix reported bugs
- Improve onboarding
- A/B test features

### Success Metrics
- 10,000 downloads in first month
- 4.5+ star rating
- 5% Premium conversion
- < 30% Day 1 churn

---

## Phase 7: Post-Launch Iterations (Months 12-18)
**Focus:** Continuous improvement and growth

### Months 12-13: Stabilization
- Bug fixes based on user feedback
- Performance improvements
- Onboarding optimization
- Support documentation

### Months 14-15: Feature Expansion
- Shared expenses (couples/roommates)
- Advanced filters and search
- Custom reports
- Widget support

### Months 16-18: Advanced Features
- Investment tracking
- Net worth dashboard
- Financial health score
- Tax preparation tools
- Bill negotiation assistant

---

## Phase 8: Scale & Expansion (Months 19-24)
**Focus:** Platform growth

### International Expansion
- Multi-language support
- Currency localization
- Regional payment methods
- Local marketing

### Platform Expansion
- Web app (desktop version)
- Browser extension
- API for developers
- Integrations (Zapier, IFTTT)

### B2B Offerings
- White-label solution
- Enterprise version
- Financial advisor partnerships
- Corporate wellness program

---

## Future Vision (Year 3+)

### Advanced AI
- Predictive spending models
- Automated savings optimization
- AI financial advisor chatbot
- Voice assistant integration

### Social Features
- Anonymous spending comparisons
- Financial challenges with friends
- Community tips and advice
- Leaderboards (tasteful)

### Financial Services
- In-app high-yield savings
- Investment recommendations
- Insurance comparisons
- Credit score monitoring

### Ecosystem Integration
- Smart home device integration
- Wearable device support
- Calendar integration (automatic expense categorization)
- Email receipt parsing

---

## Continuous Priorities

### Every Sprint
- Bug fixes
- Performance optimization
- Security updates
- User feedback implementation

### Monthly
- A/B testing new features
- Analytics review
- User surveys
- Competitive analysis

### Quarterly
- Major feature releases
- UI/UX refreshes
- Security audits
- Strategic planning

---

## Success Milestones

### User Growth
- ✅ 1,000 users (Month 1)
- ☐ 10,000 users (Month 3)
- ☐ 50,000 users (Month 6)
- ☐ 100,000 users (Month 12)
- ☐ 500,000 users (Month 24)
- ☐ 1,000,000 users (Month 36)

### Revenue Milestones
- ☐ $10K MRR (Month 6)
- ☐ $50K MRR (Month 12)
- ☐ $200K MRR (Month 18)
- ☐ $500K MRR (Month 24)
- ☐ $1M MRR (Month 36)

### Product Milestones
- ✅ MVP Launch
- ☐ 4.5+ star rating
- ☐ Featured in App Store
- ☐ 10,000+ reviews
- ☐ Industry recognition/awards
- ☐ 1 million+ downloads

---

## Risk Mitigation

### Technical Risks
- **AI accuracy issues** → Extensive testing, user feedback loop
- **Scalability problems** → Cloud auto-scaling, load testing
- **Security breaches** → Regular audits, bug bounty program

### Business Risks
- **Low conversion rate** → A/B testing, improved value proposition
- **High churn** → User research, engagement features
- **Competition** → Differentiate with superior AI, user experience

### Market Risks
- **Slow adoption** → Aggressive marketing, referral program
- **Regulatory changes** → Legal counsel, compliance monitoring
- **Economic downturn** → Focus on savings value proposition

---

## Agile Approach

### Two-Week Sprints
- Sprint planning
- Daily standups
- Sprint review
- Retrospective

### Flexible Prioritization
- User feedback drives roadmap
- Data-informed decisions
- Quick pivots when needed
- MVP mindset for all features

### Continuous Deployment
- Release small, iterate fast
- Feature flags for gradual rollout
- Monitor metrics closely
- Roll back if issues detected
