import 'package:flutter/material.dart';
import 'package:hanini_frontend/screens/become_provider_screen/onboarding2.dart';

class SimpleUserProfile extends StatefulWidget {
  const SimpleUserProfile({Key? key}) : super(key: key);

  @override
  State<SimpleUserProfile> createState() => _SimpleUserProfileState();
}

class _SimpleUserProfileState extends State<SimpleUserProfile> {
  final double profileHeight = 150; // Increased the size of the profile picture
  final TextEditingController nameController =
      TextEditingController(text: 'Benmati Ziad');
  final TextEditingController aboutController = TextEditingController(
      text:
          'I am a regular user interested in browsing services and booking providers for my needs.');

  String aboutMe = 'I am a regular user interested in browsing services and booking providers for my needs.';
  String userName = 'Benmati Ziad';

  bool isEditMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: 50), // Added space at the top
          buildTop(),
          const SizedBox(height: 30), // More space below the profile picture
          buildProfileInfo(),
          const SizedBox(height: 80), // Button moved further down
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
      if (isEditMode) {
        // Save changes
        userName = nameController.text;
        aboutMe = aboutController.text;
      }
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
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 5,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: profileHeight / 2, // Increased radius for a larger avatar
                backgroundColor: Colors.grey.shade200,
                backgroundImage:
                    const AssetImage('assets/images/profile_picture.png'),
              ),
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
        const SizedBox(height: 16),
        isEditMode
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Name',
                  ),
                ),
              )
            : Text(
                userName,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold),
              ),
        const SizedBox(height: 6),
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
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'About Me',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              isEditMode
                  ? TextField(
                      controller: aboutController,
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
        ),
      ),
    );
  }

  // Modern "Become a Provider" Button
  Widget buildBecomeProviderButton() {
    return Center(
      child: InkWell(
        onTap: () {
          // Navigate to OnboardingScreen2
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => OnboardingScreen2()),
          );
        },
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF3949AB),
                Color(0xFF1E88E5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Center(
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
