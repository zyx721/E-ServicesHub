import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ServiceProviderFullProfile extends StatefulWidget {
  final String serviceId;

  const ServiceProviderFullProfile({Key? key, required this.serviceId}) : super(key: key);

  @override
  _ServiceProviderFullProfileState createState() => _ServiceProviderFullProfileState();
}

class _ServiceProviderFullProfileState extends State<ServiceProviderFullProfile> {
  // Simulated service provider data
  late Map<String, dynamic> _providerData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProviderDetails();
  }

  void _fetchProviderDetails() {
    // Mock database - replace with actual database/API call
    final Map<String, Map<String, dynamic>> mockDatabase = {
  'service_001': {
    'id': 'service_001',
    'name': 'Ziad Benmati',
    'profession': 'Painter',
    'profileImage': 'assets/images/service1.png',
    'email': 'ziad.painter@example.com',
    'phone': '+213 550 123 456',
    'address': 'Algiers, Algeria',
    'rating': 4.0,
    'totalProjects': 35,
    'hourlyRate': 2000,
    'description': 'Professional painter with extensive experience in residential and commercial painting. Specializing in various painting techniques and color schemes.',
    'skills': [
      'Interior Painting',
      'Exterior Painting',
      'Wall Preparation',
      'Color Consultation'
    ],
    'certifications': [
      'Professional Painting Certification',
      'Color Theory Expert'
    ],
    'workExperience': [
      {
        'company': 'City Painting Solutions',
        'position': 'Lead Painter',
        'duration': '2012 - Present'
      }
    ],
    'portfolioImages': [
      'assets/images/portfolio/painting1.jpg',
      'assets/images/portfolio/painting2.jpg',
      'assets/images/portfolio/painting3.jpg',
    ],
    'reviews': [
      {
        'name': 'Ahmed',
        'rating': 4.5,
        'comment': 'Great painting work, very professional.'
      },
      {
        'name': 'Fatima',
        'rating': 4.0,
        'comment': 'Reliable and efficient service.'
      }
    ]
  },
  'service_002': {
    'id': 'service_002',
    'name': 'Anas Benali',
    'profession': 'Plumber',
    'profileImage': 'assets/images/service2.png',
    'email': 'anas.plumber@example.com',
    'phone': '+213 560 234 567',
    'address': 'Oran, Algeria',
    'rating': 4.2,
    'totalProjects': 50,
    'hourlyRate': 2500,
    'description': 'Experienced plumber specializing in residential and commercial plumbing repairs and installations. Committed to quality and customer satisfaction.',
    'skills': [
      'Pipe Installation',
      'Leak Repair',
      'Fixture Replacement',
      'Emergency Plumbing'
    ],
    'certifications': [
      'Master Plumber License',
      'Pipe Systems Certification'
    ],
    'workExperience': [
      {
        'company': 'Reliable Plumbing Services',
        'position': 'Senior Plumber',
        'duration': '2015 - Present'
      }
    ],
    'portfolioImages': [
      'assets/images/portfolio/plumbing1.jpg',
      'assets/images/portfolio/plumbing2.jpg',
      'assets/images/portfolio/plumbing3.jpg',
    ],
    'reviews': [
      {
        'name': 'Mohammed',
        'rating': 4.5,
        'comment': 'Quick and effective plumbing solutions.'
      },
      {
        'name': 'Sarah',
        'rating': 4.0,
        'comment': 'Professional and reasonably priced.'
      }
    ]
  },
  'service_003': {
    'id': 'service_003',
    'name': 'Raouf Khaldi',
    'profession': 'Big House Plumbing',
    'profileImage': 'assets/images/service3.png',
    'email': 'raouf.plumbing@example.com',
    'phone': '+213 570 345 678',
    'address': 'Constantine, Algeria',
    'rating': 4.5,
    'totalProjects': 60,
    'hourlyRate': 3000,
    'description': 'Specialized in large-scale plumbing projects with expertise in complex residential and commercial plumbing systems.',
    'skills': [
      'Large Scale Plumbing',
      'System Design',
      'Complex Installations',
      'Maintenance'
    ],
    'certifications': [
      'Advanced Plumbing Systems',
      'Commercial Plumbing Expert'
    ],
    'workExperience': [
      {
        'company': 'Big House Plumbing Solutions',
        'position': 'Lead Plumbing Specialist',
        'duration': '2010 - Present'
      }
    ],
    'portfolioImages': [
      'assets/images/portfolio/bigplumbing1.jpg',
      'assets/images/portfolio/bigplumbing2.jpg',
      'assets/images/portfolio/bigplumbing3.jpg',
    ],
    'reviews': [
      {
        'name': 'Karim',
        'rating': 4.5,
        'comment': 'Outstanding work on our commercial project.'
      },
      {
        'name': 'Leila',
        'rating': 4.6,
        'comment': 'Highly skilled and professional.'
      }
    ]
  },
  'service_004': {
    'id': 'service_004',
    'name': 'Mouh Rezki',
    'profession': 'Electrical Engineer',
    'profileImage': 'assets/images/service4.png',
    'email': 'mouh.electrical@example.com',
    'phone': '+213 580 456 789',
    'address': 'Blida, Algeria',
    'rating': 4.1,
    'totalProjects': 40,
    'hourlyRate': 3500,
    'description': 'Professional electrical engineer with extensive experience in residential, commercial, and industrial electrical systems and installations.',
    'skills': [
      'Electrical Design',
      'System Installation',
      'Maintenance',
      'Troubleshooting'
    ],
    'certifications': [
      'Electrical Engineering Degree',
      'Safety Certification'
    ],
    'workExperience': [
      {
        'company': 'Power Solutions Inc.',
        'position': 'Senior Electrical Engineer',
        'duration': '2013 - Present'
      }
    ],
    'portfolioImages': [
      'assets/images/portfolio/electrical1.jpg',
      'assets/images/portfolio/electrical2.jpg',
      'assets/images/portfolio/electrical3.jpg',
    ],
    'reviews': [
      {
        'name': 'Ibrahim',
        'rating': 4.2,
        'comment': 'Precise and professional electrical work.'
      },
      {
        'name': 'Amira',
        'rating': 4.0,
        'comment': 'Solved our complex electrical issues.'
      }
    ]
  },
  'service_005': {
    'id': 'service_005',
    'name': 'Fares Belaid',
    'profession': 'Floor Cleaning',
    'profileImage': 'assets/images/service5.png',
    'email': 'fares.cleaning@example.com',
    'phone': '+213 590 567 890',
    'address': 'Annaba, Algeria',
    'rating': 3.9,
    'totalProjects': 75,
    'hourlyRate': 1500,
    'description': 'Professional cleaning service specializing in comprehensive floor cleaning for residential and commercial spaces.',
    'skills': [
      'Deep Cleaning',
      'Carpet Cleaning',
      'Tile and Grout Cleaning',
      'Polishing'
    ],
    'certifications': [
      'Professional Cleaning Certification',
      'Eco-Friendly Cleaning Techniques'
    ],
    'workExperience': [
      {
        'company': 'Shine Clean Services',
        'position': 'Senior Cleaning Specialist',
        'duration': '2016 - Present'
      }
    ],
    'portfolioImages': [
      'assets/images/portfolio/cleaning1.jpg',
      'assets/images/portfolio/cleaning2.jpg',
      'assets/images/portfolio/cleaning3.jpg',
    ],
    'reviews': [
      {
        'name': 'Yasmin',
        'rating': 4.0,
        'comment': 'Excellent floor cleaning service.'
      },
      {
        'name': 'Omar',
        'rating': 3.8,
        'comment': 'Good job, thorough cleaning.'
      }
    ]
  },
  'service_006': {
    'id': 'service_006',
    'name': 'Ziad Hamdi',
    'profession': 'Carpentry',
    'profileImage': 'assets/images/service6.png',
    'email': 'ziad.carpenter@example.com',
    'phone': '+213 600 678 901',
    'address': 'Sétif, Algeria',
    'rating': 4.0,
    'totalProjects': 55,
    'hourlyRate': 2800,
    'description': 'Skilled carpenter with expertise in custom woodworking, furniture making, and home renovation projects.',
    'skills': [
      'Custom Furniture',
      'Wood Restoration',
      'Cabinetry',
      'Woodworking'
    ],
    'certifications': [
      'Master Carpenter Certification',
      'Design and Craftsmanship'
    ],
    'workExperience': [
      {
        'company': 'Artisan Wood Workshop',
        'position': 'Lead Carpenter',
        'duration': '2014 - Present'
      }
    ],
    'portfolioImages': [
      'assets/images/portfolio/carpentry1.jpg',
      'assets/images/portfolio/carpentry2.jpg',
      'assets/images/portfolio/carpentry3.jpg',
    ],
    'reviews': [
      {
        'name': 'Rachid',
        'rating': 4.2,
        'comment': 'Beautiful custom furniture work.'
      },
      {
        'name': 'Karima',
        'rating': 3.9,
        'comment': 'Professional and skilled carpenter.'
      }
    ]
  },
  'service_007': {
    'id': 'service_007',
    'name': 'Anas Boutebba',
    'profession': 'Makeup Artist',
    'profileImage': 'assets/images/service7.png',
    'email': 'anas.makeup@example.com',
    'phone': '+213 610 789 012',
    'address': 'Tlemcen, Algeria',
    'rating': 4.5,
    'totalProjects': 80,
    'hourlyRate': 3000,
    'description': 'Professional makeup artist specializing in bridal, event, and professional photoshoot makeup.',
    'skills': [
      'Bridal Makeup',
      'Event Makeup',
      'Professional Photoshoot',
      'Skin Consultation'
    ],
    'certifications': [
      'Professional Makeup Artistry',
      'Beauty Styling Certification'
    ],
    'workExperience': [
      {
        'company': 'Glamour Makeup Studio',
        'position': 'Lead Makeup Artist',
        'duration': '2017 - Present'
      }
    ],
    'portfolioImages': [
      'assets/images/portfolio/makeup1.jpg',
      'assets/images/portfolio/makeup2.jpg',
      'assets/images/portfolio/makeup3.jpg',
    ],
    'reviews': [
      {
        'name': 'Nadia',
        'rating': 4.6,
        'comment': 'Perfect makeup for my wedding day!'
      },
      {
        'name': 'Samira',
        'rating': 4.4,
        'comment': 'Professional and creative makeup artist.'
      }
    ]
  },
  // Continue the mockDatabase with the remaining services
'service_008': {
    'id': 'service_008',
    'name': 'Raouf Hamoud',
    'profession': 'Private Tutor',
    'profileImage': 'assets/images/service8.png',
    'email': 'raouf.tutor@example.com',
    'phone': '+213 620 890 123',
    'address': 'Batna, Algeria',
    'rating': 4.3,
    'totalProjects': 65,
    'hourlyRate': 2200,
    'description': 'Experienced private tutor specializing in mathematics, physics, and academic preparation for secondary and university students.',
    'skills': [
      'Mathematics Tutoring',
      'Physics Instruction',
      'Exam Preparation',
      'Online and In-Person Teaching'
    ],
    'certifications': [
      'Education Degree',
      'Advanced Mathematics Certification',
      'Pedagogical Training'
    ],
    'workExperience': [
      {
        'company': 'Academic Excellence Tutoring Center',
        'position': 'Senior Tutor',
        'duration': '2016 - Present'
      }
    ],
    'portfolioImages': [
      'assets/images/portfolio/tutoring1.jpg',
      'assets/images/portfolio/tutoring2.jpg',
      'assets/images/portfolio/tutoring3.jpg',
    ],
    'reviews': [
      {
        'name': 'Ahmed',
        'rating': 4.4,
        'comment': 'Helped my son improve significantly in math.'
      },
      {
        'name': 'Lamia',
        'rating': 4.2,
        'comment': 'Excellent and patient tutor.'
      }
    ]
  },
  'service_009': {
    'id': 'service_009',
    'name': 'Mouh Chaibi',
    'profession': 'Workout Coach',
    'profileImage': 'assets/images/service9.png',
    'email': 'mouh.fitness@example.com',
    'phone': '+213 630 901 234',
    'address': 'Oran, Algeria',
    'rating': 4.4,
    'totalProjects': 70,
    'hourlyRate': 3000,
    'description': 'Professional fitness coach specializing in personal training, weight loss, muscle building, and overall wellness coaching.',
    'skills': [
      'Personal Training',
      'Strength Conditioning',
      'Weight Loss Programs',
      'Nutrition Guidance'
    ],
    'certifications': [
      'Personal Training Certification',
      'Nutritional Coaching',
      'Sports Science Diploma'
    ],
    'workExperience': [
      {
        'company': 'Peak Performance Fitness Center',
        'position': 'Lead Fitness Coach',
        'duration': '2015 - Present'
      }
    ],
    'portfolioImages': [
      'assets/images/portfolio/fitness1.jpg',
      'assets/images/portfolio/fitness2.jpg',
      'assets/images/portfolio/fitness3.jpg',
    ],
    'reviews': [
      {
        'name': 'Yacine',
        'rating': 4.5,
        'comment': 'Transformed my fitness and lifestyle.'
      },
      {
        'name': 'Sophia',
        'rating': 4.3,
        'comment': 'Professional and motivational coach.'
      }
    ]
  },
  'service_010': {
    'id': 'service_010',
    'name': 'Fares Mebarki',
    'profession': 'Therapy for Mental Help',
    'profileImage': 'assets/images/service10.png',
    'email': 'fares.therapy@example.com',
    'phone': '+213 640 012 345',
    'address': 'Constantine, Algeria',
    'rating': 4.2,
    'totalProjects': 55,
    'hourlyRate': 3500,
    'description': 'Licensed mental health professional providing compassionate and evidence-based psychological counseling and therapy services.',
    'skills': [
      'Individual Counseling',
      'Stress Management',
      'Cognitive Behavioral Therapy',
      'Mental Health Support'
    ],
    'certifications': [
      'Clinical Psychology Degree',
      'Mental Health Counseling Certification',
      'Trauma-Informed Care'
    ],
    'workExperience': [
      {
        'company': 'Harmony Mental Health Center',
        'position': 'Senior Therapist',
        'duration': '2017 - Present'
      }
    ],
    'portfolioImages': [
      'assets/images/portfolio/therapy1.jpg',
      'assets/images/portfolio/therapy2.jpg',
      'assets/images/portfolio/therapy3.jpg',
    ],
    'reviews': [
      {
        'name': 'Karima',
        'rating': 4.3,
        'comment': 'Helped me through a difficult period.'
      },
      {
        'name': 'Ali',
        'rating': 4.1,
        'comment': 'Professional and empathetic therapist.'
      }
    ]
  },
  'service_011': {
    'id': 'service_011',
    'name': 'Ziad Fenniche',
    'profession': 'Locksmith',
    'profileImage': 'assets/images/service11.png',
    'email': 'ziad.locksmith@example.com',
    'phone': '+213 650 123 456',
    'address': 'Algiers, Algeria',
    'rating': 3.8,
    'totalProjects': 40,
    'hourlyRate': 2000,
    'description': 'Experienced locksmith providing comprehensive security solutions including lock installation, repair, and emergency lockout services.',
    'skills': [
      'Lock Installation',
      'Key Cutting',
      'Security System Repair',
      'Emergency Lockout Services'
    ],
    'certifications': [
      'Professional Locksmith Certification',
      'Security Systems Training'
    ],
    'workExperience': [
      {
        'company': 'Secure Lock Solutions',
        'position': 'Senior Locksmith',
        'duration': '2014 - Present'
      }
    ],
    'portfolioImages': [
      'assets/images/portfolio/locksmith1.jpg',
      'assets/images/portfolio/locksmith2.jpg',
      'assets/images/portfolio/locksmith3.jpg',
    ],
    'reviews': [
      {
        'name': 'Mohammed',
        'rating': 4.0,
        'comment': 'Quick and efficient service.'
      },
      {
        'name': 'Fatima',
        'rating': 3.6,
        'comment': 'Helped me during an emergency lockout.'
      }
    ]
  },
  'service_012': {
    'id': 'service_012',
    'name': 'Anas Boudjema',
    'profession': 'Guardian',
    'profileImage': 'assets/images/service12.png',
    'email': 'anas.guardian@example.com',
    'phone': '+213 660 234 567',
    'address': 'Sétif, Algeria',
    'rating': 4.1,
    'totalProjects': 30,
    'hourlyRate': 2800,
    'description': 'Professional security guard with extensive experience in personal and property protection, ensuring safety and security.',
    'skills': [
      'Security Monitoring',
      'Surveillance',
      'Emergency Response',
      'Personal Protection'
    ],
    'certifications': [
      'Security Guard Certification',
      'First Aid Training',
      'Emergency Response Training'
    ],
    'workExperience': [
      {
        'company': 'Elite Security Services',
        'position': 'Senior Security Guard',
        'duration': '2016 - Present'
      }
    ],
    'portfolioImages': [
      'assets/images/portfolio/guardian1.jpg',
      'assets/images/portfolio/guardian2.jpg',
      'assets/images/portfolio/guardian3.jpg',
    ],
    'reviews': [
      {
        'name': 'Rachid',
        'rating': 4.2,
        'comment': 'Very professional and attentive.'
      },
      {
        'name': 'Leila',
        'rating': 4.0,
        'comment': 'Feels secure with this guardian.'
      }
    ]
  },
  'service_013': {
    'id': 'service_013',
    'name': 'Raouf Benkhelil',
    'profession': 'Chef',
    'profileImage': 'assets/images/service13.png',
    'email': 'raouf.chef@example.com',
    'phone': '+213 670 345 678',
    'address': 'Blida, Algeria',
    'rating': 4.6,
    'totalProjects': 75,
    'hourlyRate': 3500,
    'description': 'Skilled and creative chef specializing in traditional Algerian cuisine and contemporary culinary techniques.',
    'skills': [
      'Algerian Cuisine',
      'Fine Dining Preparation',
      'Catering Services',
      'Culinary Consultation'
    ],
    'certifications': [
      'Culinary Arts Degree',
      'International Cuisine Certification',
      'Food Safety Certification'
    ],
    'workExperience': [
      {
        'company': 'Gourmet Kitchen Catering',
        'position': 'Executive Chef',
        'duration': '2018 - Present'
      }
    ],
    'portfolioImages': [
      'assets/images/portfolio/chef1.jpg',
      'assets/images/portfolio/chef2.jpg',
      'assets/images/portfolio/chef3.jpg',
    ],
    'reviews': [
      {
        'name': 'Yasmin',
        'rating': 4.7,
        'comment': 'Incredible culinary experience!'
      },
      {
        'name': 'Omar',
        'rating': 4.5,
        'comment': 'Delicious and beautifully presented dishes.'
      }
    ]
  },
  'service_014': {
    'id': 'service_014',
    'name': 'Mouh Lalaoui',
    'profession': 'Solar Panel Installation',
    'profileImage': 'assets/images/service14.png',
    'email': 'mouh.solar@example.com',
    'phone': '+213 680 456 789',
    'address': 'Annaba, Algeria',
    'rating': 4.5,
    'totalProjects': 50,
    'hourlyRate': 4000,
    'description': 'Expert in solar panel installation and renewable energy solutions, providing sustainable and efficient solar power systems.',
    'skills': [
      'Solar Panel Installation',
      'Energy Efficiency Consulting',
      'System Design',
      'Maintenance and Repair'
    ],
    'certifications': [
      'Renewable Energy Engineering',
      'Solar Installation Certification',
      'Energy Efficiency Expert'
    ],
    'workExperience': [
      {
        'company': 'Green Energy Solutions',
        'position': 'Lead Solar Technician',
        'duration': '2015 - Present'
      }
    ],
    'portfolioImages': [
      'assets/images/portfolio/solar1.jpg',
      'assets/images/portfolio/solar2.jpg',
      'assets/images/portfolio/solar3.jpg',
    ],
    'reviews': [
      {
        'name': 'Ahmed',
        'rating': 4.6,
        'comment': 'Excellent solar panel installation.'
      },
      {
        'name': 'Fatima',
        'rating': 4.4,
        'comment': 'Professional and knowledgeable about renewable energy.'
      }
    ]
  },
};


    // Simulate network delay
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _providerData = mockDatabase[widget.serviceId] ?? {};
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Provider Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileSummary(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('About Me'),
                  _buildAboutSection(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Skills'),
                  _buildSkillsSection(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Work Experience'),
                  _buildWorkExperienceSection(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Portfolio'),
                  _buildPortfolioSection(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Certifications'),
                  _buildCertificationsSection(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Client Reviews'),
                  _buildReviewsSection(),
                  const SizedBox(height: 20),
                  _buildContactButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300.0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _providerData['name'],
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              _providerData['profileImage'],
              fit: BoxFit.cover,
            ),
            // Gradient overlay
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSummary() {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: AssetImage(_providerData['profileImage']),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _providerData['profession'],
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${_providerData['rating']} (${_providerData['totalProjects']} Projects)',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              Text(
                'Hourly Rate: ${_providerData['hourlyRate']} DZD',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildAboutSection() {
    return Text(
      _providerData['description'],
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.grey[700],
      ),
      textAlign: TextAlign.justify,
    );
  }

  Widget _buildSkillsSection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: (_providerData['skills'] as List<String>)
          .map((skill) => Chip(
                label: Text(skill, style: GoogleFonts.poppins()),
                backgroundColor: Colors.blue.shade50,
              ))
          .toList(),
    );
  }

  Widget _buildWorkExperienceSection() {
    return Column(
      children: (_providerData['workExperience'] as List<Map<String, dynamic>>)
          .map((exp) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  exp['company'],
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${exp['position']} | ${exp['duration']}',
                  style: GoogleFonts.poppins(),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildPortfolioSection() {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: (_providerData['portfolioImages'] as List).length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              _providerData['portfolioImages'][index],
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCertificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: (_providerData['certifications'] as List<String>)
          .map((cert) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Icon(Icons.verified, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cert,
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      children: (_providerData['reviews'] as List<Map<String, dynamic>>)
          .map((review) => Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            review['name'],
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: List.generate(
                              review['rating'].toInt(),
                              (index) => const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        review['comment'],
                        style: GoogleFonts.poppins(
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildContactButton() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: _showContactBottomSheet,
        icon: const Icon(Icons.contact_mail),
        label: Text(
          'Contact Provider',
          style: GoogleFonts.poppins(),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }

  void _showContactBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Contact Information',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.blue),
              title: Text(
                _providerData['phone'],
                style: GoogleFonts.poppins(),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.blue),
              title: Text(
                _providerData['email'],
                style: GoogleFonts.poppins(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}