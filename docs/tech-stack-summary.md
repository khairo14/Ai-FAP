# Tech Stack Summary - FundVance AI

**Last Updated:** February 23, 2026

## Executive Summary

FundVance AI uses a modern, cost-effective stack optimized for rapid development and scalability:
- **Frontend:** Flutter (single codebase for iOS & Android)
- **Backend:** Supabase (PostgreSQL + auto-generated API)
- **OCR:** Google ML Kit (on-device, all users) — unlimited, privacy-first
- **Deployment:** Supabase hosted, CDN via Cloudflare

**Key Benefits:**
- 🚀 Launch in 3-4 months (vs 6-8 months traditional)
- 💰 Start at $0/month, scale affordably
- 🔒 Security & privacy built-in (RLS, encryption)
- 📱 Native performance on mobile
- ⚡ Real-time sync included
- 📴 Offline-first (SQLite cache + auto-sync on reconnect)

---

## Technology Decisions

### 1. Mobile Framework: Flutter ✅

**Decision:** Flutter over React Native

**Why?**
- Native compilation = better performance
- Single Dart codebase for iOS + Android
- Excellent Google ML Kit integration (on-device OCR)
- Beautiful UI out-of-the-box
- Strong Supabase Flutter SDK
- Growing ecosystem

**Install:**
```bash
flutter create ai_fap
flutter pub add supabase_flutter provider google_ml_kit fl_chart
```

---

### 2. Backend: Supabase (PostgreSQL) ✅

**Decision:** Supabase over Firebase or custom Node.js backend

**Why?**
- PostgreSQL = perfect for financial data (transactions, aggregations)
- Auto-generated REST API = 70% less backend code
- Built-in authentication, storage, real-time
- Free tier covers MVP
- 2-3x cheaper than Firebase at scale
- No vendor lock-in (standard PostgreSQL)

**Setup:**
```bash
npm install -g supabase
supabase init
supabase start
```

**Key Features:**
- Row Level Security (RLS) - users only see their data
- Real-time subscriptions - live budget updates
- Edge Functions - custom TypeScript logic
- Storage - receipt image hosting

---

### 3. Receipt OCR: Google ML Kit + Cloud Vision API ✅

**Decision:** Hybrid approach — ML Kit on-device for all users (free and premium)

**Free Users & Premium Users:** Google ML Kit (on-device)
- ✅ FREE
- ✅ Privacy-first (images never leave device)
- ✅ Offline capable
- ✅ 85-90% accuracy
- ✅ No rate limits

**Note:** Google Cloud Vision API was planned as a premium upgrade but has been deferred. On-device ML Kit accuracy is sufficient for MVP.

---

## Complete Stack Breakdown

### Mobile App (Flutter)
```yaml
Core:
  - Flutter SDK 3.19+
  - Dart 3.3+
  - Target: iOS 13+ / Android 8+

Essential Packages:
  - supabase_flutter: Backend client
  - provider: State management (Provider pattern — Riverpod NOT used)
  - google_mlkit_text_recognition: On-device OCR
  - fl_chart: Charts & graphs
  - image_picker: Camera access
  - flutter_secure_storage: Encrypted storage
  - shimmer: Skeleton loading states
  - sqflite + path: SQLite offline cache
  - uuid: Offline-safe record ID generation
  - connectivity_plus: Network state monitoring
  - local_auth: Biometric lock
  - purchases_flutter: RevenueCat v9 subscriptions (mobile)
  - flutter_stripe: Stripe web/desktop payments
  - pdf + printing: PDF report export
  - flutter_local_notifications + timezone: OS push alerts (no Firebase)
  - shared_preferences: Lightweight flags (onboarding, favourites)
  - intl: Internationalisation / date formatting
  
Not used (removed from plan):
  - go_router — using Navigator.push / MaterialPageRoute
  - riverpod — decided: Provider only
  - sentry_flutter — not integrated
  - mixpanel_flutter — not integrated
  - firebase_analytics — not integrated
```

