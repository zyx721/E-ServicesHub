import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

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
      body: ListView(
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: const AssetImage('assets/images/default_profile.png'),
              ),
              title: Text(
                'John Doe',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text('johndoe@example.com'),
              trailing: IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: () {
                  _verifyUser(context, 'staticRequestId', 'staticUserId');
                },
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VerificationDetailScreen(requestId: 'staticRequestId'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyUser(BuildContext context, String requestId, String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isVerified': true,
      });
      await _firestore
          .collection('verification_requests')
          .doc(requestId)
          .delete();
      debugPrint('User verified successfully');
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
}

class VerificationDetailScreen extends StatelessWidget {
  final String requestId;

  const VerificationDetailScreen({Key? key, required this.requestId})
      : super(key: key);

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
      body: FutureBuilder<DocumentSnapshot>(
        future:
            _firestore.collection('verification_requests').doc(requestId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requestData = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: requestData['faceImageURL'] != null
                        ? NetworkImage(requestData['faceImageURL'])
                        : const AssetImage('assets/images/default_profile.png')
                            as ImageProvider,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  requestData['name'] ?? 'Anonymous',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  requestData['email'] ?? 'No email',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'ID Document:',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                requestData['idImageURL'] != null
                    ? Image.network(requestData['idImageURL'])
                    : const Text('No ID document provided'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    _verifyUser(context, requestId, requestData['userId']);
                  },
                  child: Text(
                    'Verify User',
                    style: GoogleFonts.poppins(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _verifyUser(BuildContext context, String requestId, String userId) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    try {
      await _firestore.collection('users').doc(userId).update({
        'isVerified': true,
      });
      await _firestore
          .collection('verification_requests')
          .doc(requestId)
          .delete();
      debugPrint('User verified successfully');
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
}
