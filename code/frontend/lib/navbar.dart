import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'screens/homepage.dart';
import 'screens/shoppage.dart';      
import 'screens/profilepage.dart';  
import 'screens/favoritespage.dart'; 

class NavbarPage extends StatefulWidget {
  const NavbarPage({Key? key}) : super(key: key);

  @override
  State<NavbarPage> createState() => _NavbarPageState();
}

class _NavbarPageState extends State<NavbarPage> {

  int selectedIndex = 0;

  final List<Widget> screens = const [
    ProfilePage(),
    ShopPage(),
    FavoritesPage(),
    HomePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      home: 
      // SafeArea(child: 
      Scaffold(
        body: screens[selectedIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,          
          onDestinationSelected: (int index) {
            setState(() {
              selectedIndex = index; // Update selectedIndex on tap
              print(index);
            });
          },
          destinations: const [
            NavigationDestination(icon: Icon(Iconsax.user), label: 'User'),
            NavigationDestination(icon: Icon(Iconsax.search_normal), label: 'Search'),
            NavigationDestination(icon: Icon(Iconsax.save_2), label: 'Save'),
            NavigationDestination(icon: Icon(Iconsax.home), label: 'Home'),
          ],
        ),
        // ),
      ),
    );
  }
}
