import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: [
                _buildPage(
                  imagePath: 'assets/images/onboarding1.png',
                  title: 'Find Handyman Services',
                  description: 'Discover reliable handyman services at your fingertips.',
                ),
                _buildPage(
                  imagePath: 'assets/images/onboarding2.png',
                  title: 'Book with Ease',
                  description: 'Simple booking process to schedule services at your convenience.',
                ),
                _buildPage(
                  imagePath: 'assets/images/onboarding3.png',
                  title: 'Rate & Review',
                  description: 'Share your experience and help others find the best services.',
                ),
              ],
            ),
          ),
          _buildIndicators(),
          SizedBox(height: 20),
          _buildNextButton(context),
          SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildPage({required String imagePath, required String title, required String description}) {
    return Container(
      padding: EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, fit: BoxFit.cover, height: 300),
          SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          AnimatedOpacity(
            opacity: 1.0, // Keep it fully visible
            duration: Duration(seconds: 1), // Duration of the fade-in effect
            child: Text(
              description,
              style: GoogleFonts.poppins(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
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

  Widget _buildNextButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        if (_currentPage == 2) {
          Navigator.pushReplacementNamed(context, '/login');
        } else {
          _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeIn);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Text(
        _currentPage == 2 ? 'Get Started' : 'Next',
        style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
      ),
    );
  }
}
