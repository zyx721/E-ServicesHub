import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hanini_frontend/navbar.dart';
import 'package:hanini_frontend/user_role.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart'; // for picking images

class ServiceProviderProfile2 extends StatefulWidget {
  const ServiceProviderProfile2({Key? key}) : super(key: key);

  @override
  State<ServiceProviderProfile2> createState() => _ServiceProviderProfileState();
}

class _ServiceProviderProfileState extends State<ServiceProviderProfile2> {
  final double profileHeight = 120;
  String hourlyRate = '2500 DZD/hr';
  String aboutMe =
      'I am a professional Flutter developer with over 4 years of experience building intuitive, cross-platform mobile applications.';
  List<String> portfolioImages = [
    'assets/images/work/portpfolio1.jpeg',
    'assets/images/work/portpfolio2.jpeg',
    'assets/images/work/portpfolio3.jpeg',
  ];

  bool isEditMode = false;
  bool isVerified = true;

  final TextEditingController hourlyRateController = TextEditingController();
  final TextEditingController aboutMeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    hourlyRateController.text = hourlyRate;
    aboutMeController.text = aboutMe;
  }

  @override
  void dispose() {
    hourlyRateController.dispose();
    aboutMeController.dispose();
    super.dispose();
  }

  void toggleEditMode() async {
  setState(() {
    if (isEditMode) {
      hourlyRate = hourlyRateController.text;
      aboutMe = aboutMeController.text;
    }
    isEditMode = !isEditMode;
  });

  if (!isEditMode) {
    await _updateUserRole();
    
    // Navigate to navbar with the updated role
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(
        builder: (context) => NavbarPage(userRole: UserRole.provider)
      )
    );
  }
}
Future<void> _updateUserRole() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('userRole', UserRole.provider.toString());
}

  void navigateBack() {
    Navigator.pop(context); // Navigate back to the previous screen or navbar
  }

  Future<void> pickNewProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      debugPrint('Profile picture update triggered!');
      // Update profile picture logic here
    }
  }

  Future<void> pickNewPortfolioImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        portfolioImages.add(pickedFile.path); // Add picked image to portfolio
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              toggleEditMode();
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          buildTop(),
          const SizedBox(height: 16),
          buildProfileInfo(),
          const Divider(thickness: 1, height: 32),
          buildPortfolioSection(),
          const Divider(thickness: 1, height: 32),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: toggleEditMode,
        child: Icon(isEditMode ? Icons.check : Icons.edit),
        tooltip: isEditMode ? 'Save Changes' : 'Edit Profile',
      ),
    );
  }

  Widget buildTop() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: profileHeight / 2,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: const AssetImage('assets/images/profile_picture.png'),
            ),
            if (isEditMode)
              GestureDetector(
                onTap: () {
                  pickNewProfilePicture();
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Benmati Ziad',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (isVerified)
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(
                  Icons.check_circle_outline,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Flutter Developer',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 8),
        Text(
          'benmatiziad5@gmail.com',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget buildProfileInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buildStat('Projects', '24'),
              buildStat('Rating', _buildStarRating(4.5)),
              buildStat(
                  'Hourly Rate', isEditMode ? buildHourlyRateEditor() : hourlyRate),
            ],
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: const Text(
              'About Me',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          isEditMode
              ? TextField(
                  controller: aboutMeController,
                  onChanged: (value) => aboutMe = value,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Write about yourself...',
                  ),
                )
              : Text(
                  aboutMe,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  textAlign: TextAlign.justify,
                ),
        ],
      ),
    );
  }

  Widget buildHourlyRateEditor() {
    return SizedBox(
      width: 100,
      child: TextField(
        controller: hourlyRateController,
        onChanged: (value) => hourlyRate = value,
        decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
      ),
    );
  }

  Widget buildStat(String title, dynamic value) {
    return Column(
      children: [
        if (value is String)
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        if (value is Widget) value,
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildStarRating(double rating) {
    int fullStars = rating.floor();
    int halfStars = (rating % 1 >= 0.5) ? 1 : 0;
    int emptyStars = 5 - fullStars - halfStars;

    return Row(
      children: [
        for (int i = 0; i < fullStars; i++)
          const Icon(Icons.star, color: Colors.amber, size: 18),
        for (int i = 0; i < halfStars; i++)
          const Icon(Icons.star_half, color: Colors.amber, size: 18),
        for (int i = 0; i < emptyStars; i++)
          const Icon(Icons.star_border, color: Colors.grey, size: 18),
      ],
    );
  }

  Widget buildPortfolioSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Portfolio',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: portfolioImages.length,
              itemBuilder: (context, index) {
                return buildPortfolioCard(portfolioImages[index], index);
              },
            ),
          ),
          if (isEditMode)
            IconButton(
              icon: const Icon(Icons.add_a_photo),
              onPressed: pickNewPortfolioImage,
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget buildPortfolioCard(String imagePath, int index) {
    return GestureDetector(
      onTap: () {
        if (isEditMode) {
          setState(() {
            portfolioImages.removeAt(index); // Remove image on tap in edit mode
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        width: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
          ),
        ),
        child: isEditMode
            ? Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      portfolioImages.removeAt(index); // Remove image on tap in edit mode
                    });
                  },
                ),
              )
            : Container(),
      ),
    );
  }
}
