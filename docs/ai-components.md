# AI Components

## Overview
AI-FAP uses multiple AI/ML components to automate expense tracking, provide intelligent insights, and help users make better financial decisions.

---

## 1. Receipt OCR (Optical Character Recognition)

### Purpose
Extract structured data from receipt photos automatically.

### Technology Stack

#### Cloud Services (Primary)
- **Google Cloud Vision API**
  - High accuracy for printed text
  - Multi-language support
  - Handles various receipt formats
  - Document text detection
  
- **AWS Textract** (Alternative)
  - Structured data extraction
  - Table recognition
  - Form detection
  
- **Azure Computer Vision** (Alternative)
  - OCR capabilities
  - Good international support

#### Fallback: Tesseract.js
- Open-source OCR
- Offline processing
- Lower accuracy but privacy-focused

### Processing Pipeline

```
1. Image Capture
   ↓
2. Preprocessing
   - Crop borders
   - Enhance contrast
   - Deskew/rotate
   - Denoise
   ↓
3. OCR Processing
   - Text extraction
   - Confidence scoring
   ↓
4. Post-processing
   - Merchant name extraction
   - Amount parsing (regex patterns)
   - Date recognition
   - Line item detection
   ↓
5. Data Structuring
   - JSON format
   - Field mapping
   ↓
6. Validation & User Review
```

### Data Extraction

#### Key Fields
- **Merchant Name**
  - Look for top-of-receipt text
  - Largest font size typically
  - Cross-reference with business database
  
- **Total Amount**
  - Keywords: "Total", "Amount Due", "Balance"
  - Usually near bottom
  - Format: $XX.XX or XX.XX
  
- **Date**
  - Format detection (MM/DD/YYYY, DD-MM-YYYY, etc.)
  - Validate reasonable date range
  
- **Line Items** (Optional)
  - Item name and individual prices
  - Quantity detection
  - Tax calculation

#### Confidence Scoring
Each extracted field gets confidence score (0-100%):
- **> 90%**: Auto-accept
- **70-90%**: Flag for review
- **< 70%**: Require manual input

### Edge Cases & Error Handling

#### Common Issues
- **Crumpled receipts** → Image enhancement
- **Faded text** → Contrast adjustment
- **Multiple languages** → Language detection first
- **Handwritten** → Lower confidence, manual review
- **Poor lighting** → Request retake
- **Thermal paper** → Time-sensitive processing

#### Fallback Strategy
1. Try cloud OCR
2. If fails, try Tesseract
3. If still fails, pre-fill what's detected
4. User completes missing fields

### Training & Improvement

#### Dataset
- Collect anonymized receipts
- Diverse merchant types
- Various formats and conditions
- Multi-language samples

#### Continuous Learning
- Track user corrections
- Identify common OCR mistakes
- Retrain models quarterly
- Region-specific optimizations

---

## 2. Smart Categorization Engine

### Purpose
Automatically classify expenses into appropriate categories based on merchant, amount, and user behavior.

### Model Architecture

#### Approach: Multi-Classification ML Model

**Model Type:** BERT-based Text Classification / FastText

**Training Features:**
1. **Merchant Name** (primary)
   - Tokenized text
   - Word embeddings
   
2. **Transaction Amount**
   - Binned ranges
   - Category-specific typical amounts
   
3. **Time Context**
   - Day of week
   - Time of day
   - Month (seasonal patterns)
   
4. **User History**
   - Previous categorizations for same merchant
   - User's most frequent categories
   - Manual correction patterns

5. **Location** (if available)
   - Business type by location
   - Regional patterns

### Categories & Subcategories

```
Food
├── Groceries
├── Dining Out
├── Coffee Shops
├── Fast Food
└── Food Delivery

Transport
├── Gas/Fuel
├── Public Transit
├── Ride Sharing
├── Parking
└── Vehicle Maintenance

Bills
├── Rent/Mortgage
├── Utilities
├── Phone/Internet
├── Insurance
└── Subscriptions

Shopping
├── Clothing
├── Electronics
├── Home Goods
├── Personal Care
└── Gifts

Entertainment
├── Movies/Shows
├── Sports
├── Hobbies
├── Games
└── Concerts

Healthcare
├── Doctor Visits
├── Pharmacy
├── Dental
├── Insurance
└── Wellness

Others
├── Education
├── Charity
├── Pets
└── Miscellaneous
```

### Categorization Rules

#### Rule-Based System (Pre-ML)
For known merchants with high confidence:

```python
# Example rules
if merchant in ["Starbucks", "Dunkin Donuts", "Coffee Bean"]:
    category = "Food > Coffee Shops"
    
if merchant in ["Uber", "Lyft", "Grab"]:
    category = "Transport > Ride Sharing"
    
if merchant in ["Netflix", "Spotify", "Disney+"]:
    category = "Bills > Subscriptions"
```

#### ML Classification
For unknown merchants or ambiguous cases:

1. Feature extraction from merchant name
2. Model inference
3. Confidence score
4. If confidence > 80%, auto-categorize
5. If confidence < 80%, suggest top 3 categories

### Personalization & Learning

#### User Correction System
When user manually changes a category:

```python
# Store correction
correction = {
    'merchant': 'Shell Gas Station',
    'original_category': 'Shopping',
    'corrected_category': 'Transport > Gas',
    'user_id': 12345,
    'timestamp': '2026-02-11'
}

# Update user preference model
user_preferences[merchant] = corrected_category

# Contribute to global training data (anonymized)
training_data.append(correction)
```

