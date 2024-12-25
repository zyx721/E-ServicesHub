import 'package:flutter/material.dart';

// Localization class to manage translations
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  // Method to determine if Arabic, English, or French should be displayed
  bool get isArabic => locale.languageCode == 'ar';
  bool get isEnglish => locale.languageCode == 'en';
  bool get isFrench => locale.languageCode == 'fr';

  String get home => isArabic ? "الرئيسية" : (isFrench ? "Accueil" : "Home");
  String get search => isArabic ? "بحث" : (isFrench ? "Rechercher" : "Search");
  String get favorites =>
      isArabic ? "المفضلة" : (isFrench ? "Favoris" : "Favorites");
  String get profile =>
      isArabic ? "الملف الشخصي" : (isFrench ? "Profil" : "Profile");

  // User data updated successfully
  String get userDataUpdatedSuccessfully => isArabic
      ? "تم تحديث بيانات المستخدم بنجاح"
      : (isFrench
          ? "Les données de l'utilisateur ont été mises à jour avec succès"
          : "User data updated successfully");

  // No user logged in
  String get noUserLoggedIn => isArabic
      ? "لا يوجد مستخدم مسجل"
      : (isFrench ? "Aucun utilisateur connecté" : "No user logged in");

// Change Password
  String get changePassword => isArabic
      ? "تغيير كلمة المرور"
      : (isFrench ? "Changer le mot de passe" : "Change Password");

  // Notification Settings
  String get notificationSettings => isArabic
      ? "إعدادات الإشعارات"
      : (isFrench ? "Paramètres de notification" : "Notification Settings");

  // Privacy Settings
  String get privacySettings => isArabic
      ? "إعدادات الخصوصية"
      : (isFrench ? "Paramètres de confidentialité" : "Privacy Settings");

  // aboutApp
  String get aboutApp => isArabic
      ? "حول التطبيق"
      : (isFrench ? "À propos de l'application" : "About App");

  // Please add at least one skill, certification, and work experience
  String get addSkillsCertificationsWorkExperience => isArabic
      ? "يرجى إضافة مهارة وشهادة وخبرة عمل واحدة على الأقل"
      : (isFrench
          ? "Veuillez ajouter au moins une compétence, une certification et une expérience de travail"
          : "Please add at least one skill, certification, and work experience");

  // User is not authenticated
  String get userNotAuthenticated => isArabic
      ? "المستخدم غير مصادق عليه"
      : (isFrench
          ? "L'utilisateur n'est pas authentifié"
          : "User is not authenticated");

  // Posted
  String get posted =>
      isArabic ? " نشر " : (isFrench ? " Publié " : " Posted ");

  // Location
  String get location =>
      isArabic ? " الموقع " : (isFrench ? " Emplacement " : " Location ");
  // Popular Services
  String get popularServices => isArabic
      ? "الخدمات الشائعة"
      : (isFrench ? "Services populaires" : "Popular Services");

  // Top Services
  String get topServices => isArabic
      ? "أفضل الخدمات"
      : (isFrench ? "Meilleurs services" : "Top Services");

  // All Services
  String get allServices => isArabic
      ? "جميع الخدمات"
      : (isFrench ? "Tous les services" : "All Services");

  // Are you sure you want to log out?
  String get areYouSureYouWantToLogout => isArabic
      ? "هل أنت متأكد أنك تريد تسجيل الخروج؟"
      : (isFrench
          ? "Êtes-vous sûr de vouloir vous déconnecter?"
          : "Are you sure you want to log out?");
  // Error fetching user data:
  String get errorFetchingUserData => isArabic
      ? "حدث خطأ أثناء جلب بيانات المستخدم"
      : (isFrench
          ? "Une erreur s'est produite lors de la récupération des données de l'utilisateur"
          : "An error occurred while fetching user data");

