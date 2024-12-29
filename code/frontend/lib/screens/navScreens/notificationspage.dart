import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hanini_frontend/models/colors.dart';
import 'package:intl/intl.dart';
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

class NotificationsPage extends StatelessWidget {
  final String userId;

  const NotificationsPage({required this.userId, super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.mainGradient,
            ),
            child: AppBar(
              elevation: 0,
              centerTitle: true,
              backgroundColor: Colors.transparent,
              title: Padding(
                padding: const EdgeInsets.only(
                    top: 14.0), // Added padding to shift the title down
                child: Text(
                  localizations.notifications,
                  style: GoogleFonts.poppins(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(
                    60), // Adjusted size for better spacing
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  // padding: const EdgeInsets.symmetric(horizontal: 16), // Padding for tabs
                  child: Container(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TabBar(
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.purple,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.purple,
                tabs: [
                  Tab(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.list_alt),
                          SizedBox(width: 8),
                          Text(localizations.listings),
                        ],
                      ),
                    ),
                  ),
                  Tab(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_outline),
                          SizedBox(width: 8),
                          Text(localizations.reviews),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
                  ),
                ),
              ),
            ),
          ),
        ),
        body:
            TabBarView(
          children: [
            ListingsTab(userId: userId),
            ReviewsTab(userId: userId),
          ],
        ),
      ),
      // ),
    );
  }
}

class ListingsTab extends StatelessWidget {
  final String userId;

  ListingsTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return const SizedBox.shrink();

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
            child: Container(
              margin: EdgeInsets.only(top: 8),
              padding: EdgeInsets.all(16),
              child: TabBar(
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.purple,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.purple,
                  tabs: [
                    Tab(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.send_outlined),
                            SizedBox(width: 8),
                            Text(localizations.sent),
                          ],
                        ),
                      ),
                    ),
                    Tab( 
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.download_outlined),
                            SizedBox(width: 8),
                            Text(localizations.received),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
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

  Widget _buildNegotiationHistory(
      BuildContext context, Map<String, dynamic> listing) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return const SizedBox.shrink();

    final negotiations = listing['negotiation_history'] as List<dynamic>? ?? [];
    if (negotiations.isEmpty) return const SizedBox.shrink();

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {

        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.purple.withOpacity(0.1),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ExpansionTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.history, size: 18,color: Colors.purple,),
                const SizedBox(width: 2),
                Text(
                  localizations.negotiationHistory,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color:
                        Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${negotiations.length}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.purple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: negotiations.asMap().entries.map((entry) {
                    final index = entry.key;
                    final negotiation = entry.value;
                    final date = DateTime.parse(negotiation['timestamp']);
                    final formattedDate =
                        DateFormat.yMMMd().add_jm().format(date);
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
                              color: Colors.purple
                                  .withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.purple,
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      proposedBy == "sender"
                                          ? localizations.counterOfferSent
                                          : localizations
                                              .counterOfferReceivedText,
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
                                        color: Colors.purple
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '\DZD $amount',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: Colors.purple                                             ,
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
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return;
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.negotiatePrice,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                '${localizations.currentOffer} ${listing['pay']} ${localizations.dzd}',
                style: GoogleFonts.inter()),
            const SizedBox(height: 16),
            TextField(
              controller: payController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: localizations.yourCounterOffer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixText: "DZD",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
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
            child: Text(localizations.sendOffer),
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
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return;
    try {
      final batch = FirebaseFirestore.instance.batch();

      // Get the correct sender and receiver UIDs
      final String currentUserId = userId; // Current user's ID
      final String senderUid = listing['senderUid'] ?? userId;
      final String receiverUid = listing['receiverUid'] ?? userId;

      final String targetUid =
          currentUserId == senderUid ? receiverUid : senderUid;
      final String? targetToken = await _getDeviceToken(targetUid);

      final senderRef =
          FirebaseFirestore.instance.collection('users').doc(senderUid);

      final receiverRef =
          FirebaseFirestore.instance.collection('users').doc(receiverUid);

      // Determine if current user is sender or receiver
      final bool isCurrentUserSender = currentUserId == senderUid;

      // Set the status based on who's making the offer
      final String newSenderStatus =
          isCurrentUserSender ? "counter_offer_sent" : "counter_offer_received";
      final String newReceiverStatus =
          isCurrentUserSender ? "counter_offer_received" : "counter_offer_sent";

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
            senderDoc.data()?['Listing_(sent)'] ?? []);
        final updatedSentListings = sentListings.map((item) {
          if (item['id'] == listing['id']) {
            final currentHistory = List<Map<String, dynamic>>.from(
                item['negotiation_history'] ?? []);
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
            receiverDoc.data()?['Listing_(received)'] ?? []);
        final updatedReceivedListings = receivedListings.map((item) {
          if (item['id'] == listing['id']) {
            final currentHistory = List<Map<String, dynamic>>.from(
                item['negotiation_history'] ?? []);
            return {
              ...item,
              'status': newReceiverStatus,
              'pay': newPay,
              'negotiation_history': [...currentHistory, negotiationEntry]
            };
          }
          return item;
        }).toList();
        batch.update(
            receiverRef, {'Listing_(received)': updatedReceivedListings});
      }

      await batch.commit();

      // Send notification about counter offer
      if (targetToken != null) {
        final notificationTitle = localizations.newCounterOffer;
        final notificationBody =
            '${localizations.youReceivedCounterOfferOf} ${localizations.dzd}$newPay ${localizations.forText} "${listing['mainTitle']}"';
        final notificationData = {
          'type': 'counter_offer',
          'listingId': listing['id'],
          'newAmount': newPay
        };

        await PushNotificationService.sendNotification(
            targetToken, notificationTitle, notificationBody, notificationData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${localizations.youSentCounterOfferOf} ${newPay} ${localizations.dzd} ${localizations.successfully}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.failedToSendCounterOffer),
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
    final userHasCounterOffer =
        (status.toLowerCase().contains('counter_offer_received'));
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return const SizedBox.shrink();
    if (type == "received" && status.toLowerCase() == 'pending') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => _updateListingStatus(context, 'refused', listing),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(localizations.refuse),
          ),
          TextButton(
            onPressed: () => _showNegotiationDialog(context, listing),
            child: Text(localizations.negotiate),
          ),
          ElevatedButton(
            onPressed: () => _updateListingStatus(context, 'active', listing),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(localizations.accept, style: TextStyle(fontSize: 11.5)),
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
            child: Text(localizations.refuse), // one
          ),
          TextButton(
            onPressed: () => _showNegotiationDialog(context, listing),
            child: Text(localizations.negotiate),
          ),
          // The Accept button should appear only for the party with counter_offer_received
          ElevatedButton(
            onPressed: () => _updateListingStatus(context, 'active', listing),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(localizations.accept, style: TextStyle(fontSize: 11.5)),
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
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return;

    try {
      // Use the current userId as fallback for senderUid
      final String senderUid =
          listing['senderUid'] ?? userId; // Fallback to current user
      final String receiverUid = listing['receiverUid'];

      final String? senderToken = await _getDeviceToken(senderUid);
      final String? receiverToken = await _getDeviceToken(receiverUid);

      final batch = FirebaseFirestore.instance.batch();

      // Get references with validated UIDs
      final senderRef =
          FirebaseFirestore.instance.collection('users').doc(senderUid);

      final receiverRef =
          FirebaseFirestore.instance.collection('users').doc(receiverUid);

      // Update sender's listing
      final senderDoc = await senderRef.get();
      if (senderDoc.exists) {
        final sentListings = List<Map<String, dynamic>>.from(
            senderDoc.data()?['Listing_(sent)'] ?? []);
        final updatedSentListings = sentListings.map((item) {
          if (item['id'] == listing['id']) {
            // Ensure we preserve the senderUid in the updated listing
            return {
              ...item,
              'status': status,
              'lastUpdated': DateTime.now().toIso8601String(),
              'senderUid': senderUid, // Explicitly set senderUid
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
            receiverDoc.data()?['Listing_(received)'] ?? []);
        final updatedReceivedListings = receivedListings.map((item) {
          if (item['id'] == listing['id']) {
            // Ensure we preserve the senderUid in the updated listing
            return {
              ...item,
              'status': status,
              'lastUpdated': DateTime.now().toIso8601String(),
              'senderUid': senderUid, // Explicitly set senderUid
            };
          }
          return item;
        }).toList();

        batch.update(
            receiverRef, {'Listing_(received)': updatedReceivedListings});
      }

      await batch.commit();

      // Send notifications based on status
      String notificationTitle;
      String notificationBody;
      Map<String, dynamic> notificationData = {
        'type': 'listing_update',
        'listingId': listing['id'],
        'status': status
      };

      switch (status.toLowerCase()) {
        case 'active':
          // Notify receiver
          if (receiverToken != null) {
            notificationTitle = 'Listing Accepted';
            notificationBody =
                'Your listing "${listing['mainTitle']}" has been accepted!';
            await PushNotificationService.sendNotification(receiverToken,
                notificationTitle, notificationBody, notificationData);
          }

          // Notify sender
          if (senderToken != null) {
            notificationTitle = 'Listing Status Update';
            notificationBody =
                'Your offer for "${listing['mainTitle']}" has been accepted';
            await PushNotificationService.sendNotification(senderToken,
                notificationTitle, notificationBody, notificationData);
          }
          break;

        case 'refused':
          // Notify receiver
          if (receiverToken != null) {
            notificationTitle = localizations.listingRefused;
            notificationBody =
                'Your listing "${listing['mainTitle']}" has been refused';
            await PushNotificationService.sendNotification(receiverToken,
                notificationTitle, notificationBody, notificationData);
          }

          // Notify sender
          if (senderToken != null) {
            notificationTitle = 'Listing Status Update';
            notificationBody =
                'Your offer for "${listing['mainTitle']}" was not accepted';
            await PushNotificationService.sendNotification(senderToken,
                notificationTitle, notificationBody, notificationData);
          }
          break;
      }
      // Success message
      String statusMessage;
      Color statusColor;

      switch (status.toLowerCase()) {
        case 'active':
          statusMessage = localizations.listingAcceptedSuccessfully;
          statusColor = Colors.green;
          break;
        case 'refused':
          statusMessage = localizations.listingRefused;
          statusColor = Colors.red;
          break;
        default:
          statusMessage = localizations.listingStatusUpdatedSuccessfully;
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
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return const SizedBox.shrink();
    final collectionKey =
        type == "sent" ? 'Listing_(sent)' : 'Listing_(received)';
    final theme = Theme.of(context);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
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
                  localizations.noListingsAvailable,
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
                                          status.toLowerCase() == 'active'
                                              ? localizations.active
                                              : status.toLowerCase() ==
                                                      'refused'
                                                  ? localizations.refuse
                                                  : status.toLowerCase() ==
                                                          'pending'
                                                      ? localizations.pending
                                                      : status.toLowerCase() ==
                                                              'completed'
                                                          ? localizations
                                                              .completed
                                                          : status.toLowerCase() ==
                                                                  'cancelled'
                                                              ? localizations
                                                                  .canceled
                                                              : status.toLowerCase() ==
                                                                      'counter_offer_sent'
                                                                  ? localizations
                                                                      .counterOfferSent
                                                                  : status.toLowerCase() ==
                                                                          'counter_offer_received'
                                                                      ? localizations
                                                                          .counterOfferReceived
                                                                      : status
                                                                          .toUpperCase(),
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color:
                                                _getStatusColor(status, theme),
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
                                    ? Colors.purple.withOpacity(0.1)
                                    : Colors.purple
                                        .withOpacity(0.1),
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
                                        ? Colors.purple
                                        : Colors.purple,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    type == "sent"
                                        ? localizations.sent
                                        : localizations.received,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: type == "sent"
                                          ? Colors.purple
                                          : Colors.purple,
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
                              label: localizations.pay,
                              value: listing['pay'],
                              theme: theme,
                            ),
                            _buildInfoItem(
                              icon: Icons.location_on_outlined,
                              label: localizations.location,
                              value: listing['location'],
                              theme: theme,
                            ),
                            _buildInfoItem(
                              icon: Icons.access_time,
                              label: localizations.posted,
                              value: formattedDate,
                              theme: theme,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildNegotiationHistory(context, listing),
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
    final userDoc = await _firestore.collection('users').doc(widget.userId).get();
    final userData = userDoc.data() as Map<String, dynamic>? ?? {};
    setState(() {
      final timestampString = userData['last_viewed_reviews'] as String?;
      if (timestampString != null) {
        lastViewedTimestamp = DateTime.parse(timestampString);
      }
    });
  }

  Future<void> _updateLastViewedTimestamp() async {
    final now = DateTime.now();
    await _firestore.collection('users').doc(widget.userId).update({
      'last_viewed_reviews': now.toIso8601String(),
      'newCommentsCount': 0,
    });
  }

  @override
  void dispose() {
    _updateLastViewedTimestamp();
    super.dispose();
  }

  Widget _buildNewTag() {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.fiber_new_rounded,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            'NEW',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return const SizedBox.shrink();

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
              localizations.noReviewsAvailable,
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
                        localizations.noReviewsAvailable,
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
                        final reviewTimestamp = timestamp.isNotEmpty
                            ? DateTime.parse(timestamp)
                            : null;

                        final isNew = lastViewedTimestamp != null &&
                            reviewTimestamp != null &&
                            reviewTimestamp.isAfter(lastViewedTimestamp!);

                        final formattedTimestamp = reviewTimestamp != null
                            ? DateFormat('MMM d, yyyy • h:mm a').format(reviewTimestamp)
                            : 'Unknown time';

                        return FutureBuilder<DocumentSnapshot>(
                          future: _firestore.collection('users').doc(commenterId).get(),
                          builder: (context, commenterSnapshot) {
                            if (commenterSnapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final commenterData =
                                commenterSnapshot.data?.data() as Map<String, dynamic>? ?? {};
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
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        commenterName,
                                                        style: GoogleFonts.poppins(
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                formattedTimestamp,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: Colors.grey[500],
                                                ),
                                              ),

                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              _buildStarRating(rating),
                                              if (isNew) _buildNewTag(),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
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
