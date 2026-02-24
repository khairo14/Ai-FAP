# Enhanced Financial Management Features

> **Status: ✅ ALL FEATURES COMPLETED (Feb 2026)**  
> This document was the Phase 1 Final Week (Week 7-8) planning spec. Everything listed here has been implemented and is live in the codebase. See [roadmap.md](../roadmap.md) for the full delivery timeline.

## Phase 1 Final Week (Week 7-8) - Comprehensive Financial Tracking

### 1. Enhanced Dashboard & Navigation Menu
**Goal:** Transform the basic home screen into a comprehensive financial dashboard

#### Navigation Drawer/Menu
- **Home** - Main dashboard overview
- **Expenses** - View and manage expenses  
- **Income** - View and manage income
- **Budgets** - Budget tracking and planning
- **Accounts** - Bank/wallet management
- **Transfers** - Money transfers between accounts
- **Categories** - Manage expense/income categories
- **Analytics** - Charts and insights
- **Trash** - Soft-deleted items
- **Settings** - Profile, currency, preferences

#### Enhanced Home Dashboard
- **Monthly Overview Card**
  - Total Income vs Total Expenses 
  - Net Income (remaining money)
  - Monthly savings amount
- **Account Balances Summary** 
  - Quick view of all account balances
  - Total net worth calculation
- **Recent Transactions** (Mixed)
  - Last 10 transactions (expenses + income + transfers)
  - Quick categorization and editing
- **Budget Progress Indicators**
  - Top 3 budgets with progress bars
  - Alert indicators for over-budget categories
- **Quick Action Buttons**
  - Add Expense, Add Income, Transfer Money
  - Scan Receipt (future feature)

---

### 2. Income Tracking System
**Goal:** Complete income management with tax calculations

#### Income Data Model
```dart
class Income {
  String id;
  String userId;
  double grossAmount;
  double netAmount;
  double taxAmount;
  String taxCalculationType; // 'percentage', 'fixed', 'hybrid'
  double taxRate; // percentage (0-100)
  double fixedTaxAmount; // fixed tax amount
  String categoryId; // income category
  String accountId; // which account received the income
  DateTime date;
  String source; // employer/client name
  String description;
  bool isRecurring;
  String period; // 'monthly', 'weekly', 'yearly'
  Map<String, dynamic> taxBreakdown; // detailed tax breakdown
  bool useDefaultTaxRate; // whether to use saved default rate
}

class DefaultTaxRate {
  String id;
  String userId;
  String incomeCategoryId;
  String source; // optional specific employer/client
  String taxCalculationType;
  double defaultTaxRate;
  double defaultFixedTaxAmount;
  Map<String, dynamic> defaultTaxBreakdown;
}
```

#### Default Income Categories
- **Salary** - Regular employment income 💼
- **Freelance** - Independent contractor work 💻
- **Business** - Business profits and revenue 🏢
- **Investments** - Dividends, capital gains, interest 📈
- **Rental** - Property rental income 🏠
- **Gifts** - Money gifts and bonuses 🎁
- **Other** - Miscellaneous income 💰

#### Tax Calculation Features
- **Gross vs Net Tracking** - Track before and after tax amounts
- **Flexible Tax Configuration** - Set tax rates by percentage OR fixed amount per income source
- **Default Tax Rate Saving** - Save default tax rates per income category/source
- **Tax Rate Override** - Override default rates for individual income entries
- **Tax Category Breakdown** - Income tax, social security, medicare, etc.
- **Multiple Tax Types** - Federal, state, local taxes with different rates
- **Tax Estimation Tools** - Estimate taxes on future income
- **Tax Rate Templates** - Preset tax rates for common employment types
- **Monthly Tax Summary** - Total taxes paid per month
- **Annual Tax Report** - Yearly tax summary for filing

#### Tax Calculation Options
1. **Percentage-Based Tax**
   - Set tax rate as percentage (e.g., 25%, 30%)
   - Auto-calculate tax amount from gross income
   - Support for multiple tax brackets