// Error deleting old profile picture
  String get errorDeletingOldProfilePicture => isArabic
      ? "حدث خطأ أثناء حذف الصورة الشخصية القديمة"
      : (isFrench
          ? "Une erreur s'est produite lors de la suppression de l'ancienne photo de profil"
          : "An error occurred while deleting the old profile picture");

// Error updating profile picture
  String get errorUpdatingProfilePicture => isArabic
      ? "حدث خطأ أثناء تحديث الصورة الشخصية"
      : (isFrench
          ? "Une erreur s'est produite lors de la mise à jour de la photo de profil"
          : "An error occurred while updating the profile picture");

  //errorSavingUserData
  String get errorSavingUserData => isArabic
      ? "حدث خطأ أثناء تحديث بيانات المستخدم"
      : (isFrench
          ? "Une erreur s'est produite lors de la mise à jour des données de l'utilisateur"
          : "An error occurred while updating user data");

  String get providerText =>
      isArabic ? "مزود الخدمة" : (isFrench ? "Fournisseur" : "Provider");
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
  String get becomeProviderButton => isArabic
      ? "أصبح مقدم الخدمة"
      : (isFrench ? "Devenir fournisseur" : "Become a Provider");

  // Listings
  String get listings =>
      isArabic ? "القوائم" : (isFrench ? "Listes" : "Listings");

  // New Review Received
  String get newReviewReceived => isArabic
      ? "لديك مراجعة جديدة على ملفك الشخصي"
      : (isFrench
          ? "Nouvel avis reçu sur votre profil"
          : "New review on your profile");
  // You have a new review on your profile
  String get youHaveNewReviewOnYourProfile => isArabic
      ? "لديك مراجعة جديدة على ملفك الشخصي"
      : (isFrench
          ? "Vous avez un nouvel avis sur votre profil"
          : "You have a new review on your profile");
  // Failed to add review. Please try again.
  String get failedToAddReview => isArabic
      ? "فشل إضافة المراجعة. يرجى المحاولة مرة أخرى."
      : (isFrench
          ? "Échec de l'ajout de l'avis. Veuillez réessayer."
          : "Failed to add review. Please try again.");

  // Review added successfully!
  String get reviewAddedSuccessfully => isArabic
      ? "تمت إضافة المراجعة بنجاح!"
      : (isFrench ? "Avis ajouté avec succès!" : "Review added successfully!");

  // Reviews
  String get reviews =>
      isArabic ? "المراجعات" : (isFrench ? "Avis" : "Reviews");

  // Add Review
  String get addReview =>
      isArabic ? "إضافة مراجعة" : (isFrench ? "Ajouter un avis" : "Add Review");

  // addComment
  String get addComment => isArabic
      ? "أضف تعليق"
      : (isFrench ? "Ajouter un commentaire" : "Add Comment");

  // submit
  String get submit => isArabic ? "إرسال" : (isFrench ? "Soumettre" : "Submit");
  // Submitting review
  String get submittingReview => isArabic
      ? "جارٍ تقديم المراجعة..."
      : (isFrench ? "Soumission de l'avis ..." : "Submitting review ...");
  // Sent
  String get sent => isArabic ? "المرسل" : (isFrench ? "Envoyé" : "Sent");

  //  Received
  String get received =>
      isArabic ? "المستلم" : (isFrench ? "Reçu" : "Received");

  // No listings available
  String get noListingsAvailable => isArabic
      ? "لا توجد قوائم متاحة"
      : (isFrench ? "Aucune liste disponible" : "No listings available");

  // No reviews available
  String get noReviewsAvailable => isArabic
      ? "لا توجد مراجعات متاحة"
      : (isFrench ? "Aucun avis disponible" : "No reviews available");

  // Accept
  String get accept => isArabic ? "قبول" : (isFrench ? "Accepter" : "Accept");

  // Refuse
  String get refuse => isArabic ? "رفض" : (isFrench ? "Refuser" : "Refuse");
  // Negotiate
  String get negotiate =>
      isArabic ? "تفاوض" : (isFrench ? "Négocier" : "Negotiate");

  // step2Button
  String get step2Button =>
      isArabic ? "اخر خطوة" : (isFrench ? "Dernière étape" : "Final Step");


    String get   copiedToClipboard =>
       isArabic ? "تم نسخها إلى الحافظة" : (isFrench ? "Copié Dans Le Presse-papiers":"Copied To Clipboard ");
  // waitingButton
  String get waitingButton => isArabic
      ? "يتم التحقق من هويتك"
      : (isFrench
          ? "identité en cours de vérification"
          : "Your identity is being verified");

  // waitingMessage "Wait For Manual Verifcation"
  String get waitingMessage => isArabic
      ? "انتظر التحقق اليدوي"
      : (isFrench
          ? "Attendez la vérification manuelle"
          : "Wait For Manual Verifcation");

