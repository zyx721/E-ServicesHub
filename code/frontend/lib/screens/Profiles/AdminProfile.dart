import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hanini_frontend/localization/app_localization.dart';
import 'package:hanini_frontend/screens/admin/UserManagementScreen.dart';
import 'package:hanini_frontend/screens/admin/ServiceManagementScreen.dart';
import 'package:hanini_frontend/screens/admin/ManualVerificationScreen.dart'; // Import ManualVerificationScreen

class AdminProfile extends StatefulWidget {
  const AdminProfile({Key? key}) : super(key: key);

  @override
  State<AdminProfile> createState() => _AdminProfileState();
}

class _AdminProfileState extends State<AdminProfile> {
  final double profileHeight = 150;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String adminName = '';
  String adminEmail = '';
  String adminPhotoUrl = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAdminData();
  }

  Future<void> fetchAdminData() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            adminName = data['name'] ?? 'Admin';
            adminEmail = data['email'] ?? 'No email';
            adminPhotoUrl = data['photoURL'] ?? '';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching admin data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? localization = AppLocalizations.of(context);

    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.zero,
              children: [
                buildTop(localization!),
                const SizedBox(height: 20),
                buildAdminActions(localization),
              ],
            ),
      resizeToAvoidBottomInset: false,
    );
  }

  Widget buildTop(AppLocalizations localization) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: profileHeight / 2,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: adminPhotoUrl.isNotEmpty
                    ? NetworkImage(adminPhotoUrl) as ImageProvider
                    : const AssetImage('assets/images/default_profile.png'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            adminName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            adminEmail,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget buildAdminActions(AppLocalizations localization) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          buildActionCard(
            localization.manageUsers,
            Icons.people,
            Colors.blue,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserManagementScreen()),
              );
            },
          ),
          const SizedBox(height: 20),
          buildActionCard(
            localization.manageServices,
            Icons.build,
            Colors.green,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ServiceManagementScreen()),
              );
            },
          ),
          const SizedBox(height: 20),
          buildActionCard(
            localization.manualVerification,
            Icons.verified_user,
            Colors.orange,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ManualVerificationScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