2. **Fixed Amount Tax**
   - Set specific tax amount (e.g., ₱5,000, $500)
   - Useful for known tax deductions
   - Calculate reverse percentage for reporting

3. **Hybrid Tax Calculation**
   - Combine percentage and fixed amounts
   - Example: 20% income tax + ₱500 SSS + ₱1,200 PhilHealth

#### Income Screens
- **Add/Edit Income Form**
  - Gross amount input
  - Tax calculation method selector (Percentage/Fixed/Hybrid)
  - Tax rate configuration with save as default option
  - Auto-calculate net amount preview
  - Load default tax rates for selected category/source
  - Override default rates for one-time entries
  - Recurring income setup
  - Account selector for deposit
  - Tax breakdown configuration (federal, state, local, etc.)
- **Income List View**
  - Monthly/yearly income summaries
  - Filter by category, account, tax status
  - Gross vs net amount display
  - Tax amount and effective rate display
- **Income Analytics**
  - Monthly income trends
  - Income vs expense comparison  
  - Tax burden analysis
  - Effective tax rate tracking
- **Tax Settings Screen**
  - Manage default tax rates per category
  - Tax rate templates and presets
  - Tax bracket configuration
  - Tax calculation method preferences

---

### 3. Account/Wallet Management System
**Goal:** Track all financial accounts with real-time balances

#### Account Types & Categories
1. **Bank Accounts**
   - Bank (Savings) - Traditional savings accounts
   - Bank (Checking) - Checking/current accounts
   - Bank name required (e.g., "Chase Savings", "Wells Fargo Checking")

2. **E-Wallets & Digital Banks**
   - Online Bank (GCash) - Philippine mobile wallet
   - Online Bank (PayMaya) - Philippine digital wallet  
   - Online Bank (Wise) - International money transfer
   - Online Bank (PayPal) - Global payment platform
   - Custom e-wallet names supported

3. **Physical Cash**
   - Wallet (Cash) - Physical wallet cash
   - Wallet (Petty Cash) - Small cash reserves
   
4. **Credit Accounts**
   - Credit Card - Credit card accounts
   - Line of Credit - Credit lines and loans

#### Account Data Model
```dart
class Account {
  String id;
  String userId;
  String name; // "Chase Savings", "GCash Wallet"
  String type; // 'bank', 'online_bank', 'wallet', 'credit'
  String subtype; // 'savings', 'checking', 'cash', 'credit_card'
  String institution; // 'Chase', 'GCash', 'PayPal', null for cash
  double currentBalance;
  String currency;
  bool isActive;
  DateTime createdAt;
}
```

#### Account Features
- **Balance Tracking** - Real-time balance updates from transactions
- **Balance History** - Track balance changes over time
- **Manual Balance Adjustment** - Correct balances when needed
- **Account Status** - Active/inactive account management
- **Multi-Currency Support** - Different currencies per account

#### Account Screens
- **Account List View**
  - Total net worth display
  - Grouped by account type
  - Balance and last transaction info
  - Quick balance adjustment
- **Add/Edit Account Form**
  - Account type selector with icons
  - Institution/bank name input
  - Initial balance setup
  - Currency selection
- **Account Detail View**
  - Transaction history for the account
  - Balance trend chart
  - Account management options

---

### 4. Account Transfers System
**Goal:** Track money movement between accounts with fees

#### Transfer Types
- **Bank to Bank** - Between different bank accounts
- **Bank to E-Wallet** - Bank account to digital wallet
- **E-Wallet to E-Wallet** - Between digital wallets  
- **Cash Deposit** - Add cash to bank/e-wallet
- **Cash Withdrawal** - Withdraw from bank/e-wallet to cash
- **Credit Payment** - Pay credit card from other accounts

#### Transfer Data Model
```dart
class Transfer {
  String id;
  String userId;
  String fromAccountId;
  String toAccountId;
  double fromAmount; // amount in source account currency
  double toAmount; // amount in destination account currency
  double exchangeRate; // conversion rate used
  bool manualRateOverride; // whether user manually set the rate
  double transferFee;
  String description;
  DateTime date;
  String status; // 'completed', 'pending', 'failed'
  String referenceNumber; // optional
  Map<String, dynamic> exchangeRateHistory; // rate at time of transfer
}
```

