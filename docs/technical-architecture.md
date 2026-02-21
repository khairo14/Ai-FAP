# Technical Architecture

## System Overview

FundVance AI (AI-FAP) is built as a cross-platform mobile application with cloud-based AI services and secure data synchronization.

## Final Technology Stack

### Core Decisions ✅

| Component | Technology | Why? |
|-----------|-----------|------|
| **Mobile App** | **Flutter** | Native performance, single codebase, excellent ML Kit integration |
| **Backend/Database** | **Supabase (PostgreSQL)** | 70% faster development, built-in auth/storage/realtime, cost-effective |
| **Receipt OCR** | **Google ML Kit** (MVP) | Free, on-device, privacy-first, 85-90% accuracy |
| | **Cloud Vision API** (Premium) | 95-98% accuracy for premium users |
| **State Management** | **Provider / Riverpod** | Simple, recommended by Flutter team |
| **Authentication** | **Supabase Auth** | Built-in JWT, OAuth, social login |
| **Storage** | **Supabase Storage** | S3-compatible, integrated with database |
| **AI Processing** | **Supabase Edge Functions** | TypeScript serverless for custom logic |
| **Charts** | **fl_chart** | Beautiful, customizable Flutter charts |
| **Real-time** | **Supabase Realtime** | WebSocket-based, automatic sync |

### Key Advantages of This Stack
- **Rapid Development:** Launch MVP in 3-4 months (vs 6-8 with traditional backend)
- **Cost-Effective:** $0 for MVP, scales with revenue
- **Type-Safe:** TypeScript/Dart across the stack
- **No Vendor Lock-in:** Can migrate to self-hosted PostgreSQL
- **Privacy-First:** On-device ML Kit for free users
- **Real-time by Default:** Live budget updates and sync

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────┐
│      Mobile Application (Flutter)               │
│  ┌───────────────────────────────────────────┐  │
│  │         Flutter Framework (Dart)          │  │
│  │  ┌─────────────────────────────────────┐  │  │
│  │  │  UI: Material & Cupertino Widgets   │  │  │
│  │  └─────────────────────────────────────┘  │  │
│  │  ┌─────────────────────────────────────┐  │  │
│  │  │  State Management (Provider/Riverpod)│ │  │
│  │  └─────────────────────────────────────┘  │  │
│  │  ┌─────────────────────────────────────┐  │  │
│  │  │  Local Cache (Supabase Local)       │  │  │
│  │  └─────────────────────────────────────┘  │  │
│  │  ┌─────────────────────────────────────┐  │  │
│  │  │  Google ML Kit (On-Device OCR)      │  │  │
│  │  └─────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────┘  │
└───────────────────┬─────────────────────────────┘
                    │ HTTPS/REST API
┌───────────────────▼─────────────────────────────┐
│              Supabase (PostgreSQL)               │
│  ┌───────────────────────────────────────────┐  │
│  │        Auto-Generated REST API            │  │
│  │        + Real-time Subscriptions          │  │
│  └───────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────┐  │
│  │        PostgreSQL Database                │  │
│  │  ┌─────────┐  ┌─────────┐  ┌──────────┐  │  │
│  │  │ Users   │  │Expenses │  │Categories│  │  │
│  │  └─────────┘  └─────────┘  └──────────┘  │  │
│  │  ┌─────────┐  ┌─────────┐  ┌──────────┐  │  │
│  │  │Budgets  │  │ Goals   │  │  Insights│  │  │
│  │  └─────────┘  └─────────┘  └──────────┘  │  │
│  └───────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────┐  │
│  │        Supabase Auth (Built-in)           │  │
│  └───────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────┐  │
│  │    Supabase Storage (Receipt Images)      │  │
│  └───────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────┐  │
│  │        Edge Functions (Node.js)           │  │
│  │  ┌────────────┐  ┌──────────────────┐    │  │
│  │  │  Premium   │  │  Categorization  │    │  │
│  │  │  OCR API   │  │     AI Engine    │    │  │
│  │  └────────────┘  └──────────────────┘    │  │
│  │  ┌────────────┐  ┌──────────────────┐    │  │
│  │  │  Insights  │  │    Budget AI     │    │  │
│  │  │   Engine   │  │   Predictions    │    │  │
│  │  └────────────┘  └──────────────────┘    │  │
│  └───────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘

           ┌─────────────────────────────────┐
           │   External Services (Premium)   │
           │  ┌──────────────────────────┐   │
           │  │ Google Cloud Vision API  │   │
           │  │ (High-accuracy OCR)      │   │
           │  └──────────────────────────┘   │
           └─────────────────────────────────┘
