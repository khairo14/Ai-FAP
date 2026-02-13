# MVP Features

## Overview
The Minimum Viable Product focuses on core functionality that provides immediate value while keeping development scope manageable.

**Development Approach:**
- **Phase 1 (MVP):** Core financial tracking features with manual entry (Months 1-2) ✅ COMPLETED
- **Phase 2:** AI-powered automation including receipt scanning and smart categorization (Months 3-4)
- **Phase 3:** Advanced features and premium capabilities (Months 5-6)

**What's in MVP (Phase 1):**
- ✅ Manual expense and income tracking
- ✅ Multi-currency account management
- ✅ Budget creation and monitoring
- ✅ Category management
- ✅ Financial dashboard with summaries
- ✅ Account transfers
- ✅ Basic analytics and reporting

**Coming in Phase 2:**
- Receipt scanning with OCR (Google ML Kit / Cloud Vision)
- AI-powered auto-categorization
- Smart insights and recommendations
- Spending predictions and anomaly detection

---

## 1. Expense Tracking

### Manual Entry
**Description:** Users can manually add expenses quickly and easily.

**Implemented Features:**
- ✅ Modern card-based form layout
- ✅ **Essential fields:**
  - Expense Name/Merchant (optional, but displayed as title)
  - Amount (required, large prominent display)
  - Category (required, with IconHelper-rendered icons and colors)
  - Date (default: today, date picker)
  - Account (required, auto-selects payment method)
  - Payment Method (auto-selected based on account type)
  - Description (optional, for additional details)
  - Notes (optional, for extended notes)
  - Recurring expense toggle

- ✅ **Form enhancements:**
  - Colorful prefix icons (purple payment, teal merchant, amber category, blue date, green account, orange method)
  - Currency symbol from selected account (dynamic)
  - Auto-payment method selection based on account type
  - Category dropdown with actual Material Icons (not raw text)
  - Account dropdown with balance display
  - Helper text for guidance
  - 12px spacing between fields for compact design
  - 14px field text, 12px helper text
  - Validation with error messages

- ✅ **Account Integration:**
  - Account selection required (links expense to account)
  - Auto-balance deduction via database triggers
  - Currency follows selected account
  - Payment method maps from account type:
    * Cash → Cash
    * Credit → Credit Card
    * Bank → Debit Card
    * Online Bank/Crypto/Investment → Online Banking
    * E-Wallet → E-Wallet

- ✅ **Edit/Delete:**
  - Full expense editing support
  - Delete with confirmation dialog
  - Swipe-to-delete in list view
  - Undo option (5 seconds) after delete

### Quick Add Buttons
**Description:** One-tap expense logging for common purchases.

**Features:**
- Preset amount buttons (e.g., $5, $10, $20, $50)
- Last used expenses shortcuts
- Favorite merchant quick-add
- "Add another" for repeat purchases

### Categories
**Description:** Organized expense classification system.

**Default Categories:**
1. **Food** 🍔
   - Groceries
   - Dining out
   - Coffee shops
   - Food delivery

2. **Transport** 🚗
   - Gas/Fuel
   - Public transit
   - Ride-sharing
   - Parking

3. **Bills** 📄
   - Utilities
   - Rent/Mortgage
   - Insurance
   - Phone/Internet

4. **Shopping** 🛍️
   - Clothing
   - Electronics
   - Home goods
   - Personal care

5. **Others** 📌
   - Entertainment
   - Healthcare
   - Education
   - Miscellaneous

**Category Features:**
- Custom category creation
- Subcategory support  
- Color-coded for easy recognition
- Icon selection
- Category deletion with reassignment
- Import/export category templates

---

## 2. Income Tracking

### Manual Income Entry
**Description:** Users can log all sources of income for complete financial picture.

**Features:**
- Simple income form with fields:
  - Amount (required)
  - Source/Category (required) 
  - Date (default: today)
  - Description (optional)
  - Account received into (required)

### Income Categories
**Description:** Organized income classification system.

**Default Income Categories:**
1. **Salary** 💼
   - Regular employment
   - Bonuses
   - Overtime pay

2. **Freelance** 🎨
   - Consulting
   - Project work
   - Contract jobs

3. **Business** 🏢
   - Sales revenue
   - Service income
   - Partnership income

4. **Investments** 📈
   - Dividends
   - Interest
   - Capital gains
   - Rental income

5. **Others** 💰
   - Gifts
   - Refunds
   - Side hustles
   - Miscellaneous

### Income Features
- Custom income category creation
- Recurring income setup
- Income vs expense comparison
- Net income calculation
- Income-based budget recommendations

---

## 3. Account Management (Wallets & Banks)