// verificationButton "Identity Verification"
  String get verificationButton => isArabic
      ? " 2 التحقق من الهوية "
      : (isFrench ? "Vérification d'identité  2 " : "Identity Verification 2 ");

  // Common Buttons
  String get save => isArabic ? "حفظ" : (isFrench ? "Enregistrer" : "Save");
  String get cancel => isArabic ? "إلغاء" : (isFrench ? "Annuler" : "Cancel");

  String get saveProfile => isArabic
      ? "حفظ الملف الشخصي"
      : (isFrench ? " Enregistrer le profil" : "Save Profile");

  // Error Messages
  String get error => isArabic
      ? "حدث خطأ"
      : (isFrench ? "Une erreur est survenue" : "An error occurred");

// 'No user logged in'
  // Okay Messages
  String get okay => isArabic ? "حسنا" : (isFrench ? "D'accord" : "OK");

  String get noInternet => isArabic
      ? "لا يوجد اتصال بالإنترنت"
      : (isFrench ? "Pas de connexion Internet" : "No Internet connection");

  String get aboutMe =>
      isArabic ? "نبـذة عني" : (isFrench ? "À propos de moi" : "About Me");

  // workDomain
  String get workDomain => isArabic
      ? "مجال العمل"
      : (isFrench ? "Domaine de travail" : "Work Domain");

  // New localization for no favorite services
  String get noFavoriteServicesYet => isArabic
      ? "لا توجد خدمات مفضلة بعد"
      : (isFrench
          ? "Aucun service favori pour le moment"
          : "No favorite services yet");

  // Filter Services
  String get filterServices => isArabic
      ? "تصفية الخدمات"
      : (isFrench ? "Filtrer les services" : "Filter Services");

  // Clear Filters
  String get clearFilters => isArabic
      ? "مسح الفلاتر"
      : (isFrench ? "Effacer les filtres" : "Clear Filters");

  // Apply Filters
  String get applyFilters => isArabic
      ? "تطبيق الفلاتر"
      : (isFrench ? "Appliquer les filtres" : "Apply Filters");

  // New localization for NameEntryScreen
  String get firstName =>
      isArabic ? "الاسم الأول" : (isFrench ? "Prénom" : "First Name");
  String get lastName =>
      isArabic ? "الاسم الأخير" : (isFrench ? "Nom de famille" : "Last Name");
  String get selectYourServices => isArabic
      ? "اختر خدماتك:"
      : (isFrench ? "Sélectionnez vos services:" : "Select Your Services:");
  String get selectOneChoice => isArabic
      ? "يرجى اختيار خيار واحد فقط."
      : (isFrench
          ? "Veuillez sélectionner un seul choix."
          : "Please select only one choice.");

  String get continueButton =>
      isArabic ? "استمر" : (isFrench ? "Continuer" : "Continue");
  String get firstNameLastNameRequired => isArabic
      ? "الاسم الأول واسم العائلة مطلوبان."
      : (isFrench
          ? "Le prénom et le nom de famille sont obligatoires."
          : "First Name and Last Name are required.");
  // Add retry localization
  String get retry =>
      isArabic ? "إعادة المحاولة" : (isFrench ? "Réessayer" : "Retry");

  // babysitter
  String get babysitter =>
      isArabic ? " مربية أطفال " : (isFrench ? "Babysitter" : "Babysitter");

  String get firstNameRequired => isArabic
      ? "الاسم الأول مطلوب."
      : (isFrench ? "Le prénom est obligatoires." : "First Name is required.");

  String get LastNameRequired => isArabic
      ? "اسم العائلة مطلوب."
      : (isFrench ? "Le nom est obligatoires." : "Last Name is required.");

  String get selectTwoWorkChoices => isArabic
      ? "يرجى اختيار خيارين بالضبط."
      : (isFrench
          ? "Veuillez sélectionner exactement deux choix de travail."
          : "Please select exactly two work choices.");
  String get enterYourDetails => isArabic
      ? "أدخل تفاصيلك"
      : (isFrench ? "Entrez vos coordonnées" : "Enter Your Details");
  String get ok => isArabic ? "حسنا" : (isFrench ? "D'accord" : "OK");

  // New localization for OnboardingScreen2
  String get verifyYourIdentity => isArabic
      ? "تحقق من هويتك"
      : (isFrench ? "Vérifiez votre identité" : "Verify Your Identity");
  String get verifyIdentityDescription => isArabic
      ? "لأمانك، نحتاج إلى تأكيد هويتك. هذا يضمن تجربة موثوقة وآمنة للجميع."
      : (isFrench
          ? "Pour votre sécurité, nous devons confirmer votre identité. Cela garantit une expérience fiable et sécurisée pour tout le monde."
          : "For your security, we need to confirm your identity. This ensures a trusted and secure experience for everyone.");

  // New localization for work choices
  String get houseCleaning => isArabic
      ? "تنظيف المنازل"
      : (isFrench ? "Nettoyage maison" : "House Cleaning");
  String get electricity =>
      isArabic ? "كهرباء" : (isFrench ? "Électricité" : "Electricity");
  String get plumbing =>
      isArabic ? "سباكة" : (isFrench ? "Plomberie" : "Plumbing");
  String get gardening =>
      isArabic ? "البستنة" : (isFrench ? "Jardinage" : "Gardening");
  String get painting =>
      isArabic ? "دهان" : (isFrench ? "Peinture" : "Painting");
  String get carpentry =>
      isArabic ? "نجارة" : (isFrench ? "Menuiserie" : "Carpentry");
  String get pestControl => isArabic
      ? "مكافحة الآفات"
      : (isFrench ? "Lutte antiparasitaire" : "Pest Control");
  String get acRepair => isArabic
      ? "إصلاح مكيف الهواء"
      : (isFrench ? "Réparation AC" : "AC Repair");
  String get vehicleRepair => isArabic
      ? "إصلاح المركبات"
      : (isFrench ? "Réparation véhicule" : "Vehicle Repair");
  String get applianceInstallation => isArabic
      ? "تركيب الأجهزة"
      : (isFrench ? "Installation appareils" : "Appliance Installation");
  String get itSupport => isArabic
      ? "دعم تكنولوجيا المعلومات"
      : (isFrench ? "Support informatique" : "IT Support");
  String get homeSecurity => isArabic
      ? "أمن المنزل"
      : (isFrench ? "Sécurité domicile" : "Home Security");
  String get interiorDesign => isArabic
      ? "تصميم داخلي"
      : (isFrench ? "Design intérieur" : "Interior Design");
  String get windowCleaning => isArabic
      ? "تنظيف النوافذ"
      : (isFrench ? "Nettoyage fenêtres" : "Window Cleaning");
  String get furnitureAssembly => isArabic
      ? "تجميع الأثاث"
      : (isFrench ? "Assemblage meubles" : "Furniture Assembly");

  // New localization for id_verification_screen
  String get realTimeDetection => isArabic
      ? "الكشف في الوقت الحقيقي"
      : (isFrench ? "Détection en temps réel" : "Real-Time Detection");

  // Upload Front ID
  String get uploadFrontID => isArabic
      ? "تحميل الهوية الأمامية"
      : (isFrench ? "Télécharger l'identifiant avant" : "Upload Front ID");

  String get support => isArabic ? "الدعم" : (isFrench ? "Soutien" : "Support");
  String get supportMessage => isArabic
      ? "إذا لم يتم اكتشاف بطاقتك، يرجى التأكد من أنها محاذية بشكل صحيح وحاول مرة أخرى."
      : (isFrench
          ? "Si votre carte n'a pas été détectée, assurez-vous qu'elle est correctement alignée et réessayez."
          : "If your card was not detected, please make sure it is aligned correctly and try again.");
  String get stopDetection => isArabic
      ? "إيقاف الكشف"
      : (isFrench ? "Arrêter la détection" : "Stop Detection");
  String get startDetection => isArabic
      ? "بدء الكشف"
      : (isFrench ? "Commencer la détection" : "Start Detection");
  String get skip => isArabic ? "تخطي" : (isFrench ? "Sauter" : "Skip");
  String get uploadLabel =>
      isArabic ? "تحميل" : (isFrench ? "Télécharger" : "Upload");

  String get retake => isArabic ? "إعادة" : (isFrench ? "Reprendre" : "Retake");

  // New localization for face_verification_screen
  String get faceVerification => isArabic
      ? "التحقق من الوجه"
      : (isFrench ? "Vérification du visage" : "Face Verification");
  String get faceVerificationSupportMessage => isArabic
      ? "يرجى التأكد من أن وجهك مرئي بوضوح داخل الدليل البيضاوي وانظر مباشرة إلى الكاميرا. حافظ على وجهك في المنتصف واحتفظ بتعبير محايد."
      : (isFrench
          ? "Veuillez vous assurer que votre visage est clairement visible dans le guide ovale et regardez directement la caméra. Gardez votre visage centré et maintenez une expression neutre."
          : "Please ensure your face is clearly visible within the oval guide and look directly at the camera. Keep your face centered and maintain a neutral expression.");
  String get verifyFace => isArabic
      ? "تحقق من الوجه"
      : (isFrench ? "Vérifier le visage" : "Verify Face");

  // Profile Page
  String get editProfile => isArabic
      ? "تعديل الملف الشخصي"
      : (isFrench ? "Modifier le profil" : "Edit Profile");
  String get contactSupport => isArabic
      ? "اتصل بالدعم"
      : (isFrench ? "Contacter le support" : "Contact Support");
  String get name => isArabic ? "الاسم" : (isFrench ? "Nom" : "Name");
  String get projects =>
      isArabic ? "المشاريع" : (isFrench ? "Projets" : "Projects");
  String get rating =>
      isArabic ? "التقييم" : (isFrench ? "Évaluation" : "Rating");
  String get hourlyRate => isArabic
      ? "معدل الأجر بالساعة"
      : (isFrench ? "Tarif horaire" : "Hourly Rate");

  String get hourlyRateRequiredError => isArabic
      ? "يرجى تحديد معدل الأجر بالساعة لإتمام العملية."
      : (isFrench
          ? "Veuillez préciser votre tarif horaire pour continuer."
          : "Please specify your hourly rate to proceed.");

  String get aboutMeLabel =>
      isArabic ? "عني" : (isFrench ? "À propos de moi" : "About Me");
  String get writeAboutYourself => isArabic
      ? "اكتب عن نفسك"
      : (isFrench ? "Écrivez sur vous" : "Write about yourself");
  String get skills =>
      isArabic ? "المهارات" : (isFrench ? "Compétences" : "Skills");
  String get addSkill => isArabic
      ? "أضف مهارة"
      : (isFrench ? "Ajouter une compétence" : "Add Skill");
  String get noSkillsAvailable => isArabic
      ? "لا توجد مهارات متاحة"
      : (isFrench ? "Aucune compétence disponible" : "No skills available");
  String get workExperience => isArabic
      ? "الخبرة العملية"
      : (isFrench ? "Expérience\nprofessionnelle" : "Work Experience");

  String get companyName => isArabic
      ? "اسم الشركة"
      : (isFrench ? "Nom de l'entreprise" : "Company Name");
  String get position =>
      isArabic ? "المنصب" : (isFrench ? "Poste" : "Position");
  String get duration => isArabic ? "خلال" : (isFrench ? "Durée" : "Duration");
  String get addWorkExperience => isArabic
      ? "أضف خبرة عمل"
      : (isFrench
          ? "Ajouter une expérience"
          : "Add Work Experience");
  String get noWorkExperienceAvailable => isArabic
      ? "لا توجد خبرة عمل متاحة"
      : (isFrench
          ? "Aucune expérience professionnelle disponible"
          : "No work experience available");
  String get portfolio =>
      isArabic ? "المعرض" : (isFrench ? "Portfolio" : "Portfolio");
  String get noPortfolioImagesAvailable => isArabic
      ? "لا توجد صور في المعرض"
      : (isFrench
          ? "Aucune image dans le portfolio"
          : "No portfolio images available");
  String get addPortfolioImage => isArabic
      ? "أضف صورة إلى المعرض"
      : (isFrench ? "Ajouter une image au portfolio" : "Add Portfolio Image");

  String get noPortfolioImages => isArabic
      ? "لا توجد صور متوفرة في المعرض."
      : (isFrench
          ? "Aucune image de portfolio disponible."
          : "No portfolio images available");

  String get certifications =>
      isArabic ? "الشهادات" : (isFrench ? "Certifications" : "Certifications");
  String get addCertification => isArabic
      ? "أضف شهادة"
      : (isFrench ? "Ajouter une certification" : "Add Certification");
  String get noCertificationsAvailable => isArabic
      ? "لا توجد شهادات متاحة"
      : (isFrench
          ? "Aucune certification disponible"
          : "No certifications available");

  // contact Provider
  String get contactProvider => isArabic
      ? "اتصل بمزود الخدمة"
      : (isFrench ? "Contacter le fournisseur" : "Contact Provider");

  // Contact Information
  String get contactInformation => isArabic
      ? "معلومات الاتصال"
      : (isFrench ? "Coordonnées" : "Contact Information");

  // Send Direct Listing
  String get sendDirectListing => isArabic
      ? "إرسال قائمة مباشرة"
      : (isFrench ? "faire une demande" : "Send Direct Listing");

  // Send Direct Job Listing
  String get sendDirectJobListing => isArabic
      ? "إرسال قائمة وظائف مباشرة"
      : (isFrench
          ? "Envoyer une liste d'emplois directe"
          : "Send Direct Job Listing");

  // Main Title
  String get mainTitle => isArabic
      ? "العنوان الرئيسي"
      : (isFrench ? "Titre principal" : "Main Title");
  // Please enter a title
  String get pleaseEnterTitle => isArabic
      ? "الرجاء إدخال عنوان"
      : (isFrench ? "Veuillez entrer un titre" : "Please enter a title");

  // Description
  String get description =>
      isArabic ? "الوصف" : (isFrench ? "Description" : "Description");
  // Please enter a description
  String get pleaseEnterDescription => isArabic
      ? "الرجاء إدخال وصف"
      : (isFrench
          ? "Veuillez entrer une description"
          : "Please enter a description");

  // Pay
  String get pay => isArabic ? "الدفع" : (isFrench ? "Payer" : "Pay");
  //Please enter the pay
  String get pleaseEnterPay => isArabic
      ? "الرجاء إدخال مبلغ الدفع"
      : (isFrench ? "Veuillez entrer le paiement" : "Please enter the pay");

  // Location
  String get locationRequiredError => isArabic
      ? "يرجى تحديد الموقع"
      : (isFrench
          ? "Veuillez sélectionner l'emplacement"
          : "Please select the location");

  // Sending listing...
  String get sendingListing => isArabic
      ? "إرسال القائمة..."
      : (isFrench ? "Envoi de la liste..." : "Sending listing...");

  // sendListing
  String get sendListing => isArabic
      ? "إرسال القائمة"
      : (isFrench ? "Envoyer la liste" : "Send Listing");

  // Failed to send listing. Please try again.
  String get failedToSendListing => isArabic
      ? "فشل إرسال القائمة. يرجى المحاولة مرة أخرى."
      : (isFrench
          ? "Échec de l'envoi de la liste. Veuillez réessayer."
          : "Failed to send listing. Please try again.");
  // Job listing sent successfully!
  String get jobListingSentSuccessfully => isArabic
      ? "تم إرسال قائمة الوظائف بنجاح!"
      : (isFrench
          ? "Liste d'emplois envoyée avec succès!"
          : "Job listing sent successfully!");

  // close
  String get close => isArabic ? "إغلاق" : (isFrench ? "Fermer" : "Close");

  // Admin Profile
  String get manageUsers => isArabic
      ? "إدارة المستخدمين"
      : (isFrench ? "Gérer les utilisateurs" : "Manage Users");
  String get manageReviews => isArabic
      ? "إدارة المراجعات"
      : (isFrench ? "Gérer Les Avis" : "Manage Reviews");
  String get manualVerification => isArabic
      ? "التحقق اليدوي"
      : (isFrench ? "Vérification manuelle" : "Manual Verification");

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

