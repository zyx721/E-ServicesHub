import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class UserManagementScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'User Management',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final userData = user.data() as Map<String, dynamic>?;

              if (userData == null) {
                return const SizedBox.shrink(); // Skip if userData is null
              }

              final bool isProvider = userData['isProvider'] ?? false;

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: userData.containsKey('photoURL') &&
                            userData['photoURL'] != null
                        ? NetworkImage(userData['photoURL'])
                        : const AssetImage('assets/images/default_profile.png')
                            as ImageProvider,
                  ),
                  title: Text(
                    userData.containsKey('name')
                        ? userData['name']
                        : 'Anonymous',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userData.containsKey('email')
                          ? userData['email']
                          : 'No email'),
                      const SizedBox(height: 4),
                      Text(
                        isProvider ? 'Provider' : 'Simple User',
                        style: TextStyle(
                          color: isProvider ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _firestore.collection('users').doc(user.id).delete();
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
