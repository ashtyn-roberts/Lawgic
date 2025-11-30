import 'package:flutter/material.dart';
import 'home_tab.dart';
import 'profile_tab.dart';
import 'map_tab.dart';
import 'calendar_tab.dart';
import 'chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'bill_details_tab.dart';

class HomeScreen extends StatefulWidget {
  final String currentParish;
  final String currentElectionDate;
  const HomeScreen({super.key, required this.currentParish, required this.currentElectionDate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeTab(
        currentParish: widget.currentParish,
        currentElectionDate: widget.currentElectionDate,
      ),
      const CalendarTab(),
      const MapTab(),
      const AIChatScreen(),
      const ProfileTab(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // This ensures all 4 tabs are visible
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: 'AI Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        onTap: _onItemTapped,
      ),
    );
  }
}