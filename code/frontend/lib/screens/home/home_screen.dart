import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hanini', style: GoogleFonts.poppins(fontSize: 20)),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              // Handle notifications
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            SizedBox(height: 20),
            Text(
              'Available Services',
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            // Add your service list or grid here
            Expanded(
              child: ListView.builder(
                itemCount: 10, // Replace with your service count
                itemBuilder: (context, index) {
                  return _buildServiceItem('Service ${index + 1}');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search for services...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.blue),
        ),
        prefixIcon: Icon(Icons.search, color: Colors.blue),
      ),
    );
  }

  Widget _buildServiceItem(String serviceName) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        title: Text(serviceName, style: GoogleFonts.poppins(fontSize: 18)),
        subtitle: Text('Description of $serviceName', style: GoogleFonts.poppins(fontSize: 14)),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: () {
          // Navigate to service details or booking page
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'Menu',
              style: GoogleFonts.poppins(fontSize: 24, color: Colors.white),
            ),
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Profile', style: GoogleFonts.poppins()),
            onTap: () {
              // Navigate to profile screen
              Navigator.pop(context); // Close the drawer
              Navigator.pushNamed(context, '/profile');
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings', style: GoogleFonts.poppins()),
            onTap: () {
              // Navigate to settings screen
              Navigator.pop(context); // Close the drawer
              Navigator.pushNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: Icon(Icons.language),
            title: Text('Language', style: GoogleFonts.poppins()),
            onTap: () {
              // Show language selection dialog or navigate to language settings
              Navigator.pop(context); // Close the drawer
              // TODO: Implement language selection
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout', style: GoogleFonts.poppins()),
            onTap: () {
              // Handle logout logic
              Navigator.pop(context); // Close the drawer
            },
          ),
        ],
      ),
    );
  }
}
