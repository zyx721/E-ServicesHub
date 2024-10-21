import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home:  Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            'Terms and Conditions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        backgroundColor: Color.fromRGBO(161, 38, 248, 1),
      ),
    ),
    );

      // body: Container(
        // child: const Text('Terms and Conditions').,
      // ),

  }
}