#### Transfer Features
- **Fee Calculation** - Automatic fee calculation based on transfer type
- **Multi-Currency Transfers** - Handle currency conversion with real-time exchange rates
- **Exchange Rate Updates** - Users can update/override exchange rates for transfers
- **Manual Amount Override** - Users can manually adjust final transfer amounts after conversion
- **Transfer Categories** - Categorize transfers (bill payment, savings, etc.)
- **Recurring Transfers** - Set up automatic transfers
- **Transfer Limits** - Set daily/monthly transfer limits per account
- **Currency Conversion History** - Track exchange rates used for historical transfers

#### Common Transfer Fees (Philippine Context)
- Interbank transfers: ₱25-₱50
- E-wallet to bank: ₱15-₱25  
- International transfers: 2-3% of amount
- ATM withdrawals: ₱15-₱20

#### Transfer Screens
- **Transfer Form**
  - From/To account selectors with currency display
  - Source amount input with currency
  - Real-time exchange rate display with "Update Rate" button
  - Manual exchange rate override option
  - Destination amount preview (auto-calculated)
  - Manual destination amount override
  - Transfer fee display and explanation
  - Exchange rate source and timestamp
  - Schedule transfer option
- **Transfer History**
  - List of all transfers with status and exchange rates
  - Filter by account, date, status, currency
  - Exchange rate history for each transfer
  - Transfer receipt viewing with rate details
- **Currency Exchange Screen**
  - Real-time exchange rates for all supported currencies
  - Rate update timestamps
  - Historical exchange rate charts
  - Rate alert notifications

---

### 5. Enhanced Category Management
**Goal:** Full CRUD operations for custom categories

#### Category Types
- **Expense Categories** - For spending classification
- **Income Categories** - For income source classification
- **Transfer Categories** - For transfer purposes

#### Category CRUD Features
- **Create Categories**
  - Custom name, icon, and color
  - Parent category selection (subcategories)
  - Category type (expense/income/transfer)
- **Edit Categories**
  - Update name, icon, color
  - Change parent category
  - Merge categories with transaction reassignment
- **Delete Categories**
  - Check for existing transactions
  - Offer transaction reassignment
  - Soft delete with recovery option
- **Category Analytics**
  - Usage statistics
  - Most/least used categories
  - Category spending trends

#### Default Category Expansions
**Additional Expense Categories:**
- Travel & Vacation ✈️
- Education & Learning 🎓
- Pets 🐕
- Insurance 🛡️
- Charity & Donations ❤️
- Hobbies & Recreation 🎨
- Home & Garden 🏡

**Additional Income Categories:**
- Side Hustle 💼
- Refunds & Cashbacks 💰
- Insurance Claims 🛡️
- Lottery & Gambling 🎲
- Government Benefits 🏛️

#### Category Screens
- **Category Management Screen**
  - Tabbed view (Expense | Income | Transfer)
  - Create new category button
  - Edit/delete existing categories
- **Add/Edit Category Form**
  - Category name input
  - Icon picker with search
  - Color picker with presets
  - Parent category selector

---

### 6. Enhanced Budget System
**Goal:** Income-aware budgeting with smart recommendations

#### Budget Types
1. **Absolute Amount Budgets** - Fixed amount (e.g., ₱5,000 for food)
2. **Percentage-Based Budgets** - Percentage of income (e.g., 30% for food)
3. **Dynamic Budgets** - Adjust based on income changes

#### Budget Calculation Methods
- **50/30/20 Rule**
  - 50% Needs (rent, groceries, utilities)
  - 30% Wants (entertainment, dining out)
  - 20% Savings (emergency fund, investments)
- **Custom Ratios** - User-defined percentages
- **Zero-Based Budgeting** - Every dollar allocated