### Account Categories
**Description:** Organize accounts by type with 7 main categories.

**Implemented Categories:**
1. **Bank** 🏦
   - Checking Account
   - Savings Account

2. **Online Bank** 💻
   - Online Bank
   - Digital-only banking platforms

3. **E-Wallet** 📱
   - PayPal
   - Apple Pay
   - Google Pay
   - GCash

4. **Credit** 💳
   - Credit Card
   - Line of Credit

5. **Cash** 💵
   - Physical Cash

6. **Crypto** ₿
   - Crypto Wallet

7. **Investment** 📈
   - Investment Account

### Account Types
**Description:** 12 predefined account types automatically created on signup.

**Auto-Created Accounts:**
- 2 Bank accounts (Checking, Savings)
- 2 Online Bank accounts
- 4 E-Wallet accounts (PayPal, Apple Pay, Google Pay, GCash)
- 2 Credit accounts (Credit Card, Line of Credit)
- 1 Cash account
- 1 Crypto wallet
- 1 Investment account

### Account Management Features
**Implemented:**
- ✅ Category-based account organization
- ✅ Add new account with category selection
- ✅ Account balance tracking and display
- ✅ Accounts grouped by category in UI
- ✅ Transaction tagging by account
- ✅ Account-wise expense/income filtering
- ✅ Auto-balance update on transactions
- ✅ Dynamic currency from user profile
- ✅ Smart currency updates (preserves manual changes)
- ✅ Include/exclude account in total balance
- ✅ Toggle account active/inactive status
- ✅ Account type differentiation with unique icons and colors (15+ types supported)
- ✅ Tappable account cards with navigation to details
- ✅ Database triggers for automatic balance updates
- ✅ Multi-currency account summaries
- ✅ Edit/update account functionality (name, description, initial balance, currency)

**TODO (Week 9):**
- ☐ Per-account currency override (select different currency per account)
- ☐ Delete account with soft-delete
- ☐ Restore deleted accounts from trash
- ☐ Account transfer with transaction fees

### Account Information
**Fields:**
- Account name (required) - User-defined name for the account
- Account category (required) - Selects from 7 categories, auto-picks first account type
- Account type (auto-selected) - System selects first type from chosen category
- Initial balance (optional, defaults to 0) - Starting balance amount
- Currency (uses profile default) - **TODO:** Add per-account currency selection option
- Credit limit (optional) - For credit accounts only
- Description (optional) - Additional notes about the account
- Include in total balance (toggle, default: true) - Whether to count in net worth
- Institution name (optional) - Bank or financial institution name
- Account nickname (optional) - Friendly name for the account

---

## 4. Enhanced Dashboard & Navigation

### Main Dashboard
**Description:** Comprehensive financial overview at a glance.

**Implemented Dashboard Elements:**
- ✅ **Financial Summary Card**
  - Current month income (multi-currency support)
  - Current month expenses (multi-currency support)
  - Net income (income - expenses)
  - Transaction count display
  - Multi-currency totals with symbol formatting

- ✅ **Account Balances**
  - Total balance across all accounts (grouped by currency)
  - Individual account cards with type-specific icons
  - Tappable account cards for drill-down
  - Account sorting (non-zero balances first)
  - Account type differentiation (Bank, E-Wallet, Credit, etc.)
  - Gradient card design with balance prominence
  - Account count badge

- ✅ **Quick Actions**
  - Add Expense (prominent button with red theme)
  - Add Income (green theme)
  - Transfer Between Accounts (blue theme)
  - Ripple effect and border styling
  - Icon-based quick access

- ✅ **Recent Transactions (Recent Activity)**
  - Last 5-10 transactions
  - Displays expense name (merchant/description/category)
  - Category name as subtitle
  - Category icons with proper colors via IconHelper
  - Mixed income and expenses with account indicators
  - Currency-specific formatting
  - Type-based color coding (red for expenses, green for income)
  - Empty state with helpful message

- ✅ **Welcome Section**
  - Time-based greeting (morning/afternoon/evening)
  - User email display
  - Gradient background with primary color theme
  - AI-powered insights tagline

- ✅ **Financial Health Card** (Coming Soon)
  - Health score (0-100) with color indicator
  - Status badge (Excellent/Good/Fair/Needs Improvement)
  - Actionable insights list
  - Progress bar visualization

- ✅ **Income vs Expenses Chart** (Coming Soon)
  - Bar chart for last 6 months
  - Green bars for income, red for expenses
  - Interactive tooltips with amounts
  - Month labels on X-axis
  - Empty state with helpful message

