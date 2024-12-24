import 'package:flutter/material.dart';
import 'package:hanini_frontend/localization/app_localization.dart';

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

  static List<PopularServicesModel> getPopularServices(BuildContext context) {
    List<PopularServicesModel> popularServices = [];

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.houseCleaning ?? 'House Cleaning',
        color: Colors.blue, // Example color
        availableProviders: 12,
        iconPath: 'assets/services_icon/House_Cleaning.svg',
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.electricity ?? 'Electricity',
        color: Colors.orange, // Example color
        availableProviders: 8,
        iconPath: 'assets/services_icon/Electricity.svg',
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.plumbing ?? 'Plumbing',
        color: Colors.green, // Example color
        availableProviders: 10,
        iconPath: 'assets/services_icon/Plumbing.svg',
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.gardening ?? 'Gardening',
        color: Colors.greenAccent, // Example color
        availableProviders: 7,
        iconPath: 'assets/services_icon/Gardening.svg',
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.painting ?? 'Painting',
        color: Colors.red, // Example color
        availableProviders: 5,
        iconPath: 'assets/services_icon/Painting.svg',
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.carpentry ?? 'Carpentry',
        color: Colors.brown, // Example color
        availableProviders: 6,
        iconPath: 'assets/services_icon/Carpentry.svg',
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.acRepair ?? 'AC Repair',
        color: Colors.blueAccent, // Example color
        availableProviders: 9,
        iconPath: 'assets/services_icon/air-conditioner-svgrepo-com.svg',
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.vehicleRepair ?? 'Vehicle Repair',
        color: Colors.cyan, // Example color
        availableProviders: 3,
        iconPath: 'assets/services_icon/Vehicle_Repair.svg',
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.homeSecurity ?? 'Home Security',
        color: Colors.grey, // Example color
        availableProviders: 6,
        iconPath: 'assets/services_icon/Home_Security.svg',
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.windowCleaning ?? 'Window Cleaning',
        color: Colors.lightBlue, // Example color
        availableProviders: 8,
        iconPath: 'assets/services_icon/Window_Cleaning.svg',
      ),
    );

    return popularServices;
  }
}
