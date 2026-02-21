# AI Components

## Overview
FundVance AI uses multiple AI/ML components to automate expense tracking, provide intelligent insights, and help users make better financial decisions.

---

## 1. Receipt OCR (Optical Character Recognition)

### Purpose
Extract structured data from receipt photos automatically, fully on-device.

### Implementation (Phase 2 — Deployed)

**Package:** `google_mlkit_text_recognition: ^0.13.0`  
**Package:** `image_picker: ^1.1.2`  
**Service:** `lib/shared/services/receipt_service.dart`  
**Model:** `lib/shared/models/receipt_scan_result.dart`

#### Technology: Google ML Kit (On-Device)
- ✅ **FREE** — zero API costs
- ✅ **Privacy-first** — images never leave the device
- ✅ **Offline capable** — no internet required
- ✅ **Fast** — < 1 second processing
- ✅ **85–90% accuracy** on clear receipts
- ✅ **No rate limits** — unlimited scans

#### Processing Pipeline

```
1. Image Capture
   User taps Scan button → camera or gallery picker opens
   ↓
2. OCR (On-Device, Google ML Kit)
   TextRecognizer().processImage(InputImage.fromFile(file))
   Returns raw recognized text string
   ↓
3. Amount Extraction
   Priority keyword regex: "total", "amount", "grand total", etc.
   Fallback: largest numeric value found in text
   ↓
4. Date Extraction
   4 regex patterns: MM/DD/YYYY, DD-MM-YYYY, Month-name formats, etc.
   ↓
5. Merchant Extraction
   First non-numeric, non-special text line (typically the shop name)
   ↓
6. Line-Item Extraction
   Lines matching "text $price" or "text price" patterns
   ↓
7. Confidence Scoring
   0.0–1.0 based on how many fields were extracted
   ↓
8. Auto-Categorization
   AutoCategorizationService.suggestFromMerchant() + suggestFromItems()
   ↓
9. Review Screen
   User edits extracted fields → taps Save → expense created
```

#### Models

```dart
class ReceiptItem {
  final String name;
  final double? price;
}

class ReceiptScanResult {
  final double?      amount;
  final DateTime?    date;
  final String?      merchant;
  final List<ReceiptItem> items;
  final String       rawText;
  final double       confidence;     // 0.0 – 1.0
  final String?      suggestedCategoryName;
}
```

#### Confidence Scoring Logic
- Start at 0.0
- +0.4 if total amount extracted
- +0.2 if merchant extracted
- +0.2 if date extracted
- +0.2 if line items extracted
- Score ≥ 0.6 → considered reliable; shown green in UI

#### Android Permissions
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
```

#### iOS Info.plist
```xml
<key>NSCameraUsageDescription</key>
<key>NSPhotoLibraryUsageDescription</key>
```

### Future Upgrade Path

| Phase | Free Users | Premium Users |
|-------|-----------|--------------|
| MVP (now) | Google ML Kit (unlimited) | Google ML Kit |
| Growth | ML Kit (10 scans/month) | Cloud Vision API |
| Scale | ML Kit (10 scans) | Custom fine-tuned model |

---

## 2. Smart Categorization Engine

### Purpose
Automatically suggest an expense category based on merchant name or scanned receipt items.

### Implementation (Phase 2 — Deployed)

**Service:** `lib/shared/services/auto_categorization_service.dart`

#### Approach: Keyword-Based Matching

A static keyword map is defined for 9 top-level categories. The service does a lowercase substring scan of the merchant name (and optionally item names) against each category's keyword list.

```dart
static const Map<String, List<String>> _categoryKeywords = {
  'Food & Dining':    ['restaurant','cafe','coffee','pizza','burger','mcd','kfc',
                       'starbucks','subway','sushi','bakery','grocery','supermarket',
                       'market','food','dining','eat','lunch','dinner','breakfast'],
  'Transportation':   ['uber','grab','taxi','bus','train','mrt','lrt','petrol',
                       'fuel','parking','toll','car','auto','transport','lyft'],
  'Shopping':         ['mall','shop','store','amazon','lazada','shopee','fashion',
                       'clothing','nike','adidas','electronic','gadget','retail'],
  'Bills & Utilities':['electric','water','gas','internet','phone','telco','bill',
                       'utility','rent','insurance','subscription','netflix','spotify'],
  'Healthcare':       ['hospital','clinic','pharmacy','doctor','medical','health',
                       'dental','optical','guardian','watson'],
  'Entertainment':    ['cinema','movie','theater','game','concert','sport','gym',
                       'fitness','entertainment','recreation'],
  'Education':        ['school','university','college','course','tuition','book',
                       'stationery','education','training','class'],
  'Travel':           ['hotel','flight','airline','airbnb','travel','holiday',
                       'vacation','resort','booking','airport'],
  'Others':           [],
};
```

#### Matching Logic

```
1. Normalize input → lowercase
2. For each category keyword list:
   - If any keyword is substring of merchant name → return that category
