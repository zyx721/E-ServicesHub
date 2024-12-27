import 'package:flutter/material.dart';
import 'package:hanini_frontend/localization/app_localization.dart';

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

  static List<PopularServicesModel> getPopularServices(BuildContext context) {
    List<PopularServicesModel> popularServices = [];

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.houseCleaning ?? 'House Cleaning',
        color: Colors.blue,
        availableProviders: 12,
        iconPath: 'assets/services_icon/House_Cleaning.svg',
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.electricity ?? 'Electricity',
        color: Colors.orange,
        availableProviders: 8,
        iconPath: 'assets/services_icon/Electricity.svg',
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.plumbing ?? 'Plumbing',
        color: Colors.green,
        availableProviders: 10,
        iconPath: 'assets/services_icon/Plumbing.svg',
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.gardening ?? 'Gardening',
        color: Colors.greenAccent,
        availableProviders: 7,
        iconPath: 'assets/services_icon/Gardening.svg',
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.painting ?? 'Painting',
        color: Colors.red,
        availableProviders: 5,
        iconPath: 'assets/services_icon/Painting.svg',
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.carpentry ?? 'Carpentry',
        color: Colors.brown,
        availableProviders: 6,
        iconPath: 'assets/services_icon/Carpentry.svg',
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.pestControl ?? 'Pest Control',
        color: Colors.purple,
        availableProviders: 4,
        iconPath: 'assets/services_icon/Pest_Control.svg',
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.acRepair ?? 'AC Repair',
        color: Colors.blueAccent,
        availableProviders: 9,
        iconPath: 'assets/services_icon/air-conditioner-svgrepo-com.svg',
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.vehicleRepair ?? 'Vehicle Repair',
        color: Colors.cyan,
        availableProviders: 3,
        iconPath: 'assets/services_icon/Vehicle_Repair.svg',
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.applianceInstallation ?? 'Appliance Installation',
        color: Colors.teal,
        availableProviders: 5,
        iconPath: 'assets/services_icon/Appliance_Installation.svg',
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.itSupport ?? 'IT Support',
        color: Colors.indigo,
        availableProviders: 7,
        iconPath: 'assets/services_icon/IT_Support.svg',
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.homeSecurity ?? 'Home Security',
        color: Colors.grey,
        availableProviders: 6,
        iconPath: 'assets/services_icon/Home_Security.svg',
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.interiorDesign ?? 'Interior Design',
        color: Colors.deepPurple,
        availableProviders: 4,
        iconPath: 'assets/services_icon/Interior_Design.svg',
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.windowCleaning ?? 'Window Cleaning',
        color: Colors.lightBlue,
        availableProviders: 8,
        iconPath: 'assets/services_icon/Window_Cleaning.svg',
      ),
    );

    popularServices.add(
      PopularServicesModel(
        name: AppLocalizations.of(context)?.furnitureAssembly ?? 'Furniture Assembly',
        color: Colors.amber,
        availableProviders: 5,
        iconPath: 'assets/services_icon/Furniture_Assembly.svg',
      ),
    );

    return popularServices;
  }
}