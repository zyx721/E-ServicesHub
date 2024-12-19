import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatelessWidget {
  final String userId;

  NotificationsPage({required this.userId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Notifications"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Demands"),
              Tab(text: "Reviews"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            DemandsTab(userId: userId),
            ReviewsTab(userId: userId),
          ],
        ),
      ),
    );
  }
}

class DemandsTab extends StatelessWidget {
  final String userId;

  DemandsTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    final _firestore = FirebaseFirestore.instance;

    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error fetching demands. Please try again later.',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(
            child: Text(
              'No demands available.',
              style: GoogleFonts.poppins(fontSize: 16, fontStyle: FontStyle.italic),
            ),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final demands = userData['demands'] ?? [];

        return Column(
          children: [
            Expanded(
              child: demands.isEmpty
                  ? Center(
                      child: Text(
                        'No demands available.',
                        style: GoogleFonts.poppins(fontSize: 16, fontStyle: FontStyle.italic),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: demands.length,
                      itemBuilder: (context, index) {
                        final demand = demands[index] as Map<String, dynamic>;
                        final description = demand['description'] ?? 'No description provided';
                        final requesterId = demand['requester_id'] ?? 'Unknown';
                        final date = demand['date'] ?? 'Unknown date';

                        return FutureBuilder<DocumentSnapshot>(
                          future: _firestore.collection('users').doc(requesterId).get(),
                          builder: (context, requesterSnapshot) {
                            if (requesterSnapshot.connectionState == ConnectionState.waiting) {
                              return const SizedBox(
                                  height: 60, child: Center(child: CircularProgressIndicator()));
                            }

                            final requesterData =
                                requesterSnapshot.data?.data() as Map<String, dynamic>? ?? {};
                            final requesterName = requesterData['name'] ?? 'Anonymous';
                            final requesterPhoto =
                                requesterData['photoURL'] ?? '';

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage: requesterPhoto.isNotEmpty
                                          ? NetworkImage(requesterPhoto)
                                          : const AssetImage(
                                                  'assets/images/default_profile.png')
                                              as ImageProvider,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            requesterName,
                                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            date,
                                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            description,
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
                    ),
            ),
          ],
        );
      },
    );
  }
}

class ReviewsTab extends StatefulWidget {
  final String userId;

  ReviewsTab({required this.userId});

  @override
  _ReviewsTabState createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<ReviewsTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime? lastViewedTimestamp;

  @override
  void initState() {
    super.initState();
    _loadLastViewedTimestamp();
  }

  Future<void> _loadLastViewedTimestamp() async {
    // Fetch the last viewed timestamp from Firestore (or local storage)
    final userDoc = await _firestore.collection('users').doc(widget.userId).get();
    final userData = userDoc.data() as Map<String, dynamic>? ?? {};
    setState(() {
      final timestampString = userData['last_viewed_reviews'] as String?; // Stored as ISO 8601 string
      if (timestampString != null) {
        lastViewedTimestamp = DateTime.parse(timestampString);
      }
    });
  }

  Future<void> _updateLastViewedTimestamp() async {
    // Update the last viewed timestamp in Firestore
    final now = DateTime.now();
    await _firestore.collection('users').doc(widget.userId).update({
      'last_viewed_reviews': now.toIso8601String(),
      'newCommentsCount':0,
    });
  }

  @override
  void dispose() {
    // Update the timestamp when the user leaves the page
    _updateLastViewedTimestamp();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(widget.userId).get(),
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

        return Column(
          children: [
            Expanded(
              child: reviews.isEmpty
                  ? Center(
                      child: Text(
                        'No reviews available.',
                        style: GoogleFonts.poppins(
                            fontSize: 16, fontStyle: FontStyle.italic),
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
                        final reviewTimestamp = timestamp.isNotEmpty
                            ? DateTime.parse(timestamp)
                            : null;

                        // Determine if the review is "new"
                        final isNew = lastViewedTimestamp != null &&
                            reviewTimestamp != null &&
                            reviewTimestamp.isAfter(lastViewedTimestamp!);

                        // Parse and format the timestamp
                        final formattedTimestamp = reviewTimestamp != null
                            ? DateFormat('MMM d, yyyy • h:mm a').format(reviewTimestamp)
                            : 'Unknown time';

                        return FutureBuilder<DocumentSnapshot>(
                          future: _firestore.collection('users').doc(commenterId).get(),
                          builder: (context, commenterSnapshot) {
                            if (commenterSnapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
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
        CircleAvatar(
          radius: 20,
          backgroundImage: commenterPhoto.isNotEmpty
              ? NetworkImage(commenterPhoto)
              : const AssetImage('assets/images/default_profile.png')
                  as ImageProvider,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          commenterName,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
              const SizedBox(height: 6),
              _buildStarRating(rating),
              const SizedBox(height: 8),
              ],
              ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formattedTimestamp,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      if (isNew)
                        Row(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'NEW',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
                Text(
                comment,
                style: GoogleFonts.poppins(
                  color: Colors.grey[700],
                  fontSize: 13,
                ),
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
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.yellow,
          size: 18,
        );
      }),
    );
  }
}