3. If no match from merchant → try item names (from receipt)
4. If still no match → return null (user selects manually)
5. findCategoryId() → resolve category name against Supabase categories list
```

#### Integration Points
- Called by `ReceiptService` after OCR scan → result stored in `ReceiptScanResult.suggestedCategoryName`
- `ReceiptReviewScreen` pre-selects the suggested category in the dropdown
- `ExpenseFormScreen` allows user to override

### Upgrade Path (Phase 3)
- Replace keyword maps with on-device FastText or TFLite model
- Add user-correction feedback loop
- Sync corrections to Supabase for aggregate model retraining

---

## 3. AI Insights Engine

### Purpose
Analyze spending patterns on-device and surface actionable, human-readable insights without any cloud calls.

### Implementation (Phase 2 — Deployed)

**Service:** `lib/shared/services/smart_insights_service.dart`  
**Model:** `lib/shared/models/spending_insight.dart`  
**Screen:** `lib/features/analytics/screens/smart_insights_screen.dart`

#### Insight Types (5)

| `InsightType` | `InsightSeverity` range | Description |
|---|---|---|
| `budgetAlert` | warning / critical | Budget nearing / exceeded threshold |
| `anomaly` | warning / critical | Category spend unusually high vs average |
| `trend` | info / warning | Month-over-month spend direction |
| `recurring` | info | Detected recurring expense pattern |
| `milestone` | info | Category where spending improved |

#### Algorithm Overview

**1. Budget Alerts** (`_budgetAlerts`)
```
For each active budget:
  spent = sum(expenses in category in current month)
  ratio = spent / budget.amount
  if ratio >= 1.0  → critical alert
  if ratio >= 0.8  → warning alert
```

**2. Anomaly Detection** (`_anomalyInsights`)
```
For each category:
  currentMonth = total spend this month
  avg = average monthly spend over previous 3 months
  if currentMonth > avg * 1.5 AND currentMonth > avg + 50
    → anomaly insight ("X% above your average")
```

**3. Trend Analysis** (`_trendInsights`)
```
For each category:
  thisMonth vs lastMonth
  if change > 20% AND absolute > $20
    → trend insight (up or down)
```

**4. Recurring Detection** (`_findRecurring` → `detectRecurring`)
```
Group expenses by normalized description/category
For each group ≥ 3 occurrences:
  Compute day-gaps between consecutive expenses
  if stdDev(gaps) < 5 AND mean ≈ 7  → weekly
  if stdDev(gaps) < 7 AND mean ≈ 14 → bi-weekly
  if stdDev(gaps) < 10 AND mean ≈ 30 → monthly
  → create RecurringExpense(frequency, avgAmount, nextDate)
```

**5. Milestones** (`_milestoneInsights`)
```
For each category:
  if thisMonth < lastMonth * 0.8 AND savings > $20
    → milestone insight ("saved $X vs last month")
```

#### UI Integration
- `SmartInsightsScreen` — full page, `TabController` with Insights tab + Recurring tab
- `_SmartInsightsBanner` — top widget on Analytics Dashboard (shows first 3 insights)
- Navigation drawer entry → Smart Insights

#### Data Model

```dart
enum InsightType   { budgetAlert, anomaly, trend, recurring, milestone }
enum InsightSeverity { info, warning, critical, positive }

class SpendingInsight {
  final String        id;
  final InsightType   type;
  final InsightSeverity severity;
  final String        title;
  final String        message;
  final DateTime      generatedAt;
  final String?       categoryId;
  final double?       amount;
  final double?       percentageChange;
}
```

#### Performance Characteristics
- **Zero API calls** — all computation in-memory on client
- **Input:** `List<Expense>`, `List<Budget>`, `List<Category>`
- **Output latency:** < 100 ms for typical data sets (< 1,000 expenses)
- **No persistent storage** — regenerated on each navigation to screen

---

## 4. Spending Digest (NLG Monthly Summary)

### Purpose
Generate a concise, readable monthly summary of the user's financial activity using template-based Natural Language Generation — no LLM required.

### Implementation (Phase 2 — Deployed)

**Service:** `lib/shared/services/spending_digest_service.dart`  
**Model:** `SpendingDigest`, `DigestLine`, `DigestLineType`  
**Widget:** `lib/features/home/widgets/spending_digest_card.dart`

#### DigestLineType (5 values)
| Value | Meaning |
|---|---|
| `topCategory` | Highest-spending category this month |
| `budgetStatus` | Budget adherence summary |
| `savingsOpportunity` | Potential saving vs. last month |
| `trend` | Overall spend trend |
| `general` | Catch-all summary line |

#### Generation Algorithm

```
Input: List<Expense> (current month), List<Budget>, List<Category>
Output: SpendingDigest (title + 5–6 DigestLine objects)

