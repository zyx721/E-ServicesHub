import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ProviderReviewsScreen extends StatelessWidget {
  final String providerId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ProviderReviewsScreen({Key? key, required this.providerId}) : super(key: key);

  Future<void> _deleteReview(BuildContext context, List<dynamic> reviews, int index) async {
    try {
      // Create a new list without the deleted review
      final updatedReviews = List<dynamic>.from(reviews);
      updatedReviews.removeAt(index);

      // Update Firestore
      await _firestore.collection('users').doc(providerId).update({
        'reviews': updatedReviews,
      });

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete review'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context, List<dynamic> reviews, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Review',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete this review?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteReview(context, reviews, index);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Provider Reviews',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.amber,
      ),
      body: StreamBuilder<DocumentSnapshot>( // Changed to StreamBuilder to update in real-time
        stream: _firestore.collection('users').doc(providerId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error fetching reviews. Please try again later.',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                'No reviews available.',
                style: GoogleFonts.poppins(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            );
          }

          final providerData = snapshot.data!.data() as Map<String, dynamic>;
          final reviews = providerData['reviews'] ?? [];

          return reviews.isEmpty
              ? Center(
                  child: Text(
                    'No reviews available.',
                    style: GoogleFonts.poppins(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index] as Map<String, dynamic>;
                    final comment = review['comment'] ?? 'No comment provided';
                    final commenterId = review['id_commentor'] ?? 'Unknown';
                    final rating = review['rating']?.toDouble() ?? 0.0;
                    final timestamp = review['timestamp'] ?? '';

                    final formattedTimestamp = timestamp.isNotEmpty
                        ? DateFormat('MMM d, yyyy • h:mm a').format(
                            DateTime.parse(timestamp),
                          )
                        : 'Unknown time';

                    return FutureBuilder<DocumentSnapshot>(
                      future: _firestore.collection('users').doc(commenterId).get(),
                      builder: (context, commenterSnapshot) {
                        if (commenterSnapshot.connectionState == ConnectionState.waiting) {
                          return const Card(
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          );
                        }

                        final commenterData = commenterSnapshot.data?.data() as Map<String, dynamic>? ?? {};
                        final commenterName = commenterData['name'] ?? 'Anonymous';
                        final commenterPhoto = commenterData['photoURL'] ?? '';

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage: commenterPhoto.isNotEmpty
                                          ? NetworkImage(commenterPhoto)
                                          : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                                    ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                                onPressed: () => _showDeleteConfirmation(context, reviews, index),
                                              ),
                                  ],
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            commenterName,
                                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                formattedTimestamp,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: List.generate(5, (index) {
                                          if (index < rating.floor()) {
                                            return const Icon(Icons.star, color: Colors.amber, size: 16);
                                          } else if (index < rating.ceil() && rating.truncateToDouble() != rating) {
                                            return const Icon(Icons.star_half, color: Colors.amber, size: 16);
                                          } else {
                                            return const Icon(Icons.star_border, color: Colors.amber, size: 16);
                                          }
                                        }),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        comment,
                                        style: GoogleFonts.poppins(color: Colors.grey[700]),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
}


class CommentManagementScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CommentManagementScreen({Key? key}) : super(key: key);

  Widget _buildUserSection(String title, List<QueryDocumentSnapshot> users) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
        ),
        
        // Users List
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: users.length,
          itemBuilder: (context, index) => _buildUserCard(context, users[index]),
        ),
      ],
    );
  }

  Widget _buildUserCard(BuildContext context, QueryDocumentSnapshot user) {
    final userData = user.data() as Map<String, dynamic>;
    final isProvider = userData['isProvider'] == true;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isProvider ? Colors.amber : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: _buildUserAvatar(userData),
        title: _buildUserName(userData),
        subtitle: _buildUserDetails(userData),
        trailing: _buildActionButtons(context, user),
      ),
    );
  }

  Widget _buildUserAvatar(Map<String, dynamic> userData) {
    return Stack(
      children: [
        // User Avatar
        CircleAvatar(
          backgroundImage: userData['photoURL'] != null
              ? NetworkImage(userData['photoURL'])
              : const AssetImage('assets/images/default_profile.png')
                  as ImageProvider,
        ),
        
        // Provider Badge
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
                color: Colors.amber,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUserName(Map<String, dynamic> userData) {
    return Text(
      userData['name'] ?? 'Anonymous',
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildUserDetails(Map<String, dynamic> userData) {
    return Column(
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
              color: Colors.amber,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, QueryDocumentSnapshot user) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProviderReviewsScreen(providerId: user.id),
      ),
    );
  },
  child: Icon(
    Icons.star, // Star icon
    color: Colors.amber, // Color of the icon
    size: 30, // Size of the icon
  ),
),

      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Comment Management',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.amber,
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

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (providers.isNotEmpty)
                  _buildUserSection('Service Providers', providers),
              ],
            ),
          );
        },
      ),
    );
  }
}
