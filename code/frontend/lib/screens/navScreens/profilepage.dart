import 'package:flutter/material.dart';

class ServiceProviderProfile extends StatefulWidget {
  const ServiceProviderProfile({Key? key}) : super(key: key);

  @override
  State<ServiceProviderProfile> createState() => _ServiceProviderProfileState();
}

class _ServiceProviderProfileState extends State<ServiceProviderProfile> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          buildTop(),
          const SizedBox(height: 16),
          buildProfileInfo(),
          const Divider(thickness: 1, height: 32),
          buildPortfolioSection(),
          const Divider(thickness: 1, height: 32),
          buildReviews(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: toggleEditMode,
        child: Icon(isEditMode ? Icons.check : Icons.edit),
        tooltip: isEditMode ? 'Save Changes' : 'Edit Profile',
      ),
    );
  }

  void toggleEditMode() {
    if (isEditMode) {
      // Save changes (if necessary) and exit edit mode
    }
    setState(() {
      isEditMode = !isEditMode;
    });
  }

  // Top Profile Section
  Widget buildTop() {
    return Column(
      children: [
        const SizedBox(
            height: 40), // Added space between navbar and profile picture
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: profileHeight / 2,
              backgroundColor: Colors.grey.shade200,
              backgroundImage:
                  const AssetImage('assets/images/profile_picture.png'),
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
        const SizedBox(
            height: 20), // Increased the space for better positioning
        Text(
          'Benmati Ziad', // Changed name
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Flutter Developer',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 8),
        Text(
          'benmatiziad5@gmail.com', // Added Gmail
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // Main Profile Information
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
              buildStat('Hourly Rate',
                  isEditMode ? buildHourlyRateEditor() : hourlyRate),
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
                  controller: TextEditingController(text: aboutMe),
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
        controller: TextEditingController(text: hourlyRate),
        onChanged: (value) => hourlyRate = value,
        decoration:
            const InputDecoration(border: OutlineInputBorder(), isDense: true),
      ),
    );
  }

  // Portfolio Section
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
            height: 100, // Match the fixed height of portfolio cards
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: portfolioImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    buildPortfolioCard(portfolioImages[index]),
                    if (isEditMode)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              portfolioImages.removeAt(index);
                            });
                          },
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.red,
                            child: Icon(Icons.close,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          if (isEditMode)
            ElevatedButton.icon(
              onPressed: addPortfolioImage,
              icon: const Icon(Icons.add),
              label: const Text('Add Portfolio Image'),
            ),
        ],
      ),
    );
  }

  // Placeholder methods
  void pickNewProfilePicture() {
    debugPrint('Profile picture update triggered!');
  }

  void addPortfolioImage() {
    debugPrint('Add portfolio image triggered!');
  }

  Widget buildReviews() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Client Reviews',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          buildReview('John Doe', 4.5, 'James is a highly skilled developer.'),
          const SizedBox(height: 12),
          buildReview(
              'Jane Smith', 5.0, 'Amazing experience! Highly recommended.'),
        ],
      ),
    );
  }

  Widget buildReview(String reviewer, double rating, String comment) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                child: Text(
                  reviewer[0],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                reviewer,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              _buildStarRating(rating),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
        ],
      ),
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

  // Dialog for Editing Profile
  void showEditProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Hourly Rate',
                ),
                onChanged: (value) {
                  setState(() {
                    hourlyRate = value;
                  });
                },
              ),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'About Me',
                ),
                onChanged: (value) {
                  setState(() {
                    aboutMe = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  isEditMode = false;
                });
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
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

  Widget buildPortfolioCard(String imagePath) {
    return Container(
      width: 160, // Fixed width
      height: 100, // Fixed height
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        imagePath,
        fit: BoxFit
            .cover, // Ensures the image fills the container proportionally
      ),
    );
  }
}
