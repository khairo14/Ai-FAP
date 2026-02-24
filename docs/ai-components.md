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

## 6. Budget Prediction AI ✅ DEPLOYED (Dart on-device)

### Purpose
Calculate realistic budgets based on spending history and suggest optimal allocations.

### Implementation (Phase 3 — Deployed)

**Service:** `lib/features/budgets/services/budget_suggestion_service.dart`  
**Screen:** `lib/features/budgets/screens/budget_suggestion_screen.dart`

#### Algorithm (50/30/20 Rule Engine — Dart)

```
Input: monthly_income (from IncomeProvider or user-entered)
       3-month expense history per category (from Supabase)

1. Map categories to buckets:
   - "Needs" (50%): rent, bills, groceries, transport, healthcare
   - "Wants" (30%): dining, entertainment, shopping, travel
   - "Savings" (20%): remainder allocated as savings goal

2. Compute 3-month average per category

3. Allocate proportionally within each bucket;
   cap overspending categories to rule limits

4. Round suggestions to nearest $5

5. Mark categories that already have a budget → "Update" badge

Output: List<BudgetSuggestion> with bucket label, 3-mo avg, suggested amount,
        is_existing_budget flag
```

#### BudgetSuggestionScreen
- Income input with auto-detect from `IncomeProvider` stats
- Inline 50/30/20 rule explainer with bucket legend
- Suggestions grouped by Needs / Wants
- Checkbox selection — toggle individual or Select All / Deselect All
- "Apply N Budgets" button — bulk create or update via `BudgetProvider`
- Savings goal tile (20% recommendation)
- AI `✨` button in `BudgetListScreen` AppBar opens this screen

**Note:** Time series forecasting (Facebook Prophet) is **not implemented** — the engine is rule-based + 3-month averaging, all in Dart, zero cloud calls.

---

## 7. Subscription Detection AI ✅ DEPLOYED (inside SmartInsightsService)

### Purpose
Automatically identify recurring charges from expense transaction history.

### Implementation (Phase 2 — Deployed inside SmartInsightsService)

**Service:** `lib/shared/services/smart_insights_service.dart`  
**Method:** `_findRecurring()` → `detectRecurring()`

#### Algorithm (Dart)

```
Group expenses by normalized (description/category)
For each group with ≥ 3 occurrences:
  Compute day-gaps between consecutive transactions
  if stdDev(gaps) < 5  AND mean ≈ 7  → weekly
  if stdDev(gaps) < 7  AND mean ≈ 14 → bi-weekly
  if stdDev(gaps) < 10 AND mean ≈ 30 → monthly
  → RecurringExpense(frequency, avgAmount, nextEstimatedDate)
```

The results appear in:
- `SmartInsightsScreen` Recurring tab
- `SubscriptionTrackerScreen` (premium-gated) — filtered to monthly recurring only
- Spending Digest

**Note:** The Python pseudo-code in the earlier design spec was never implemented. All detection is Dart on-device with the gap-analysis algorithm above.

---

## 8. Financial Health Score ⚠️ PARTIAL

### Purpose
Give users a simple metric to understand overall financial health.

### Current State
- ✅ `FinancialHealthCard` widget exists in the UI (`lib/features/home/widgets/financial_health_card.dart`)
- ✅ `DashboardService` computes a basic health score from budget adherence + income vs expenses
- ⚠️ Savings rate input (emergency fund tracking) not yet wired — shows basic score only
- ❌ Full 5-factor scoring (debt management, spending consistency, emergency fund) not implemented

**Planned Score Components (0-100):**
1. Budget Adherence (30 pts)
2. Savings Rate (25 pts)
3. Debt Management (20 pts)
4. Spending Consistency (15 pts)
5. Emergency Fund (10 pts)

---

## 9. Personalization Engine ✅ DEPLOYED (Phase 3)

### Purpose
Learn from user corrections to category suggestions and apply the learned mapping instantly on subsequent entries.

### Implementation (Phase 3 — Deployed)

**Service:** `lib/shared/services/personalization_service.dart`  
**Table:** `merchant_category_overrides` (Supabase, RLS + index)

#### How It Works

```
On ExpenseFormScreen open:
  PersonalizationService.preload() → fetches all user overrides into in-memory Map<merchant, categoryId>

On merchant field unfocus:
  1. Check in-memory override cache → if found, pre-select that category
     Show "Personalized suggestion" chip below the field
  2. If not in cache → fallback to AutoCategorizationService (keyword matching)

On expense save:
  if user manually changed the category → _userPickedCategory flag is true
    → PersonalizationService.saveOverride(merchant, chosenCategoryId)
    → upserts to DB (use_count++ if exists, insert if new)
```

#### Data Model

```dart
// merchant_category_overrides table
{
  id:          uuid,
  user_id:     uuid,
  merchant:    text,       // lowercase, trimmed
  category_id: uuid,
  use_count:   int DEFAULT 1,
  created_at:  timestamptz,
  updated_at:  timestamptz
}
```

---

## 10. Goal AI Service ✅ DEPLOYED (Phase 4)

### Purpose
Provide timeline-based savings recommendations and feasibility analysis for financial goals.

### Implementation (Phase 4 — Deployed)

**Service:** `lib/features/goals/services/goal_ai_service.dart`

#### Capabilities

```
Input: goal (target_amount, current_savings, deadline), monthlyIncome, monthlyExpenses

1. requiredMonthlySavings = (target - current) / monthsRemaining

2. Feasibility:
   - availableToSave = monthlyIncome - monthlyExpenses
   - feasibilityRatio = requiredMonthlySavings / availableToSave
   - FEASIBLE  : ratio ≤ 0.8
   - STRETCH   : ratio ≤ 1.2
   - INFEASIBLE: ratio > 1.2

3. Suggestions:
   - If infeasible → "Consider extending deadline by X months" or
     "Reduce spending by $Y/month to stay on track"
   - If feasible → "You can reach this goal by [date] saving $Z/month"

4. Milestone projections: 25% / 50% / 75% dates
```

---

## 11. Debt Payoff AI Service ✅ DEPLOYED (Phase 4)

### Purpose
Simulate snowball and avalanche debt payoff strategies and recommend the optimal approach.

### Implementation (Phase 4 — Deployed)

**Service:** `lib/features/debts/services/debt_ai_service.dart`

#### Strategies

**Snowball Method:**
```
Sort debts by balance ascending
Apply minimum payments to all + extra payment to smallest
When smallest paid off → roll payment to next
→ Motivational (quick wins) but costs more interest
```

**Avalanche Method:**
```
Sort debts by APR descending
Apply minimum payments to all + extra payment to highest-APR
→ Mathematically optimal (least total interest)
```

#### Output
```dart
class DebtPayoffResult {
  final String   strategy;           // 'snowball' | 'avalanche'
  final DateTime payoffDate;
  final double   totalInterestPaid;
  final double   monthlyPayment;
  final List<DebtMilestone> milestones; // per-debt payoff dates
}
```

The simulation is displayed in `DebtDetailScreen` with a side-by-side comparison of both strategies.

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