#### Income-Based Budget Features
- **Income Integration** - Budgets adjust to monthly income
- **Net Income Calculation** - Budget from after-tax income
- **Remaining Income Tracking** - Money left after budgets
- **Budget Recommendations** - AI suggests budget amounts
- **Savings Goal Integration** - Automatic savings allocation

#### Enhanced Budget Screens
- **Budget Overview**
  - Monthly income display
  - Allocated vs available money
  - Budget vs actual progress bars
  - Savings goal progress
- **Budget Planning**
  - Income-based budget calculator
  - Preset ratio templates (50/30/20)
  - Custom ratio builder
- **Budget Analytics**
  - Budget adherence trends
  - Category overspend analysis
  - Savings rate tracking

---

### 7. Database Schema Updates

#### New Tables Required
```sql
-- Income tracking
CREATE TABLE income (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  gross_amount DECIMAL(10,2) NOT NULL,
  net_amount DECIMAL(10,2) NOT NULL,
  tax_amount DECIMAL(10,2) DEFAULT 0,
  tax_rate DECIMAL(5,2) DEFAULT 0,
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  account_id UUID REFERENCES accounts(id) ON DELETE SET NULL,
  source TEXT,
  description TEXT,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  is_recurring BOOLEAN DEFAULT false,
  period TEXT,
  tax_details JSONB,
  deleted_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Account/Wallet management  
CREATE TABLE accounts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('bank', 'online_bank', 'wallet', 'credit')),
  subtype TEXT NOT NULL,
  institution TEXT,
  current_balance DECIMAL(12,2) NOT NULL DEFAULT 0,
  currency TEXT NOT NULL DEFAULT 'USD',
  is_active BOOLEAN DEFAULT true,
  deleted_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Account transfers
CREATE TABLE transfers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  from_account_id UUID REFERENCES accounts(id) ON DELETE CASCADE,
  to_account_id UUID REFERENCES accounts(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL,
  transfer_fee DECIMAL(8,2) DEFAULT 0,
  exchange_rate DECIMAL(10,6) DEFAULT 1,
  description TEXT,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  status TEXT DEFAULT 'completed' CHECK (status IN ('completed', 'pending', 'failed')),
  reference_number TEXT,
  deleted_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### Table Updates Required
```sql
-- Add account_id to expenses table
ALTER TABLE expenses ADD COLUMN account_id UUID REFERENCES accounts(id) ON DELETE SET NULL;

-- Add budget type to budgets table  
ALTER TABLE budgets ADD COLUMN budget_type TEXT DEFAULT 'absolute' CHECK (budget_type IN ('absolute', 'percentage'));
ALTER TABLE budgets ADD COLUMN percentage DECIMAL(5,2);

-- Add category type to categories table
ALTER TABLE categories ADD COLUMN category_type TEXT DEFAULT 'expense' CHECK (category_type IN ('expense', 'income', 'transfer'));
```

---

### 8. Implementation Priority — ✅ ALL COMPLETED

**Week 7 (Phase 1 Final) — ✅ DONE**
1. ✅ Enhanced Navigation — drawer menu with proper routing
2. ✅ Income System — full income CRUD with tax calculation
3. ✅ Account Management — account CRUD with balance tracking
4. ✅ Enhanced Dashboard — income vs expense overview

**Week 8 (Phase 1 Complete) — ✅ DONE**
5. ✅ Account Transfers — transfer system with live exchange rates and fees
6. ✅ Tax Calculation — income tax integration (percentage / fixed / hybrid)
7. ✅ Category CRUD — full category management (expense / income / transfer types)
8. ✅ Enhanced Budgets — income-based budget calculations

**Post-Phase 1 (Completed in later phases) — ✅ ALL DONE**
9. ✅ Advanced Analytics — income/expense/transfer analytics via fl_chart
10. ✅ Recurring Transactions — RecurringSchedulerService (5 sub-runners)
11. ✅ Financial Goals — GoalListScreen, GoalFormScreen, GoalDetailScreen + GoalAIService
12. ✅ Reports & Export — WeeklyReportScreen + PDF export via ReportPdfService

This comprehensive system now provides a full financial management platform.