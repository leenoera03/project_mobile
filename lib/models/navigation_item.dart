import 'package:flutter/material.dart';

enum NavigationTab {
  home,
  profile,
  search,
  about
}

class NavigationItem {
  final String label;
  final IconData icon;
  final NavigationTab tab;

  NavigationItem({
    required this.label,
    required this.icon,
    required this.tab,
  });
}

// Navigation items configuration
final List<NavigationItem> navigationItems = [
  NavigationItem(
    label: 'Beranda',
    icon: Icons.home,
    tab: NavigationTab.home,
  ),
  NavigationItem(
    label: 'Profil',
    icon: Icons.person,
    tab: NavigationTab.profile,
  ),
  NavigationItem(
    label: 'Cari',
    icon: Icons.search,
    tab: NavigationTab.search,
  ),
  NavigationItem(
    label: 'Tentang',
    icon: Icons.info,
    tab: NavigationTab.about,
  ),
];