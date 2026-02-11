# FundVance AI Documentation

**AI Financial Assistant & Planning (AI-FAP)**

A mobile app that intelligently tracks expenses, analyzes spending patterns, and provides personalized financial advice to help users save money.

## Quick Links

**⚡ Start Here:**
- [Tech Stack Summary](tech-stack-summary.md) - **Quick overview of all technology decisions**
- [Product Overview](product-overview.md) - Core concept and vision
- [Technical Architecture](technical-architecture.md) - Complete system design

**📱 Features:**
- [MVP Features](features/mvp-features.md) - Core functionality for launch
- [Premium Features](features/premium-features.md) - Advanced paid features

**👥 Users & Business:**
- [Target Users](target-users.md) - User personas and segments
- [Monetization Strategy](monetization-strategy.md) - Revenue model and pricing

**🤖 AI & Technical:**
- [AI Components](ai-components.md) - ML models and capabilities
- [Roadmap](roadmap.md) - Development phases and timeline

---

## Final Technology Stack ✅

| Component | Choice | Why |
|-----------|--------|-----|
| **Mobile** | Flutter | Native performance, single codebase |
| **Backend** | Supabase | PostgreSQL + auto API + auth + storage |
| **OCR** | Google ML Kit + Cloud Vision | Free on-device + premium cloud |
| **State** | Provider/Riverpod | Flutter recommended |
| **Charts** | fl_chart | Beautiful & customizable |

**Project Name:** FundVance AI  
**Supabase Project:** FundVanceAI  
**Total Development Time:** 10 months  
**MVP Cost:** $15/month  
**Launch Target:** January 2027

---

## Documentation Structure

- [Tech Stack Summary](tech-stack-summary.md) - **All tech decisions in one place**
- [Product Overview](product-overview.md) - Core concept and vision
- [Target Users](target-users.md) - User personas and segments
- [Features](features/) - Detailed feature specifications
  - [MVP Features](features/mvp-features.md)
  - [Premium Features](features/premium-features.md)
- [Technical Architecture](technical-architecture.md) - Complete system design
- [AI Components](ai-components.md) - AI/ML models and capabilities
- [Monetization Strategy](monetization-strategy.md) - Revenue model
- [Roadmap](roadmap.md) - Development phases and timeline

---

## Getting Started

### For Developers
1. Read [Tech Stack Summary](tech-stack-summary.md)
2. Review [Technical Architecture](technical-architecture.md)
3. Check [Roadmap](roadmap.md) for current phase
4. Set up development environment (see Tech Architecture)

### For Product/Business
1. Read [Product Overview](product-overview.md)
2. Review [Target Users](target-users.md)
3. Explore [MVP Features](features/mvp-features.md)
4. Check [Monetization Strategy](monetization-strategy.md)

### For Project Management
1. Review [Roadmap](roadmap.md)
2. Check current development phase
3. Track milestones and deliverables
4. Monitor budget vs timeline

---

## Key Decisions Made

✅ **Mobile Framework:** Flutter (over React Native)  
✅ **Backend:** Supabase (over Firebase or custom Node.js)  
✅ **Database:** PostgreSQL via Supabase  
✅ **OCR:** Google ML Kit (free) + Cloud Vision API (premium)  
✅ **Development Approach:** Rapid MVP with scalable architecture  

See [Tech Stack Summary](tech-stack-summary.md) for complete details and rationale.

---

**Version:** 1.0.0  
**Last Updated:** February 11, 2026
