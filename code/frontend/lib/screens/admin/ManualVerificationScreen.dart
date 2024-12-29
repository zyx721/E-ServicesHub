import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:hanini_frontend/localization/app_localization.dart';

// Add this method to fetch device token
Future<String?> _getDeviceToken(String userId) async {
  try {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.data()?['deviceToken'] as String?;
  } catch (e) {
    print('Error fetching device token: $e');
    return null;
  }
}

class PushNotificationService {
  static Future<String> getAccessToken() async {
    // Load the service account JSON
    final serviceAccountJson =
        await rootBundle.loadString('assets/credentials/test.json');

    // Define the required scopes
    List<String> scopes = [
      "https://www.googleapis.com/auth/firebase.database",
      "https://www.googleapis.com/auth/firebase.messaging"
    ];

    // Create a client using the service account credentials
    final auth.ServiceAccountCredentials credentials =
        auth.ServiceAccountCredentials.fromJson(serviceAccountJson);

    final auth.AuthClient client =
        await auth.clientViaServiceAccount(credentials, scopes);

    // Retrieve the access token
    final String accessToken = client.credentials.accessToken.data;

    // Close the client to avoid resource leaks
    client.close();

    return accessToken;
  }

  static Future<void> sendNotification(String deviceToken, String title,
      String body, Map<String, dynamic> data) async {
    final String serverKey = await getAccessToken();
    String endpointFirebaseCloudMessaging =
        'https://fcm.googleapis.com/v1/projects/hanini-2024/messages:send';

    final Map<String, dynamic> message = {
      'message': {
        'token': deviceToken,
        'notification': {
          'title': title,
          'body': body,
        },
        'data': data,
      }
    };

    final http.Response response = await http.post(
      Uri.parse(endpointFirebaseCloudMessaging),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $serverKey',
      },
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print('Notification sent successfully');
    } else {
      print('Failed to send notification');
      print('Response: ${response.body}');
    }
  }
}

class ManualVerificationScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.manualVerificationTitle,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('verification_requests').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading requests',
                style: GoogleFonts.poppins(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!.docs;

          if (requests.isEmpty) {
            return Center(
              child: Text(
                'No pending verification requests',
                style: GoogleFonts.poppins(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: requests.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final request = requests[index].data() as Map<String, dynamic>;
              final requestId = requests[index].id;
              final userId = request['userId'];

              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('users').doc(userId).get(),
                builder:
                    (context, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator.adaptive());
                  }

                  if (userSnapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading user data: ${userSnapshot.error}',
                        style: GoogleFonts.poppins(color: Colors.red),
                      ),
                    );
                  }

                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return Center(
                      child: Text(
                        'User data not found',
                        style: GoogleFonts.poppins(color: Colors.grey[600]),
                      ),
                    );
                  }

                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;

                  return Card(
                    elevation: 3,
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundImage: userData['photoURL'] != null
                            ? NetworkImage(userData['photoURL'])
                            : const AssetImage(
                                    'assets/images/default_profile.png')
                                as ImageProvider,
                      ),
                      title: Text(
                        userData['name'] ?? 'Anonymous',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userData['email'] ?? 'No email',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            'Submitted: ${_formatDate(request['timestamp'])}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.search, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VerificationDetailScreen(
                                requestId: requestId,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(String? timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final date = DateTime.parse(timestamp);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  Future<void> _verifyUser(
    BuildContext context,
    String requestId,
    String userId,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isSTEP_2': true,
        'isWaiting': false,
      });
      await _firestore
          .collection('verification_requests')
          .doc(requestId)
          .delete();

      // Send notification
      final deviceToken = await _getDeviceToken(userId);
      if (deviceToken != null) {
        await PushNotificationService.sendNotification(
          deviceToken,
          'Verification Successful',
          'Your account has been successfully verified! You now have full access to all features.',
          {
            'type': 'verification',
            'status': 'success',
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User verified successfully')),
      );
    } catch (e) {
      debugPrint('Error verifying user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error verifying user')),
      );
    }
  }

  Future<void> _rejectRequest(
    BuildContext context,
    String requestId,
    String userId,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isWaiting': false,
      });
      await _firestore
          .collection('verification_requests')
          .doc(requestId)
          .delete();

      final deviceToken = await _getDeviceToken(userId);
      if (deviceToken != null) {
        await PushNotificationService.sendNotification(
          deviceToken,
          'Verification Update',
          'Your verification request was not approved. Please ensure all submitted documents meet our requirements and try again.',
          {
            'type': 'verification',
            'status': 'rejected',
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request rejected')),
      );
    } catch (e) {
      debugPrint('Error rejecting request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error rejecting request')),
      );
    }
  }
}