**Dashboard Features:**
- Pull-to-refresh for data sync
- Auto-refresh on app resume
- Error handling with retry option
- Loading states for async data
- Empty states for each section
- Smooth transitions and animations

### Navigation Structure
**Features:**
- Bottom navigation or drawer menu
- Sections: Dashboard, Expenses, Income, Budgets, Analytics, Accounts
- Quick access to frequently used features
- Search functionality across all transactions

---

## 5. Income-Aware Budget System

### Budget Types
**Description:** Advanced budgeting that considers income for realistic budget setting.

**Budget Options:**
1. **Absolute Amount Budgets**
   - Fixed amount per category (e.g., $500 for groceries)
   - Traditional budgeting approach
   - Good for stable expense categories

2. **Income Percentage Budgets**
   - Percentage of income per category (e.g., 30% for housing)
   - Automatically adjusts with income changes
   - Follows financial best practices (50/30/20 rule)

3. **Savings Goal Budgets**
   - Set savings target first
   - Budget remainder across expense categories
   - Prioritizes financial goals

### Budget Features
**Advanced Capabilities:**
- **Income Integration**
  - Budget recommendations based on income
  - Automatic budget adjustment for income changes
  - Net income calculation (income - fixed expenses)

- **Budget Monitoring**
  - Real-time budget vs actual tracking
  - Color-coded status indicators
  - Budget progress notifications
  - Overspending alerts

- **Smart Suggestions**
  - AI budget recommendations
  - Category-wise spending insights
  - Savings optimization suggestions
  - Budget rebalancing recommendations

### Budget Analytics
**Insights:**
- Budget adherence rate
- Category-wise performance
- Income vs expense ratio
- Savings rate calculation
- Financial health scoring

---

## 6. Enhanced Analytics & Insights

### Financial Overview
**Description:** Comprehensive analytics combining income, expenses, and account data.

**Analytics Features:**
1. **Income vs Expense Analysis**
   - Monthly income and expense trends
   - Net income tracking over time
   - Income source diversification
   - Expense category breakdown

2. **Account Analytics**
   - Balance trends across accounts
   - Account usage patterns
   - Net worth tracking
   - Account performance comparison

3. **Financial Health Metrics**
   - Savings rate calculation
   - Expense ratio by category
   - Budget adherence scoring
   - Financial stability indicators

### Visualization
**Chart Types:**
- Income vs Expense trend lines
- Category breakdown pie charts
- Account balance area charts
- Budget performance progress bars
- Net worth line graphs
- Savings rate indicators

---

## Technical Requirements

### Auto-Classification
**Description:** AI automatically assigns categories to expenses.

**How It Works:**
- Merchant name recognition
- Purchase pattern learning
- Context-aware classification
- User behavior training

**Examples:**
- "Starbucks" → Food (Coffee shops)
- "Grab" / "Uber" → Transport (Ride-sharing)
- "Netflix" → Bills (Subscriptions)
- "Walmart" → Shopping (could learn Groceries if frequent)
- "Shell" → Transport (Gas)

### Learning System
**Description:** AI improves accuracy over time.

**Features:**
- Learns from user corrections
- Remembers merchant preferences
- Adapts to spending patterns
- Suggests new categories when needed

---

## 4. AI Insights (Main Selling Point)

### Spending Analysis
**Description:** AI provides clear, actionable insights about spending habits.

**Insight Types:**

#### Comparative Insights
- "You spent 28% more on food this week."
- "Transport costs down 15% from last month."
- "Your bills are 5% higher than usual."

#### Pattern Recognition
- "You typically spend $120/week on groceries."
- "Most of your shopping happens on weekends."
- "Your biggest expense category is Food (35%)."

#### Subscription Tracking
- "Your subscriptions cost $42/month."
- "You have 7 active subscriptions."
- "Netflix charged you today."

#### Savings Opportunities
- "If you reduce dining out by 20%, you'll save $85/month."
- "You could save $30/month by meal prepping."
- "Consider reviewing subscriptions you rarely use."

#### Spending Alerts
- "You've already spent 80% of your food budget."
- "Unusual expense detected: $250 at Electronics Store."
- "You've exceeded your budget in Transport."

### Visualization
**Description:** Clear charts and graphs for spending overview.

**Chart Types:**
- Pie chart: Spending by category
- Line graph: Spending trends over time
- Bar chart: Monthly comparisons
- Progress bars: Budget usage

---

## 5. Monthly Budget Suggestions

### AI-Calculated Budgets
**Description:** System analyzes spending and recommends realistic budgets.

**Calculation Method:**
1. Analyze 2-3 months of spending history
2. Calculate average per category
3. Identify variable vs. fixed expenses
4. Suggest safe budget limits (avg + 10-15% buffer)
5. Recommend savings allocation

