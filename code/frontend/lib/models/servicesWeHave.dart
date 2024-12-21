import 'package:flutter/material.dart';

class PopularServicesModel {
  String name;
  Color color;
  int availableProviders;
  String iconPath; // Added iconPath for each service's image

  PopularServicesModel({
    required this.name,
    required this.color,
    required this.availableProviders,
    required this.iconPath, // Include iconPath in the constructor
  });

  static List<PopularServicesModel> getPopularServices() {
    List<PopularServicesModel> popularServices = [];

    popularServices.add(
      PopularServicesModel(
        name: 'House Cleaning',
        color: Colors.blue, // Example color
        availableProviders: 12,
        iconPath: 'assets/icons/house_cleaning.png', // Path to image
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: 'Electricity',
        color: Colors.orange, // Example color
        availableProviders: 8,
        iconPath: 'assets/icons/electricity.png', // Path to image
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: 'Plumbing',
        color: Colors.green, // Example color
        availableProviders: 10,
        iconPath: 'assets/icons/plumbing.png', // Path to image
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: 'Gardening',
        color: Colors.greenAccent, // Example color
        availableProviders: 7,
        iconPath: 'assets/icons/gardening.png', // Path to image
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: 'Painting',
        color: Colors.red, // Example color
        availableProviders: 5,
        iconPath: 'assets/icons/painting.png', // Path to image
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: 'Carpentry',
        color: Colors.brown, // Example color
        availableProviders: 6,
        iconPath: 'assets/icons/carpentry.png', // Path to image
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: 'AC Repair',
        color: Colors.blueAccent, // Example color
        availableProviders: 9,
        iconPath: 'assets/icons/ac_repair.png', // Path to image
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: 'Vehicle Repair',
        color: Colors.cyan, // Example color
        availableProviders: 3,
        iconPath: 'assets/icons/vehicle_repair.png', // Path to image
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: 'Appliance Installation',
        color: Colors.yellow, // Example color
        availableProviders: 11,
        iconPath: 'assets/icons/appliance_installation.png', // Path to image
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: 'Home Security',
        color: Colors.grey, // Example color
        availableProviders: 6,
        iconPath: 'assets/icons/home_security.png', // Path to image
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: 'Window Cleaning',
        color: Colors.lightBlue, // Example color
        availableProviders: 8,
        iconPath: 'assets/icons/window_cleaning.png', // Path to image
      ),
    );

    return popularServices;
  }
}
