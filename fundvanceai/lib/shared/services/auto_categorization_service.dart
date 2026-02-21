/// Rule-based auto-categorization service.
/// Maps merchant names and item keywords → category names.
///
/// Category names correspond to system category names in the DB.
/// Used by [ReceiptService] and the expense form's smart suggestions.
class AutoCategorizationService {
  // ── Merchant keyword dictionary ─────────────────────────────────────────────
  // key = DB category name (case-insensitive match), value = brand/keyword list
  static const Map<String, List<String>> _merchantKeywords = {
    'Food & Dining': [
      'restaurant', 'cafe', 'coffee', 'pizza', 'burger', 'sushi', 'noodle',
      'kitchen', 'grill', 'bistro', 'diner', 'eatery', 'bakery', 'bakes',
      'starbucks', 'mcdonalds', "mcdonald's", 'kfc', 'subway', 'dominos',
      "domino's", 'wendys', "wendy's", 'taco bell', 'chipotle', 'panera',
      'dunkin', 'popeyes', 'chick-fil-a', 'five guys', 'shake shack',
      'jollibee', 'mang inasal', 'max\'s', 'greenwich', 'yellow cab',
      'burger king', 'carl\'s jr', 'hardee\'s', 'tim hortons', 'pret',
      'nando\'s', 'wagamama', 'itsu', 'leon', 'gong cha', 'chatime',
    ],
    'Groceries': [
      'grocery', 'supermarket', 'market', 'mart', 'express', 'fresh',
      'organics', 'walmart', 'target', 'costco', 'aldi', 'lidl', 'kroger',
      'safeway', 'whole foods', 'trader joe', 'publix', 'heb', 'meijer',
      'sprouts', 'lucky', 'savemart', 'vons', 'ralphs', 'pavilions',
      'giant', 'stop & shop', 'hannaford', 'shoprite', 'weis',
      'sm supermarket', 'robinsons', 'puregold', 'waltermart',
      'tesco', 'sainsbury', 'asda', 'waitrose', 'marks & spencer',
      'carrefour', 'auchan', 'leclerc', 'casino',
    ],
    'Transportation': [
      'grab', 'uber', 'lyft', 'ola', 'didi', 'taxify', 'bolt',
      'grab car', 'grab taxi', 'grab express', 'move it',
      'gas', 'fuel', 'petrol', 'gasoline', 'shell', 'caltex', 'petron',
      'seaoil', 'total', 'bp', 'chevron', 'exxon', 'mobil', 'texaco',
      'lrt', 'mrt', 'bus', 'jeepney', 'commute', 'transit', 'metro',
      'uber eats', 'grabfood',
      'parking', 'toll', 'ez-link', 'oyster', 'clipper',
    ],
    'Shopping': [
      'mall', 'shop', 'store', 'boutique', 'fashion', 'apparel', 'clothing',
      'zara', 'h&m', 'uniqlo', 'gap', 'forever 21', 'topshop', 'primark',
      'mango', 'next', 'river island', 'cos', 'acne', 'aritzia',
      'amazon', 'lazada', 'shopee', 'shein', 'temu', 'wish', 'ebay',
      'etsy', 'aliexpress', 'taobao', 'zalora',
      'nike', 'adidas', 'puma', 'new balance', 'under armour', 'reebok',
      'converse', 'vans', 'timberland', 'foot locker',
    ],
    'Entertainment': [
      'netflix', 'spotify', 'youtube', 'apple tv', 'disney', 'hbo',
      'cinema', 'movie', 'theater', 'theatre', 'imax', 'sm cinema',
      'steam', 'playstation', 'xbox', 'nintendo', 'epic games',
      'google play', 'app store', 'apple arcade', 'xbox game pass',
      'concert', 'event', 'ticket', 'ticketmaster', 'stubhub',
      'bowling', 'billiards', 'gaming', 'arcade', 'karaoke',
    ],
    'Healthcare': [
      'pharmacy', 'drugstore', 'hospital', 'clinic', 'medical', 'dental',
      'doctor', 'lab', 'laboratory', 'diagnostic', 'health',
      'mercury drug', 'rose pharmacy', 'generika', 'southstar drug',
      'boots', 'cvs', 'walgreens', 'rite aid', 'lloyds',
      'watson', 'guardian', 'caring',
    ],
    'Bills & Utilities': [
      'electric', 'water', 'internet', 'wifi', 'broadband', 'cable',
      'phone', 'mobile', 'telecom', 'pldt', 'globe', 'smart', 'converge',
      'meralco', 'maynilad', 'manila water',
      'at&t', 'verizon', 't-mobile', 'sprint', 'comcast', 'xfinity',
      'gas bill', 'utility', 'pg&e', 'con ed', 'duke energy',
    ],
    'Personal Care': [
      'salon', 'barber', 'spa', 'nail', 'beauty', 'hair', 'skin',
      'wash', 'laundry', 'dry clean', 'cleaners',
    ],
    'Education': [
      'school', 'university', 'tuition', 'books', 'bookstore', 'library',
      'course', 'udemy', 'coursera', 'skillshare', 'masterclass',
    ],
  };

