import 'package:flutter/material.dart';
// to connect with backend
import 'package:http/http.dart' as http;
// firts page
import './screens//terms_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text(' TESTING '),
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              final response = await http
                  .get(Uri.parse('http://192.168.201.70:3000/api/data'));
              print('Response: ${response.body}');
            },
            child: const Text('connected to node.js'),
          ),
        ),
      ),

      // title: 'Your App Title',
      // initialRoute: '/terms', // Set the initial route to the terms page
      // routes: {
      //   '/terms': (context) => const TermsPage(), // Route to the TermsPage
      // },
    );
  }
}