Steps:
1. Aggregate spend per category
2. Find top spending category → topCategory line
3. For each active budget: compute spent/limit ratio → budgetStatus lines
4. Compare to previous month total → trend line
5. Identify categories where spend dropped → savingsOpportunity lines
6. Compose title: "Your [MonthName] Financial Summary"
7. Return SpendingDigest(month, year, title, lines)
```

#### Sample Output
```
📊 Your February Financial Summary

• Your top spending category was Food & Dining ($342)
• You're within budget for Transportation (72% used)
• ⚠️ You exceeded your Shopping budget by $45
• Your overall spending is down 8% from January
• You saved $28 on Entertainment compared to last month
```

#### UI
- `SpendingDigestCard` on Home screen — collapsible (lazy-loads on demand)
- Shortcut button → navigates to `SmartInsightsScreen`
- Generated fresh each time card is expanded

---

## 5. Notification Centre

### Purpose
Deliver in-app financial alerts based on budget thresholds, spending anomalies, and monthly summaries — without any push notification service.

### Implementation (Phase 2 — Deployed)

**Provider:** `lib/features/notifications/notification_provider.dart`  
**Model:** `lib/shared/models/app_notification.dart`  
**Screen:** `lib/features/notifications/screens/notifications_screen.dart`

#### Notification Types (6)
| `NotificationType` | Trigger |
|---|---|
| `budgetAlert` | Budget ≥ 80% used or exceeded |
| `spendingAnomaly` | Category spend > 150% of average |
| `monthlyDigest` | Start of new month |
| `savingsOpportunity` | Category spend dropped significantly |
| `goalMilestone` | (Phase 3) Goal progress |
| `systemAlert` | App-level messages |

#### Severity Levels (4)
`info` → `warning` → `critical` → `positive`

#### NotificationProvider
```dart
class NotificationProvider extends ChangeNotifier {
  List<AppNotification> get notifications;    // all, newest first
  int get unreadCount;                        // badge count
  bool get hasUnread;

  Future<void> refreshAlerts(...)            // generate from insights
  void markRead(String id)
  void markAllRead()
  void dismiss(String id)
  void clearAll()
  void addMonthlySummaryNotification(SpendingDigest digest)
}
```

#### Alert Generation Flow
```
1. Home screen init → refreshAlerts(expenses, budgets, categories)
2. NotificationProvider calls SmartInsightsService.generateInsights()
3. Converts SpendingInsight list → AppNotification list
   - budgetAlert insight  → budgetAlert notification
   - anomaly insight      → spendingAnomaly notification
   - milestone insight    → positive notification
4. Sorts by severity (critical first)
5. Notifies listeners → bell badge updates
```

#### UI
- Bell icon with red dot in Home app bar (shows when `hasUnread`)
- Navigation drawer "Notifications" entry with `Badge` widget
- `NotificationsScreen`: swipe-to-dismiss tiles, unread dot per item, "Mark All Read" + "Clear All" actions

---

## 6. Budget Prediction AI

### Purpose
Calculate realistic budgets based on spending history and suggest optimal allocations.

### Algorithm

#### Data Collection
Minimum 2 months of spending data required.

**Inputs:**
- Historical expense data
- Income information (if provided)
- Fixed vs. variable expense classification
- User's financial goals

#### Budget Calculation Method

```python
def calculate_suggested_budget(category, user_id):
    # Get last 3 months of data
    history = get_spending_history(user_id, category, months=3)
    
    # Calculate statistics
    avg_spending = history.mean()
    std_dev = history.std()
    max_spending = history.max()
    
    # Base budget: average + 15% buffer
    suggested_budget = avg_spending * 1.15
    
    # Adjust for volatility
    if std_dev > avg_spending * 0.3:  # High volatility
        suggested_budget += std_dev * 0.5
    
    # Round to nearest $5
    return round(suggested_budget / 5) * 5
