import 'package:flutter/material.dart';

// Localization class to manage translations
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  // Method to determine if Arabic or English should be displayed
  bool get isArabic => locale.languageCode == 'ar';
  String service(int index) {
    switch (index) {
      case 1:
        return isArabic ? "سباكة" : "Plumbing";
      case 2:
        return isArabic ? "كهرباء" : "Electrical";
      case 3:
        return isArabic ? "نجارة" : "Carpentry";
      case 4:
        return isArabic ? "تنظيف" : "Cleaning";
      case 5:
        return isArabic ? "دهان" : "Painting";
      case 6:
        return isArabic ? "تكييف" : "Air Conditioning";
      default:
        return isArabic ? "خدمة غير معروفة" : "Unknown Service";
    }
  }
  // Onboarding translations
  String get onboardingTitle1 =>
      isArabic ? "اكتشف خدمات الحرفيين" : "Discover Handyman Services";
  String get onboardingDescription1 =>
      isArabic ? "اكتشف خدمات الحرفيين الموثوقين عند أطراف أصابعك."
               : "Discover trusted handyman services at your fingertips.";
  String get onboardingTitle2 =>
      isArabic ? "احجز بسهولة" : "Book Easily";
  String get onboardingDescription2 =>
      isArabic ? "عملية الحجز بسيطة لتحديد مواعيد الخدمات في الوقت الذي يناسبك."
               : "The booking process is simple to schedule services at your convenience.";
  String get onboardingTitle3 =>
      isArabic ? "قيم وراجع" : "Rate and Review";
  String get onboardingDescription3 =>
      isArabic ? "شارك تجربتك وساعد الآخرين في العثور على أفضل الخدمات."
               : "Share your experience and help others find the best services.";
  String get getStarted =>
      isArabic ? "ابدأ الآن" : "Get Started Now";
  String get next =>
      isArabic ? "التالي" : "Next";

  // Login translations
  String get loginTitle =>
      isArabic ? "تسجيل الدخول" : "Login";
  String get loginDescription =>
      isArabic ? "قم بتسجيل الدخول إلى حسابك للبدء" : "Log into your account to get started";
  String get email =>
      isArabic ? "البريد الإلكتروني" : "Email";
  String get password =>
      isArabic ? "كلمة المرور" : "Password";
  String get loginButton =>
      isArabic ? "تسجيل الدخول" : "Login";
  String get forgotPassword =>
      isArabic ? "نسيت كلمة المرور؟" : "Forgot password?";
  String get createAccount =>
      isArabic ? "إنشاء حساب جديد" : "Create a new account";

  // Home Screen translations
  String get searchHint => isArabic ? "ابحث عن خدمات..." : "Search for services...";
  String get availableServices => isArabic ? "الخدمات المتاحة" : "Available Services";
  String get menu => isArabic ? "القائمة" : "Menu";
  String get profile => isArabic ? "الملف الشخصي" : "Profile";
  String get settings => isArabic ? "الإعدادات" : "Settings";
  String get language => isArabic ? "اللغة" : "Language";
  String get logout => isArabic ? "تسجيل الخروج" : "Logout";
  
  // Static method to access the instance
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }
}

// Delegate class to handle localization
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    // Create and return an instance of AppLocalizations with the current locale
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
