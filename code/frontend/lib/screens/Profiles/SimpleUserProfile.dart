import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hanini_frontend/localization/app_localization.dart';
import 'package:hanini_frontend/screens/Profiles/AdminProfile.dart';
import 'package:hanini_frontend/screens/become_provider_screen/onboarding2.dart';

class SimpleUserProfile extends StatefulWidget {
  const SimpleUserProfile({Key? key}) : super(key: key);

  @override
  State<SimpleUserProfile> createState() => _SimpleUserProfileState();
}

class _SimpleUserProfileState extends State<SimpleUserProfile> {
  final double profileHeight = 150;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String userName = '';
  String userEmail = '';
  String userPhotoUrl = '';
  String aboutMe = '';
  bool isEditMode = false;
  bool isLoading = true;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            userName = data['name'] ?? 'Anonymous';
            userEmail = data['email'] ?? 'No email';
            userPhotoUrl = data['photoURL'] ?? '';
            aboutMe = data['aboutMe'] ?? 'Tell us about yourself';
            nameController.text = userName;
            aboutController.text = aboutMe;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  Future<void> saveUserData() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        // Update Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'name': userName,
          'aboutMe': aboutMe,
        });

        // Update FirebaseAuth user profile
        await user.updateDisplayName(userName);
        await user.reload(); // Refresh the current user
        debugPrint('User data updated successfully');
      }
    } catch (e) {
      debugPrint('Error saving user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? localization = AppLocalizations.of(context); // Get localization

    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 50),
                buildTop(localization!),
                const SizedBox(height: 30),
                buildProfileInfo(localization),
                const SizedBox(height: 60),
                buildBecomeProviderButton(localization),
                const SizedBox(height: 20),
                buildBecomeAdminButton(), // Add the temporary button here
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: toggleEditMode,
        child: Icon(isEditMode ? Icons.check : Icons.edit),
        tooltip: isEditMode ? localization?.save : localization?.editProfile, // Use localization
      ),
    );
  }

  void toggleEditMode() {
    setState(() {
      if (isEditMode) {
        // Save changes
        userName = nameController.text;
        aboutMe = aboutController.text;
        saveUserData();
      }
      isEditMode = !isEditMode;
    });
  }

  Widget buildTop(AppLocalizations localization) {
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
                radius: profileHeight / 2,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: userPhotoUrl.isNotEmpty
                    ? NetworkImage(userPhotoUrl) as ImageProvider
                    : const AssetImage('assets/images/default_profile.png'),
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
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: localization.name, // Use localization
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
          userEmail,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  Widget buildProfileInfo(AppLocalizations localization) {
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
              Text(
                localization.aboutMe, // Use localization
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              isEditMode
                  ? TextField(
                      controller: aboutController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: localization.aboutMe, // Use localization
                      ),
                    )
                  : Text(
                      aboutMe,
                      style:
                          TextStyle(fontSize: 14, color: Colors.grey.shade700),
                      textAlign: TextAlign.justify,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildBecomeProviderButton(AppLocalizations localization) {
    return Center(
      child: InkWell(
        onTap: () {
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
          child: Center(
            child: Text(
              localization.becomeProviderButton, // Use localization
              style: const TextStyle(
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

  Widget buildBecomeAdminButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () async {
          await makeUserAdmin();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminProfile()),
          );
        },
        child: Text('Become Admin'),
      ),
    );
  }

  Future<void> makeUserAdmin() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'isAdmin': true,
        });
        debugPrint('User is now an admin');
      }
    } catch (e) {
      debugPrint('Error making user admin: $e');
    }
  }
}
