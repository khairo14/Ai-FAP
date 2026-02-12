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

### Receipt Scanning Flow

```
1. User takes photo with Flutter camera
   ↓
2. Preprocess image (crop, enhance)
   ↓
3. IF Free User:
     → Google ML Kit OCR (on-device)
     → Parse text for amount, merchant, date
   ELSE IF Premium User:
     → Upload image to Supabase Storage
     → Call Edge Function: analyze-receipt
     → Edge Function calls Google Cloud Vision API
     → Return structured data
   ↓
4. Show extracted data to user for review
   ↓
5. User confirms/edits
   ↓
6. Insert expense to Supabase
   ↓
7. Categorization AI runs
   ↓
8. Save final expense with category
   ↓
9. Update UI
```

### AI Insights Generation Flow

```
1. Scheduled Job (Supabase pg_cron - daily at 8 AM)
   ↓
2. Trigger Edge Function: generate-insights
   ↓
3. Query user expenses (last 30 days)
   ↓
4. Run analysis algorithms:
   - Category spending breakdown
   - Week-over-week comparison
   - Anomaly detection
   - Budget adherence check
   - Savings opportunities
   ↓
5. Generate natural language insights
   ↓
6. Store insights in 'insights' table
   ↓
7. IF significant insight (budget exceeded, big savings):
     → Send push notification (OneSignal)
   ↓
8. Real-time subscription updates app dashboard
   ↓
9. User sees new insights on next app open
```

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

### Phase 1: Foundation (Months 1-2)
- Supabase project setup
- Database schema design and RLS policies
- Flutter project initialization
- Basic authentication (email/password)
- UI component library

### Phase 2: Core Features (Months 3-4)
- Manual expense CRUD
- Category management
- Receipt scanning with ML Kit
- Basic charts and visualizations
- Monthly summaries

### Phase 3: AI Features (Months 5-6)
- Smart categorization (Edge Function)
- Insights generation algorithm
- Budget suggestions AI
- Pattern detection
- Real-time budget tracking

### Phase 4: Premium Features (Months 7-8)
- Premium OCR (Cloud Vision API)
- Goal planner
- Debt management tools
- Subscription detection
- Weekly reports via email

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
State Management: Provider / Riverpod
HTTP Client: Dio
Database Client: supabase_flutter
OCR: google_ml_kit
Charts: fl_chart
Navigation: go_router
Camera: image_picker
Storage: flutter_secure_storage
Analytics: mixpanel_flutter
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

## Current Implementation Status (As of Feb 12, 2026)

### Backend Infrastructure ✅

**Supabase Database:**
- ✅ 12 sequential migrations fully deployed
- ✅ PostgreSQL 15 with Row Level Security (RLS) on all tables
- ✅ 12+ tables: profiles, categories, expenses, budgets, accounts, account_types, income, income_categories, transfers, transfer_categories, taxes, tax_presets
- ✅ 20+ optimized indexes for performance
- ✅ 25+ RLS policies for data security
- ✅ 3 database triggers (auto-profile creation, auto-account creation, smart currency updates)
- ✅ Soft delete system with deleted_at timestamps
- ✅ Comprehensive seeder data (21 categories, 12 account types, 18 tax presets)

**Account Management System:**
- ✅ 7 account categories (Bank, E-Wallet, Online Bank, Credit, Cash, Crypto, Investment)
- ✅ 12 predefined account types auto-created on user signup
- ✅ Category-based account organization
- ✅ Dynamic currency system (profile default with smart account updates)
- ✅ Balance tracking with automatic updates
- ✅ Include/exclude accounts from net worth calculation
- ✅ Toggle account active/inactive status
- ☐ **TODO:** Per-account currency override in add account dialog
- ☐ **TODO:** Edit/update account functionality
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
- ✅ Material Design 3 UI
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

**Account UI Components:**
- ✅ Accounts screen with category grouping
- ✅ Add account dialog with category selection
- ✅ Account type auto-selection based on category
- ✅ Balance display by account
- ✅ Account status toggle (active/inactive)
- ✅ Include in total toggle
- ☐ **TODO:** Edit account dialog
- ☐ **TODO:** Currency dropdown per account in add/edit forms
- ☐ **TODO:** Account deletion confirmation

**Services & Data Layer:**
- ✅ AccountService with category joins
- ✅ Account model with accountTypeCategory field
- ✅ AccountProvider with state management
- ✅ Account balance calculations
- ✅ Total balance aggregation by currency
- ✅ RLS-compliant queries

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

### Next Development Priorities

**Week 9 - Account Enhancements:**
1. ☐ Add currency dropdown to account add/edit dialog
2. ☐ Implement edit account functionality
3. ☐ Add account soft-delete with confirmation
4. ☐ Implement restore deleted accounts
5. ☐ Account transfer functionality with fees
6. ☐ Account balance history tracking

**Week 10 - UI/UX Polish:**
1. ☐ Receipt scanning (ML Kit integration)
2. ☐ Enhanced analytics with account breakdowns
3. ☐ Budget recommendations based on income
4. ☐ Financial health indicators
5. ☐ Recurring transactions
6. ☐ Transaction search and filters

**Phase 2 - Advanced Features:**
1. ☐ Cloud Storage for receipts
2. ☐ AI-powered categorization
3. ☐ Budget predictions
4. ☐ Savings goals
5. ☐ Bill reminders
6. ☐ Export functionality (CSV, PDF)