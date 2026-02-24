# Product Overview

**Last Updated:** February 25, 2026  
**Status:** Feature-complete through Phase 5 — pending beta launch

## Core Idea

FundVance AI (AI-FAP) is a mobile application that combines manual and automated expense tracking with on-device artificial intelligence to give users actionable financial insights, goal planning, and debt management — all with full offline support.

## Problem Statement

Most people struggle with:
- Keeping track of daily expenses across multiple accounts
- Understanding where their money goes each month
- Making informed budgeting and savings decisions
- Managing debt and working toward financial goals

## Solution

FundVance AI addresses these challenges by:
- Providing fast manual expense entry with merchant autocomplete
- Automating expense capture through on-device receipt scanning (ML Kit OCR)
- Using on-device AI heuristics to analyze spending and surface actionable insights
- Offering a full offline mode so tracking works anywhere

## What's Implemented (Feb 2026)

### Core Tracking
- ✅ Manual expense + income CRUD (soft-delete, undo, recurring freq.)
- ✅ Tags on expenses, notes, merchant name, account tagging
- ✅ Favourite merchants / recent-merchant autocomplete chips
- ✅ Quick Add — frequent expense shortcuts from transaction history

### Accounts & Transfers
- ✅ 12 account types across 7 categories (Bank, E-Wallet, Online Bank, Credit, Cash, Crypto, Investment)
- ✅ Multi-currency per account with live exchange rates (open.er-api.com)
- ✅ Account transfers with fee tracking and currency conversion
- ✅ Transfer history on Account Detail screen
- ✅ Account delete (soft-delete) + restore

### Budgets
- ✅ Budget creation for any category (weekly / monthly / yearly)
- ✅ Real-time budget vs actual tracking with colour-coded progress
- ✅ Budget carry-forward (rollover unspent amount to next period)
- ✅ 50/30/20 rule budget suggestion engine (BudgetSuggestionService)
- ✅ Budget alerts via OS push notifications

### Categories & Tax
- ✅ Full category CRUD (expense / income / transfer types, icons, colours)
- ✅ Tax settings — gross/net income tracking with percentage/fixed/hybrid calc
- ✅ Tax presets for PH / USA / WLD

### AI & Insights
- ✅ On-device receipt OCR (Google ML Kit — unlimited, offline-capable)
- ✅ Smart auto-categorization (9-category keyword engine)
- ✅ Personalization engine — learns from user corrections (DB-backed overrides)
- ✅ SmartInsightsService — budget alerts, anomaly detection, trends, recurring detection, milestones, savings opportunities, spending concentration patterns
- ✅ SpendingDigestService — template NLG monthly summary on Home screen
- ✅ In-app Notification Centre with badge count (bell icon)
- ✅ OS push notifications (flutter_local_notifications — no Firebase)

### Premium Features (Phase 4)
- ✅ Financial Goal Planner (GoalAIService — on-device deadline/savings-rate AI)
- ✅ Debt Payoff Planner (DebtAIService — snowball/avalanche simulator)
- ✅ Subscription Tracker (auto-detection via SmartInsightsService)
- ✅ PDF report export (spending + categories + goals + debt snapshot)
- ✅ Swipe-to-delete on debt payments and goal contributions
- ✅ RevenueCat v9 (mobile) + Stripe Edge Function (web/desktop)
- ✅ 14-day free trial; $4.99/month or $39.99/year
- ✅ Premium gating via PremiumGate / PremiumActionGate widgets

### Theme & UX
- ✅ 6 themes (3 free: Default, Dark, Ocean; 3 premium-gated: Sunset, Forest, Midnight)
- ✅ Biometric lock (local_auth)
- ✅ Onboarding flow (4-page first-launch experience)
- ✅ Shimmer loading states, Material 3 Zoom transitions, empty states
- ✅ Recurring Scheduler (RecurringSchedulerService — 5 sub-runners)

### Infrastructure
- ✅ Offline mode — SQLite cache (sqflite) + pending-ops sync queue + auto-sync on reconnect
- ✅ OfflineBanner UI showing pending op count
- ✅ 33 database migrations

## Not Yet Implemented

| Feature | Notes |
|---------|-------|
| Cloud Vision API (premium OCR) | Deferred — ML Kit sufficient for MVP |
| Bank account linking (Plaid/Yodlee) | Deferred to Phase 7 |
| Round-up / automated savings | Not started |
| Supabase Edge Functions for AI | All AI is on-device Dart — no Edge Functions deployed |
| Weekly email reports | Only in-app digest exists |
| Family / couple sharing | Deferred |
| Export to CSV | Planned post-launch |

## Competitive Advantages

- **On-Device OCR** — Receipt scanning works offline, zero API costs, privacy-first
- **Full Offline Mode** — SQLite cache + auto-sync; the app works anywhere with no data loss
- **On-Device AI** — Zero cloud AI costs; insights run locally in < 100 ms
- **Debt + Goal AI** — Snowball/avalanche debt simulator and timeline-aware goal recommendations
- **Personalization Engine** — Category suggestions improve with every correction the user makes

## Success Metrics

- Daily active users (DAU)
- Expense tracking frequency
- Premium conversion rate (target: 5%)
- User-reported savings achieved
- App retention rate (30/60/90 days)

## Vision

To become the most intelligent and user-friendly personal finance assistant that helps everyone achieve their financial goals — even offline, even without a degree in finance.
