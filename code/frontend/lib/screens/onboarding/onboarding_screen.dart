import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hanini_frontend/localization/app_localization.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return Center(child: CircularProgressIndicator());
    }

    // Define pages dynamically based on localization strings
    final pages = [
      {
        "imagePath": 'assets/images/onboarding1.png',
        "title": localizations.onboardingTitle1,
        "description": localizations.onboardingDescription1,
      },
      {
        "imagePath": 'assets/images/onboarding2.png',
        "title": localizations.onboardingTitle2,
        "description": localizations.onboardingDescription2,
      },
      {
        "imagePath": 'assets/images/onboarding3.png',
        "title": localizations.onboardingTitle3,
        "description": localizations.onboardingDescription3,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: pages.length,
              itemBuilder: (context, index) {
                final page = pages[index];
                return _buildPage(
                  imagePath: page["imagePath"]!,
                  title: page["title"]!,
                  description: page["description"]!,
                );
              },
            ),
          ),
          _buildIndicators(pages.length),
          SizedBox(height: 20),
          _buildNextButton(context, localizations),
          SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildPage({
    required String imagePath,
    required String title,
    required String description,
  }) {
    return Container(
      padding: EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, fit: BoxFit.cover, height: 300),
          SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            description,
            style: GoogleFonts.poppins(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIndicators(int pageCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 5.0),
          height: 10,
          width: _currentPage == index ? 20 : 10,
          decoration: BoxDecoration(
            color: _currentPage == index ? Colors.blue : Colors.grey,
            borderRadius: BorderRadius.circular(12),
          ),
        );
      }),
    );
  }

  Widget _buildNextButton(BuildContext context, AppLocalizations localizations) {
    return ElevatedButton(
      onPressed: () {
        if (_currentPage == 2) {
          Navigator.pushReplacementNamed(context, '/login');
        } else {
          _pageController.nextPage(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeIn,
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Text(
        _currentPage == 2 ? localizations.getStarted : localizations.next,
        style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
      ),
    );
  }
}