```

---

## Technology Stack

### Mobile Application

#### Framework: Flutter

**Why Flutter?**
- **Superior Performance:** Compiled to native ARM code, consistent 60fps
- **Single Codebase:** One codebase for iOS and Android
- **Rich UI:** Beautiful Material Design and Cupertino widgets built-in
- **Hot Reload:** Instant development feedback
- **Strong Ecosystem:** Excellent package support (pub.dev)
- **Google ML Kit Integration:** Native support for on-device ML
- **Supabase Integration:** Official Flutter SDK with real-time support
- **Cost-Effective:** One development team for both platforms
- **Future-Proof:** Growing rapidly with Google's backing

**Perfect for FundVance AI because:**
- Smooth animations for financial charts and transitions
- Excellent camera integration for receipt scanning
- Native ML Kit support for OCR
- Flutter Web support for future expansion
- Strong form handling for expense entry

#### Flutter Tech Stack

**Core Framework:**
- **Flutter SDK:** 3.19+ (stable)
- **Dart:** 3.3+
- **Target:** iOS 13+ / Android 8+ (API 26+)

**Essential Packages:**
- **State Management:** `provider` or `riverpod` (dependency injection + state)
- **Backend:** `supabase_flutter` (database, auth, storage, real-time)
- **HTTP Client:** `dio` (REST API calls, interceptors)
- **Local Storage:** Built-in with Supabase (offline-first)
- **Navigation:** `go_router` (declarative routing)
- **Image Handling:** `image_picker` (camera + gallery)
- **Image Processing:** `image` (crop, resize, enhance)
- **Charts:** `fl_chart` (beautiful, customizable charts)
- **OCR:** `google_ml_kit` (on-device text recognition)
- **UI Components:** `flutter_svg`, `cached_network_image`
- **Forms:** `flutter_form_builder` (validation, complex forms)
- **Date/Time:** `intl` (formatting, localization)
- **Permissions:** `permission_handler` (camera, storage access)

**Development Tools:**
- **Code Generation:** `freezed`, `json_serializable`
- **Testing:** `flutter_test`, `mockito`, `integration_test`
- **Linting:** `flutter_lints`
- **Analytics:** `firebase_analytics` or `mixpanel`

### Backend Services: Supabase + Edge Functions

#### Architecture Approach

**Primary Backend: Supabase (PostgreSQL + Auto-Generated API)**
- Handles 90% of backend needs out-of-the-box
- Auto-generated REST API from database schema
- Built-in authentication (JWT-based)
- Row Level Security (RLS) for data protection
- Real-time subscriptions for live updates
- File storage for receipt images

**Custom Backend: Supabase Edge Functions (Node.js/TypeScript)**
- For complex AI/ML operations
- Custom business logic
- Third-party API integrations
- Serverless execution (Deno runtime)

**Why This Approach?**
- ✅ **70% faster development** - No boilerplate CRUD code
- ✅ **Cost-effective** - No dedicated backend servers for MVP
- ✅ **Auto-scaling** - Supabase handles infrastructure
- ✅ **Type-safe** - TypeScript on Edge Functions
- ✅ **Real-time by default** - Built-in WebSocket support
- ✅ **Easy to extend** - Can add custom Node.js services later

#### Core Stack

**Database & API:**
- **Platform:** Supabase (PostgreSQL 15)
- **API:** Auto-generated REST API + PostgREST
- **Real-time:** Supabase Realtime (WebSocket-based)
- **Authentication:** Supabase Auth (JWT + OAuth 2.0)
- **Storage:** Supabase Storage (S3-compatible)

**Edge Functions (for AI/ML & Custom Logic):**
- **Runtime:** Deno (TypeScript/JavaScript)
- **Language:** TypeScript 5.x
- **Deployed:** Supabase Edge Functions
- **Use Cases:**
  - Premium OCR (Google Cloud Vision API calls)
  - AI categorization inference
  - Insights generation
  - Budget predictions
  - Subscription detection
  - Weekly report generation

**Edge Function Example:**
```typescript
// supabase/functions/analyze-receipt/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const { imageUrl, isPremium } = await req.json()
  
  if (isPremium) {
    // Call Google Cloud Vision API
    const ocrResult = await callCloudVisionAPI(imageUrl)
    return new Response(JSON.stringify(ocrResult))
  }
  
  return new Response(
    JSON.stringify({ error: 'Premium required' }),
    { status: 403 }
  )
})
```

#### When to Add Custom Node.js Backend

Consider dedicated Node.js + Express backend when:
- More than 100K active users
- Complex microservices architecture needed
- Heavy AI/ML processing (not suitable for Edge Functions)
- Need for complex caching strategies
- Multi-tenant enterprise features

**Migration Path:**
Supabase Edge Functions → Node.js services (gradual migration, keep Supabase for data)

### Database: Detailed Comparison

**Option 1: Firebase (Backend as a Service)**

**Advantages:**
- ✅ **Fastest Development** - No backend code needed
- ✅ **Real-time Sync** - Built-in live updates
- ✅ **Authentication** - Built-in auth (Google, Apple, email)
- ✅ **Free Tier** - Generous limits for MVP
- ✅ **Serverless** - Auto-scaling, no DevOps
- ✅ **Flutter Integration** - Excellent packages
- ✅ **Cloud Storage** - File hosting included
- ✅ **Security Rules** - Row-level security
- ✅ **Analytics** - Built-in Firebase Analytics

**Disadvantages:**
- ❌ **NoSQL Limitations** - Complex queries difficult
- ❌ **Vendor Lock-in** - Hard to migrate away
- ❌ **Cost at Scale** - Expensive beyond free tier
- ❌ **Limited Aggregations** - No SQL joins/aggregates
- ❌ **Data Modeling** - Requires denormalization
- ❌ **Download Charges** - Pay for data transfer

**Cost (After Free Tier):**
- 1GB storage: Free
- 10GB download/month: Free
- Beyond: $1/GB stored, $0.12/GB downloaded
- At 10K users: $100-300/month

**Best For:** MVP, rapid prototyping, real-time apps, small teams

---

**Option 2: Supabase (Open Source Firebase Alternative)**

**Advantages:**
- ✅ **PostgreSQL Backend** - Full SQL power
- ✅ **Open Source** - Self-hostable, no lock-in
- ✅ **Real-time Subscriptions** - Like Firebase
- ✅ **Built-in Auth** - Similar to Firebase Auth
- ✅ **RESTful API** - Auto-generated from schema
- ✅ **Row Level Security** - PostgreSQL RLS
- ✅ **Better Pricing** - More predictable costs
- ✅ **Storage Included** - S3-compatible storage
- ✅ **Edge Functions** - Serverless functions
- ✅ **Better Queries** - Full SQL, joins, aggregates

**Disadvantages:**
- ❌ **Newer Platform** - Less mature than Firebase (est. 2020)
- ❌ **Smaller Community** - Fewer resources/tutorials
- ❌ **Less Integrated** - More manual setup
- ❌ **Real-time Limits** - Connection limits on free tier
- ❌ **Still Developing** - Some features in beta

**Cost:**
- Free tier: 500MB database, 1GB file storage, 2GB bandwidth
- Pro ($25/month): 8GB database, 100GB storage, 250GB bandwidth
- At 10K users: $25-75/month

**Best For:** PostgreSQL benefits + rapid development, cost-conscious

---

**Option 3: PostgreSQL + Node.js Backend (Self-Built)**

**Advantages:**
- ✅ **Full Control** - Complete customization
- ✅ **Powerful SQL** - Complex queries, joins, transactions
- ✅ **ACID Compliance** - Data integrity guaranteed
- ✅ **Mature Ecosystem** - 30+ years of development
- ✅ **Scalability** - Proven at massive scale
- ✅ **No Vendor Lock-in** - Standard SQL, portable
- ✅ **Cost Effective** - Cheaper at scale
- ✅ **Advanced Features** - JSON columns, full-text search, extensions
- ✅ **Better for Complex Logic** - Stored procedures, triggers
- ✅ **Data Warehouse Ready** - Easy analytics integration

**Disadvantages:**
- ❌ **Longer Development** - Build everything yourself
- ❌ **DevOps Required** - Server management, backups
- ❌ **No Real-time** - Need to implement (Socket.io)
- ❌ **Auth Implementation** - Build from scratch
- ❌ **More Code** - API endpoints, middleware, etc.
- ❌ **Team Size** - Needs backend developers

**Cost:**
- AWS RDS: $15-50/month (small to medium instance)
- Heroku Postgres: $9-50/month
- Self-hosted (DigitalOcean): $6-40/month
- At 10K users: $25-100/month

**Best For:** Complex apps, enterprise, long-term scalability (consider after 100K users)

---

**FINAL DECISION: Supabase**

Supabase provides the perfect balance for AI-FAP:
- Rapid MVP development (launch in 3-4 months vs 6-8 months)
- Cost-effective ($0 for MVP, scales with revenue)
- SQL power for financial data (aggregations, transactions, reports)
- Real-time features built-in
- No vendor lock-in (can migrate to self-hosted PostgreSQL)
- Excellent Flutter integration

---

**COMPARISON SUMMARY**

| Factor | Firebase | Supabase | PostgreSQL + Node |
|--------|----------|----------|-------------------|
| **Development Speed** | Fastest (days) | Fast (1-2 weeks) | Slower (3-4 weeks) |
| **Database Type** | NoSQL (Firestore) | PostgreSQL (SQL) | PostgreSQL (SQL) |
| **Real-time** | ✅ Built-in | ✅ Built-in | ❌ Custom (Socket.io) |
| **Complex Queries** | ❌ Limited | ✅ Full SQL | ✅ Full SQL |
| **Transactions** | ❌ Limited | ✅ ACID | ✅ ACID |
| **Authentication** | ✅ Built-in | ✅ Built-in | ❌ Custom (Passport, JWT) |
| **File Storage** | ✅ Included | ✅ Included | ❌ Need S3/similar |
| **Vendor Lock-in** | ❌ High | ✅ Low (open source) | ✅ None |
| **Learning Curve** | Easy | Medium | Steep |
| **Flutter Packages** | Excellent | Good | Need HTTP client |
| **Cost (MVP)** | Free | Free | $10-20/month |
| **Cost (10K users)** | $100-300/month | $25-75/month | $50-100/month |
| **Cost (100K users)** | $1000-2000/month | $200-500/month | $200-400/month |
| **Scalability** | Auto-scale | Good | Excellent (manual) |
| **Data Aggregations** | ❌ Difficult | ✅ Excellent | ✅ Excellent |
| **Offline Support** | ✅ Excellent | ⚠️ Limited | ❌ Custom |
| **Security** | Good (Rules) | Excellent (RLS) | Excellent (Custom) |
| **Analytics Queries** | ❌ Poor | ✅ Excellent | ✅ Excellent |
| **Migration Path** | Difficult | Easy | N/A |
| **Community** | Huge | Growing | Massive |
| **Best For** | MVP, Real-time | SQL + Speed | Complex, Enterprise |

---

**DATABASE DECISION FOR FUNDVANCE AI:**

**RECOMMENDED: Supabase (Best of Both Worlds)**

**Why Supabase Wins:**

1. **Financial Data = Relational**
   - Expenses have categories, users, budgets (relationships)
   - Need aggregations (SUM, AVG, GROUP BY)
   - Transactions critical for financial data

2. **Development Speed**
   - 70% faster than building Node.js backend
   - Auto-generated REST API
   - Built-in auth and storage

3. **Cost-Effective**
   - Free tier covers MVP
   - Predictable pricing at scale
   - Cheaper than Firebase at 10K+ users

4. **No Lock-in**
   - Standard PostgreSQL
   - Can self-host if needed
   - Export data anytime

5. **Flutter Support**
   - Official Supabase Flutter package
   - Real-time subscriptions
   - Simple integration

**Implementation Example:**
```dart
// Initialize Supabase
final supabase = Supabase.instance.client;