  // ── Item keyword dictionary ─────────────────────────────────────────────────
  static const Map<String, List<String>> _itemKeywords = {
    'Food & Dining': [
      'burger', 'pizza', 'pasta', 'rice', 'chicken', 'beef', 'fish',
      'salad', 'sandwich', 'wrap', 'soup', 'fries', 'coffee', 'tea',
      'juice', 'soda', 'drink', 'meal', 'combo', 'set meal',
    ],
    'Groceries': [
      'milk', 'bread', 'egg', 'butter', 'cheese', 'yogurt', 'flour',
      'sugar', 'salt', 'oil', 'vinegar', 'sauce', 'cereal', 'oats',
      'noodles', 'pasta', 'rice', 'detergent', 'soap', 'shampoo',
      'tissue', 'toilet paper', 'garbage bag', 'canned', 'frozen',
    ],
    'Transportation': [
      'fuel', 'gas', 'petrol', 'diesel', 'parking', 'toll', 'fare',
    ],
    'Healthcare': [
      'medicine', 'tablet', 'capsule', 'syrup', 'vitamin', 'supplement',
      'bandage', 'paracetamol', 'ibuprofen', 'amoxicillin', 'mefenamic',
    ],
  };

  /// Suggest a category name based on merchant name string.
  /// Returns null if no strong match found.
  static String? suggestFromMerchant(String merchant) {
    if (merchant.isEmpty) return null;
    final lower = merchant.toLowerCase();

    for (final entry in _merchantKeywords.entries) {
      for (final keyword in entry.value) {
        if (lower.contains(keyword)) return entry.key;
      }
    }
    return null;
  }

  /// Suggest a category name from a list of item names.
  static String? suggestFromItems(List<String> items) {
    if (items.isEmpty) return null;
    final all = items.map((i) => i.toLowerCase()).join(' ');
    final scores = <String, int>{};

    for (final entry in _itemKeywords.entries) {
      int score = 0;
      for (final kw in entry.value) {
        if (all.contains(kw)) score++;
      }
      if (score > 0) scores[entry.key] = score;
    }

    if (scores.isEmpty) return null;
    return scores.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  /// Given a suggested category name, find the best matching [Category.id]
  /// from the user's actual categories list.
  static String? findCategoryId(
      String categoryName, List<dynamic> categories) {
    final lower = categoryName.toLowerCase();

    // Exact name match first
    for (final cat in categories) {
      if ((cat.name as String).toLowerCase() == lower) return cat.id as String;
    }

    // Partial match
    for (final cat in categories) {
      if ((cat.name as String).toLowerCase().contains(lower) ||
          lower.contains((cat.name as String).toLowerCase())) {
        return cat.id as String;
      }
    }
    return null;
  }
}
