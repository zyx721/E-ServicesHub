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
String get home => isArabic ? "الرئيسية" : (isFrench ? "Accueil" : "Home");
  String get search => isArabic ? "بحث" : (isFrench ? "Rechercher" : "Search");
  String get favorites =>
      isArabic ? "المفضلة" : (isFrench ? "Favoris" : "Favorites");
  String get profile =>
      isArabic ? "الملف الشخصي" : (isFrench ? "Profil" : "Profile");

  // Sidebar Translations
  String get settings =>
      isArabic ? "الإعدادات" : (isFrench ? "Paramètres" : "Settings");
  String get logout =>
      isArabic ? "تسجيل الخروج" : (isFrench ? "Se déconnecter" : "Logout");
  String get language =>
      isArabic ? "اللغة" : (isFrench ? "Langue" : "Language");

  // Notifications
  String get notifications =>
      isArabic ? "الإشعارات" : (isFrench ? "Notifications" : "Notifications");

  // Common Buttons
  String get save => isArabic ? "حفظ" : (isFrench ? "Enregistrer" : "Save");
  String get cancel =>
      isArabic ? "إلغاء" : (isFrench ? "Annuler" : "Cancel");

  // Error Messages
  String get error =>
      isArabic ? "حدث خطأ" : (isFrench ? "Une erreur est survenue" : "An error occurred");
  String get noInternet =>
      isArabic ? "لا يوجد اتصال بالإنترنت" : (isFrench ? "Pas de connexion Internet" : "No Internet connection");

  // Profile Page
  String get editProfile =>
      isArabic ? "تعديل الملف الشخصي" : (isFrench ? "Modifier le profil" : "Edit Profile");
  String get contactSupport =>
      isArabic ? "اتصل بالدعم" : (isFrench ? "Contacter le support" : "Contact Support");

  // Password recovery translations
  String get enterValidEmail => isArabic
      ? "يرجى إدخال بريد إلكتروني صالح"
      : (isFrench
          ? "Veuillez entrer une adresse e-mail valide."
          : "Please enter a valid email.");

  String get networkError => isArabic
      ? "خطأ في الشبكة. يرجى المحاولة مرة أخرى لاحقًا."
      : (isFrench
          ? "Erreur réseau. Veuillez réessayer plus tard."
          : "Network error. Please try again later.");

  String get emailNotFound => isArabic
      ? "البريد الإلكتروني غير موجود. يرجى التحقق والمحاولة مرة أخرى."
      : (isFrench
          ? "E-mail introuvable. Veuillez vérifier et réessayer."
          : "Email not found. Please check and try again.");

  String get passwordResetEmailSent => isArabic
      ? "تم إرسال بريد إلكتروني لإعادة تعيين كلمة المرور إلى بريدك الإلكتروني."
      : (isFrench
          ? "Un e-mail de réinitialisation du mot de passe a été envoyé à votre boîte de réception."
          : "A password reset email has been sent to your inbox.");

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

  // Signup screen translations
  String get signupTitle => isArabic
      ? "إنشاء حساب"
      : (isFrench ? "Créer un compte" : "Create Account");

  String get nameLabel => isArabic ? "الاسم" : (isFrench ? "Nom" : "Name");

  String get emailLabel =>
      isArabic ? "البريد الإلكتروني" : (isFrench ? "E-mail" : "Email");

  String get passwordLabel =>
      isArabic ? "كلمة المرور" : (isFrench ? "Mot de passe" : "Password");

  String get passwordCheckLabel => isArabic
      ? "أعد كتابة كلمة المرور"
      : (isFrench ? "Confirmez le Mot de passe" : "Confirm Password");

  String get phoneLabel =>
      isArabic ? "رقم الهاتف" : (isFrench ? "Numéro de téléphone" : "Phone");

  String get termsAgreement => isArabic
      ? "أوافق على الشروط والأحكام"
      : (isFrench
          ? "J'accepte les termes"
          : "I agree to the Terms and Conditions");

  String get signInWithGoogle => isArabic
      ? "تسجيل الدخول باستخدام Google"
      : (isFrench ? "Se connecter avec Google" : "Sign in with Google");

  String get signupButton =>
      isArabic ? "إنشاء حساب" : (isFrench ? "Créer un compte" : "Sign Up");

  String get termsAgreementLink => isArabic
      ? "الشروط والأحكام"
      : (isFrench ? "Conditions d'utilisation" : "Terms and Conditions");

  String get termsAgreementPrefix => isArabic
      ? "أوافق على "
      : (isFrench ? "J'accepte les " : "I agree to the ");

  String get loginButtonText => isArabic
      ? "لديك حساب بالفعل؟ تسجيل الدخول"
      : (isFrench
          ? "Vous avez déjà un compte ? Connexion"
          : "Already have an account? Login");
  String get passwordRequiredError => isArabic
      ? "الرجاء إدخال كلمة المرور"
      : (isFrench
          ? "Veuillez entrer un mot de passe"
          : "Please enter your password");

  String get passwordMinLengthError => isArabic
      ? "كلمة المرور يجب أن تكون على الأقل 8 أحرف"
      : (isFrench
          ? "Le mot de passe doit comporter au moins 8 caractères"
          : "Password must be at least 8 characters long");

  String get emailRequiredError => isArabic
      ? "الرجاء إدخال البريد الإلكتروني"
      : (isFrench
          ? "Veuillez entrer une adresse e-mail"
          : "Please enter your email");

  String get emailInvalidError => isArabic
      ? "الرجاء إدخال بريد إلكتروني صالح"
      : (isFrench
          ? "Veuillez entrer une adresse e-mail valide"
          : "Please enter a valid email");

  String get fieldRequiredError => isArabic
      ? "الرجاء إدخال اسمك"
      : (isFrench ? "Veuillez entrer votre nom" : "Please enter your name");

  // Home Screen translations

  // Home Screen translations
  String get appTitle => isArabic ? "هنيني" : (isFrench ? "Hanini" : "Hanini");
  String get searchHint => isArabic
      ? "ابحث عن خدمات..."
      : (isFrench ? "Recherchez des services..." : "Search for services...");
 String get topService => isArabic
    ? "الخدمات المميزة"
    : (isFrench ? "Services principaux" : "Top Services");

  String get menu => isArabic ? "القائمة" : (isFrench ? "Menu" : "Menu");

  String get provider =>
      isArabic ? "المزود" : (isFrench ? "Fournisseur" : "Provider");

  String get phoneRequiredError => isArabic
      ? "يرجى إدخال رقم الهاتف"
      : (isFrench
          ? "Veuillez entrer le numéro de téléphone"
          : "Please enter phone number");

  String get phoneInvalidError => isArabic
      ? "رقم الهاتف غير صالح"
      : (isFrench ? "Numéro de téléphone invalide" : "Invalid phone number");
  String get selectLanguage => isArabic
      ? "اختر اللغة"
      : (isFrench ? "Sélectionner la langue" : "Select Language");


  String get services =>
      isArabic ? "إلغاء" : (isFrench ? "service" : "service");

  String get myProfile =>
      isArabic ? "إلغاء" : (isFrench ? "mon profile" : "my Profil");

  String get appName =>
      isArabic ? "إلغاء" : (isFrench ? "mon profile" : "my Profil");


  String get sponsoredServices => isArabic ? "إلغاء" : (isFrench ? "mon profile" : "Sponsored Services");

  String get homePage => isArabic ? "إلغاء" : (isFrench ? "mon profile" : "home page");


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
