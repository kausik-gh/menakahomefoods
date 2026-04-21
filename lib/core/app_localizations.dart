import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [Locale('en'), Locale('ta')];

  static final Map<String, Map<String, String>> _translations = {
    'en': {
      // Navigation
      'home': 'Home',
      'menu': 'Menu',
      'track': 'Track',
      'profile': 'Profile',
      'cart': 'Cart',

      // Auth Screen
      'already_customer': 'Already a customer?',
      'new_customer': 'New to Menaka Home Foods?',
      'log_in': 'Log In',
      'sign_up': 'Sign Up',
      'already_customer_login': 'Already a customer? Log In',
      'new_customer_signup': 'New to Menaka Home Foods? Sign Up',
      'tagline': 'Freshly made. Lovingly delivered.',
      'admin_hint':
          'Admin & delivery partners: use your registered number to log in',

      // Home Screen
      'good_morning': 'Good morning',
      'good_afternoon': 'Good afternoon',
      'good_evening': 'Good evening',
      'what_to_eat': 'What would you like\nto eat today?',
      'chefs_special': "Chef's Special",
      'order_now': 'Order Now',
      'breakfast': 'Breakfast',
      'lunch': 'Lunch',
      'dinner': 'Dinner',
      'added_to_cart': 'added to cart',
      'view': 'View',

      // Subscription Banner
      'subscribe_cta': 'Tired of ordering daily?',
      'subscribe_subtext': 'Get your meals on repeat — subscribe and relax 🍱',
      'start_subscription': 'Start Subscription',

      // Menu Screen
      'our_menu': 'Our Menu',
      'search_dishes': 'Search dishes...',
      'all': 'All',
      'veg': 'Veg',
      'non_veg': 'Non-Veg',
      'add': 'Add',

      // Track Screen
      'track_order': 'Track Order',
      'nothing_on_way': 'Nothing on the way... yet!',
      'no_orders_subtext':
          "Looks like you don't have any current orders or subscriptions. Order something delicious!",
      'subscribe': 'Subscribe',
      'order_placed': 'Order Placed!',
      'order_placed_desc': "We've received your order",
      'confirmed_preparing': 'Confirmed & Preparing',
      'confirmed_preparing_desc': 'Our chefs are on it',
      'out_for_delivery': 'Out for Delivery',
      'out_for_delivery_desc': 'On the way to you',
      'delivered': 'Delivered',
      'delivered_desc': 'Enjoy your meal!',
      'checking_orders': 'Checking your orders...',
      'estimated_arrival': 'Est. Arrival',
      'min': 'min',
      'call_rider': 'Call Rider',
      'order_summary': 'Order Summary',
      'total': 'Total',
      'items': 'items',

      // Subscription Tracking
      'todays_meals': "Today's Meals",
      'days_remaining': 'Day {current} of {total}',
      'next_delivery': 'Next Delivery',
      'edit_today_dish': "Edit Today's Dish",
      'edit_closes': 'Edit closes in',
      'edit_closes_in': 'Edit closes in',
      'active_subscription': 'Active Subscription',
      'upcoming': 'Upcoming',
      'preparing': 'Preparing',
      'status_delivered': 'Delivered',

      // Profile Screen
      'my_profile': 'My Profile',
      'edit_address': 'Edit Address',
      'my_orders': 'My Orders',
      'language': 'Language',
      'english': 'English',
      'tamil': 'தமிழ்',
      'logout': 'Logout',
      'logout_confirm': 'Are you sure you want to logout?',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'save': 'Save',
      'address': 'Address',
      'street': 'Street / House No.',
      'city': 'City',
      'pincode': 'Pincode',
      'landmark': 'Landmark (optional)',
      'address_saved': 'Address saved successfully!',
      'no_orders_yet': 'No orders yet',
      'place_first_order': 'Place your first order!',
      'order_date': 'Date',
      'order_total': 'Total',
      'order_status': 'Status',
      'order_items': 'Items',
      'close': 'Close',
      'my_subscription': 'My Subscription',
      'saved_addresses': 'Saved Addresses',
      'order_history': 'Order History',
      'favourites': 'Favourites',
      'notifications': 'Notifications',
      'help_support': 'Help & Support',
      'about': 'About Menaka Home Foods',
      'orders': 'Orders',
      'reviews': 'Reviews',
      'customer': 'Customer',

      // Order Status Labels
      'status_placed': 'Placed',
      'status_confirmed': 'Confirmed',
      'status_preparing': 'Preparing',
      'status_out_for_delivery': 'Out for Delivery',
      'status_cancelled': 'Cancelled',

      // Error Messages
      'error_loading': 'Something went wrong. Please try again.',
      'no_internet': 'No internet connection.',
      'retry': 'Retry',
      'slow_connection': 'Slow connection, retrying…',

      // Empty States
      'no_orders': 'Nothing on the way... yet!',
      'no_menu': 'No dishes available',
      'no_riders': 'No riders available',

      // Subscription Wizard
      'when_to_start': 'When should we start?',
      'which_meals': 'Which meals do you want?',
      'plan_your_week': 'Plan your week',
      'review_confirm': 'Review & Confirm',
      'subscribe_pay': 'Subscribe & Pay',
      'days_of_meals': "That's {days} days of delicious meals!",
      'per_day': 'per day',
      'total_amount': 'Total Amount',
      'start_date': 'Start Date',
      'end_date': 'End Date',
      'next': 'Next',
      'back': 'Back',

      // Admin Panel
      'admin_dashboard': 'Admin Dashboard',
      'orders_tab': 'Orders',
      'riders_tab': 'Riders',
      'menu_tab': 'Menu',
      'analytics_tab': 'Analytics',
      'one_time_orders': 'One-time Orders',
      'subscriptions': 'Subscriptions',
      'assign_rider': 'Assign Rider',
      'add_rider': 'Add New Rider',
      'available_today': 'Available Today',
      'add_dish': 'Add New Dish',
      'todays_revenue': "Today's Revenue",
      'active_subscriptions': 'Active Subscriptions',

      // Rider Panel
      'active_deliveries': 'Active Deliveries',
      'completed_today': 'Completed Today',
      'navigate': 'Navigate',
      'mark_delivered': 'Mark as Delivered',
      'delivery_confirmed': 'Delivery Confirmed!',
    },
    'ta': {
      // Navigation
      'home': 'முகப்பு',
      'menu': 'மெனு',
      'track': 'கண்காணி',
      'profile': 'சுயவிவரம்',
      'cart': 'கார்ட்',

      // Auth Screen
      'already_customer': 'ஏற்கனவே வாடிக்கையாளரா?',
      'new_customer': 'மேனகா ஹோம் புட்ஸில் புதியவரா?',
      'log_in': 'உள்நுழை',
      'sign_up': 'பதிவு செய்க',
      'already_customer_login': 'ஏற்கனவே வாடிக்கையாளரா? உள்நுழை',
      'new_customer_signup': 'மேனகா ஹோம் புட்ஸில் புதியவரா? பதிவு செய்க',
      'tagline': 'புதிதாக தயாரிக்கப்பட்டது. அன்புடன் டெலிவரி செய்யப்படுகிறது.',
      'admin_hint':
          'நிர்வாகி & டெலிவரி பார்ட்னர்கள்: உங்கள் பதிவு செய்த எண்ணை பயன்படுத்தி உள்நுழையுங்கள்',

      // Home Screen
      'good_morning': 'காலை வணக்கம்',
      'good_afternoon': 'மதிய வணக்கம்',
      'good_evening': 'மாலை வணக்கம்',
      'what_to_eat': 'இன்று என்ன சாப்பிட\nவிரும்புகிறீர்கள்?',
      'chefs_special': 'சமையல்காரர் சிறப்பு',
      'order_now': 'இப்போது ஆர்டர் செய்',
      'breakfast': 'காலை உணவு',
      'lunch': 'மதிய உணவு',
      'dinner': 'இரவு உணவு',
      'added_to_cart': 'கார்ட்டில் சேர்க்கப்பட்டது',
      'view': 'பார்',

      // Subscription Banner
      'subscribe_cta': 'தினமும் ஆர்டர் செய்வதில் சோர்வாக உள்ளீர்களா?',
      'subscribe_subtext':
          'உங்கள் உணவை திரும்பத் திரும்ப பெறுங்கள் — சந்தா செலுத்தி ரிலாக்ஸ் ஆகுங்கள் 🍱',
      'start_subscription': 'சந்தா தொடங்கு',

      // Menu Screen
      'our_menu': 'எங்கள் மெனு',
      'search_dishes': 'உணவுகளை தேடுங்கள்...',
      'all': 'அனைத்தும்',
      'veg': 'சைவம்',
      'non_veg': 'அசைவம்',
      'add': 'சேர்',

      // Track Screen
      'track_order': 'ஆர்டர் கண்காணி',
      'nothing_on_way': 'வழியில் எதுவும் இல்லை... இன்னும்!',
      'no_orders_subtext':
          'தற்போது உங்களுக்கு எந்த ஆர்டரும் அல்லது சந்தாவும் இல்லை. சுவையான ஏதாவது ஆர்டர் செய்யுங்கள்!',
      'subscribe': 'சந்தா செலுத்து',
      'order_placed': 'ஆர்டர் பதிவாகியது!',
      'order_placed_desc': 'உங்கள் ஆர்டரை பெற்றோம்',
      'confirmed_preparing': 'உறுதிப்படுத்தப்பட்டு தயாரிக்கப்படுகிறது',
      'confirmed_preparing_desc': 'எங்கள் சமையல்காரர்கள் தயாரிக்கிறார்கள்',
      'out_for_delivery': 'டெலிவரியில் உள்ளது',
      'out_for_delivery_desc': 'உங்களை நோக்கி வருகிறது',
      'delivered': 'டெலிவரி ஆனது',
      'delivered_desc': 'உணவை ரசியுங்கள்!',
      'checking_orders': 'உங்கள் ஆர்டர்களை சரிபார்க்கிறோம்...',
      'estimated_arrival': 'எதிர்பார்க்கப்படும் வருகை',
      'min': 'நிமிடம்',
      'call_rider': 'ரைடரை அழை',
      'order_summary': 'ஆர்டர் சுருக்கம்',
      'total': 'மொத்தம்',
      'items': 'பொருட்கள்',

      // Subscription Tracking
      'todays_meals': 'இன்றைய உணவுகள்',
      'days_remaining': 'நாள் {current} / {total}',
      'next_delivery': 'அடுத்த டெலிவரி',
      'edit_today_dish': 'இன்றைய உணவை திருத்து',
      'edit_closes': 'திருத்தம் மூடுகிறது',
      'edit_closes_in': 'திருத்தம் மூடுகிறது',
      'active_subscription': 'செயலில் உள்ள சந்தா',
      'upcoming': 'வரவிருக்கிறது',
      'preparing': 'தயாரிக்கப்படுகிறது',
      'status_delivered': 'டெலிவரி ஆனது',

      // Profile Screen
      'my_profile': 'என் சுயவிவரம்',
      'edit_address': 'முகவரியை திருத்து',
      'my_orders': 'என் ஆர்டர்கள்',
      'language': 'மொழி',
      'english': 'English',
      'tamil': 'தமிழ்',
      'logout': 'வெளியேறு',
      'logout_confirm': 'நீங்கள் வெளியேற விரும்புகிறீர்களா?',
      'cancel': 'ரத்து செய்',
      'confirm': 'உறுதிப்படுத்து',
      'save': 'சேமி',
      'address': 'முகவரி',
      'street': 'தெரு / வீட்டு எண்.',
      'city': 'நகரம்',
      'pincode': 'பின்கோட்',
      'landmark': 'அடையாளம் (விருப்பமானது)',
      'address_saved': 'முகவரி வெற்றிகரமாக சேமிக்கப்பட்டது!',
      'no_orders_yet': 'இன்னும் ஆர்டர் இல்லை',
      'place_first_order': 'உங்கள் முதல் ஆர்டரை செய்யுங்கள்!',
      'order_date': 'தேதி',
      'order_total': 'மொத்தம்',
      'order_status': 'நிலை',
      'order_items': 'பொருட்கள்',
      'close': 'மூடு',
      'my_subscription': 'என் சந்தா',
      'saved_addresses': 'சேமித்த முகவரிகள்',
      'order_history': 'ஆர்டர் வரலாறு',
      'favourites': 'விருப்பங்கள்',
      'notifications': 'அறிவிப்புகள்',
      'help_support': 'உதவி & ஆதரவு',
      'about': 'மேனகா ஹோம் ஃபுட்ஸ் பற்றி',
      'orders': 'ஆர்டர்கள்',
      'reviews': 'மதிப்புரைகள்',
      'customer': 'வாடிக்கையாளர்',

      // Order Status Labels
      'status_placed': 'பதிவாகியது',
      'status_confirmed': 'உறுதிப்படுத்தப்பட்டது',
      'status_preparing': 'தயாரிக்கப்படுகிறது',
      'status_out_for_delivery': 'டெலிவரியில் உள்ளது',
      'status_cancelled': 'ரத்து செய்யப்பட்டது',

      // Error Messages
      'error_loading': 'ஏதோ தவறு நடந்தது. மீண்டும் முயற்சிக்கவும்.',
      'no_internet': 'இணைய இணைப்பு இல்லை.',
      'retry': 'மீண்டும் முயற்சி',
      'slow_connection': 'மெதுவான இணைப்பு, மீண்டும் முயற்சிக்கிறோம்…',

      // Empty States
      'no_orders': 'இன்னும் எதுவும் வரவில்லை!',
      'no_menu': 'உணவுகள் எதுவும் இல்லை',
      'no_riders': 'ரைடர்கள் யாரும் இல்லை',

      // Subscription Wizard
      'when_to_start': 'எப்போது தொடங்க வேண்டும்?',
      'which_meals': 'எந்த உணவுகள் வேண்டும்?',
      'plan_your_week': 'உங்கள் வாரத்தை திட்டமிடுங்கள்',
      'review_confirm': 'மதிப்பாய்வு & உறுதிப்படுத்து',
      'subscribe_pay': 'சந்தா செலுத்து & பணம் செலுத்து',
      'days_of_meals': 'அது {days} நாட்கள் சுவையான உணவு!',
      'per_day': 'ஒரு நாளுக்கு',
      'total_amount': 'மொத்த தொகை',
      'start_date': 'தொடக்க தேதி',
      'end_date': 'முடிவு தேதி',
      'next': 'அடுத்து',
      'back': 'பின்னால்',

      // Admin Panel
      'admin_dashboard': 'நிர்வாக டாஷ்போர்டு',
      'orders_tab': 'ஆர்டர்கள்',
      'riders_tab': 'ரைடர்கள்',
      'menu_tab': 'மெனு',
      'analytics_tab': 'பகுப்பாய்வு',
      'one_time_orders': 'ஒரு முறை ஆர்டர்கள்',
      'subscriptions': 'சந்தாக்கள்',
      'assign_rider': 'ரைடரை நியமி',
      'add_rider': 'புதிய ரைடர் சேர்',
      'available_today': 'இன்று கிடைக்கும்',
      'add_dish': 'புதிய உணவு சேர்',
      'todays_revenue': 'இன்றைய வருவாய்',
      'active_subscriptions': 'செயலில் உள்ள சந்தாக்கள்',

      // Rider Panel
      'active_deliveries': 'செயலில் உள்ள டெலிவரிகள்',
      'completed_today': 'இன்று முடிந்தவை',
      'navigate': 'வழிசெலுத்து',
      'mark_delivered': 'டெலிவரி ஆனது என குறி',
      'delivery_confirmed': 'டெலிவரி உறுதிப்படுத்தப்பட்டது!',
    },
  };

  String t(String key) {
    return _translations[locale.languageCode]?[key] ??
        _translations['en']?[key] ??
        key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (l) => l.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Language provider for app-wide locale management
class LanguageProvider {
  static final LanguageProvider _instance = LanguageProvider._();
  static LanguageProvider get instance => _instance;
  LanguageProvider._();

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback cb) => _listeners.add(cb);
  void removeListener(VoidCallback cb) => _listeners.remove(cb);

  void setLocale(Locale locale) {
    _locale = locale;
    for (final cb in _listeners) {
      cb();
    }
  }

  void toggleLanguage() {
    if (_locale.languageCode == 'en') {
      setLocale(const Locale('ta'));
    } else {
      setLocale(const Locale('en'));
    }
  }
}
