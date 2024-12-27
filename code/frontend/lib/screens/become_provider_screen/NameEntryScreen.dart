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
  String? _selectedChoice;

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

  Future<void> _incrementWorkChoiceCount(String choiceId) async {
    final docRef = FirebaseFirestore.instance.collection('Metadata').doc('WorkChoices');
    
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;
      
      final choices = List<Map<String, dynamic>>.from(snapshot.data()!['choices']);
      final index = choices.indexWhere((choice) => choice['id'] == choiceId);
      
      if (index != -1) {
        choices[index]['count'] = (choices[index]['count'] ?? 0) + 1;
        transaction.update(docRef, {'choices': choices});
      }
    });
  }

  void _saveProviderInfo() async {
    if (_selectedChoice == null) {
      _showErrorDialog(AppLocalizations.of(context)!.selectOneChoice);
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorDialog("User not authenticated.");
        return;
      }

      await _incrementWorkChoiceCount(_selectedChoice!);
      
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'selectedWorkChoice': _selectedChoice,
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
    final appLocalizations = AppLocalizations.of(context)!;

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
                  return Center(child: CircularProgressIndicator());
                }

                final workChoices = snapshot.data ?? [];
                if (workChoices.isEmpty) return Text('No choices available.');

                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: workChoices.map((choice) {
                    final isSelected = _selectedChoice == choice.id;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedChoice = choice.id);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.purple[300] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Colors.purple : Colors.grey[400]!,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _getLocalizedWorkChoice(choice, context),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
                    colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
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