// Sign up
await supabase.auth.signUp(
  email: 'user@example.com',
  password: 'password',
);

// Insert expense
await supabase.from('expenses').insert({
  'user_id': userId,
  'amount': 45.99,
  'category': 'Food',
  'date': DateTime.now().toIso8601String(),
});

// Get monthly expenses
final response = await supabase
  .from('expenses')
  .select()
  .eq('user_id', userId)
  .gte('date', startOfMonth.toIso8601String())
  .lt('date', endOfMonth.toIso8601String());

// Real-time subscription
supabase
  .from('expenses:user_id=eq.$userId')
  .on(SupabaseEventTypes.all, (payload) {
    // Update UI in real-time
  })
  .subscribe();
```

**Database Schema (Supabase/PostgreSQL):**
```sql
-- Users (handled by Supabase Auth)
-- auth.users table auto-created

-- User Profiles
CREATE TABLE profiles (
  id UUID REFERENCES auth.users PRIMARY KEY,
  full_name TEXT,
  avatar_url TEXT,
  currency TEXT DEFAULT 'USD',
  created_at TIMESTAMP DEFAULT NOW()
);

-- Expenses
CREATE TABLE expenses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  category_id UUID REFERENCES categories,
  merchant TEXT,
  description TEXT,
  date DATE NOT NULL,
  payment_method TEXT,
  receipt_url TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Categories
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users,
  name TEXT NOT NULL,
  icon TEXT,
  color TEXT,
  is_default BOOLEAN DEFAULT false
);

-- Budgets
CREATE TABLE budgets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users NOT NULL,
  category_id UUID REFERENCES categories,
  amount DECIMAL(10,2) NOT NULL,
  period TEXT NOT NULL, -- 'monthly', 'weekly'
  start_date DATE NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Row Level Security (RLS)
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can only see their own expenses" 
  ON expenses FOR SELECT 
  USING (auth.uid() = user_id);
```

**When to Consider PostgreSQL + Node.js:**
- More than 100K active users
- Need complex microservices
- Require custom real-time logic
- Building multiple products on same backend
- Team has strong DevOps capability

**Migration Path:**
Supabase → Self-hosted PostgreSQL is straightforward (standard SQL dump/restore)

#### Future Scaling Considerations

**Cache Layer: Redis** (Add at 50K+ users)
- Session management
- Rate limiting  
- Frequent queries caching
- Real-time analytics leaderboards

**Additional Services** (Add as needed):
- **Background Jobs:** Supabase pg_cron or separate Node.js workers
- **Message Queue:** AWS SQS or RabbitMQ for async processing
- **CDN:** Cloudflare for global asset delivery
- **Monitoring:** Sentry for errors, LogRocket for session replay

### AI/ML Components

#### Receipt OCR: Detailed Comparison

**Option 1: Google ML Kit (On-Device) - RECOMMENDED FOR MVP**

**Advantages:**
- ✅ **FREE** - No API costs
- ✅ **Privacy-First** - Images never leave device
- ✅ **Offline Capable** - Works without internet
- ✅ **Fast** - No network latency (<1 second)
- ✅ **Native Flutter Integration** - google_ml_kit package
- ✅ **Good Accuracy** - 85-90% for clear receipts
- ✅ **No Rate Limits** - Unlimited scans
- ✅ **Easy Setup** - Add package, configure, done

**Disadvantages:**
- ❌ Lower accuracy than cloud APIs (85% vs 95%)
- ❌ Limited to text recognition (requires custom parsing)
- ❌ Struggles with poor quality images
- ❌ Device resource usage (battery, processing)
- ❌ Model size adds to app size (~5-10MB)

**Best For:** MVP, privacy-conscious users, cost optimization

**Implementation:**
```dart
import 'package:google_ml_kit/google_ml_kit.dart';

