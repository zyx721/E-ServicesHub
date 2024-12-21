import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class UserManagementScreen extends StatelessWidget {
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
            'Confirm Delete',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete user "$userName"?',
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
                'Delete',
                style: GoogleFonts.poppins(
                  color: Colors.red,
                ),
              ),
              onPressed: () {
                _firestore.collection('users').doc(userId).delete();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showUserProfile(BuildContext context, Map<String, dynamic> userData) {
  // Format the timestamp for display
  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Not available';
    return timestamp.toDate().toString().split('.')[0]; // Remove milliseconds
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: userData['photoURL'] != null
                        ? NetworkImage(userData['photoURL'])
                        : const AssetImage('assets/images/default_profile.png')
                            as ImageProvider,
                  ),
                  if (userData['isProvider'] == true)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified,
                          size: 24,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                userData['name'] ?? 'Anonymous',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (userData['isProvider'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Service Provider',
                    style: GoogleFonts.poppins(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _buildProfileDetail(Icons.email, userData['email'] ?? 'No email'),
              if (userData['phone'] != null)
                _buildProfileDetail(Icons.phone, userData['phone']),
              if (userData['address'] != null)
                _buildProfileDetail(Icons.location_on, userData['address']),
              
              // Add connection status
              _buildProfileDetail(
                Icons.circle,
                userData['isConnected'] == true ? 'Online' : 'Offline',
                color: userData['isConnected'] == true ? Colors.green : Colors.grey,
              ),
              
              // Add created at date
              _buildProfileDetail(
                Icons.calendar_today,
                'Created: ${formatDate(userData['createdAt'])}',
              ),
              
              // Add last sign in date
              _buildProfileDetail(
                Icons.access_time,
                'Last Sign In: ${formatDate(userData['lastSignIn'])}',
              ),
              
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Close',
                  style: GoogleFonts.poppins(
                    color: Colors.blue,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// Updated _buildProfileDetail to support colored icons
Widget _buildProfileDetail(IconData icon, String text, {Color? color}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(icon, size: 20, color: color ?? Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 16,
            ),
          ),
        ),
      ],
    ),
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
              color: Colors.blue,
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
                  color: userData['isProvider'] == true ? Colors.blue : Colors.grey.shade300,
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
                            color: Colors.blue,
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
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility, color: Colors.blue),
                      onPressed: () => _showUserProfile(context, userData),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
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
          final providers = users.where((user) {
            final userData = user.data() as Map<String, dynamic>;
            return userData['isProvider'] == true;
          }).toList();
          
          final regularUsers = users.where((user) {
            final userData = user.data() as Map<String, dynamic>;
            return userData['isProvider'] != true;
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