# FundVance AI Documentation

**AI Financial Assistant & Planning (AI-FAP)**

A mobile app that intelligently tracks expenses, analyzes spending patterns, and provides personalized financial advice to help users save money.

## Quick Links

**⚡ Start Here:**
- [Tech Stack Summary](tech-stack-summary.md) - **Quick overview of all technology decisions**
- [Product Overview](product-overview.md) - Core concept and vision
- [Technical Architecture](technical-architecture.md) - Complete system design

**📱 Features:**
- [MVP Features](features/mvp-features.md) - Core functionality for launch
- [Premium Features](features/premium-features.md) - Advanced paid features

**👥 Users & Business:**
- [Target Users](target-users.md) - User personas and segments
- [Monetization Strategy](monetization-strategy.md) - Revenue model and pricing

**🤖 AI & Technical:**
- [AI Components](ai-components.md) - ML models and capabilities
- [Roadmap](roadmap.md) - Development phases and timeline

---

## Final Technology Stack ✅

| Component | Choice | Why |
|-----------|--------|-----|
| **Mobile** | Flutter | Native performance, single codebase |
| **Backend** | Supabase | PostgreSQL + auto API + auth + storage |
| **OCR** | Google ML Kit (on-device, all users) | Free, privacy-first, no rate limits |
| **State** | Provider | Decided: Provider only (not Riverpod) |
| **Charts** | fl_chart | Beautiful & customizable |
| **Offline** | sqflite + connectivity_plus | SQLite cache + pending-ops sync queue |
| **Subscriptions** | RevenueCat v9 (mobile) + Stripe (web) | Dual payment path |
| **Notifications** | flutter_local_notifications | Local-only, no Firebase required |

**Project Name:** FundVance AI  
**Supabase Project:** FundVanceAI  
**Total Development Time:** 10 months  
**MVP Cost:** $15/month  
**Status:** Feature-complete through Phase 5 — pending beta launch

---

## Documentation Structure

- [Tech Stack Summary](tech-stack-summary.md) - **All tech decisions in one place**
- [Product Overview](product-overview.md) - Core concept and vision
- [Target Users](target-users.md) - User personas and segments
- [Features](features/) - Detailed feature specifications
  - [MVP Features](features/mvp-features.md)
  - [Premium Features](features/premium-features.md)
- [Technical Architecture](technical-architecture.md) - Complete system design
- [AI Components](ai-components.md) - AI/ML models and capabilities
- [Monetization Strategy](monetization-strategy.md) - Revenue model
- [Roadmap](roadmap.md) - Development phases and timeline

---

## Getting Started

### For Developers
1. Read [Tech Stack Summary](tech-stack-summary.md)
2. Review [Technical Architecture](technical-architecture.md)
3. Check [Roadmap](roadmap.md) for current phase
4. Set up development environment (see Tech Architecture)

### For Product/Business
1. Read [Product Overview](product-overview.md)
2. Review [Target Users](target-users.md)
3. Explore [MVP Features](features/mvp-features.md)
4. Check [Monetization Strategy](monetization-strategy.md)

### For Project Management
1. Review [Roadmap](roadmap.md)
2. Check current development phase
3. Track milestones and deliverables
4. Monitor budget vs timeline

---

## Key Decisions Made

✅ **Mobile Framework:** Flutter (over React Native)  
✅ **Backend:** Supabase (over Firebase or custom Node.js)  
✅ **Database:** PostgreSQL via Supabase  
✅ **OCR:** Google ML Kit (free) + Cloud Vision API (premium)  
✅ **Development Approach:** Rapid MVP with scalable architecture  

See [Tech Stack Summary](tech-stack-summary.md) for complete details and rationale.

---

## Current Status (Feb 25, 2026)

**Phase 5: Polish & Beta Launch** - 🚧 FEATURE-COMPLETE (pending launch)

**Completed Phases:**
- ✅ Phase 1 — Core infrastructure (Supabase DB, auth, expense/income/account CRUD)
- ✅ Phase 1 Extension — Enhanced financial management (transfers, tax, categories, offline mode)
- ✅ Phase 2 — AI features (on-device OCR, smart categorization, insights, notifications)
- ✅ Phase 3 — Advanced AI (personalization engine, budget suggestions, savings opportunities)
- ✅ Phase 4 — Premium features (Goals, Debt Payoff, Subscription Tracker, PDF reports)
- ✅ Phase 5 — Polish (offline bugfixes, RevenueCat v9, Stripe web, premium gating, animations, shimmer, onboarding)

**Latest Updates (Feb 25, 2026):**
- ✅ 33 database migrations fully deployed
- ✅ Transfer history display on Account Detail screen
- ✅ Swipe-to-delete on debt payments and goal contributions
- ✅ Budget carry-forward (rollover) system (`carry_forward_amount` column)
- ✅ RevenueCat v9 (`purchases_flutter ^9.x`)
- ✅ Complete offline mode with SQLite cache + auto-sync

**Pending (launch prep):**
- ⏳ Security audit
- ⏳ Performance testing
- ⏳ App store submission
- ⏳ Beta testing (100 users)
- ⏳ Marketing materials

See [Roadmap](roadmap.md) for detailed progress tracking.

---

**Version:** 1.5.0  
**Last Updated:** February 25, 2026