### Backend (Supabase)
```yaml
Core Services:
  - PostgreSQL 15: Database
  - PostgREST: Auto-generated REST API
  - Supabase Auth: JWT + OAuth (Google, Apple)
  - Supabase Storage: Receipt images (S3-compatible)
  - Supabase Realtime: WebSocket for live updates
  - Edge Functions: Deno/TypeScript for custom logic

Database Schema:
  - profiles, categories, expenses, budgets
  - accounts, account_types, income, income_categories
  - transfers, transfer_categories, taxes, tax_presets
  - goals, goal_contributions, debts, debt_payments
  - recurring_schedules, merchant_category_overrides
  - (33 migrations total)
```

### AI/ML Services
```yaml
Receipt OCR:
  - Google ML Kit (on-device, all users, unlimited, offline)
  - Cloud Vision API: deferred (ML Kit sufficient for MVP)

Categorization:
  - AutoCategorizationService — keyword-based (9-category map, Dart)
  - PersonalizationService — DB-backed merchant overrides (Dart)
  - No BERT/FastText/TFLite — all rule-based + learning from corrections

Insights Engine (all on-device Dart, zero cloud calls):
  - SmartInsightsService: 7 insight types, < 100 ms
  - SpendingDigestService: NLG monthly summary (template-based)
  - BudgetSuggestionService: 50/30/20 rule engine
  - GoalAIService: deadline/savings-rate recommendations
  - DebtAIService: snowball/avalanche payoff simulator
```

### External Services
```yaml
Notifications:
  - flutter_local_notifications: OS push (local, no Firebase, no OneSignal)
  - Email reports: not yet implemented

Payments:
  - RevenueCat v9 (purchases_flutter ^9.x): Subscription management on iOS/Android
  - Stripe: Web/desktop payments via create-checkout-session Edge Function

Analytics / Error Tracking:
  - Not yet integrated (Sentry, Mixpanel, Firebase Analytics all deferred)

Edge Functions (Deployed):
  - create-checkout-session: Stripe checkout session for web/desktop
  - stripe-webhook: Handle subscription events
```

### Development Tools
```yaml
Version Control: Git + GitHub
CI/CD: 
  - GitHub Actions (testing, linting)
  - Codemagic (iOS builds, TestFlight)
  - Play Store automated deployment

Testing:
  - flutter_test: Unit & widget tests
  - integration_test: E2E tests
  - mockito: Mocking

Design: Figma
Project Management: Linear / Jira
Documentation: Notion
```

---

## Architecture Diagram (Simplified)

```
┌──────────────────────────┐
│   Flutter Mobile App     │
│  ┌────────────────────┐  │
│  │  Google ML Kit     │  │ (On-device OCR)
│  │  (Free tier)       │  │
│  └────────────────────┘  │
│  ┌────────────────────┐  │
│  │ Supabase Client    │  │ (Offline-first cache)
│  └────────────────────┘  │
└───────────┬──────────────┘
            │ HTTPS + WebSocket
            ▼
┌───────────────────────────────────────┐
│          Supabase Platform            │
│  ┌─────────────────────────────────┐  │
│  │  PostgreSQL Database            │  │
│  │  (Expenses, Categories, etc.)   │  │
│  └─────────────────────────────────┘  │
│  ┌─────────────────────────────────┐  │
│  │  Auto-Generated REST API        │  │
│  │  (PostgREST)                    │  │
│  └─────────────────────────────────┘  │
│  ┌─────────────────────────────────┐  │
│  │  Supabase Auth (JWT + OAuth)    │  │
│  └─────────────────────────────────┘  │
│  ┌─────────────────────────────────┐  │
│  │  Supabase Storage (Receipts)    │  │
│  └─────────────────────────────────┘  │
│  ┌─────────────────────────────────┐  │
│  │  Edge Functions (TypeScript)    │  │
│  │  - Premium OCR                  │  │
│  │  - Categorization AI            │  │
│  │  - Insights Generation          │  │
│  └─────────────────────────────────┘  │
└───────────────────────────────────────┘
            │
            ▼ (Premium users only)
┌───────────────────────────┐
│  Google Cloud Vision API  │ (High-accuracy OCR)
└───────────────────────────┘
```

---

## Cost Analysis