class VerificationDetailScreen extends StatelessWidget {
  final String requestId;

  VerificationDetailScreen({Key? key, required this.requestId})
      : super(key: key);

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();

  void _showFullScreenImage(
      BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                top: 40,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateUserInfo(
      String userId, String firstName, String lastName) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'firstName': firstName,
      'lastName': lastName,
    });
  }

  Widget _buildUserInfoCard(
      Map<String, dynamic> userData, Map<String, dynamic> requestData) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey[200],
              backgroundImage: _getUserAvatar(userData['photoURL'] as String?),
              child: userData['photoURL'] == null
                  ? Icon(Icons.person, size: 40, color: Colors.grey[400])
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              requestData['name'] as String? ?? 'No name',
              style: GoogleFonts.poppins(
                fontSize: 20,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              requestData['email'] as String? ?? 'No email',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: firstNameController,
              decoration: InputDecoration(
                labelText: 'First Name',
                labelStyle: GoogleFonts.poppins(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: lastNameController,
              decoration: InputDecoration(
                labelText: 'Last Name',
                labelStyle: GoogleFonts.poppins(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyUser(
    BuildContext context,
    String requestId,
    String userId,
  ) async {
    try {
      await _updateUserInfo(
          userId, firstNameController.text, lastNameController.text);
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isSTEP_2': true,
        'isWaiting': false,
      });
      await FirebaseFirestore.instance
          .collection('verification_requests')
          .doc(requestId)
          .delete();

      final deviceToken = await _getDeviceToken(userId);
      if (deviceToken != null) {
        await PushNotificationService.sendNotification(
          deviceToken,
          'Verification Successful',
          'Your account has been successfully verified! You now have full access to all features.',
          {
            'type': 'verification',
            'status': 'success',
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User verified successfully')),
      );
    } catch (e) {
      debugPrint('Error verifying user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error verifying user')),
      );
    }
  }

  Future<void> _rejectUser(
      BuildContext context, String requestId, String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isWaiting': false,
      });
      await FirebaseFirestore.instance
          .collection('verification_requests')
          .doc(requestId)
          .delete();

      final deviceToken = await _getDeviceToken(userId);
      if (deviceToken != null) {
        await PushNotificationService.sendNotification(
          deviceToken,
          'Verification Update',
          'Your verification request was not approved. Please ensure all submitted documents meet our requirements and try again.',
          {
            'type': 'verification',
            'status': 'rejected',
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification request rejected')),
      );
    } catch (e) {
      debugPrint('Error rejecting user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error rejecting request')),
      );
    }
  }

  Widget _buildActionButtons(
    BuildContext context,
    String requestId,
    Map<String, dynamic> requestData,
    TextEditingController firstNameController,
    TextEditingController lastNameController,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.check_circle_outline),
          label: Text(
            'Approve Verification',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            if (firstNameController.text.trim().isEmpty ||
                lastNameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Please fill in both First Name and Last Name fields.',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            _updateUserInfo(
              requestData['userId'],
              firstNameController.text,
              lastNameController.text,
            );
            _verifyUser(
              context,
              requestId,
              requestData['userId'] as String,
            );
          },
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.cancel_outlined),
          label: Text(
            'Reject Verification',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => _rejectUser(
            context,
            requestId,
            requestData['userId'],
          ),
        ),
      ],
    );
  }

  Widget _buildImageTile(
      BuildContext context, String title, String? imageUrl, bool isCircular) {
    if (imageUrl == null) {
      return ListTile(
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('No image provided'),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          InkWell(
            onTap: () => _showFullScreenImage(context, imageUrl, title),
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: isCircular
                  ? Center(
                      child: CircleAvatar(
                        radius: 80,
                        backgroundImage: NetworkImage(imageUrl),
                      ),
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.zoom_in),
                  label: Text(
                    'View Full Size',
                    style: GoogleFonts.poppins(),
                  ),
                  onPressed: () =>
                      _showFullScreenImage(context, imageUrl, title),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Verification Details',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            _firestore.collection('verification_requests').doc(requestId).get(),
        builder: (context, AsyncSnapshot<DocumentSnapshot> requestSnapshot) {
          if (requestSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (requestSnapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('Error loading data: ${requestSnapshot.error}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.red[300],
                        fontWeight: FontWeight.w500,
                      )),
                ],
              ),
            );
          }

          if (!requestSnapshot.hasData || !requestSnapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_off, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Verification request not found',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      )),
                ],
              ),
            );
          }

          final requestData =
              requestSnapshot.data!.data() as Map<String, dynamic>;
          final userId = requestData['userId'] as String?;

          if (userId == null) {
            return Center(
              child: Text('Invalid request data: Missing user ID',
                  style: GoogleFonts.poppins(color: Colors.red)),
            );
          }

          return FutureBuilder<DocumentSnapshot>(
            future: _firestore.collection('users').doc(userId).get(),
            builder: (context, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator.adaptive());
              }

              if (userSnapshot.hasError) {
                return Center(
                  child: Text('Error loading user data: ${userSnapshot.error}',
                      style: GoogleFonts.poppins(color: Colors.red)),
                );
              }

              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                return Center(
                  child: Text('User data not found',
                      style: GoogleFonts.poppins(color: Colors.grey[600])),
                );
              }

              final userData =
                  userSnapshot.data!.data() as Map<String, dynamic>;
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withOpacity(0.0),
                          ],
                          stops: const [0.0, 0.2],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: _buildUserInfoCard(userData, requestData),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildVerificationDocuments(context, requestData),
                        const SizedBox(height: 24),
                        _buildActionButtons(
                          context,
                          requestId,
                          requestData,
                          firstNameController,
                          lastNameController,
                        ),
                        const SizedBox(height: 32),
                      ]),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildVerificationDocuments(
      BuildContext context, Map<String, dynamic> requestData) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.folder_special_rounded,
                color: Theme.of(context).primaryColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Verification Documents',
                style: GoogleFonts.poppins(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Please review the submitted documents carefully',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),
          _buildDocumentCard(
            context: context,
            title: 'Profile Photo',
            subtitle: 'Facial verification image',
            icon: Icons.face,
            imageUrl: requestData['faceImageURL'] as String?,
          ),
          const SizedBox(height: 16),
          _buildDocumentCard(
            context: context,
            title: 'ID Document',
            subtitle: 'Government-issued identification',
            icon: Icons.badge,
            imageUrl: requestData['idImageURL'] as String?,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required String? imageUrl,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (imageUrl != null)
                  IconButton(
                    icon: const Icon(Icons.fullscreen),
                    onPressed: () =>
                        _showFullScreenImage(context, imageUrl, title),
                    tooltip: 'View Full Size',
                  ),
              ],
            ),
          ),
          if (imageUrl != null)
            InkWell(
              onTap: () => _showFullScreenImage(context, imageUrl, title),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  child: Hero(
                    tag: imageUrl,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported,
                        color: Colors.grey[400], size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'No image provided',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  ImageProvider _getUserAvatar(String? photoURL) {
    if (photoURL != null && photoURL.isNotEmpty) {
      return NetworkImage(photoURL);
    }
    return const AssetImage('assets/images/default_profile.png');
  }
}
