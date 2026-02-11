# MVP Features

## Overview
The Minimum Viable Product focuses on core functionality that provides immediate value while keeping development scope manageable.

---

## 1. Expense Tracking

### Manual Entry
**Description:** Users can manually add expenses quickly and easily.

**Features:**
- Simple form with essential fields:
  - Amount (required)
  - Category (required)
  - Date (default: today)
  - Note/Description (optional)
  - Payment method (optional)

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

### Account Types
**Description:** Manage multiple financial accounts and track balances.

**Supported Account Types:**
1. **Bank Accounts** 🏦
   - Checking accounts
   - Savings accounts
   - Current accounts

2. **Digital Wallets** 📱
   - PayPal
   - Apple Pay
   - Google Pay
   - Other e-wallets

3. **Cash** 💵
   - Physical cash tracking
   - Wallet cash

4. **Credit Cards** 💳
   - Credit card accounts
   - Due balance tracking

### Account Management Features
**Features:**
- Add/edit/delete accounts
- Account balance tracking
- Transaction tagging by account
- Account-wise expense/income filtering
- Balance update on transactions
- Account transfer tracking
- Multiple currency support per account

### Account Information
**Fields:**
- Account name (required)
- Account type (required)
- Bank name (optional)
- Account number (optional, masked)
- Current balance (auto-calculated)
- Currency (required)
- Account color/icon (for easy identification)

---

## 4. Enhanced Dashboard & Navigation

### Main Dashboard
**Description:** Comprehensive financial overview at a glance.

**Dashboard Elements:**
- **Financial Summary Card**
  - Current month income
  - Current month expenses  
  - Net income (income - expenses)
  - Previous month comparison

- **Account Balances**
  - Total balance across all accounts
  - Individual account balances
  - Balance trend indicators

- **Quick Actions**
  - Add Expense (prominent button)
  - Add Income 
  - Transfer Between Accounts
  - Scan Receipt (Phase 2)

- **Recent Transactions**
  - Last 5 transactions
  - Mixed income and expenses
  - Account indicators

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

### Performance
- Receipt scan: < 3 seconds
- App launch: < 2 seconds
- Smooth scrolling (60fps)
- Offline capability for manual entry

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

### User Engagement
- ✅ Users log expenses at least 3x/week
- ✅ 70%+ receipt scan accuracy
- ✅ 80%+ auto-categorization accuracy
- ✅ Users view insights weekly

### User Satisfaction
- ✅ 4.5+ star app store rating
- ✅ 60%+ retention after 30 days
- ✅ Positive feedback on AI insights

### Technical
- ✅ 99.5% app uptime
- ✅ < 50MB app size
- ✅ Works on Android 8+ / iOS 13+
