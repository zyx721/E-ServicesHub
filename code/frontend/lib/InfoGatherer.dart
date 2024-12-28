import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hanini_frontend/localization/app_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InfoGatherer extends StatefulWidget {
  @override
  _NameEntryScreenState createState() => _NameEntryScreenState();
}

class _NameEntryScreenState extends State<InfoGatherer> {
  Set<String> _selectedChoices = {};
  static const int requiredChoices = 3;
  String? _selectedGender;
  int? _selectedAge;
  final List<int> _ageRange = List.generate(63, (i) => i + 18);

  // Enhanced color scheme
  static const primaryPurple = Color(0xFF6A1B9A);
  static const secondaryPurple = Color(0xFFAB47BC);
  static const lightPurple = Color(0xFFE1BEE7);
  static const backgroundPurple = Color(0xFFF3E5F5);

  Stream<List<WorkChoice>> get _workChoicesStream {
    return FirebaseFirestore.instance
        .collection('Metadata')
        .doc('WorkChoices')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || !snapshot.data()!.containsKey('choices')) {
        return [];
      }
      return List<WorkChoice>.from(
          snapshot.data()!['choices'].map((x) => WorkChoice.fromMap(x)));
    });
  }

  void _toggleChoice(String choiceId) {
    setState(() {
      if (_selectedChoices.contains(choiceId)) {
        _selectedChoices.remove(choiceId);
      } else if (_selectedChoices.length < requiredChoices) {
        _selectedChoices.add(choiceId);
      }
    });
  }

  void _saveProviderInfo() async {
    if (_selectedChoices.length != requiredChoices) {
      _showErrorDialog(AppLocalizations.of(context)!.selectThreeChoices ??
          'Please select exactly three choices');
      return;
    }

    if (_selectedGender == null || _selectedAge == null) {
      _showErrorDialog('Please complete all fields');
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorDialog("User not authenticated.");
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'service_categories_interest': _selectedChoices.toList(),
        'gender': _selectedGender,
        'age': _selectedAge,
        'isNotFirst': false,
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/navbar',
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      _showErrorDialog("Failed to save data: $e");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          AppLocalizations.of(context)!.error,
          style: TextStyle(color: primaryPurple),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.ok,
              style: TextStyle(color: primaryPurple),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSelection() {
    final localizations = AppLocalizations.of(context)!;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.selectGender,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: primaryPurple,
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildGenderButton(localizations.male, Icons.male),
              SizedBox(width: 20),
              _buildGenderButton(localizations.female, Icons.female),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderButton(String gender, IconData icon) {
    final isSelected = _selectedGender == gender;
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedGender = gender),
          borderRadius: BorderRadius.circular(25),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [primaryPurple, secondaryPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected ? null : backgroundPurple,
              borderRadius: BorderRadius.circular(25),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: primaryPurple.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : primaryPurple,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  gender,
                  style: TextStyle(
                    color: isSelected ? Colors.white : primaryPurple,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgeSelection() {
    final localizations = AppLocalizations.of(context)!;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.selectAge,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: primaryPurple,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: backgroundPurple,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: lightPurple, width: 2),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedAge,
                isExpanded: true,
                hint: Text(
                  localizations.selectYourAge,
                  style: TextStyle(color: primaryPurple.withOpacity(0.7)),
                ),
                icon: Icon(Icons.arrow_drop_down, color: primaryPurple),
                items: _ageRange.map((age) {
                  return DropdownMenuItem<int>(
                    value: age,
                    child: Text(
                      age.toString(),
                      style: TextStyle(color: primaryPurple),
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedAge = value),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          localizations.selectYourServices,
          style: TextStyle(
            color: primaryPurple,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: primaryPurple),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, backgroundPurple.withOpacity(0.3)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildGenderSelection(),
              SizedBox(height: 8),
              _buildAgeSelection(),
              SizedBox(height: 24),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryPurple.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      '${localizations.selectExactly} ${requiredChoices} ${localizations.services}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: primaryPurple,
                      ),
                    ),
                    SizedBox(height: 16),
                    StreamBuilder<List<WorkChoice>>(
                      stream: _workChoicesStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text(
                              'Error loading choices: ${snapshot.error}');
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(primaryPurple),
                            ),
                          );
                        }

                        final workChoices = snapshot.data ?? [];
                        if (workChoices.isEmpty) {
                          return Text('No choices available.');
                        }

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: workChoices.map((choice) {
                            final isSelected =
                                _selectedChoices.contains(choice.id);
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _toggleChoice(choice.id),
                                borderRadius: BorderRadius.circular(25),
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 200),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? LinearGradient(
                                            colors: [
                                              primaryPurple,
                                              secondaryPurple
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : null,
                                    color: isSelected ? null : backgroundPurple,
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: primaryPurple
                                                  .withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: Offset(0, 4),
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isSelected)
                                        Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: Icon(
                                            Icons.check_circle,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                      Text(
                                        _getLocalizedWorkChoice(
                                            choice, context),
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : primaryPurple,
                                          fontSize: 15,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
              GestureDetector(
                onTap: (_selectedChoices.length == requiredChoices &&
                        _selectedGender != null &&
                        _selectedAge != null)
                    ? _saveProviderInfo
                    : null,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: (_selectedChoices.length == requiredChoices &&
                              _selectedGender != null &&
                              _selectedAge != null)
                          ? [primaryPurple, secondaryPurple]
                          : [Colors.grey[400]!, Colors.grey[600]!],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: (_selectedChoices.length == requiredChoices &&
                                _selectedGender != null &&
                                _selectedAge != null)
                            ? primaryPurple.withOpacity(0.3)
                            : Colors.black12,
                        offset: Offset(0, 4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Text(
                    localizations.continueButton,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _getLocalizedWorkChoice(WorkChoice choice, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    switch (locale) {
      case 'ar':
        return choice.ar;
      case 'fr':
        return choice.fr ?? choice.en;
      default:
        return choice.en;
    }
  }
}

class WorkChoice {
  final String id;
  final String en;
  final String ar;
  final String? fr;
  final int count;

  WorkChoice({
    required this.id,
    required this.en,
    required this.ar,
    this.fr,
    this.count = 0,
  });

  factory WorkChoice.fromMap(Map<String, dynamic> map) {
    return WorkChoice(
      id: map['id'] as String,
      en: map['en'] as String,
      ar: map['ar'] as String,
      fr: map['fr'] as String?,
      count: map['count'] as int? ?? 0,
    );
  }
}
