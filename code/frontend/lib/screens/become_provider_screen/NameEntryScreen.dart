import 'package:flutter/material.dart';

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
                      isSelected
                          ? _selectedChoices.remove(choice)
                          : _selectedChoices.add(choice);
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
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 40),

            // Continue Button
            GestureDetector(
              onTap: () {
                // Proceed to the next page, passing the data
                String firstName = _firstNameController.text;
                String lastName = _lastNameController.text;
                print("First Name: $firstName");
                print("Last Name: $lastName");
                print("Selected Services: $_selectedChoices");

                // Navigate to the next screen
                Navigator.pushNamed(context, '/verification');
              },
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
            SizedBox(height: 20),

            // Skip Option
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/verification');
              },
              child: Text(
                "Skip for Now",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
