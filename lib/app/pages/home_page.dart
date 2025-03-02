import 'package:flutter/material.dart';
import 'subject_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        children: <Widget>[
          SubjectPage(),
        ],
        onPageChanged: (int page) {
          setState(() {
            _currentIndex = page;
          });
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Subjects',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_alarm), // Example icon for the second tab
            label: 'Test Tab', // Example label
          ),
        ],
      ),
    );
  }
}
