import 'package:flutter/material.dart';

class SimpleUserProfile extends StatefulWidget {
  const SimpleUserProfile({Key? key}) : super(key: key);

  @override
  State<SimpleUserProfile> createState() => _SimpleUserProfileState();
}

class _SimpleUserProfileState extends State<SimpleUserProfile> {
  final double profileHeight = 120;
  String aboutMe =
      'I am a regular user interested in browsing services and booking providers for my needs.';
  
  bool isEditMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          buildTop(),
          const SizedBox(height: 16),
          buildProfileInfo(),
          const SizedBox(height: 24),
          buildBecomeProviderButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: toggleEditMode,
        child: Icon(isEditMode ? Icons.check : Icons.edit),
        tooltip: isEditMode ? 'Save Changes' : 'Edit Profile',
      ),
    );
  }

  void toggleEditMode() {
    setState(() {
      isEditMode = !isEditMode;
    });
  }

  // Top Profile Section
  Widget buildTop() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: profileHeight / 2,
              backgroundColor: Colors.grey.shade200,
              backgroundImage:
                  const AssetImage('assets/images/profile_picture.png'),
            ),
            if (isEditMode)
              GestureDetector(
                onTap: () {
                  pickNewProfilePicture();
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Benmati Ziad',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'benmatiziad5@gmail.com',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  // Main Profile Information
  Widget buildProfileInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: const Text(
              'About Me',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          isEditMode
              ? TextField(
                  controller: TextEditingController(text: aboutMe),
                  onChanged: (value) => aboutMe = value,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Write about yourself...',
                  ),
                )
              : Text(
                  aboutMe,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  textAlign: TextAlign.justify,
                ),
        ],
      ),
    );
  }

  // "Become a Provider" Button
  Widget buildBecomeProviderButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: () {
          // Logic to navigate to provider registration screen
          print("Navigate to become a provider screen.");
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF3949AB),
                Color(0xFF1E88E5),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              'Become a Provider',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Placeholder methods
  void pickNewProfilePicture() {
    debugPrint('Profile picture update triggered!');
  }
}