// Profile nameChangeLimit translations
  String get nameChangeLimit => isArabic
      ? "يمكنك تغيير حرفين فقط في إسمك."
      : (isFrench
          ? "Vous ne pouvez changer que deux caractères dans vos noms."
          : "You can only change up to 2 characters in your names.");

  // Profile Profession translations
  String get profession =>
      isArabic ? "المهنة" : (isFrench ? "Profession" : "Profession");
  String get professionRequiredError => isArabic
      ? "يرجى تحديد مهنتك"
      : (isFrench
          ? "Veuillez sélectionner votre profession."
          : "Please select your profession.");
  // Profile address translations
  String get wilaya => isArabic ? "الولاية" : (isFrench ? "Wilaya" : "Wilaya");
  String get wilayaRequiredError => isArabic
      ? "يرجى اختيار ولايتك"
      : (isFrench
          ? "Veuillez sélectionner votre Wilaya."
          : "Please select your Wilaya.");
  String get commune =>
      isArabic ? "البلدية" : (isFrench ? "Commune" : "Commune");
  String get communeRequiredError => isArabic
      ? "يرجى اختيار بلديتك"
      : (isFrench
          ? "Veuillez sélectionner votre Commune."
          : "Please select your Commune.");
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
      ? "هذا الحقل مطلوب."
      : (isFrench ? "Ce champ est requis." : "This field is required.");

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

  String get phone => isArabic
      ? "رقم الهاتف"
      : (isFrench ? "numéro de téléphone" : "phone number");

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

  String get sponsoredServices =>
      isArabic ? "إلغاء" : (isFrench ? "mon profile" : "Sponsored Services");

  String get homePage =>
      isArabic ? "إلغاء" : (isFrench ? "mon profile" : "home page");

  String get setupYourProfile => isArabic
      ? "إعداد ملفك الشخصي"
      : (isFrench ? "Configurer votre profil" : "Setup Your Profile");

  String get BaicInfo => isArabic
      ? "معلومات عامة"
      : (isFrench ? "Informations de base" : "Basic Information");

  // Price Range (DZD)
  String get priceRange =>
      isArabic ? "حدود السعر " : (isFrench ? "Plage de prix" : "Price Range");

  // DZD
  String get dzd => isArabic ? "دج" : (isFrench ? "DZD" : "DZD");

  // Minimum Rating
  String get minimumRating => isArabic
      ? "التقييم الأدنى"
      : (isFrench ? "Note minimale" : "Minimum Rating");

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
