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
- ☐ Offline mode
- ☐ Data synchronization
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
**Status:** 🚀 NEXT — Starting now
**Focus:** AI-powered automation and intelligence

### Receipt Scanner (AI-Powered)
**Week 1-2:**
- Camera integration and image capture
- Supabase Storage setup for receipt images
- Google Cloud Vision API integration
- OCR text extraction and processing

**Week 3-4:**
- AI receipt parsing logic
- Amount extraction (regex + NLP)
- Date recognition and validation
- Merchant identification
- Confidence scoring and accuracy metrics

**Week 5-6:**
- Receipt review UI with edit capability
- AI confidence indicators
- Manual fallback and corrections
- Auto-populate expense form
- Receipt storage and retrieval

### Smart Categorization (AI)
**Week 7-8:**
- Merchant database and pattern recognition
- Machine learning model for auto-categorization
- User behavior learning and adaptation
- Category suggestion engine
- Confidence-based auto-assignment

### Automated Insights & Recommendations
**Week 7-8:**
- Spending pattern detection
- Budget optimization suggestions
- Savings opportunities identification
- Financial health scoring
- Personalized recommendations
- Anomaly detection for unusual transactions
- Save to expense

**Week 7-8:**
- Error handling
- Edge case testing
- Performance optimization
- User testing

### Manual Entry Enhancements
**Week 1-2:**
- Quick add buttons
- Favorite merchants
- Recent expenses

**Week 3-4:**
- Payment method selector
- Notes and tags
- Photo attachment
- Recurring expenses

### Basic Insights
**Week 5-8:**
- Category spending breakdown
- Monthly summaries
- Simple comparisons
- Spending charts

### Deliverables
- ✅ Receipt scanner (working)
- ✅ Enhanced manual entry
- ✅ Basic insights
- ✅ Charts and visualizations

---

## Phase 3: AI Features & Intelligence (Months 5-6)
**Duration:** 8 weeks
**Focus:** AI capabilities

### Smart Categorization
**Week 1-2:**
- Merchant database
- Rule-based categorization
- Training data collection

**Week 3-4:**
- ML model training
- Text classification model
- Feature engineering
- Model evaluation

**Week 5-6:**
- Model deployment
- API integration
- Confidence scoring
- User correction system

**Week 7-8:**
- Personalization engine
- Learning from corrections
- A/B testing
- Accuracy improvements

### Advanced Insights
**Week 1-4:**
- Pattern recognition algorithms
- Comparative analysis
- Anomaly detection
- NLG (Natural Language Generation)

**Week 5-8:**
- Savings opportunity detection
- Budget adherence tracking
- Spending alerts
- Personalized recommendations

### Budget Suggestions
**Week 1-4:**
- Historical analysis
- Average calculation
- Budget algorithm
- Safe limit calculation

**Week 5-8:**
- Income-based budgeting
- 50/30/20 rule implementation
- Goal integration
- Dynamic adjustments

### Deliverables
- ✅ Smart categorization (85%+ accuracy)
- ✅ Advanced AI insights
- ✅ Budget suggestions
- ✅ Personalization engine

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
- ✅ Goal planner
- ✅ Debt payoff tools
- ✅ Subscription tracker
- ✅ Weekly reports
- ✅ Multi-account support

---

## Phase 5: Polish & Beta Launch (Months 9-10)
**Duration:** 8 weeks
**Focus:** Quality, testing, launch prep

### Beta Testing
**Week 1-2:**
- Recruit 100 beta testers
- TestFlight/Play Store Beta
- Feedback collection
- Bug tracking

**Week 3-4:**
- Fix critical bugs
- UI/UX improvements
- Performance optimization
- Accessibility enhancements

### Premium Implementation
**Week 3-4:**
- Subscription system (RevenueCat)
- Payment processing (Stripe)
- Free trial logic
- Upgrade prompts

**Week 5-6:**
- Paywall UI
- Pricing display
- Restore purchases
- Receipt validation

### Final Polish
**Week 5-6:**
- Animations and transitions
- Loading states
- Empty states
- Error messages
- Onboarding flow

**Week 7-8:**
- Security audit
- Performance testing
- App store assets
- Marketing materials

### Pre-Launch
**Week 7-8:**
- App store submission
- Landing page launch
- Social media setup
- Press kit preparation
- Beta feedback implementation

### Deliverables
- ✅ Beta tested with 100 users
- ✅ All critical bugs fixed
- ✅ Subscription system working
- ✅ App store approved
- ✅ Launch materials ready

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
