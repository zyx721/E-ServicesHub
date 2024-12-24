import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static Map<String, String>? _localizedStrings;

  Future<bool> load() async {
    String jsonString =
        await rootBundle.loadString('assets/l10n/${locale.languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedStrings =
        jsonMap.map((key, value) => MapEntry(key, value.toString()));
    return true;
  }

  String? get findHandymanServices =>
      _localizedStrings!['findHandymanServices'];
  String? get discoverReliableHandyman =>
      _localizedStrings!['discoverReliableHandyman'];
  String? get bookWithEase => _localizedStrings!['bookWithEase'];
  String? get simpleBookingProcess =>
      _localizedStrings!['simpleBookingProcess'];
  String? get rateAndReview => _localizedStrings!['rateAndReview'];
  String? get shareExperience => _localizedStrings!['shareExperience'];
  String? get getStarted => _localizedStrings!['getStarted'];
  String? get next => _localizedStrings!['next'];
}
