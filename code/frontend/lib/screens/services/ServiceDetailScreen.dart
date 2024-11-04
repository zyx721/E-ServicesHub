import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ServiceDetailScreen extends StatelessWidget {
  final String serviceName;
  final String imagePath;
  final String providerName;
  final String providerProfileImage;
  final double rating;

  const ServiceDetailScreen({
    Key? key,
    required this.serviceName,
    required this.imagePath,
    required this.providerName,
    required this.providerProfileImage,
    required this.rating,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(serviceName, style: GoogleFonts.poppins(fontSize: 20)),
        backgroundColor: Colors.blue,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(),
            const SizedBox(height: 20),
            _buildServiceTitle(),
            const SizedBox(height: 15),
            _buildProviderInfo(),
            const SizedBox(height: 15),
            _buildRatingSection(),
            const SizedBox(height: 20),
            _buildDescription(),
            const SizedBox(height: 20),
            _buildContactInfo(),
            const SizedBox(height: 20),
            _buildReviewsSection(),
            const SizedBox(height: 20),
            _buildBookingButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Image.asset(
        imagePath,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildServiceTitle() {
    return Text(
      serviceName,
      style: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildProviderInfo() {
    return Row(
      children: [
        ClipOval(
          child: Image.asset(
            providerProfileImage,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          providerName,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSection() {
    return Row(
      children: [
        Text(
          'Rating: ',
          style: GoogleFonts.poppins(fontSize: 16),
        ),
        for (int i = 0; i < 5; i++)
          Icon(
            i < rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 20,
          ),
        SizedBox(width: 10),
        Text(
          '($rating)',
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      'This section provides a detailed description of the $serviceName. You can include an in-depth explanation of the services offered, pricing details, the types of tasks the service covers, and any special requirements or qualifications of the provider.',
      style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
    );
  }

  Widget _buildContactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Information',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          'Phone: +123456789\nEmail: example@example.com',
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reviews',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _buildReviewTile('John Doe', 'Excellent service, very professional!'),
        _buildReviewTile('Jane Smith', 'I would highly recommend this service.'),
      ],
    );
  }

  Widget _buildReviewTile(String reviewer, String review) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const Icon(Icons.person, color: Colors.blue, size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reviewer,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  review,
                  style: GoogleFonts.poppins(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingButton(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          // Implement booking functionality here
        },
        child: Text(
          'Book Now',
          style: GoogleFonts.poppins(fontSize: 18),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
