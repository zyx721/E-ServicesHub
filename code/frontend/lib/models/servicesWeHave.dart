import 'package:flutter/material.dart';
import 'package:hanini_frontend/localization/app_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
 // Add this import

class PopularServicesModel {
  String name;
  Color color;
  int availableProviders;
  String iconPath;

  PopularServicesModel({
    required this.name,
    required this.color,
    required this.availableProviders,
    required this.iconPath,
  });

  static Future<List<PopularServicesModel>> getPopularServices(BuildContext context) async {
    List<PopularServicesModel> popularServices = [];
    
    // Fetch the WorkChoices metadata
    final metadata = await FirebaseFirestore.instance
        .collection('Metadata')
        .doc('WorkChoices')
        .get();
    
    final choices = metadata.data()?['choices'] as List<dynamic>;

    // Helper function to find count by service ID
    int getCountById(String serviceId) {
      final service = choices.firstWhere(
        (choice) => choice['id'] == serviceId,
        orElse: () => {'count': 0},
      );
      return service['count'] ?? 0;
    }

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.houseCleaning ?? 'House Cleaning',
        color: Colors.blue,
        availableProviders: getCountById('houseCleaning'),
        iconPath: 'assets/services_icon/House_Cleaning.svg',
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.electricity ?? 'Electricity',
        color: Colors.orange,
        availableProviders: getCountById('electricity'),
        iconPath: 'assets/services_icon/Electricity.svg',
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.plumbing ?? 'Plumbing',
        color: Colors.green,
        availableProviders: getCountById('plumbing'),
        iconPath: 'assets/services_icon/Plumbing.svg',
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.gardening ?? 'Gardening',
        color: Colors.greenAccent,
        availableProviders: getCountById('gardening'),
        iconPath: 'assets/services_icon/Gardening.svg',
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.painting ?? 'Painting',
        color: Colors.red,
        availableProviders: getCountById('painting'),
        iconPath: 'assets/services_icon/Painting.svg',
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.carpentry ?? 'Carpentry',
        color: Colors.brown,
        availableProviders: getCountById('carpentry'),
        iconPath: 'assets/services_icon/Carpentry.svg',
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.pestControl ?? 'Pest Control',
        color: Colors.purple,
        availableProviders: getCountById('pestControl'),
        iconPath: 'assets/services_icon/Pest_Control.svg',
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.acRepair ?? 'AC Repair',
        color: Colors.blueAccent,
        availableProviders: getCountById('acRepair'),
        iconPath: 'assets/services_icon/air-conditioner-svgrepo-com.svg',
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.vehicleRepair ?? 'Vehicle Repair',
        color: Colors.cyan,
        availableProviders: getCountById('vehicleRepair'),
        iconPath: 'assets/services_icon/Vehicle_Repair.svg',
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.applianceInstallation ?? 'Appliance Installation',
        color: Colors.teal,
        availableProviders: getCountById('applianceInstallation'),
        iconPath: 'assets/services_icon/Appliance_Installation.svg',
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.itSupport ?? 'IT Support',
        color: Colors.indigo,
        availableProviders: getCountById('itSupport'),
        iconPath: 'assets/services_icon/IT_Support.svg',
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.homeSecurity ?? 'Home Security',
        color: Colors.grey,
        availableProviders: getCountById('homeSecurity'),
        iconPath: 'assets/services_icon/Home_Security.svg',
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.interiorDesign ?? 'Interior Design',
        color: Colors.deepPurple,
        availableProviders: getCountById('interiorDesign'),
        iconPath: 'assets/services_icon/Interior_Design.svg',
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.windowCleaning ?? 'Window Cleaning',
        color: Colors.lightBlue,
        availableProviders: getCountById('windowCleaning'),
        iconPath: 'assets/services_icon/Window_Cleaning.svg',
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.furnitureAssembly ?? 'Furniture Assembly',
        color: Colors.amber,
        availableProviders: getCountById('furnitureAssembly'),
        iconPath: 'assets/services_icon/Furniture_Assembly.svg',
      ),
    );

    return popularServices;
  }
}