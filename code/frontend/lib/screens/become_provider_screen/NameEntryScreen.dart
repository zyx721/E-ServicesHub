import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hanini_frontend/localization/app_localization.dart';

class NameEntryScreen extends StatefulWidget {
  @override
  _NameEntryScreenState createState() => _NameEntryScreenState();
}

class _NameEntryScreenState extends State<NameEntryScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  // Stream for work choices with multilingual support
  Stream<List<WorkChoice>> get _workChoicesStream {
    return FirebaseFirestore.instance
        .collection('Metadata')
        .doc('WorkChoices')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || !snapshot.data()!.containsKey('choices')) {
        return [];
      }

      final List<dynamic> choices = snapshot.data()!['choices'];
      final workChoices =
          choices.map((choice) => WorkChoice.fromMap(choice)).toList();

      // Print choices in console
      workChoices.forEach((choice) {
        print(
            'Choice: ${choice.id}, EN: ${choice.en}, AR: ${choice.ar}, FR: ${choice.fr}');
      });

      return workChoices;
    });
  }

  final Set<String> _selectedChoices = {};

  String _getLocalizedWorkChoice(WorkChoice choice, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    switch (locale) {
      case 'ar':
        return choice.ar;
      case 'fr':
        return choice.fr ??
            choice.en; // Fallback to English if French not available
      default:
        return choice.en;
    }
  }

  void _saveProviderInfo() async {
    if (_selectedChoices.length != 1) {
      _showErrorDialog(AppLocalizations.of(context)!.selectTwoWorkChoices);
      return;
    }

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorDialog("User not authenticated.");
        return;
      }

      final DocumentReference userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      await userDoc.update({
        'selectedWorkChoices': _selectedChoices.toList(),
        'isSTEP_1': true,
      });

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/verification',
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
        title: Text(AppLocalizations.of(context)!.error),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(appLocalizations.selectYourServices)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 10),
            StreamBuilder<List<WorkChoice>>(
              stream: _workChoicesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error loading choices: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text('Loading choices...')
                      ],
                    ),
                  );
                }

                final workChoices = snapshot.data ?? [];

                if (workChoices.isEmpty) {
                  return Text('No choices available.');
                }

                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: workChoices.map((choice) {
                    final isSelected = _selectedChoices.contains(choice.id);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedChoices.remove(choice.id);
                          } else if (_selectedChoices.length < 1) {
                            _selectedChoices.add(choice.id);
                          } else {
                            _showErrorDialog(appLocalizations.selectOneChoice);
                          }
                        });
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.purple[300]
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                isSelected ? Colors.purple : Colors.grey[400]!,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _getLocalizedWorkChoice(choice, context),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            SizedBox(height: 40),
            GestureDetector(
              onTap: _saveProviderInfo,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF6A1B9A),
                      Color(0xFFAB47BC),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(0, 4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Text(
                  appLocalizations.continueButton,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Model class for WorkChoice
class WorkChoice {
  final String id;
  final String en;
  final String ar;
  final String? fr;

  WorkChoice({
    required this.id,
    required this.en,
    required this.ar,
    this.fr,
  });

  factory WorkChoice.fromMap(Map<String, dynamic> map) {
    return WorkChoice(
      id: map['id'] as String,
      en: map['en'] as String,
      ar: map['ar'] as String,
      fr: map['fr'] as String?,
    );
  }
}
