import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Main ProfilePage StatefulWidget
class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

// ProfilePage
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
      ),
    );
  }

  // Top section with Cover and Profile Images
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
        ),
      ],
    );
  }

  Widget buildCoverImage() => Container(
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
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          shape: BoxShape.circle,
        ),
        child: CircleAvatar(
          radius: profileHeight / 2,
          backgroundColor: Colors.grey.shade800,
          backgroundImage: const AssetImage('assets/images/work/painter.jpeg'),
        ),
      );

  // Main content section
  Widget buildContent() => Column(
        children: [
          const SizedBox(height: 8),
          buildProfileInfo(),
          const SizedBox(height: 16),
          buildSocialIcons(),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          NumbersWidget(),
          const SizedBox(height: 16),
          const Divider(),
          // const SizedBox(height: 16),
          buildBarAboutAndComment(),
          const Divider(),

          const SizedBox(height: 32),
          portpholio(),
        ],
      );

  Widget buildProfileInfo() => Column(
        children: [
          Text(
            'James Summer',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Flutter Software Engineer',
            style: TextStyle(fontSize: 20, color: Colors.black),
          ),
        ],
      );

  Widget buildSocialIcons() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          buildSocialIcon(Icons.call),
          const SizedBox(width: 12),
          buildSocialIcon(Icons.location_on),
          const SizedBox(width: 12),
          buildSocialIcon(FontAwesomeIcons.route),
          const SizedBox(width: 12),
          buildSocialIcon(FontAwesomeIcons.commentDots),
          const SizedBox(width: 12),
          // buildSocialIcon(FontAwesomeIcons.solidSave),
          // const SizedBox(width: 12),
        ],
      );

  Widget buildSocialIcon(IconData icon) => CircleAvatar(
        radius: 25,
        backgroundColor: Colors.blue,
        child: Material(
          
          shape: CircleBorder(),
          clipBehavior: Clip.hardEdge,
          child: InkWell(
            onTap: () {},
            child: Center(child: Icon(icon, size: 32)),
          ),
        ),
      );

  // About Me and Comments Section
  Widget buildBarAboutAndComment() {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(text: 'About Me'),
              Tab(text: 'Comments'),
            ],
          ),
          Container(
            height: 300,
            padding: const EdgeInsets.all(16.0),
            child: TabBarView(
              children: [
                buildAboutMeContent(),
                buildCommentsContent(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAboutMeContent() => Column(
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
      );

  Widget buildCommentsContent() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comments',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                buildComment('John Doe', 'Great profile, James!'),
                buildComment('Jane Smith', 'Amazing work and portfolio!'),
                buildComment('Bob Johnson', 'Keep up the great work!'),
              ],
            ),
          ),
        ],
      );

Widget buildComment(String username, String comment) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 8.0),
  child: Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade300, width: 1), // Add border to create the frame
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 6,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 20,
          child: Text(username[0], style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                comment,
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
);
}

// Portfolio Section
Widget portpholio() {
  return Container(
    child: Column(
      children: [
        Text(
          'Portpholio',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),

        Container(
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
        ),
      ],
    ),
  );
}

Widget buildCard(String imagePath) => GestureDetector(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(4, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
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
                color: Colors.black.withOpacity(0.6),
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

// Numbers Widget
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

  Widget buildNumber(BuildContext context, String value, String title) =>
      Column(
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

  Widget buildDivider() => Container(
        height: 24,
        child: VerticalDivider(
          thickness: 1,
          color: Colors.grey.shade300,
        ),
      );
}