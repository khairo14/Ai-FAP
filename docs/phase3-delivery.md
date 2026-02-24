# Phase 3 Delivery — AI Features & Intelligence

**Phase:** 3  
**Original timeline:** Months 5–6 (8 weeks)  
**Actual completion:** February 2026  
**Status:** ✅ COMPLETED

---

## Overview

Phase 3 transformed FundVance from a capable expense tracker into a genuinely intelligent financial companion. Every AI service in this phase runs fully on-device in Dart — no cloud calls, no API keys, zero latency, works fully offline. The key theme was *personalization*: the app now learns from user behaviour and improves its suggestions over time.

---

## Feature Delivery

| Feature | Status | Key Files | Notes |
|---|---|---|---|
| Personalization Engine | ✅ Done | `lib/shared/services/personalization_service.dart` | DB-backed merchant→category override table; in-memory cache; learns from corrections |
| `merchant_category_overrides` DB table | ✅ Done | `supabase/migrations/20260221000003_create_merchant_category_overrides.sql` | RLS + index; `use_count` tracked per override |
| Two-tier category suggestion | ✅ Done | `lib/features/expenses/screens/expense_form_screen.dart` | Personalization override first → keyword fallback second |
| Personalization indicator chip | ✅ Done | `expense_form_screen.dart` | Shows "Personalized suggestion" below category field when DB override applies |
| Auto-learn on save | ✅ Done | `expense_form_screen.dart` | If user manually changes category → override saved to DB automatically |
| Advanced Insights — Savings Opportunities | ✅ Done | `lib/shared/services/smart_insights_service.dart` | `_savingsOpportunities()` — finds over-budget categories, quantifies monthly saving potential, top 3 by overspend |
| Advanced Insights — Spending Concentration | ✅ Done | `smart_insights_service.dart` | `_spendingPatternInsights()` — flags if top 3 categories = 75%+ of spend; flags single category > 35% |
| Budget Suggestions (50/30/20 Engine) | ✅ Done | `lib/shared/services/budget_suggestion_service.dart` | 3-month history + income; maps categories to Needs/Wants; rounds to nearest $5 |
| Budget Suggestion Screen | ✅ Done | `lib/features/budgets/screens/budget_suggestion_screen.dart` | Income auto-detect; inline 50/30/20 explainer; checkbox per category; bulk apply/update |
| AI suggestion entry in Budget list | ✅ Done | `lib/features/budgets/screens/budget_list_screen.dart` | AppBar ✨ button + persistent banner above budget list |

---

## Architecture Decisions

### On-Device-Only AI
All Phase 3 AI runs as synchronous Dart code against data already loaded into providers. No HTTP calls, no queuing. The `PersonalizationService` preloads all overrides into memory at expense form open — single DB read per session, then pure in-memory lookups.

### Two-Tier Suggestion Flow
```
Expense form — merchant field unfocus
  └─ PersonalizationService.getOverride(merchant)
       ├─ Hit? → apply override + show "Personalized suggestion" chip
       └─ Miss? → AutoCategorizationService.categorize(merchant, items)
                    ├─ Hit? → apply keyword category
                    └─ Miss? → leave category unset (user picks manually → saved as new override)
```

### 50/30/20 Mapping Logic
`BudgetSuggestionService` maps every category to a bucket by name keywords:
- **Needs (50%):** Housing, Transport, Groceries, Utilities, Health, Insurance
- **Wants (30%):** Dining, Entertainment, Shopping, Subscription services
- **Savings (20%):** Shown as a non-budget recommendation tile (links to Goals)

Within each bucket, historical 3-month averages are used to allocate proportionally. If a category's 3-month average already exceeds its 50/30/20 allocation, it is capped at the rule limit and flagged as "over budget on rule".

---

## Known Limitations

| Limitation | Severity | Status |
|---|---|---|
| `AutoCategorizationService` keyword map covers only 9 categories | Low | Acceptable for MVP; can expand keywords in a minor update |
| Personalization overrides are per-user, not cross-device sync until Supabase sync | Low | Sync happens on reconnect via `SyncService` |
| 50/30/20 category mapping is English keyword-based — may misclassify custom category names | Medium | User can override any suggestion before applying |
| Budget suggestions require at least 1 month of expense history to be meaningful | Low | Empty-state message guides new users |

---

## Deferred Items

- Personalization export/import (for device migration) — deferred to Phase 7
- ML-based categorization (replace keyword map with a trained model) — not planned; keyword map has sufficient accuracy for MVP
- Cross-user category intelligence (aggregate anonymous category patterns to improve suggestions) — deferred; privacy implications require careful design

---

## Related Backlog Items

- Backlog item 13: AI for Debt Management ✅ (implemented Phase 4 / 5)
- Backlog item 14: AI for Goal Setting ✅ (implemented Phase 4 / 5)
- Backlog item 15: AI for Reports ✅ (implemented Phase 5)
- Backlog item 19: Financial Health Score — remaining 3 factors ⏳ (pending)
