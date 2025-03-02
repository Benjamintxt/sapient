import 'package:flutter/material.dart';

class SubjectPage extends StatelessWidget {
  const SubjectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subjects')),
      body: const Center(child: Text('Subject Page Content')),
    );
  }
}