final textRecognizer = TextRecognizer();
final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
for (TextBlock block in recognizedText.blocks) {
  final String text = block.text;
  // Parse for amount, merchant, date
}
```

---

**Option 2: Tesseract OCR (Open Source)**

**Advantages:**
- ✅ **FREE** - Open source
- ✅ **Offline** - No internet required
- ✅ **Multi-Language** - 100+ languages
- ✅ **Customizable** - Train own models
- ✅ **No Vendor Lock-in** - Self-hosted

**Disadvantages:**
- ❌ **Lower Accuracy** - 75-85% (worst of three)
- ❌ **Slower Processing** - 3-5 seconds
- ❌ **Requires Preprocessing** - Image quality critical
- ❌ **Complex Setup** - Native integration tricky
- ❌ **Large Binary Size** - Adds 10-15MB to app
- ❌ **Limited Mobile Optimization** - Designed for desktop

**Best For:** Budget projects, specific language requirements, full control needed

---

**Option 3: API-Based OCR (Google Cloud Vision / AWS Textract)**

**Advantages:**
- ✅ **Highest Accuracy** - 95-98% for receipts
- ✅ **Structured Data** - AWS Textract extracts key-value pairs
- ✅ **Advanced Features** - Logo detection, table extraction
- ✅ **Continuous Improvement** - Google/AWS maintains models
- ✅ **No App Size Impact** - Processing in cloud
- ✅ **Handles Complex Receipts** - Better with damaged/faded receipts
- ✅ **Multiple Languages** - Auto-detection

**Disadvantages:**
- ❌ **Cost Per Request** - $1.50 per 1,000 images (Cloud Vision)
- ❌ **Internet Required** - Must be online
- ❌ **Privacy Concerns** - Images sent to cloud
- ❌ **Latency** - 2-4 seconds (network + processing)
- ❌ **Rate Limits** - Can be throttled
- ❌ **Vendor Lock-in** - Difficult to switch

**Cost Analysis (10,000 receipts/month):**
- Google Cloud Vision: $15/month
- AWS Textract: $15-25/month
- Azure Computer Vision: $10/month (first 5K free)

**Best For:** Premium features, high accuracy requirements, scaling

---

**RECOMMENDED APPROACH: Hybrid Strategy**

**Phase 1 (MVP - Months 1-6):**
- Use **Google ML Kit** for all users
- Free tier users: 10 scans/month
- Premium users: Unlimited scans
- Cost: $0

**Phase 2 (Growth - Months 6-12):**
- Free tier: Google ML Kit (10 scans/month)
- Premium tier: **API-based OCR** (unlimited)
- Cost: Predictable scaling with revenue

**Phase 3 (Scale - Year 2+):**
- Free: ML Kit (10 scans)
- Premium: API OCR or **Custom ML Model** (trained on receipt data)
- Consider AWS Textract for complex receipts

**Implementation Strategy:**
```dart
Future<ReceiptData> scanReceipt(File image, bool isPremium) async {
  if (isPremium) {
    // Use Cloud API for better accuracy
    return await cloudOCR(image);
  } else {
    // Use on-device ML Kit
    return await mlKitOCR(image);
  }
}
```

**Comparison Table:**

| Feature | Google ML Kit | Tesseract | API-Based OCR |
|---------|---------------|-----------|---------------|
| **Cost** | Free | Free | ~$15/10K scans |
| **Accuracy** | 85-90% | 75-85% | 95-98% |
| **Speed** | < 1 sec | 3-5 sec | 2-4 sec |
| **Offline** | ✅ Yes | ✅ Yes | ❌ No |
| **Privacy** | ✅ On-device | ✅ On-device | ❌ Cloud |
| **App Size** | +5-10MB | +10-15MB | No impact |
| **Setup Difficulty** | Easy | Medium | Easy |
| **Flutter Support** | Excellent | Poor | Excellent |
| **Maintenance** | Google maintains | Community | Provider maintains |
| **Structured Data** | No | No | Yes (Textract) |
| **Best For** | MVP, Free tier | Full control | Premium, Production |

**FINAL DECISION: Google ML Kit for MVP, Hybrid for Scale**

---

#### Categorization Engine (AI-Powered)

**Deployed as Supabase Edge Function**
**Approach:** Supervised Machine Learning

**Model:** 
- Text classification: BERT-based model / FastText
- Training data: Merchant names + historical user data
- Confidence scoring

**Features:**
- Merchant name
- Transaction amount
- Day of week
- Time of day
- User's historical patterns

#### Insights Engine
**Technology:** Rule-based AI + Statistical Analysis

**Components:**
1. **Pattern Detection** - Time series analysis
2. **Anomaly Detection** - Z-score / IQR methods
3. **Comparison Engine** - Historical comparisons
4. **NLG (Natural Language Generation)** - Convert data to readable insights

**Libraries:**
- TensorFlow / PyTorch for ML models
- Pandas/NumPy for data processing
- Scikit-learn for statistical models

#### Budget Prediction
**Model:** Time Series Forecasting (ARIMA / Prophet)

**Inputs:**
- Historical spending
- Income patterns  
- Seasonal trends
- User-defined constraints

---

## Infrastructure

### Cloud Provider: Supabase (Hosted on AWS)

**Supabase Infrastructure** (Managed for us):
- **Compute:** Auto-managed, auto-scaling
- **Database:** PostgreSQL 15 (AWS RDS behind the scenes)
- **Storage:** S3-compatible (for receipt images)
- **CDN:** Global edge network
- **Regions:** Multiple options (US, EU, Asia)

**Additional Services (As Needed):**

#### For AI/ML (Premium Features)
- **Google Cloud Vision API** - High-accuracy OCR for premium users
- **Cost:** $1.50 per 1,000 requests
- **Usage:** Only for premium receipt scans

#### For Monitoring & Analytics
- **Sentry** - Error tracking and monitoring
- **Mixpanel / Amplitude** - User analytics and funnels
- **Supabase Dashboard** - Built-in metrics and logs

#### For Notifications
- **OneSignal** - Push notifications
- **SendGrid / Mailgun** - Email delivery (weekly reports)
- **Twilio** - SMS for alerts (optional)

### DevOps & Development

#### Version Control
- **Git:** GitHub or GitLab
- **Branching:** GitFlow (main, develop, feature branches)
- **Code Review:** Required before merge

#### CI/CD Pipeline

**Flutter App:**
- **iOS:** Codemagic or Bitrise (automated TestFlight builds)
- **Android:** GitHub Actions (automated Play Store builds)
- **Testing:** Automated unit tests on every PR
- **Code Analysis:** flutter analyze, dart format

**Edge Functions:**
- **Deployment:** Supabase CLI (automatic on git push)
- **Testing:** Deno test
- **Monitoring:** Supabase Dashboard logs

#### Testing Strategy

**Mobile (Flutter):**
- **Unit Tests:** For business logic (`flutter test`)
- **Widget Tests:** For UI components
- **Integration Tests:** For user flows
- **Target Coverage:** 70%+

**Backend (Supabase):**
- **Database Tests:** Test RLS policies and functions
- **Edge Function Tests:** Deno test framework
- **API Tests:** Postman collections for manual testing

#### Monitoring & Logging
- **Mobile Errors:** Sentry for crash reporting
- **Backend Errors:** Supabase logs + Sentry
- **Performance:** Firebase Performance Monitoring
- **Analytics:** Mixpanel for user behavior
- **Database:** Supabase Dashboard (query performance, usage)

---

## Security Architecture

### Authentication & Authorization

**Supabase Auth (Built-in):**
- **JWT Tokens:** Automatic token management
- **OAuth 2.0:** Google, Apple, Facebook sign-in
- **Email/Password:** Traditional authentication
- **Magic Links:** Passwordless login option
- **Session Management:** Automatic refresh tokens
- **MFA:** Optional two-factor authentication (can enable)

**Mobile App:**
- **Biometric:** Face ID / Touch ID / Fingerprint
- **Secure Storage:** flutter_secure_storage for sensitive data
- **Auto-logout:** After inactivity period

### Data Security

**Supabase (Automatic):**
- **Encryption at Rest:** AES-256 (PostgreSQL)
- **Encryption in Transit:** TLS 1.3
- **Row Level Security (RLS):** User can only see their own data
- **Database Encryption:** Managed by Supabase/AWS

**Mobile App:**
- **Local Storage:** Encrypted with Supabase local cache
- **Sensitive Data:** Never logged or exposed
- **Receipt Images:** Encrypted in Supabase Storage

**RLS Policy Example:**
```sql
-- Users can only see their own expenses
CREATE POLICY "Users view own expenses"
ON expenses FOR SELECT
USING (auth.uid() = user_id);

