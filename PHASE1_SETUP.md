# Phase 1: Foundation Setup Guide

## Week 1-2: Project Setup & Database Design

### Day 1: Supabase Setup

**Tasks:**
1. **Create Supabase Account**
   - Go to https://supabase.com
   - Sign up with GitHub account
   - Create new organization (if needed)

2. **Create New Project**
   - Project name: `ai-fap-prod`
   - Database password: (generate strong password - save in password manager)
   - Region: Choose closest to target users (e.g., US East, Singapore, Europe)
   - Pricing tier: Free (upgrade later)

3. **Save Credentials**
   ```
   Project URL: https://[your-project-ref].supabase.co
   Anon Key: [copy from Settings > API]
   Service Role Key: [copy from Settings > API - KEEP SECRET]
   ```

4. **Install Supabase CLI**
   ```bash
   npm install -g supabase
   supabase login
   supabase link --project-ref [your-project-ref]
   ```

---

### Day 2-3: Database Schema Design

**Execute these SQL scripts in Supabase SQL Editor:**

#### 1. Enable UUID Extension
```sql
-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```

#### 2. Create Profiles Table
```sql
-- User profiles (extends Supabase Auth)
CREATE TABLE profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  full_name TEXT,
  avatar_url TEXT,
  currency TEXT DEFAULT 'USD',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'full_name');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

#### 3. Create Categories Table
```sql
-- Categories for expense classification
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users ON DELETE CASCADE,
  name TEXT NOT NULL,
  icon TEXT,
  color TEXT,
  is_default BOOLEAN DEFAULT false,
  parent_id UUID REFERENCES categories(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view own categories"
  ON categories FOR SELECT
  USING (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "Users can manage own categories"
  ON categories FOR ALL
  USING (auth.uid() = user_id);

-- Create indexes
CREATE INDEX idx_categories_user_id ON categories(user_id);
CREATE INDEX idx_categories_parent_id ON categories(parent_id);
```

#### 4. Create Expenses Table
```sql
-- Main expenses table
CREATE TABLE expenses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  merchant TEXT,
  description TEXT,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  payment_method TEXT,
  receipt_url TEXT,
  notes TEXT,
  is_recurring BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view own expenses"
  ON expenses FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own expenses"
  ON expenses FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own expenses"
  ON expenses FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own expenses"
  ON expenses FOR DELETE
  USING (auth.uid() = user_id);

-- Create indexes for performance
CREATE INDEX idx_expenses_user_id ON expenses(user_id);
CREATE INDEX idx_expenses_date ON expenses(date);
CREATE INDEX idx_expenses_category_id ON expenses(category_id);
CREATE INDEX idx_expenses_user_date ON expenses(user_id, date DESC);
```

#### 5. Create Budgets Table
```sql
-- Budget tracking
CREATE TABLE budgets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL,
  period TEXT NOT NULL CHECK (period IN ('weekly', 'monthly', 'yearly')),
  start_date DATE NOT NULL,
  end_date DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can manage own budgets"
  ON budgets FOR ALL
  USING (auth.uid() = user_id);

-- Create indexes
CREATE INDEX idx_budgets_user_id ON budgets(user_id);
CREATE INDEX idx_budgets_category_id ON budgets(category_id);
```

#### 6. Create Default Categories
```sql
-- Insert default categories (null user_id = available to all)
INSERT INTO categories (user_id, name, icon, color, is_default) VALUES
  (NULL, 'Food', '🍔', '#FF6B6B', true),
  (NULL, 'Transport', '🚗', '#4ECDC4', true),
  (NULL, 'Bills', '📄', '#45B7D1', true),
  (NULL, 'Shopping', '🛍️', '#96CEB4', true),
  (NULL, 'Entertainment', '🎬', '#FFEAA7', true),
  (NULL, 'Healthcare', '⚕️', '#DDA15E', true),
  (NULL, 'Others', '📌', '#95A5A6', true);

-- Insert subcategories for Food
INSERT INTO categories (user_id, name, icon, color, is_default, parent_id) VALUES
  (NULL, 'Groceries', '🛒', '#FF6B6B', true, (SELECT id FROM categories WHERE name = 'Food' LIMIT 1)),
  (NULL, 'Dining Out', '🍽️', '#FF6B6B', true, (SELECT id FROM categories WHERE name = 'Food' LIMIT 1)),
  (NULL, 'Coffee Shops', '☕', '#FF6B6B', true, (SELECT id FROM categories WHERE name = 'Food' LIMIT 1)),
  (NULL, 'Food Delivery', '🍕', '#FF6B6B', true, (SELECT id FROM categories WHERE name = 'Food' LIMIT 1));
```

---

### Day 4-5: Flutter Project Setup

**Tasks:**

1. **Install Flutter**
   ```bash
   # Check Flutter installation
   flutter doctor
   
   # Update Flutter
   flutter upgrade
   ```

2. **Create Flutter Project**
   ```bash
   cd "d:\khairo\personal project\Ai-FAP"
   flutter create --org com.aifap --platforms=android,ios ai_fap_mobile
   cd ai_fap_mobile
   ```

3. **Update pubspec.yaml**
   ```yaml
   name: ai_fap_mobile
   description: AI-powered financial assistant and planning app
   version: 1.0.0+1

   environment:
     sdk: '>=3.3.0 <4.0.0'

   dependencies:
     flutter:
       sdk: flutter
     
     # State Management
     provider: ^6.1.1
     
     # Backend & Database
     supabase_flutter: ^2.3.4
     
     # HTTP & Network
     dio: ^5.4.0
     
     # Local Storage
     flutter_secure_storage: ^9.0.0
     
     # UI Components
     cupertino_icons: ^1.0.6
     flutter_svg: ^2.0.9
     cached_network_image: ^3.3.1
     
     # Navigation
     go_router: ^13.0.0
     
     # Forms & Validation
     flutter_form_builder: ^9.1.1
     form_builder_validators: ^9.1.0
     
     # Date & Time
     intl: ^0.19.0
     
     # Charts (will add later)
     # fl_chart: ^0.66.0
     
     # Image Handling
     # image_picker: ^1.0.7
     # google_ml_kit: ^0.16.3

   dev_dependencies:
     flutter_test:
       sdk: flutter
     flutter_lints: ^3.0.1
     mockito: ^5.4.4
   ```

4. **Install Dependencies**
   ```bash
   flutter pub get
   ```

5. **Create Project Structure**
   ```bash
   # Create folder structure
   mkdir lib/core lib/features lib/shared
   mkdir lib/core/config lib/core/constants lib/core/utils
   mkdir lib/features/auth lib/features/expenses lib/features/categories
   mkdir lib/shared/widgets lib/shared/models lib/shared/services
   ```

---

### Day 6-7: Supabase Integration

**Create: lib/core/config/supabase_config.dart**
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
  
  static SupabaseClient get client => Supabase.instance.client;
}
```

**Update: lib/main.dart**
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseConfig.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FundVance AI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'FundVance AI',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
```

---

## Week 3-4: Authentication & Core Models

### Tasks:
1. **Build authentication screens** (Sign up, Login, Forgot password)
2. **Implement auth service** with Supabase
3. **Create data models** (Expense, Category, Budget)
4. **Set up navigation** with go_router
5. **Create reusable UI components**

---

## Next Steps

**Immediate actions to take:**

1. ✅ Create Supabase account and project
2. ✅ Execute database schema SQL
3. ✅ Create Flutter project
4. ✅ Set up project structure
5. ✅ Configure Supabase in Flutter

**What you need to decide:**

- Supabase project region (closest to target users)
- App package name (currently: com.aifap.ai_fap_mobile)
- Color scheme and branding

---

## Tracking Progress

Create a checklist:
- [ ] Supabase project created
- [ ] Database tables created
- [ ] RLS policies tested
- [ ] Flutter project initialized
- [ ] Dependencies installed
- [ ] Supabase integrated
- [ ] First successful auth test

**Estimated Time:** 2 weeks for full Phase 1 setup

Ready to start? Let me know which step you want to begin with!