**Budget Components:**
- **Income** - Monthly take-home
- **Fixed Expenses** - Rent, bills, subscriptions
- **Variable Expenses** - Food, transport, shopping
- **Savings Goal** - Recommended amount to save
- **Discretionary** - Leftover for fun spending

### Budget Tracking
**Features:**
- Real-time budget vs. actual spending
- Category-level budget monitoring
- Weekly spending summaries
- Month-end projections

---

## 6. Dashboard & Reporting

### Home Dashboard
**Display Elements:**
- Current month spending total
- Budget status (on track/over budget)
- Top 3 spending categories
- Recent transactions (last 5)
- Quick action buttons

### Reports
**Available Reports:**
- Daily spending summary
- Weekly overview
- Monthly breakdown
- Category analysis
- Year-to-date totals

---

## Technical Requirements

### Performance (MVP - Phase 1)
- App launch: < 2 seconds
- Smooth scrolling (60fps)
- Offline capability for manual entry
- Transaction sync: < 1 second

### Performance (Phase 2 - AI Features)
- Receipt scan: < 3 seconds
- AI categorization: < 1 second
- Real-time insights generation

### Data Storage
- Local database (SQLite/Realm)
- Cloud sync (optional)
- Data export (CSV/PDF)

### Privacy & Security
- Local data encryption
- Biometric authentication
- No expense data sold
- GDPR compliant

---

## Success Criteria

### MVP (Phase 1) - Core Features
**User Engagement:**
- ✅ Users log expenses at least 3x/week
- ✅ Users create and monitor budgets
- ✅ Users track multiple accounts
- ✅ Users view financial summaries daily

**User Satisfaction:**
- ✅ 4.5+ star app store rating
- ✅ 60%+ retention after 30 days
- ✅ Positive feedback on UI/UX
- ✅ Easy manual expense entry

**Technical:**
- ✅ 99.5% app uptime
- ✅ < 50MB app size
- ✅ Works on Android 8+ / iOS 13+
- ✅ Multi-currency support
- ✅ Automatic balance updates

### Phase 2 - AI Features
**User Engagement:**
- ✅ 70%+ receipt scan accuracy
- ✅ 85%+ auto-categorization accuracy
- ✅ Users scan receipts 2x/week
- ✅ Users view AI insights weekly

**User Satisfaction:**
- ✅ High confidence in AI accuracy
- ✅ Positive feedback on AI insights
- ✅ Reduced manual entry time by 50%

**Technical:**
- ✅ Cloud OCR integration working
- ✅ ML model accuracy improving
- ✅ Receipt storage < 100MB/user

---

## Phase 2 Features (Coming Soon)

### Receipt Scanner (AI-Powered)
**Description:** Instant expense capture from receipt photos using OCR and AI.

**Planned Features:**
- 📸 Camera integration for receipt capture
- 🔍 OCR text extraction (Google ML Kit for free tier, Cloud Vision API for premium)
- 🤖 AI parsing for amount, date, merchant, and items
- ✅ Auto-populate expense form with extracted data
- 📊 Confidence scoring for accuracy indicators
- ✏️ Manual correction and review interface
- 💾 Receipt image storage (Supabase Storage)
- 🔗 Link receipts to expenses
- 📱 < 3 seconds scan-to-expense flow

**Success Criteria:**
- 70%+ OCR accuracy on receipts
- < 3 seconds from scan to populated form
- User can edit any extracted field before saving
- Receipt images linked to expenses for audit trail

### Smart Auto-Categorization
**Description:** AI learns from user patterns to automatically categorize expenses.

**Planned Features:**
- 🧠 Machine learning model for category prediction
- 🏪 Merchant database and pattern recognition
- 📈 User behavior learning and adaptation
- 🎯 Category suggestion with confidence scores
- ⚡ Real-time categorization as user types
- 🔄 Continuous learning from corrections
- 📊 85%+ categorization accuracy goal

### AI Insights & Recommendations
**Description:** Personalized financial insights powered by AI.

**Planned Features:**
- 📊 Spending pattern analysis
- ⚠️ Anomaly detection (unusual expenses)
- 💡 Budget recommendations based on income
- 📈 Predictive spending forecasts
- 🎯 Savings opportunity identification
- 📅 Bill reminder predictions
- 🏆 Financial health score improvements

### Additional Phase 2 Features
- 🔄 Recurring expense automation
- 📧 Email receipt parsing
- 🌐 Multi-device sync improvements
- 📤 Advanced export options (PDF reports)
- 🔔 Smart notifications and alerts
- 🎨 Custom category creation with AI suggestions