-- Users can only insert their own expenses
CREATE POLICY "Users insert own expenses"
ON expenses FOR INSERT
WITH CHECK (auth.uid() = user_id);
```

### API Security

**Supabase (Built-in):**
- **Rate Limiting:** Automatic per-user limits
- **CORS:** Configurable origin policies
- **API Keys:** Separate anon/service keys
- **RLS:** Database-level security
- **Input Validation:** PostgreSQL constraints + app-level validation

**Edge Functions:**
- **Authentication:** JWT verification required
- **Input Validation:** Zod schemas for TypeScript
- **Error Handling:** No sensitive data in error messages
- **Rate Limiting:** Built-in per Supabase

**Mobile App:**
- **API Key Security:** Anon key safe for client (RLS protects data)
- **Input Sanitization:** Validate all user inputs
- **SQL Injection:** Impossible with Supabase (parameterized queries)
- **XSS Prevention:** Flutter renders safely by default

### Banking Integration Security (Future Feature)

**Third-party Service:** Plaid or Yodlee
- **Compliance:** SOC 2, PCI DSS certified
- **Access:** Read-only (no fund transfers)
- **Token Storage:** Encrypted in Supabase
- **Audit Logs:** All access logged in PostgreSQL
- **User Control:** Easy disconnect option

### Privacy & Compliance

**GDPR Compliance:**
- **Right to Access:** Export all user data (Supabase API)
- **Right to Deletion:** Delete account + all data
- **Data Portability:** CSV/JSON export
- **Consent:** Clear privacy policy and opt-ins
- **Data Minimization:** Only collect necessary data

**Privacy-First Design:**
- Receipt images: Optional, can use ML Kit without cloud upload
- Financial data: Never shared or sold
- Analytics: Anonymized aggregate data only
- Marketing: Opt-in only

**Data Retention:**
- Active users: Unlimited storage
- Inactive (1 year): Notify before deletion
- Deleted accounts: 30-day recovery period, then permanent deletion

### Security Best Practices

**Development:**
- No hardcoded secrets (use environment variables)
- Dependency scanning (Dependabot)
- Security audits before major releases
- Bug bounty program (post-launch)

**Monitoring:**
- Failed login attempts tracking
- Unusual expense patterns (fraud detection)
- API abuse detection
- Security incident response plan

---

## Data Flow

### Expense Creation Flow (Manual Entry)

```
1. User fills expense form in Flutter app
   ↓
2. Client-side validation (amount, category, date)
   ↓
3. Call Supabase API: supabase.from('expenses').insert()
   ↓
4. Supabase verifies JWT token
   ↓
5. RLS checks: user_id matches auth.uid()
   ↓
6. Insert to PostgreSQL expenses table
   ↓
7. Trigger categorization Edge Function (if merchant provided)
   ↓
8. Real-time subscription notifies app
   ↓
9. Update local cache
   ↓
10. Refresh UI with new expense
```

### Receipt Scanning Flow (Phase 2 — Implemented)

```
1. User taps scan icon in ExpenseFormScreen
   ↓
2. image_picker → camera or gallery selection
   ↓
3. ReceiptService.scanFromCamera() / scanFromGallery()
   ↓
4. Google ML Kit TextRecognizer.processImage() (on-device, offline)
   ↓
5. _parseText() runs regex pipelines:
   - _extractTotal()    → priority keywords first, largest-amount fallback
   - _extractDate()     → 4 regex date format patterns
   - _extractMerchant() → first non-numeric, non-special text line
   - _extractItems()    → "text $price" pattern matches
   ↓
6. AutoCategorizationService.suggestFromMerchant()
   → keyword map lookup across 9 categories
   ↓
7. ReceiptScanResult returned (confidence 0.0–1.0)
   ↓
8. User reviews ReceiptReviewScreen → edit any field
   ↓
9. Confirmed → expense inserted to Supabase
   ↓
10. UI refreshed
```

**Phase 4 Plan:** Premium users → Google Cloud Vision API for higher accuracy (95–98% vs 85–90%)

### AI Insights Generation Flow (Phase 2 — Implemented)

```
1. User navigates to Analytics Dashboard or Notifications
   ↓
2. SmartInsightsService.generateInsights(expenses, budgets, categories)
   called on-device (zero network calls)
   ↓
3. Heuristic engine runs 5 analysis passes:
   - _budgetAlerts()     → budget ≥ 80% warnings
   - _anomalyInsights()  → category > 150% of 3-month avg
   - _trendInsights()    → month-over-month changes > 20%
   - _recurringInsights() → gap analysis (weekly/bi-weekly/monthly)
   - _milestoneInsights() → categories where spend improved
   ↓
4. Returns List<SpendingInsight> sorted by severity
   ↓
5a. SmartInsightsScreen → renders tabbed insight + recurring views
5b. NotificationProvider.refreshAlerts() → converts insights to
    List<AppNotification> (bell badge updates)
5c. SpendingDigestService.generateMonthlyDigest() → NLG 5-6 lines
    shown in SpendingDigestCard on Home screen
```

**Phase 3 Plan:** Move heavy pattern analysis to Supabase Edge Function
for server-side processing + push notifications via OneSignal.

### Real-time Budget Update Flow

```
1. User adds new expense
   ↓
2. Expense inserted to database
   ↓
3. PostgreSQL trigger fires
   ↓
4. Recalculate budget_spent for affected category
   ↓
5. Update budgets table
   ↓
6. Supabase Realtime broadcasts change
   ↓
7. Flutter app receives WebSocket message
   ↓
8. Update budget progress bar in UI (smooth animation)
   ↓
9. IF budget exceeded:
     → Show alert dialog
     → Generate insight about overspending
```

---

## Scalability Considerations

### Horizontal Scaling (Automatic with Supabase)
- **Database:** Supabase handles connection pooling
- **API:** Auto-scales based on load
- **Storage:** Unlimited (pay per GB)
- **Edge Functions:** Auto-scale per request

### Manual Scaling (When Needed)
- **Database Read Replicas:** At 100K+ users (upgrade Supabase plan)
- **Redis Cache:** Add when query performance degrades
- **Custom Backend:** Offload heavy AI processing to dedicated servers

### Caching Strategy

**Client-side (Flutter):**
- **Supabase Local Cache:** Automatic offline-first caching
- **Image Cache:** `cached_network_image` for avatars/receipts
- **Query Cache:** Recent expenses cached for 5 minutes

**Server-side (Future):**
- **Redis:** For expensive queries (monthly summaries, category totals)
- **CDN:** Cloudflare for static assets and images

### Performance Optimization
- **Lazy Loading:** Load data on demand
- **Pagination:** Limit query results
- **Image Compression:** Optimize receipt photos
- **Background Jobs:** Async processing for AI tasks
- **Database Indexing:** Optimize common queries

---

## Offline Capabilities

### Offline-First with Supabase

**What Works Offline:**
- View all cached expenses (last 30 days synced)
- Add new expenses (queued for sync)
- Edit existing expenses
- View cached insights and charts
- Scan receipts with ML Kit (on-device)

**Automatic Sync When Online:**
- Pending expenses uploaded
- Latest data fetched
- Conflicts resolved (last-write-wins)
- Real-time subscriptions reconnect

**Implementation:**
```dart
// Supabase handles offline automatically
final response = await supabase
  .from('expenses')
  .insert(expense)
  .select(); // Will queue if offline, sync when online
