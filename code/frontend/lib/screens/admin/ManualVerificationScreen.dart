import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:googleapis_auth/auth_io.dart' as auth;


// Add this method to fetch device token
Future<String?> _getDeviceToken(String userId) async {
  try {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    return userDoc.data()?['deviceToken'] as String?;
  } catch (e) {
    print('Error fetching device token: $e');
    return null;
  }
}

class PushNotificationService {
  static Future<String> getAccessToken() async {
    // Load the service account JSON
    final serviceAccountJson =await rootBundle.loadString(
        'assets/credentials/test.json'
      );

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

  static Future<void> sendNotification(
      String deviceToken, String title, String body, Map<String, dynamic> data) async {
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manual Verification',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.orange,
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

              return Card(
  elevation: 3,
  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
  child: ListTile(
    leading: CircleAvatar(
      backgroundImage: request['faceImageURL'] != null
          ? NetworkImage(request['faceImageURL'])
          : const AssetImage('assets/images/default_profile.png') as ImageProvider,
    ),
    title: Text(
      request['name'] ?? 'Anonymous',
      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
    ),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          request['email'] ?? 'No email',
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
    trailing: PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'verify') {
          _verifyUser(context, requestId, request['userId']);
        } else if (value == 'view') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerificationDetailScreen(
                requestId: requestId,
              ),
            ),
          );
        } else if (value == 'reject') {
          _rejectRequest(context, requestId, request['userId']);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'verify',
          child: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
              SizedBox(width: 8),
              Text('Verify'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.visibility, color: Colors.blue, size: 18),
              SizedBox(width: 8),
              Text('View Details'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'reject',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red, size: 18),
              SizedBox(width: 8),
              Text('Reject'),
            ],
          ),
        ),
      ],
      child: const Icon(Icons.more_vert),
    ),
  ),
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

  const VerificationDetailScreen({Key? key, required this.requestId})
      : super(key: key);

  void _showFullScreenImage(BuildContext context, String imageUrl, String title) {
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  Widget _buildImageTile(BuildContext context, String title, String? imageUrl, bool isCircular) {
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
                onPressed: () => _showFullScreenImage(context, imageUrl, title),
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
      title: Text(
        'Verification Details',
        style: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.orange,
    ),
    body: FutureBuilder<List<DocumentSnapshot>>(
      future: Future.wait([
        _firestore.collection('verification_requests').doc(requestId).get(),
        _firestore.collection('users').doc(requestId).get(),
      ]),
      builder: (context, AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading data: ${snapshot.error}',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty || snapshot.data!.length != 2) {
          return Center(
            child: Text(
              'No data available',
              style: GoogleFonts.poppins(),
            ),
          );
        }

        final requestData = snapshot.data![0].data() as Map<String, dynamic>? ?? {};
        final userData = snapshot.data![1].data() as Map<String, dynamic>? ?? {};

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserInfoCard(userData, requestData),
                const SizedBox(height: 16),
                _buildImageTile(
                  context,
                  'Profile Photo',
                  requestData['faceImageURL'] as String?,
                  false,
                ),
                _buildImageTile(
                  context,
                  'ID Document',
                  requestData['idImageURL'] as String?,
                  false,
                ),
                const SizedBox(height: 20),
                _buildActionButtons(context, requestId, requestData),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Widget _buildUserInfoCard(Map<String, dynamic> userData, Map<String, dynamic> requestData) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: _getUserAvatar(userData['photoURL'] as String?),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User Information',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim(),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  requestData['email'] as String? ?? 'No email',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

ImageProvider _getUserAvatar(String? photoURL) {
  if (photoURL != null && photoURL.isNotEmpty) {
    return NetworkImage(photoURL);
  }
  return const AssetImage('assets/images/default_profile.png');
}

Widget _buildActionButtons(BuildContext context, String requestId, Map<String, dynamic> requestData) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.green,
        ),
        onPressed: () => _verifyUser(
          context,
          requestId,
          requestData['userId'] as String,
        ),
        child: Text(
          'Verify User',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(height: 12),
      OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          foregroundColor: Colors.red,
        ),
        onPressed: () => _rejectUser(
          context,
          requestId,
          requestData['userId'] ,
        ),
        child: Text(
          'Reject Verification',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ],
  );
}
  Future<void> _verifyUser(
      BuildContext context, String requestId, String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isSTEP_2': true,
        'isWaiting': false,
      });
      await FirebaseFirestore.instance
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
}