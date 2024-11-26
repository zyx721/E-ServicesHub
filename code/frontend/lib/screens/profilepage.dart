import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final double coverHeight = 280;
  final double profileHeight = 144;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        buildTop(),
        buildContent(),
      ],
    ));
  }

  Widget buildContent() => Column(
        children: [
          const SizedBox(height: 8),
          Text(
            'james Summer',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          Text(
            'Flutter Software Engineer',
            style: TextStyle(fontSize: 20, color: Colors.black),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              buildSocialIcon(FontAwesomeIcons.slack),
              const SizedBox(width: 12),
              buildSocialIcon(FontAwesomeIcons.github),
              const SizedBox(width: 12),
              buildSocialIcon(FontAwesomeIcons.twitter),
              const SizedBox(width: 12),
              buildSocialIcon(FontAwesomeIcons.linkedin),
              const SizedBox(width: 12),
            ],
          ),

          const SizedBox(height: 16),
          Divider(),
          const SizedBox(height: 16),
          NumbersWidget(),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          buildAbout(),
          const SizedBox(height: 32),
                  
          portpholio(),

        ],

        //
      );

  Widget buildAbout(){
    return Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 24.0, vertical: 16.0), // Increased padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About Me',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'I am a passionate Flutter Software Engineer with experience in building mobile applications. '
                  'I love exploring new technologies and improving my skills in mobile development. In my spare time, '
                  'I enjoy contributing to open-source projects and learning about different areas of tech.',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          );
  }



  Widget buildCoverImage() => Container(
        // color: Colors.grey,
              decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black.withOpacity(0.6), Colors.transparent],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
      ),
        child: Image.asset(
          'assets/images/work/pic2.jpeg',
          width: double.infinity,
          height: coverHeight,
          fit: BoxFit.cover,
        ),
      );

  Widget buildProfileImage() => Container(
        padding: const EdgeInsets.all(4), // Padding for the grey border
        decoration: BoxDecoration(
          color: Colors.grey.shade300, // Light grey circle around the image
          shape: BoxShape.circle,
        ),
        child: CircleAvatar(
          radius: profileHeight / 2, // Inner image size
          backgroundColor: Colors.grey.shade800,
          backgroundImage: const AssetImage('assets/images/work/painter.jpeg'),
        ),
      );

  Widget buildTop() {
    final bottom = profileHeight / 2;
    final top = coverHeight - (profileHeight / 2);
    return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            margin: EdgeInsets.only(bottom: bottom),
            child: buildCoverImage(),
          ),
          Positioned(
            top: top,
            child: buildProfileImage(),
          )
        ]);
  }

  Widget buildSocialIcon(IconData icon) => CircleAvatar(
      radius: 25,
      child: Material(
        shape: CircleBorder(),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: () => {},
          child: Center(child: Icon(icon, size: 32)),
        ),
      ));
}

class NumbersWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        buildNumber(context, '50', 'Posts'),
        buildDivider(),
        buildNumber(context, '120K', 'Followers'),
        buildDivider(),
        buildNumber(context, '300', 'Following'),
      ],
    );
  }

  Widget buildNumber(BuildContext context, String value, String title) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget buildDivider() {
    return Container(
      height: 24,
      child: VerticalDivider(
        thickness: 1,
        color: Colors.grey,
      ),
    );
  }
}


Widget portpholio(){
  return Container(
    height: 220,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        SizedBox(width: 12),
        buildCard('assets/images/work/portpfolio1.jpeg'),
        SizedBox(width: 12),
        buildCard('assets/images/work/portpfolio2.jpeg'),
        SizedBox(width: 12),
        buildCard('assets/images/work/portpfolio3.jpeg'),
        SizedBox(width: 12),
        buildCard('assets/images/work/portpfolio4.jpeg'),
        SizedBox(width: 12),

      ],
    ),
  );
}

  Widget buildCard(String imagePath) => GestureDetector(
  // onTap: () {
    // Handle image tap, e.g., navigate to a detail page or show a dialog
    // print('Tapped on $imagePath');
  // },
  child: Container(
    decoration: BoxDecoration(
      color: Colors.blue,
      borderRadius: BorderRadius.circular(16), // Rounded corners
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 8,
          offset: Offset(4, 4), // Shadow position
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias, // Ensures content inside respects the border radius
    child: Stack(
      children: [
        Image.asset(
          imagePath,
          fit: BoxFit.cover,
        ),
        Positioned(
          bottom: 8,
          left: 8,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.black.withOpacity(0.6), // Semi-transparent overlay
            child: Text(
              'Portfolio',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    ),
  ),
);