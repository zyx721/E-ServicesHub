import 'package:flutter/material.dart';

class PrivacyInfoPage extends StatelessWidget {
  const PrivacyInfoPage({Key? key}) : super(key: key);

  Widget _buildSection({
    required String number,
    required String title,
    required String content,
    IconData? icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.purple[100],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      number,
                      style: TextStyle(
                        color: Colors.purple[900],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[900],
                    ),
                  ),
                ),
                if (icon != null)
                  Icon(
                    icon,
                    color: Colors.purple[700],
                    size: 24,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF9C27B0), // Purple 500
            Color(0xFF7B1FA2), // Purple 700
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Privacy Information',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.purple[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.security,
                            size: 60,
                            color: Colors.purple[700],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.purple[50]!,
                              Colors.purple[100]!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Privacy Policy',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple[900],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Welcome to HANINI! Your privacy is important to us. This page outlines how we collect, use, and protect your information.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.purple[900],
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        number: '1',
                        title: 'Information We Collect',
                        content: 'We may collect personal information such as your name, email address, location, and payment details to provide better services.',
                        icon: Icons.person_outline,
                      ),
                      _buildSection(
                        number: '2',
                        title: 'How We Use Your Information',
                        content: 'Your data is used to connect you with service providers, enhance your experience, and for app analytics to improve our services.',
                        icon: Icons.data_usage,
                      ),
                      _buildSection(
                        number: '3',
                        title: 'Data Protection',
                        content: 'We implement strict measures to protect your information from unauthorized access, alteration, or deletion.',
                        icon: Icons.shield_outlined,
                      ),
                      _buildSection(
                        number: '4',
                        title: 'Sharing Your Information',
                        content: 'We do not sell your information. We may share data with third-party services necessary for running the app, following privacy standards.',
                        icon: Icons.share_outlined,
                      ),
                      _buildSection(
                        number: '5',
                        title: 'Your Rights',
                        content: 'You have the right to access, modify, or request deletion of your data. Contact us at support@hanini.com for any concerns.',
                        icon: Icons.gavel_outlined,
                      ),
                      _buildSection(
                        number: '6',
                        title: 'Updates to this Policy',
                        content: 'We may update this policy occasionally. Please check this page regularly for updates.',
                        icon: Icons.update,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Back to Home',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}