```

### Sync Strategy
- **Auto Sync:** Immediate when connection restored
- **Background Sync:** Periodic check every 5 minutes
- **Manual Sync:** Pull-to-refresh gesture
- **Real-time:** WebSocket for live updates when online
- **Conflict Handling:** Server wins, notify user of changes

---

## API Design

### Supabase Auto-Generated REST API

Supabase automatically generates REST endpoints from database tables:

#### Expenses
```
GET    /rest/v1/expenses?user_id=eq.{id}&order=date.desc
POST   /rest/v1/expenses
PATCH  /rest/v1/expenses?id=eq.{id}
DELETE /rest/v1/expenses?id=eq.{id}
```

#### Categories
```
GET    /rest/v1/categories?user_id=eq.{id}
POST   /rest/v1/categories
```

#### Budgets
```
GET    /rest/v1/budgets?user_id=eq.{id}
POST   /rest/v1/budgets
```

### Custom Edge Functions

#### AI & Premium Features
```
POST   /functions/v1/analyze-receipt
POST   /functions/v1/categorize-expense
POST   /functions/v1/generate-insights
POST   /functions/v1/calculate-budget
POST   /functions/v1/detect-subscriptions
```

### Flutter SDK Usage
```dart
// Querying expenses
final response = await supabase
  .from('expenses')
  .select('*, categories(*)')
  .eq('user_id', userId)
  .gte('date', startDate)
  .order('date', ascending: false);

// Inserting expense
await supabase.from('expenses').insert({
  'user_id': userId,
  'amount': 45.99,
  'category_id': categoryId,
  'merchant': 'Starbucks',
  'date': DateTime.now().toIso8601String(),
});

// Calling Edge Function
final result = await supabase.functions.invoke(
  'analyze-receipt',
  body: {'imageUrl': url, 'isPremium': true},
);

// Real-time subscription
supabase
  .from('expenses:user_id=eq.$userId')
  .stream(primaryKey: ['id'])
  .listen((data) {
    // Update UI with new/changed expenses
  });
```

---

## Development Phases

### Phase 1: Foundation ✅ COMPLETED (Jan 2026)
- Supabase project setup (13 migrations)
- Database schema: profiles, categories, expenses, budgets, accounts, income, transfers, taxes
- Flutter project initialization (Material Design 3, Provider state management)
- Email/password authentication with Supabase Auth (PKCE flow)
- UI component library — navigation drawer, bottom nav, home screen
- Account management system (7 categories, 12 predefined types, balance triggers)
- Category management with icons and colours
- Expense CRUD with form validation
- Budget management with progress indicators
- Analytics dashboard with fl_chart charts
- Transfer system, Tax system, Income tracking

### Phase 2: AI Features ✅ COMPLETED (Feb 2026)
- On-device receipt scanner (Google ML Kit OCR, `image_picker`)
- Auto-categorization service (keyword maps, 9 categories)
- Smart Insights engine (on-device heuristics — budget alerts, anomaly, trend, recurring, milestone)
- Recurring expense detection algorithm (weekly / bi-weekly / monthly gap analysis)
- Spending Digest (template-based NLG monthly summary)
- Notification Centre (in-app alerts, read/dismiss/badge)
- Analytics dashboard integration (SmartInsightsBanner + SmartInsightsScreen)

### Phase 3: Advanced AI & Intelligence 🚀 NEXT
- Budget suggestions AI (50/30/20 rule, income-based allocation)
- Smart categorization ML model (on-device FastText / TFLite)
- User correction feedback loop → adaptive learning
- Savings goals planner
- Advanced anomaly detection improvements
- Subscription detection

### Phase 4: Premium Features (Months 7-8)
- Premium OCR (Cloud Vision API for paid users)
- Goal planner UI
- Debt management tools
- Weekly reports via email (SendGrid)
- RevenueCat premium subscription

### Phase 5: Polish & Launch (Months 9-10)
- Beta testing (100 users)
- Premium subscription (RevenueCat)
- Performance optimization
- Security audit
- App store submission

**Total Development Time: 10 months** (faster than traditional backend: 12-14 months)

---

## Cost Breakdown (Monthly)

### MVP Phase (0-1,000 users)
| Service | Cost | Notes |
|---------|------|-------|
| Supabase | $0 | Free tier: 500MB DB, 1GB storage, 2GB bandwidth |
| Google ML Kit | $0 | On-device processing |
| Sentry | $0 | Free tier: 5K errors/month |
| OneSignal | $0 | Free tier: Unlimited notifications |
| Domain & SSL | $15 | Domain registration |
| **Total** | **$15/month** | |

### Growth Phase (1K-10K users)
| Service | Cost | Notes |
|---------|------|-------|
| Supabase Pro | $25 | 8GB DB, 100GB storage, 250GB bandwidth |
| Cloud Vision API | $50 | ~3,000 premium scans/month |
| Sentry | $26 | Team plan |
| OneSignal | $0 | Still free |
| SendGrid | $15 | Email delivery for reports |
| Monitoring | $20 | Mixpanel Starter |
| **Total** | **$136/month** | |

### Scale Phase (10K-100K users)
| Service | Cost | Notes |
|---------|------|-------|
| Supabase Team | $100 | Upgrading for performance |
| Cloud Vision API | $300 | ~20,000 premium scans/month |
| Sentry | $80 | Business plan |
| SendGrid | $90 | Essentials plan |
| Monitoring | $100 | Mixpanel Growth |
| CDN (Cloudflare) | $20 | Pro plan |
| Redis Cache | $50 | For heavy queries |
| **Total** | **$740/month** | |

**Cost Per User:**
- MVP: $0.015/user/month
- Growth: $0.014/user/month
- Scale: $0.007/user/month

**Cost decreases as we scale** - excellent economics!

---

## Technology Stack Summary

### Frontend (Mobile)
```yaml
Framework: Flutter 3.19+
Language: Dart 3.3+
State Management: Provider
HTTP Client: Dio
Database Client: supabase_flutter
OCR: google_mlkit_text_recognition (^0.13.0, on-device)
Camera/Gallery: image_picker (^1.1.2)
Charts: fl_chart (^0.70.1)
Navigation: go_router
Storage: flutter_secure_storage
Localization: intl (^0.20.2)
Error Tracking: sentry_flutter
```

### Backend (Supabase)
```yaml
Database: PostgreSQL 15
API: Auto-generated REST (PostgREST)
Real-time: Supabase Realtime (WebSocket)
Authentication: Supabase Auth (JWT + OAuth)
Storage: Supabase Storage (S3-compatible)
Functions: Supabase Edge Functions (Deno/TypeScript)
```

### External Services
```yaml
OCR (Premium): Google Cloud Vision API
Push Notifications: OneSignal
Email: SendGrid / Mailgun
Analytics: Mixpanel / Amplitude
Error Tracking: Sentry
CDN: Cloudflare (future)
Payments: RevenueCat + Stripe
```

### Development Tools
```yaml
Version Control: Git + GitHub
CI/CD: GitHub Actions + Codemagic
Testing: flutter_test, mockito, integration_test
Code Quality: flutter_lints, dart analyze
Design: Figma
Project Management: Linear / Jira
Documentation: Notion / Confluence
```

---

## Quick Start Commands

### Flutter Setup
```bash
# Install Flutter
flutter doctor

