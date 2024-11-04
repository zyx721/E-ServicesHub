import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ServiceDetailScreen extends StatelessWidget {
  final String serviceName;
  final String imagePath;
  final String providerName;
  final double rating;

  const ServiceDetailScreen({
    Key? key,
    required this.serviceName,
    required this.imagePath,
    required this.providerName,
    required this.rating,
    required String description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(serviceName, style: GoogleFonts.poppins(fontSize: 20)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.asset(imagePath, height: 200, fit: BoxFit.cover),
                ),
              ),
              SizedBox(height: 20),
              Text(
                serviceName,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Provided by: $providerName',
                style:
                    GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
              ),
              Text(
                'Rating: ${rating.toStringAsFixed(1)}',
                style:
                    GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
              ),
              SizedBox(height: 20),
              Text(
                'Detailed description of the service. This could include features, benefits, availability, pricing, and other details that help the user understand what this service offers.',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Implement booking functionality here
                },
                child: Text('Book Now',
                    style: GoogleFonts.poppins(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
