import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class Addadmin extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  void _showDeleteConfirmation(BuildContext context, String userId, String userName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Confirm Addition',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to Add user "$userName" as an Admin"?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text(
                'ADD',
                style: GoogleFonts.poppins(
                  color: Colors.red,
                ),
              ),
              onPressed: () {
                Map<String, dynamic> profileData = {'isAdmin': true,};
                _firestore.collection('users').doc(userId).update(profileData);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

 

  Widget _buildUserSection(String title, List<QueryDocumentSnapshot> users) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 106, 10, 10),
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final userData = user.data() as Map<String, dynamic>;

            return Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: userData['isProvider'] == true ? const Color.fromARGB(255, 106, 10, 10) : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: ListTile(
                leading: Stack(
                  children: [
                    CircleAvatar(
                      backgroundImage: userData['photoURL'] != null
                          ? NetworkImage(userData['photoURL'])
                          : const AssetImage('assets/images/default_profile.png')
                              as ImageProvider,
                    ),
                    if (userData['isProvider'] == true)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified,
                            size: 14,
                            color: const Color.fromARGB(255, 106, 10, 10),
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  userData['name'] ?? 'Anonymous',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userData['email'] ?? 'No email',
                      style: GoogleFonts.poppins(),
                    ),
                    if (userData['isProvider'] == true)
                      Text(
                        'Service Provider',
                        style: GoogleFonts.poppins(
                          color: const Color.fromARGB(255, 106, 10, 10),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.red),
                      onPressed: () => _showDeleteConfirmation(
                        context,
                        user.id,
                        userData['name'] ?? 'Anonymous',
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Admin',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 106, 10, 10),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;
final providers = users.where((user) {
  final userData = user.data() as Map<String, dynamic>;
  return userData['isProvider'] == true && userData['isAdmin'] != true;
}).toList();

final regularUsers = users.where((user) {
  final userData = user.data() as Map<String, dynamic>;
  return userData['isProvider'] != true && userData['isAdmin'] != true;
}).toList();


          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (providers.isNotEmpty)
                  _buildUserSection('Service Providers', providers),
                _buildUserSection('Regular Users', regularUsers),
              ],
            ),
          );
        },
      ),
    );
  }
}