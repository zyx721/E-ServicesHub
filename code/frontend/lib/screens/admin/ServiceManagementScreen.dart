import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class ServiceManagementScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Service Management',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('services').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final services = snapshot.data!.docs;

          return ListView.builder(
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              final serviceData = service.data() as Map<String, dynamic>;

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: serviceData['imageURL'] != null
                        ? NetworkImage(serviceData['imageURL'])
                        : const AssetImage('assets/images/default_service.png')
                            as ImageProvider,
                  ),
                  title: Text(
                    serviceData['name'] ?? 'Unnamed Service',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle:
                      Text(serviceData['description'] ?? 'No description'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _firestore
                          .collection('services')
                          .doc(service.id)
                          .delete();
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ServiceDetailScreen(serviceId: service.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ServiceDetailScreen extends StatelessWidget {
  final String serviceId;

  const ServiceDetailScreen({Key? key, required this.serviceId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Service Details',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _firestore.collection('services').doc(serviceId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final serviceData = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: serviceData['imageURL'] != null
                        ? NetworkImage(serviceData['imageURL'])
                        : const AssetImage('assets/images/default_service.png')
                            as ImageProvider,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  serviceData['name'] ?? 'Unnamed Service',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  serviceData['description'] ?? 'No description',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Category: ${serviceData['category'] ?? 'Unknown'}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Price: ${serviceData['price'] ?? 'Unknown'}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    _showEditServiceDialog(context, serviceData);
                  },
                  child: Text(
                    'Edit Service',
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

  void _showEditServiceDialog(
      BuildContext context, Map<String, dynamic> serviceData) {
    final _formKey = GlobalKey<FormState>();
    String name = serviceData['name'] ?? '';
    String description = serviceData['description'] ?? '';
    String category = serviceData['category'] ?? '';
    String price = serviceData['price'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Edit Service',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  initialValue: name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a name' : null,
                  onSaved: (value) => name = value!,
                ),
                TextFormField(
                  initialValue: description,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a description' : null,
                  onSaved: (value) => description = value!,
                ),
                TextFormField(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a category' : null,
                  onSaved: (value) => category = value!,
                ),
                TextFormField(
                  initialValue: price,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a price' : null,
                  onSaved: (value) => price = value!,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();

                          // Update service data in Firestore
                          await FirebaseFirestore.instance
                              .collection('services')
                              .doc(serviceData['id'])
                              .update({
                            'name': name,
                            'description': description,
                            'category': category,
                            'price': price,
                          });

                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Service updated successfully!')),
                          );
                        }
                      },
                      child: Text(
                        'Save',
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
