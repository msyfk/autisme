// lib/pages/main_navigation.dart

import 'package:autisme/pages/home_page.dart';
import 'package:autisme/pages/profile_page.dart';
import 'package:autisme/pages/reminder_page.dart';
import 'package:flutter/material.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0; // Indeks halaman yang sedang aktif

  // Daftar halaman yang akan ditampilkan di menu
  static const List<Widget> _pages = <Widget>[
    HomePage(), // Indeks 0: Dashboard
    ReminderPage(), // Indeks 1: Pengingat
    ProfilePage(), // Indeks 2: Profil
  ];

  // Daftar judul untuk AppBar
  static const List<String> _titles = <String>[
    'Dashboard',
    'Pengingat',
    'Profil',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Judul akan berubah sesuai halaman yang dipilih
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: _pages.elementAt(
          _selectedIndex,
        ), // Tampilkan halaman yang dipilih
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Pengingat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue.shade800,
        onTap: _onItemTapped, // Panggil fungsi saat item di-tap
      ),
    );
  }
}