### MVP (0-1K users)
| Item | Cost/Month |
|------|------------|
| Supabase Free Tier | $0 |
| Google ML Kit | $0 |
| Domain | $15 |
| **Total** | **$15** |

### Growth (1K-10K users)
| Item | Cost/Month |
|------|------------|
| Supabase Pro | $25 |
| Cloud Vision API (3K scans) | $50 |
| Sentry | $26 |
| SendGrid | $15 |
| Analytics | $20 |
| **Total** | **$136** |

**Cost per user:** $0.014/month

### Scale (10K-100K users)
| Item | Cost/Month |
|------|------------|
| Supabase Team | $100 |
| Cloud Vision API (20K scans) | $300 |
| Sentry Business | $80 |
| SendGrid | $90 |
| Analytics | $100 |
| CDN | $20 |
| Redis | $50 |
| **Total** | **$740** |

**Cost per user:** $0.007/month (cost decreases with scale!)

---

## Development Timeline

### Phase 1: Foundation (2 months)
- Supabase setup
- Flutter project initialization
- Database schema
- Basic auth
- UI component library

### Phase 2: Core Features (2 months)
- Expense CRUD
- Receipt scanning (ML Kit)
- Categories
- Charts
- Monthly summaries

### Phase 3: AI Features (2 months)
- Smart categorization
- Insights generation
- Budget suggestions
- Real-time updates

### Phase 4: Premium Features (2 months)
- Premium OCR (Cloud Vision)
- Goal planner
- Debt management
- Subscription detector
- Weekly reports

### Phase 5: Polish & Launch (2 months) ✅ FEATURE-COMPLETE
- ✅ RevenueCat (mobile) + Stripe (web/desktop) premium subscriptions
- ✅ Premium gating on Pro features (PremiumGate widget)
- ✅ Local push notifications, onboarding, PDF export
- ✅ Animations (`ZoomPageTransitionsBuilder`), shimmer loaders (`shimmer ^3.0.0`), error standardization
- ✅ Offline mode (`sqflite` SQLite cache + `connectivity_plus` monitoring + `pending_ops` sync queue)
- ⏳ Security audit, performance testing, app store submission

**Total: 10 months from start to launch**

---

## Key Advantages of This Stack

### 1. Development Speed
- Supabase eliminates 70% of backend boilerplate
- Flutter single codebase = half the development time
- Auto-generated API = no manual endpoint creation
- Built-in auth = no custom implementation

### 2. Cost Efficiency
- $0 to start (free tiers)
- Scales affordably with revenue
- No infrastructure management needed
- Pay-as-you-grow pricing

### 3. Performance
- Flutter native compilation = 60fps guaranteed
- PostgreSQL optimized queries
- On-device ML Kit = instant OCR
- Real-time WebSocket updates

### 4. Security & Privacy
- Row Level Security (RLS) built-in
- JWT authentication standard
- On-device processing for free users
- GDPR compliant by default

### 5. Scalability
- Auto-scaling included
- PostgreSQL handles millions of records
- Easy upgrade path (self-hosting)
- No vendor lock-in

### 6. Developer Experience
- Type-safe (TypeScript + Dart)
- Hot reload for instant feedback
- Excellent documentation
- Strong community support

---

## Comparison: Why Not Other Options?

### Why Not React Native?
- Flutter faster for this use case
- Better ML Kit integration
- More consistent UI across platforms
- Better performance for charts/animations

### Why Not Firebase?
- NoSQL not ideal for financial data
- Missing SQL aggregations (SUM, GROUP BY)
- More expensive at scale
- Harder to migrate away

### Why Not Custom Node.js Backend?
- 3-4 months longer development
- More infrastructure to manage
- Higher costs from day one
- No built-in real-time

### Why Not Tesseract OCR?
- Lower accuracy (75-85% vs 85-90%)
- Slower processing (3-5s vs <1s)
- More complex setup
- Poor Flutter integration

---

## Risks & Mitigation

### Risk 1: Supabase Service Downtime
**Impact:** Users can't sync data
**Mitigation:**
- Offline-first app works without connection
- Supabase 99.9% uptime SLA
- Can migrate to self-hosted PostgreSQL if needed