```

#### Income-Based Allocation
If income is known, use percentage-based budgeting.

**50/30/20 Rule:**
- 50% Needs (rent, bills, groceries)
- 30% Wants (dining, entertainment)
- 20% Savings

```python
def allocate_budget_by_income(monthly_income):
    return {
        'needs': monthly_income * 0.50,
        'wants': monthly_income * 0.30,
        'savings': monthly_income * 0.20,
    }
```

### Time Series Forecasting

#### Predictive Models
For users with 6+ months of data.

**Model:** Prophet (by Facebook)
- Handles seasonality
- Accounts for trends
- Robust to missing data

```python
from fbprophet import Prophet

def forecast_next_month_spending(category, user_id):
    # Historical data
    df = get_spending_timeseries(user_id, category)
    
    # Prophet model
    model = Prophet()
    model.fit(df)
    
    # Forecast next 30 days
    future = model.make_future_dataframe(periods=30)
    forecast = model.predict(future)
    
    return forecast['yhat'].tail(30).sum()
```

### Adaptive Budgeting

#### Dynamic Adjustments
Budgets evolve as spending patterns change.

- **Life Event Detection:** Big changes in spending → Suggest budget revision
- **Seasonal Adjustment:** Holidays → Temporarily increase budgets
- **Goal Integration:** If user is saving for goal → Reduce discretionary budgets

---

## 7. Subscription Detection AI

### Purpose
Automatically identify recurring charges as subscriptions.

### Detection Algorithm

#### Pattern Matching
Identify recurring transactions.

```python
def detect_subscriptions(expenses):
    # Group by merchant
    merchant_groups = group_by_merchant(expenses)
    
    subscriptions = []
    
    for merchant, transactions in merchant_groups.items():
        # Check for regularity
        if is_recurring(transactions):
            period = calculate_period(transactions)
            avg_amount = calculate_avg(transactions)
            
            subscriptions.append({
                'merchant': merchant,
                'frequency': period,  # monthly, weekly, annually
                'amount': avg_amount,
                'next_renewal': predict_next_charge(transactions)
            })
    
    return subscriptions

def is_recurring(transactions):
    # At least 3 transactions
    if len(transactions) < 3:
        return False
    
    # Similar amounts
    amounts = [t.amount for t in transactions]
    if np.std(amounts) / np.mean(amounts) > 0.1:  # More than 10% variation
        return False
    
    # Regular intervals
    dates = [t.date for t in transactions]
    intervals = np.diff(dates)
    
    # Check if intervals are roughly equal (±3 days)
    if np.std(intervals) < timedelta(days=3):
        return True
    
    return False
```

#### Known Subscription Services
Maintain database of common subscriptions:
- Streaming (Netflix, Spotify, Disney+)
- Software (Adobe, Microsoft 365)
- Memberships (gym, Amazon Prime)
- News/Media (NYT, Medium)

---

## 8. Financial Health Score

### Purpose
Give users a simple metric to understand overall financial health.

### Score Calculation (0-100)

#### Components
1. **Budget Adherence (30 points)**
   - Staying within budget = 30
   - Slightly over = 20
   - Significantly over = 0

2. **Savings Rate (25 points)**
   - Saving 20%+ of income = 25
   - Saving 10-20% = 15
   - Saving < 10% = 5

3. **Debt Management (20 points)**
   - No high-interest debt = 20
   - Paying down debt = 15
   - Debt increasing = 0

4. **Spending Consistency (15 points)**
   - Low volatility = 15
   - Medium volatility = 10
   - High volatility = 5

5. **Emergency Fund (10 points)**
   - 3+ months expenses = 10
   - 1-3 months = 5
   - < 1 month = 0

```python
def calculate_financial_health_score(user_id):
    score = 0
    
    # Budget adherence
    score += calculate_budget_score(user_id)
    
    # Savings rate
    score += calculate_savings_score(user_id)
    
    # Debt management
    score += calculate_debt_score(user_id)
    
    # Spending consistency
    score += calculate_consistency_score(user_id)
    
    # Emergency fund
    score += calculate_emergency_fund_score(user_id)
    
    return min(score, 100)  # Cap at 100
```

---

## AI Ethics & Privacy

### Data Privacy
- All AI processing respects user privacy
- No personally identifiable data in training sets
- Option to opt-out of AI training contributions
- Data anonymization for aggregate analysis

### Transparency
- Explain why AI made certain classifications
- Show confidence scores
- Allow users to correct AI decisions
- Document AI capabilities and limitations

### Bias Mitigation
- Diverse training data across income levels
- Avoid assumptions based on demographics
- Regular bias audits
- Inclusive language in insights

### User Control
- Toggle AI features on/off
- Adjust insight frequency
- Choose insight types (e.g., only savings tips)
- Export AI decisions for review