# Create project
flutter create ai_fap

# Add dependencies
flutter pub add supabase_flutter provider dio google_ml_kit fl_chart

# Run app
flutter run
```

### Supabase Setup
```bash
# Install Supabase CLI
npm install -g supabase

# Initialize project
supabase init

# Start local development
supabase start

# Create migration
supabase migration new create_expenses_table

# Push to production
supabase db push
```

### Deploy Edge Function
```bash
# Create function
supabase functions new analyze-receipt

# Deploy function
supabase functions deploy analyze-receipt

# Test function
supabase functions invoke analyze-receipt --body '{"imageUrl": "..."}'
```

---

## Key Documentation Links

- [Flutter Docs](https://docs.flutter.dev/)
- [Supabase Docs](https://supabase.com/docs)
- [Supabase Flutter Package](https://pub.dev/packages/supabase_flutter)
- [Google ML Kit](https://developers.google.com/ml-kit)
- [Provider State Management](https://pub.dev/packages/provider)
- [Cloud Vision API](https://cloud.google.com/vision/docs)
- [fl_chart Examples](https://pub.dev/packages/fl_chart)

---

## Next Steps

1. ✅ Review and approve technical architecture
2. ☐ Set up development environment
3. ☐ Create Supabase project
4. ☐ Design database schema
5. ☐ Initialize Flutter project
6. ☐ Set up CI/CD pipeline
7. ☐ Begin Phase 1 development

**Estimated Start Date:** March 2026  
**Estimated Launch Date:** January 2027

---

## Testing Strategy

### Flutter App Testing

**Unit Tests** (70% coverage target)
- Business logic and calculations
- Data models and serialization
- Utility functions
- State management logic

**Widget Tests**
- UI components render correctly
- User interactions work
- Form validation
- Navigation flows

**Integration Tests**
- Complete user journeys (signup → add expense → view insights)
- Receipt scanning flow
- Offline → online sync
- Real-time updates

**Tools:**
- `flutter_test` for unit and widget tests
- `integration_test` for E2E tests
- `mockito` for mocking dependencies
- `golden_toolkit` for visual regression tests

### Backend Testing

**Database Tests**
- Row Level Security (RLS) policies work correctly
- Only users can access their own data
- Triggers and functions execute properly
- Foreign key constraints

**Edge Function Tests**
- Unit tests with Deno test framework
- Mock external API calls (Cloud Vision)
- Test error handling
- Validate input/output schemas

**Manual API Tests**
- Postman collections for all endpoints
- Test authentication flows
- Verify real-time subscriptions

### AI/ML Testing

**OCR Accuracy**
- Test with 100+ diverse receipt samples
- Measure character error rate
- Compare ML Kit vs Cloud Vision accuracy
- Test edge cases (crumpled, faded, multilingual)

**Categorization Testing**
- Accuracy metrics (precision, recall, F1 score)
- Test with common merchants
- Verify learning from user corrections
- Benchmark against rule-based baseline

**Target: 85%+ categorization accuracy**

### Security Testing

**Pre-Launch:**
- RLS policy verification (automated tests)
- Input validation testing (SQL injection attempts)
- Authentication flow testing
- Token expiration and refresh

**Post-Launch:**
- Penetration testing (hire security firm)
- Bug bounty program
- Regular dependency audits (Dependabot)
- OWASP Mobile Top 10 checklist
---

## Current Implementation Status (As of Feb 2026 — Phase 2 Complete)

### Backend Infrastructure ✅

**Supabase Database:**
- ✅ 13 sequential migrations fully deployed
- ✅ PostgreSQL 15 with Row Level Security (RLS) on all tables
- ✅ 12+ tables: profiles, categories, expenses, budgets, accounts, account_types, income, income_categories, transfers, transfer_categories, taxes, tax_presets
- ✅ 20+ optimized indexes for performance
- ✅ 25+ RLS policies for data security
- ✅ 6 database triggers (auto-profile, auto-account, smart currency, expense balance updates)
- ✅ Soft delete system with deleted_at timestamps
- ✅ Comprehensive seeder data (21 categories, 12 account types, 18 tax presets)
- ✅ Automatic account balance updates via triggers (insert/update/delete)

**Account Management System:**
- ✅ 7 account categories (Bank, E-Wallet, Online Bank, Credit, Cash, Crypto, Investment)
- ✅ 12 predefined account types auto-created on user signup
- ✅ Category-based account organization
- ✅ Dynamic currency system (profile default with smart account updates)
- ✅ Balance tracking with automatic updates via database triggers
- ✅ Include/exclude accounts from net worth calculation
- ✅ Toggle account active/inactive status
- ✅ Account type differentiation with unique icons and colors (15+ types supported)
- ✅ Tappable account cards with navigation to details
- ✅ Edit/update account functionality with balance adjustments
- ✅ Multi-currency account summaries
- ☐ **TODO:** Per-account currency override in add account dialog
- ☐ **TODO:** Account soft-delete and restore

**Authentication & User Management:**
- ✅ Supabase Auth with PKCE flow
- ✅ Email/password authentication
- ✅ Auto-profile creation trigger
- ✅ Profile INSERT policy for signup fix
- ✅ Currency preferences per user
- ✅ Signout with proper navigation and state management

### Flutter Mobile App ✅

**Core Features Implemented:**
- ✅ Material Design 3 UI with modern card layouts
- ✅ Provider pattern for state management
- ✅ Comprehensive navigation with drawer menu
- ✅ Expense CRUD with category and account tracking
- ✅ Income tracking with categories
- ✅ Budget management with income consideration
- ✅ Account management with category grouping
- ✅ Analytics dashboard with visualizations
- ✅ Soft delete with trash and restore
- ✅ Category management (view, filter by type)
- ✅ Currency selection (30+ currencies)
- ✅ Error handling with user feedback
- ✅ Complete dashboard redesign with modern UI
- ✅ Multi-currency support across all features
- ✅ IconHelper utility for consistent icon rendering
- ✅ HomeProvider for dashboard state management
- ✅ DashboardService for centralized data fetching

**Enhanced UI Components:**
- ✅ **Expense Form:**
  - Colorful prefix icons (purple, teal, amber, blue, green, orange)
  - Auto-payment method selection based on account type
  - Category dropdown with Material Icons (IconHelper)
  - Dynamic currency from selected account
  - Account dropdown with balance display
  - 12px spacing, 14px/12px text sizing for compact design
  - Full validation and error handling
  - Delete with confirmation and undo support

- ✅ **Expense List:**
  - Modern card layout with category icons
  - Category name and date badges
  - Account and payment method display
  - Swipe-to-delete with confirmation
  - Multi-currency expense totals
  - PopupMenu for edit/delete actions
  - Enhanced visual hierarchy with shadows

- ✅ **Budget Screens:**
  - Redesigned form with colorful icons (purple, amber, blue, green, orange)
  - Modern card layout with 12px spacing
  - Category icons rendered as Material Icons (not raw text)
  - Progress bars (6px height) with subtle styling
  - Status badges with light backgrounds
  - Period selection with proper validation
  - Custom date range support

- ✅ **Dashboard (HomePage):**
  - Welcome section with time-based greeting
  - Financial summary with multi-currency totals
  - Quick actions (Add Expense/Income/Transfer) with ripple effects
  - Account balances with gradient card design
  - Tappable account cards navigating to details
  - Account type-specific icons and colors
  - Recent Activity showing merchant names
  - Category icons with proper colors
  - Pull-to-refresh for data sync
  - Auto-refresh on app resume
  - Empty states for each section
  - FinancialHealthCard widget (UI ready)
  - IncomeExpensesChart widget (UI ready)

**Account UI Components:**
- ✅ Accounts screen with category grouping
- ✅ Add account dialog with category selection
- ✅ Account type auto-selection based on category
- ✅ Balance display by account
- ✅ Account status toggle (active/inactive)
- ✅ Include in total toggle
- ✅ Account type differentiation with icons/colors
- ✅ Tappable cards with navigation to details
- ✅ Edit account dialog with full functionality
- ☐ **TODO:** Currency dropdown per account in add/edit forms
- ☐ **TODO:** Account deletion confirmation

**Services & Data Layer:**
- ✅ AccountService with category joins
- ✅ Account model with accountTypeCategory field
- ✅ AccountProvider with state management
- ✅ Account balance calculations
- ✅ Total balance aggregation by currency
- ✅ RLS-compliant queries
- ✅ DashboardService for financial summaries
- ✅ ExpenseService with enhanced joins (categories, accounts)
- ✅ Multi-currency grouping and calculations
- ✅ Enhanced expense model with display fields (currency, categoryName, etc.)

**Utilities & Helpers:**
- ✅ IconHelper: Map icon names to Material IconData
- ✅ IconHelper: hexToColor() for category colors
- ✅ IconHelper: getIcon() widget helper
- ✅ Expense.displayName getter (merchant > description > category)

**Widget Library:**
- ✅ FinancialHealthCard: Score display with insights
- ✅ IncomeExpensesChart: Bar chart for last 6 months
- ✅ AppNavigationDrawer: Comprehensive menu
- ✅ Custom form fields with icon prefixes

### AI Features (Phase 2) ✅

**Receipt Scanner:**
- ✅ `google_mlkit_text_recognition ^0.13.0` — on-device OCR (no cloud, no cost)
- ✅ `image_picker ^1.1.2` — camera + gallery
- ✅ `ReceiptScanResult` model (amount, date, merchant, items, confidence 0–1)
- ✅ `ReceiptService` — OCR + regex parsing pipeline
- ✅ Android permissions: CAMERA, READ_EXTERNAL_STORAGE (maxSdk 32), READ_MEDIA_IMAGES
- ✅ iOS: NSCameraUsageDescription + NSPhotoLibraryUsageDescription
- ✅ `ReceiptReviewScreen` — edit all fields before saving
- ✅ `ExpenseFormScreen` — scan icon wired in

**Auto-Categorization:**
- ✅ `AutoCategorizationService` — keyword maps for 9 categories
- ✅ `suggestFromMerchant()` + `suggestFromItems()` + `findCategoryId()`
- ✅ Pre-selects category on `ReceiptReviewScreen`

**Smart Insights Engine:**
- ✅ `SpendingInsight` model — 5 `InsightType` values × 4 `InsightSeverity` levels
- ✅ `SmartInsightsService` — on-device heuristic engine
  - `_budgetAlerts()` — budget ≥ 80% / exceeded
  - `_anomalyInsights()` — category spend > 150% of 3-month average
  - `_trendInsights()` — month-over-month comparison > 20%
  - `_findRecurring()` — gap analysis → weekly/bi-weekly/monthly
  - `_milestoneInsights()` — improved categories
- ✅ `SmartInsightsScreen` — tabbed UI (Insights + Recurring)
- ✅ `_SmartInsightsBanner` on Analytics Dashboard
- ✅ Navigation drawer entry

**Spending Digest:**
- ✅ `SpendingDigestService.generateMonthlyDigest()` — template-based NLG (5–6 sentences)
- ✅ `SpendingDigest` model, `DigestLine`, `DigestLineType` (5 values)
- ✅ `SpendingDigestCard` — collapsible on Home screen, lazy-loaded

**Notification Centre:**
- ✅ `AppNotification` model — 6 `NotificationType` values, 4 severity levels
- ✅ `NotificationProvider` — in-memory store (read/dismiss/clearAll/markAllRead)
- ✅ `NotificationsScreen` — swipe-to-dismiss tiles, unread dot
- ✅ Bell icon with red-dot badge on Home app bar
- ✅ Navigation drawer Notifications entry with `Badge` widget
- ✅ `NotificationProvider` registered in `MultiProvider` in `main.dart`

### Migration Timeline

| Migration | Description | Status |
|-----------|-------------|--------|
| 001 | UUID extension (gen_random_uuid) | ✅ Applied |
| 002 | Profiles with auto-creation + INSERT policy | ✅ Applied |
| 003 | Categories (expense, income, both) | ✅ Applied |
| 004 | Expenses with soft delete | ✅ Applied |
| 005 | Budgets with period constraints | ✅ Applied |
| 006 | Income system | ✅ Applied |
| 007 | Account system (e_wallet category) | ✅ Applied |
| 008 | Transfer system | ✅ Applied |
| 009 | Tax system (PH/USA/WLD presets) | ✅ Applied |
| 010 | Enhanced categories | ✅ Applied |
| 011 | Add account_id to expenses | ✅ Applied |
| 012 | Auto-create accounts + currency triggers | ✅ Applied |
| 013 | Expense account balance triggers | ✅ Applied |

### Next Development Priorities (Phase 3)

**Budget Intelligence:**
1. ☐ 50/30/20 rule budget suggestion engine
2. ☐ Income-based budget auto-allocation
3. ☐ Budget prediction from historical averages
4. ☐ Dynamic budget adjustment recommendations

**Savings Goals:**
1. ☐ Goal creation UI (type: savings, debt, purchase)
2. ☐ Timeline calculator (months to reach goal)
3. ☐ Progress tracking with milestone celebrations
4. ☐ AI-powered savings recommendations

**Categorization Improvements:**
1. ☐ On-device FastText / TFLite classification model
2. ☐ User correction feedback loop
3. ☐ Adaptive learning from manual overrides

**Account & Transaction Enhancements:**
1. ☐ Currency dropdown per account in add/edit forms
2. ☐ Account soft-delete and restore
3. ☐ Transaction search and advanced filters
4. ☐ Recurring transaction templates
5. ☐ Data export (CSV, PDF)