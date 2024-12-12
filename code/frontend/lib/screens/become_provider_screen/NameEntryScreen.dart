import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NameEntryScreen extends StatefulWidget {
  @override
  _NameEntryScreenState createState() => _NameEntryScreenState();
}

class _NameEntryScreenState extends State<NameEntryScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  // List of service categories
  final List<String> _workChoices = [
    "House Cleaning",
    "Electricity",
    "Plumbing",
    "Gardening",
    "Painting",
    "Carpentry",
    "Pest Control",
    "AC Repair",
    "Vehicle Repair",
    "Appliance Installation",
    "IT Support",
    "Home Security",
    "Interior Design",
    "Window Cleaning",
    "Furniture Assembly",
  ];

  // To track selected services
  final Set<String> _selectedChoices = {};

  void _saveProviderInfo() async {
    final String firstName = _firstNameController.text.trim();
    final String lastName = _lastNameController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      _showErrorDialog("First Name and Last Name are required.");
      return;
    }

    if (_selectedChoices.length != 2) {
      _showErrorDialog("Please select exactly two work choices.");
      return;
    }

    try {
      // Get the current user's UID
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorDialog("User not authenticated.");
        return;
      }

      // Reference Firestore document
      final DocumentReference userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      // Update Firestore with the new information
      await userDoc.update({
        'firstName': firstName,
        'lastName': lastName,
        'selectedWorkChoices': _selectedChoices.toList(),
      });

      // Navigate to verification screen
      Navigator.pushNamed(context, '/verification');
    } catch (e) {
      _showErrorDialog("Failed to save data: $e");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Enter Your Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // First Name TextField
            TextField(
              controller: _firstNameController,
              decoration: InputDecoration(labelText: 'First Name'),
            ),
            SizedBox(height: 20),

            // Last Name TextField
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(labelText: 'Last Name'),
            ),
            SizedBox(height: 30),

            // Work Choice Grid
            Text(
              "Select Your Services:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _workChoices.map((choice) {
                final isSelected = _selectedChoices.contains(choice);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedChoices.remove(choice);
                      } else if (_selectedChoices.length < 2) {
                        _selectedChoices.add(choice);
                      } else {
                        _showErrorDialog("You can only select two choices.");
                      }
                    });
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
            ),
            SizedBox(height: 40),

            // Continue Button
            GestureDetector(
              onTap: _saveProviderInfo,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF6A1B9A), // Start color
                      Color(0xFFAB47BC), // End color
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
                  "Continue",
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