### Risk 2: ML Kit Accuracy Too Low
**Impact:** Poor user experience with OCR
**Mitigation:**
- Always show review screen for user confirmation
- Offer premium Cloud Vision upgrade
- Collect feedback to improve parsing logic

### Risk 3: Scaling Costs Higher Than Expected
**Impact:** Profit margins squeezed
**Mitigation:**
- Free tier covers MVP validation
- Costs scale with paying users (premium)
- Can optimize queries and add caching
- Self-hosting option at 100K+ users

### Risk 4: Flutter/Dart Adoption
**Impact:** Harder to hire developers
**Mitigation:**
- Flutter growing rapidly (5M+ developers)
- Easier to learn than React Native
- Strong documentation and community
- Can pivot to React Native if needed (API-first design)

---

## Getting Started Checklist

### Week 1: Setup
- [ ] Install Flutter SDK
- [ ] Create Supabase account and project
- [ ] Set up GitHub repository
- [ ] Design initial database schema
- [ ] Create Figma designs

### Week 2: Foundation
- [ ] Initialize Flutter project
- [ ] Add Supabase integration
- [ ] Implement authentication
- [ ] Create database tables with RLS
- [ ] Set up CI/CD pipeline

### Week 3-4: First Feature
- [ ] Build expense entry form
- [ ] Implement CRUD operations
- [ ] Add category selection
- [ ] Create expense list view
- [ ] Write tests

### Week 5-6: Receipt Scanning
- [ ] Integrate Google ML Kit
- [ ] Build camera interface
- [ ] Implement OCR parsing
- [ ] Add review/edit screen
- [ ] Test with real receipts

---

## Questions & Decisions

### Decided ✅
- Mobile framework: Flutter
- Backend: Supabase (PostgreSQL)
- OCR: Google ML Kit (on-device, all users)
- State management: **Provider** (not Riverpod)
- Navigation: **Navigator.push / MaterialPageRoute** (not go_router)
- Charts: fl_chart
- Real-time: Supabase Realtime (used for live sync on reconnect)
- Subscriptions: RevenueCat v9 (mobile) + Stripe (web/desktop)
- Notifications: flutter_local_notifications (local-only, no Firebase)

### Still To Decide 🤔
- Analytics platform (Mixpanel vs Amplitude vs none at launch)
- Error tracking (Sentry deferred)
- Email service for reports (SendGrid vs Mailgun — deferred, email reports not built)
- CSV export format and timing

### Future Considerations 💭
- Web app (Flutter Web)
- Desktop app (Flutter Desktop)
- AI chatbot (OpenAI integration)
- Bank integration (Plaid) — Phase 7
- Family / couple sharing
- Cloud Vision API as premium OCR upgrade

---

## Success Metrics

### Technical KPIs
- App performance: 60fps consistent
- Cold start time: < 2 seconds
- OCR accuracy: > 85% (free), > 95% (premium)
- Categorization accuracy: > 85%
- API response time: < 200ms
- App crash rate: < 0.1%
- Test coverage: > 70%

### Cost KPIs
- Cost per user: < $0.02/month
- Infrastructure costs: < 10% of revenue
- Break-even: 5,000 premium users

---

## Resources

### Documentation
- [Technical Architecture (Full)](technical-architecture.md)
- [Product Overview](product-overview.md)
- [MVP Features](features/mvp-features.md)
- [Premium Features](features/premium-features.md)

### External Resources
- [Flutter Documentation](https://docs.flutter.dev/)
- [Supabase Documentation](https://supabase.com/docs)
- [Supabase Flutter Package](https://pub.dev/packages/supabase_flutter)
- [Google ML Kit](https://developers.google.com/ml-kit)
- [Cloud Vision API](https://cloud.google.com/vision/docs)

### Community
- [Flutter Discord](https://discord.gg/flutter)
- [Supabase Discord](https://discord.supabase.com)
- [r/FlutterDev](https://reddit.com/r/FlutterDev)

---

**Next Step:** Review this stack with the team and approve to start development!

**Contact:** [Your Name] | [Your Email]  
**Last Updated:** February 23, 2026
