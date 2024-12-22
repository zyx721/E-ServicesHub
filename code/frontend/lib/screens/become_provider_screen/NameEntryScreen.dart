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

  // Stream for work choices with debug prints
  Stream<List<String>> get _workChoicesStream {
    return FirebaseFirestore.instance
        .collection('Metadata')
        .doc('WorkChoices')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return [];
      }
      // Changed from 'choices' to 'WorkChoices'
      if (!snapshot.data()!.containsKey('WorkChoices')) {
        return [];
      }
      return List<String>.from(snapshot.data()!['WorkChoices']);
    });
  }

  // To track selected services
  final Set<String> _selectedChoices = {};

  // Let's also try a direct fetch method for testing
  Future<void> _testFetch() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Metadata')
          .doc('WorkChoices')
          .get();
      print("Direct fetch result: ${doc.data()}");
    } catch (e) {
      print("Error in direct fetch: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _testFetch(); // Test the Firebase connection
  }

  void _saveProviderInfo() async {
    final String firstName = _firstNameController.text.trim();
    final String lastName = _lastNameController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      _showErrorDialog(AppLocalizations.of(context)!.firstNameLastNameRequired);
      return;
    }

    if (_selectedChoices.length != 2) {
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
        'firstName': firstName,
        'lastName': lastName,
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
      appBar: AppBar(title: Text(appLocalizations.enterYourDetails)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextField(
              controller: _firstNameController,
              decoration:
                  InputDecoration(labelText: appLocalizations.firstName),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(labelText: appLocalizations.lastName),
            ),
            SizedBox(height: 30),
            Text(
              appLocalizations.selectYourServices,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 10),
            StreamBuilder<List<String>>(
              stream: _workChoicesStream,
              builder: (context, snapshot) {
                // Add more detailed error and state handling
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
                  ));
                }

                final workChoices = snapshot.data ?? [];

                if (workChoices.isEmpty) {
                  return Text(
                      'No choices available. Please check Firebase configuration.');
                }

                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: workChoices.map((choice) {
                    final isSelected = _selectedChoices.contains(choice);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedChoices.remove(choice);
                          } else if (_selectedChoices.length < 2) {
                            _selectedChoices.add(choice);
                          } else {
                            _showErrorDialog(appLocalizations.selectTwoChoices);
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
                          choice,
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