#### Adaptive Learning
- Per-user models fine-tuned on individual behavior
- Global model updated monthly with aggregate data
- A/B testing for model improvements

### Performance Metrics

#### Target Metrics
- **Accuracy:** > 85% on first attempt
- **User Correction Rate:** < 15%
- **Unknown Merchant Handling:** > 70% accuracy

#### Evaluation
- Confusion matrix for category misclassifications
- Precision/recall per category
- User satisfaction surveys

---

## 3. AI Insights Engine

### Purpose
Analyze spending patterns and generate actionable, human-readable insights.

### Insight Types

#### 1. Comparative Insights
Compare current spending to historical data.

**Examples:**
- "You spent 28% more on food this week."
- "Your transport costs are down 15% from last month."
- "This is your highest shopping month this year."

**Algorithm:**
```python
def generate_comparative_insight(category, timeframe):
    current = get_spending(category, timeframe)
    previous = get_spending(category, timeframe - 1)
    
    change_pct = ((current - previous) / previous) * 100
    
    if abs(change_pct) > 10:  # Significant change
        trend = "more" if change_pct > 0 else "less"
        return f"You spent {abs(change_pct):.0f}% {trend} on {category} {timeframe}."
```

#### 2. Pattern Recognition
Identify spending habits and trends.

**Examples:**
- "You typically spend $120/week on groceries."
- "Most shopping happens on weekends."
- "Coffee expenses spike on Mondays."

**Algorithm:**
```python
def detect_patterns(category, period='weekly'):
    data = get_historical_spending(category, last_12_weeks)
    
    # Time series analysis
    avg = data.mean()
    std = data.std()
    
    # Day of week analysis
    dow_spending = group_by_day_of_week(data)
    peak_day = dow_spending.idxmax()
    
    return f"You typically spend ${avg:.0f}/{period} on {category}."
```

#### 3. Anomaly Detection
Flag unusual expenses.

**Examples:**
- "Unusual expense: $250 at Electronics Store."
- "Your bill spending doubled this month."
- "First time spending on Healthcare in 3 months."

**Algorithm:**
```python
def detect_anomalies(expenses):
    amounts = [e.amount for e in expenses]
    
    # Z-score method
    mean = np.mean(amounts)
    std = np.std(amounts)
    
    for expense in expenses:
        z_score = (expense.amount - mean) / std
        
        if abs(z_score) > 2:  # Outlier
            return f"Unusual expense: ${expense.amount} at {expense.merchant}."
```

#### 4. Savings Opportunities
Suggest ways to reduce spending.

**Examples:**
- "If you reduce dining out by 20%, you'll save $85/month."
- "You could save $30/month by meal prepping."
- "Cancel unused subscriptions to save $25/month."

**Algorithm:**
```python
def find_savings_opportunities(spending_data):
    opportunities = []
    
    # High-frequency categories
    for category in ['Dining Out', 'Coffee Shop']:
        monthly_spend = get_monthly_spending(category)
        
        if monthly_spend > category_threshold[category]:
            reduction = monthly_spend * 0.20
            opportunities.append({
                'category': category,
                'suggestion': f'Reduce by 20%',
                'savings': reduction
            })
    
    return opportunities
```

#### 5. Budget Alerts
Warn when approaching or exceeding budgets.

**Examples:**
- "You've spent 80% of your food budget."
- "Warning: Already exceeded transport budget."
- "On track to stay within budget this month."

**Algorithm:**
```python
def check_budget_status(category):
    budget = get_budget(category)
    spent = get_monthly_spending(category)
    
    percentage = (spent / budget) * 100
    
    if percentage >= 80:
        return f"You've spent {percentage:.0f}% of your {category} budget."
```

### Natural Language Generation (NLG)

#### Template-Based Generation
Structured templates with variable insertion.

```python
templates = {
    'comparative_increase': "You spent {pct}% more on {category} this {period}.",
    'comparative_decrease': "You spent {pct}% less on {category} this {period}.",
    'savings_opportunity': "If you reduce {category} by {pct}%, you'll save ${amount}/month.",
}
```

#### Dynamic Language
Adjust tone based on insight severity:
- **Positive:** "Great job! You saved..."
- **Neutral:** "You spent..."
- **Alert:** "Warning: You've exceeded..."

### Insight Prioritization

#### Ranking System
Not all insights are equally important.

**Priority Levels:**
1. **Critical** - Budget exceeded, unusual charges
2. **High** - Significant spending changes, savings opportunities
3. **Medium** - Pattern observations, milestones
4. **Low** - General stats, historical comparisons

**Display Strategy:**
- Show top 3-5 insights on dashboard
- Critical insights → Push notifications
- Rest available in "View All Insights"

### Personalization

#### User Preferences
- Financial goals influence insight focus
- Opt-in for aggressive vs. gentle nudges
- Category-specific interest (e.g., "I care most about food budget")

#### Learning from Engagement
Track which insights users act on:
- Clicked insight → Increase similar insights
- Ignored consistently → Reduce frequency
- Led to behavior change → Prioritize type

---

## 4. Budget Prediction AI

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

## 5. Subscription Detection AI

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

## 6. Financial Health Score

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
