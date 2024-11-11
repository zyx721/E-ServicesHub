import 'package:flutter/material.dart';

// Localization class to manage translations
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  // Method to determine if Arabic, English, or French should be displayed
  bool get isArabic => locale.languageCode == 'ar';
  bool get isEnglish => locale.languageCode == 'en';
  bool get isFrench => locale.languageCode == 'fr';

  // Service translations
  String service(int index) {
    switch (index) {
      case 1:
        return isArabic ? "سباكة" : (isFrench ? "Plomberie" : "Plumbing");
      case 2:
        return isArabic ? "كهرباء" : (isFrench ? "Électrique" : "Electrical");
      case 3:
        return isArabic ? "نجارة" : (isFrench ? "Menuiserie" : "Carpentry");
      case 4:
        return isArabic ? "تنظيف" : (isFrench ? "Nettoyage" : "Cleaning");
      case 5:
        return isArabic ? "دهان" : (isFrench ? "Peinture" : "Painting");
      case 6:
        return isArabic
            ? "تكييف"
            : (isFrench ? "Climatisation" : "Air Conditioning");
      default:
        return isArabic
            ? "خدمة غير معروفة"
            : (isFrench ? "Service inconnu" : "Unknown Service");
    }
  }

  // Onboarding translations
  // Get the language name based on the current locale
  String get englishLanguageName =>
      isArabic ? "الإنجليزية" : (isFrench ? "Anglais" : "English");
  String get arabicLanguageName =>
      isArabic ? "العربية" : (isFrench ? "Arabe" : "Arabic");
  String get frenchLanguageName =>
      isArabic ? "الفرنسية" : (isFrench ? "Français" : "French");
  String get onboardingTitle1 => isArabic
      ? "اكتشف خدمات الحرفيين"
      : (isFrench
          ? "Découvrez les services de bricoleurs"
          : "Discover Handyman Services");
  String get onboardingDescription1 => isArabic
      ? "اكتشف خدمات الحرفيين الموثوقين عند أطراف أصابعك."
      : (isFrench
          ? "Découvrez les services de bricoleurs fiables à portée de main."
          : "Discover trusted handyman services at your fingertips.");
  String get onboardingTitle2 => isArabic
      ? "احجز بسهولة"
      : (isFrench ? "Réservez facilement" : "Book Easily");
  String get onboardingDescription2 => isArabic
      ? "عملية الحجز بسيطة لتحديد مواعيد الخدمات في الوقت الذي يناسبك."
      : (isFrench
          ? "Le processus de réservation est simple pour planifier des services à votre convenance."
          : "The booking process is simple to schedule services at your convenience.");
  String get onboardingTitle3 => isArabic
      ? "قيم وراجع"
      : (isFrench ? "Évaluez et laissez un avis" : "Rate and Review");
  String get onboardingDescription3 => isArabic
      ? "شارك تجربتك وساعد الآخرين في العثور على أفضل الخدمات."
      : (isFrench
          ? "Partagez votre expérience et aidez les autres à trouver les meilleurs services."
          : "Share your experience and help others find the best services.");
  String get getStarted => isArabic
      ? "ابدأ الآن"
      : (isFrench ? "Commencer maintenant" : "Get Started Now");
  String get next => isArabic ? "التالي" : (isFrench ? "Suivant" : "Next");

  // Login translations
  String get loginTitle =>
      isArabic ? "تسجيل الدخول" : (isFrench ? "Connexion" : "Login");
  String get loginDescription => isArabic
      ? "قم بتسجيل الدخول إلى حسابك للبدء"
      : (isFrench
          ? "Connectez-vous à votre compte pour commencer"
          : "Log into your account to get started");
  String get email =>
      isArabic ? "البريد الإلكتروني" : (isFrench ? "E-mail" : "Email");
  String get password =>
      isArabic ? "كلمة المرور" : (isFrench ? "Mot de passe" : "Password");
  String get loginButton =>
      isArabic ? "تسجيل الدخول" : (isFrench ? "Se connecter" : "Login");
  String get forgotPassword => isArabic
      ? "نسيت كلمة المرور؟"
      : (isFrench ? "Mot de passe oublié?" : "Forgot password?");
  String get googleSignIn => isArabic
      ? "تسجيل الدخول باستخدام جوجل"
      : (isFrench ? "Se connecter avec Google" : "Sign in with Google");
  String get createAccount => isArabic
      ? "إنشاء حساب جديد"
      : (isFrench ? "Créer un nouveau compte" : "Create a new account");

  // Home Screen translations
  String get searchHint => isArabic
      ? "ابحث عن خدمات..."
      : (isFrench ? "Recherchez des services..." : "Search for services...");
  String get availableServices => isArabic
      ? "الخدمات المتاحة"
      : (isFrench ? "Services disponibles" : "Available Services");
  String get menu => isArabic ? "القائمة" : (isFrench ? "Menu" : "Menu");
  String get profile =>
      isArabic ? "الملف الشخصي" : (isFrench ? "Profil" : "Profile");
  String get settings =>
      isArabic ? "الإعدادات" : (isFrench ? "Paramètres" : "Settings");
  String get language =>
      isArabic ? "اللغة" : (isFrench ? "Langue" : "Language");
  String get logout =>
      isArabic ? "تسجيل الخروج" : (isFrench ? "Se déconnecter" : "Logout");

  // Static method to access the instance
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static void load(Locale newLocale) {}
}

// Delegate class to handle localization
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'ar', 'fr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    // Create and return an instance of AppLocalizations with the current locale
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
