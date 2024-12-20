import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
class NotificationsPage extends StatelessWidget {
  final String userId;

  const NotificationsPage({required this.userId, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
          centerTitle: true,
          backgroundColor: theme.colorScheme.surface,
          title: Text(
            "Notifications",
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 20,
              letterSpacing: -0.5,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(65),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: TabBar(
                indicatorWeight: 3,
                indicatorColor: theme.colorScheme.primary,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.5),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
                indicatorSize: TabBarIndicatorSize.label,
                labelPadding: const EdgeInsets.symmetric(horizontal: 24),
                tabs: [
                  Tab(
                    height: 56,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.list_alt,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Listings",
                          style: TextStyle(
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    height: 56,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_outline,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Reviews",
                          style: TextStyle(
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Container(
          color: theme.colorScheme.surface.withOpacity(0.95),
          child: TabBarView(
            children: [
              Container(
                color: theme.colorScheme.surface.withOpacity(0.95),
                child: ListingsTab(userId: userId),
              ),
              Container(
                color: theme.colorScheme.surface.withOpacity(0.95),
                child: ReviewsTab(userId: userId),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class ListingsTab extends StatelessWidget {
  final String userId;

  ListingsTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Theme.of(context).primaryColor,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              tabs: const [
                Tab(
                  text: "Sent",
                  icon: Icon(Icons.send_outlined),
                  height: 56,
                ),
                Tab(
                  text: "Received",
                  icon: Icon(Icons.download_outlined),
                  height: 56,
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.grey[50],
              child: TabBarView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListingsList(userId: userId, type: "sent"),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListingsList(userId: userId, type: "received"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class ListingsList extends StatelessWidget {
  final String userId;
  final String type;

  const ListingsList({required this.userId, required this.type});

  Color _getStatusColor(String status, ThemeData theme) {
  switch (status.toLowerCase()) {
    case 'pending':
      return Colors.orange;
    case 'active':
      return Colors.green;
    case 'completed':
      return theme.colorScheme.primary;
    case 'cancelled':
      return Colors.red;
    case 'refused':
      return Colors.red.shade700;
    case 'counter_offer_sent':
    case 'counter_offer_received':
      return Colors.blue; // Or any color you prefer for negotiation states
    default:
      return theme.colorScheme.onSurface.withOpacity(0.6);
  }
}

  String _getStatusIcon(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return '⌛';
    case 'active':
      return '✓';
    case 'completed':
      return '★';
    case 'cancelled':
      return '×';
    case 'refused':
      return '✕';
    case 'counter_offer_sent':
    case 'counter_offer_received':
      return '💬'; // Or any icon you prefer for negotiation states
    default:
      return '•';
  }
}


Widget _buildNegotiationHistory(Map<String, dynamic> listing) {
  final negotiations = listing['negotiation_history'] as List<dynamic>? ?? [];
  if (negotiations.isEmpty) return const SizedBox.shrink();

  return StatefulBuilder(
    builder: (BuildContext context, StateSetter setState) {
      bool isExpanded = false;
      
      return Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ExpansionTile(
          title: Row(
            children: [
              const Icon(Icons.history, size: 20),
              const SizedBox(width: 2),
              Text(
                'Negotiation History',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${negotiations.length}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: negotiations.asMap().entries.map((entry) {
                  final index = entry.key;
                  final negotiation = entry.value;
                  final date = DateTime.parse(negotiation['timestamp']);
                  final formattedDate = DateFormat.yMMMd().add_jm().format(date);
                  final proposedBy = negotiation['proposed_by'];
                  final amount = negotiation['pay'];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    proposedBy == "sender" ? "Offer sent" : "Counter offer received",
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '\DZD $amount',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formattedDate,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );
    },
  );
}


   Future<void> _showNegotiationDialog(
    BuildContext context,
    Map<String, dynamic> listing,
  ) async {
    final TextEditingController payController = TextEditingController();
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Negotiate Price',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current offer: ${listing['pay']}',
              style: GoogleFonts.inter()),
            const SizedBox(height: 16),
            TextField(
              controller: payController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Your Counter Offer',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixText: 'DZD',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (payController.text.isNotEmpty) {
                await _updateListingWithNegotiation(
                  context,
                  listing,
                  payController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Send Offer'),
          ),
        ],
      ),
    );
  }

Future<void> _updateListingWithNegotiation(
  BuildContext context,
  Map<String, dynamic> listing,
  String newPay,
) async {
  try {
    final batch = FirebaseFirestore.instance.batch();
    
    // Get the correct sender and receiver UIDs
    final String currentUserId = userId; // Current user's ID
    final String senderUid = listing['senderUid'] ?? userId;
    final String receiverUid = listing['receiverUid'] ?? userId;
    
    final senderRef = FirebaseFirestore.instance
        .collection('users')
        .doc(senderUid);
    
    final receiverRef = FirebaseFirestore.instance
        .collection('users')
        .doc(receiverUid);

    // Determine if current user is sender or receiver
    final bool isCurrentUserSender = currentUserId == senderUid;
    
    // Set the status based on who's making the offer
    final String newSenderStatus = isCurrentUserSender ? "counter_offer_sent" : "counter_offer_received";
    final String newReceiverStatus = isCurrentUserSender ? "counter_offer_received" : "counter_offer_sent";
    
    // Create negotiation history entry
    final negotiationEntry = {
      'pay': newPay,
      'timestamp': DateTime.now().toIso8601String(),
      'proposed_by': isCurrentUserSender ? "sender" : "receiver"
    };

    // Update sender's listing
    final senderDoc = await senderRef.get();
    if (senderDoc.exists) {
      final sentListings = List<Map<String, dynamic>>.from(
        senderDoc.data()?['Listing_(sent)'] ?? []
      );
      final updatedSentListings = sentListings.map((item) {
        if (item['id'] == listing['id']) {
          final currentHistory = List<Map<String, dynamic>>.from(item['negotiation_history'] ?? []);
          return {
            ...item,
            'status': newSenderStatus,
            'pay': newPay,
            'negotiation_history': [...currentHistory, negotiationEntry]
          };
        }
        return item;
      }).toList();
      batch.update(senderRef, {'Listing_(sent)': updatedSentListings});
    }

    // Update receiver's listing
    final receiverDoc = await receiverRef.get();
    if (receiverDoc.exists) {
      final receivedListings = List<Map<String, dynamic>>.from(
        receiverDoc.data()?['Listing_(received)'] ?? []
      );
      final updatedReceivedListings = receivedListings.map((item) {
        if (item['id'] == listing['id']) {
          final currentHistory = List<Map<String, dynamic>>.from(item['negotiation_history'] ?? []);
          return {
            ...item,
            'status': newReceiverStatus,
            'pay': newPay,
            'negotiation_history': [...currentHistory, negotiationEntry]
          };
        }
        return item;
      }).toList();
      batch.update(receiverRef, {'Listing_(received)': updatedReceivedListings});
    }

    await batch.commit();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Counter offer of \DZD$newPay sent successfully'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Failed to send counter offer. Please try again.'),
        backgroundColor: Colors.red,
      ),
    );
    print('Error updating listing with negotiation: $e');
  }
}
  
  
  
  
 Widget _buildActionButtons(
    BuildContext context,
    Map<String, dynamic> listing,
    String status,
  ) {
    final userHasCounterOffer = (status.toLowerCase().contains('counter_offer_received'));

    if (type == "received" && status.toLowerCase() == 'pending') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => _updateListingStatus(context, 'refused', listing),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Refuse'),
          ),
          TextButton(
            onPressed: () => _showNegotiationDialog(context, listing),
            child: const Text('Negotiate'),
          ),
          ElevatedButton(
            onPressed: () => _updateListingStatus(context, 'active', listing),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Accept', style: TextStyle(fontSize: 11.5)),
          ),
        ],
      );
    } else if (userHasCounterOffer) {
      // Show buttons for counter_offer_received party
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => _updateListingStatus(context, 'refused', listing),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Refuse'),
          ),
          TextButton(
            onPressed: () => _showNegotiationDialog(context, listing),
            child: const Text('Counter Offer'),
          ),
          // The Accept button should appear only for the party with counter_offer_received
          ElevatedButton(
            onPressed: () => _updateListingStatus(context, 'active', listing),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Accept', style: TextStyle(fontSize: 11.5)),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
Future<void> _updateListingStatus(
  BuildContext context,
  String status,
  Map<String, dynamic> listing,
) async {
  try {
    // Use the current userId as fallback for senderUid
    final String senderUid = listing['senderUid'] ?? userId;  // Fallback to current user
    final String? receiverUid = listing['receiverUid'];
    
    // Now we only need to check receiverUid since senderUid has a fallback
    if (receiverUid == null) {
      print('Debug - listing data: $listing');
      throw Exception('Missing receiver UID in listing data');
    }

    final batch = FirebaseFirestore.instance.batch();
    
    // Get references with validated UIDs
    final senderRef = FirebaseFirestore.instance
        .collection('users')
        .doc(senderUid);
    
    final receiverRef = FirebaseFirestore.instance
        .collection('users')
        .doc(receiverUid);

    // Update sender's listing
    final senderDoc = await senderRef.get();
    if (senderDoc.exists) {
      final sentListings = List<Map<String, dynamic>>.from(
        senderDoc.data()?['Listing_(sent)'] ?? []
      );
      final updatedSentListings = sentListings.map((item) {
        if (item['id'] == listing['id']) {
          // Ensure we preserve the senderUid in the updated listing
          return {
            ...item,
            'status': status,
            'lastUpdated': DateTime.now().toIso8601String(),
            'senderUid': senderUid,  // Explicitly set senderUid
          };
        }
        return item;
      }).toList();
      
      batch.update(senderRef, {'Listing_(sent)': updatedSentListings});
    }

    // Update receiver's listing
    final receiverDoc = await receiverRef.get();
    if (receiverDoc.exists) {
      final receivedListings = List<Map<String, dynamic>>.from(
        receiverDoc.data()?['Listing_(received)'] ?? []
      );
      final updatedReceivedListings = receivedListings.map((item) {
        if (item['id'] == listing['id']) {
          // Ensure we preserve the senderUid in the updated listing
          return {
            ...item,
            'status': status,
            'lastUpdated': DateTime.now().toIso8601String(),
            'senderUid': senderUid,  // Explicitly set senderUid
          };
        }
        return item;
      }).toList();
      
      batch.update(receiverRef, {'Listing_(received)': updatedReceivedListings});
    }

    await batch.commit();

    // Success message
    String statusMessage;
    Color statusColor;
    
    switch (status.toLowerCase()) {
      case 'active':
        statusMessage = 'Listing accepted successfully';
        statusColor = Colors.green;
        break;
      case 'refused':
        statusMessage = 'Listing refused';
        statusColor = Colors.red;
        break;
      default:
        statusMessage = 'Listing status updated successfully';
        statusColor = Colors.blue;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(statusMessage),
        backgroundColor: statusColor,
      ),
    );
  } catch (e) {
    print('Error updating listing status: $e');
    print('Current user ID: $userId');
    print('Listing data: $listing');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to update listing status: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  
  @override
  Widget build(BuildContext context) {
    final collectionKey = type == "sent" ? 'Listing_(sent)' : 'Listing_(received)';
    final theme = Theme.of(context);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final listings = userData[collectionKey] as List<dynamic>? ?? [];

        if (listings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: theme.colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  "No listings available",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: listings.length,
          itemBuilder: (context, index) {
            final listing = listings[index];
            final date = DateTime.parse(listing['timestamp']);
            final formattedDate = DateFormat.yMMMd().add_jm().format(date);
            final status = listing['status'] ?? 'pending';

            return SizedBox(
              child: Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    // Handle tap event
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    listing['mainTitle'],
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                     
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(status, theme)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _getStatusIcon(status),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        Text(
                                          status.toUpperCase(),
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: _getStatusColor(status, theme),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: type == "sent"
                                    ? theme.colorScheme.primary.withOpacity(0.1)
                                    : theme.colorScheme.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    type == "sent"
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                    size: 16,
                                    color: type == "sent"
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.secondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    type == "sent" ? "Sent" : "Received",
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: type == "sent"
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          listing['description'],
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            _buildInfoItem(
                              icon: Icons.attach_money,
                              label: "Pay",
                              value: listing['pay'],
                              theme: theme,
                            ),
                            _buildInfoItem(
                              icon: Icons.location_on_outlined,
                              label: "Location",
                              value: listing['location'],
                              theme: theme,
                            ),
                            _buildInfoItem(
                              icon: Icons.access_time,
                              label: "Posted",
                              value: formattedDate,
                              theme: theme,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildNegotiationHistory(listing),
                          const SizedBox(height: 16),
                        _buildActionButtons(context, listing, status),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
        const SizedBox(width: 4),
        Text(
          "$label: ",
          style: GoogleFonts.inter(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
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
