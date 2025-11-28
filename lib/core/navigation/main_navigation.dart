import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainNavigation extends StatefulWidget {
  final Widget child;
  final String currentPath;

  const MainNavigation({
    super.key,
    required this.child,
    required this.currentPath,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<NavigationItem> _items = [
    NavigationItem(
      path: '/feed',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Feed',
    ),
    NavigationItem(
      path: '/users-list',
      icon: Icons.search_outlined,
      activeIcon: Icons.search,
      label: 'Search',
    ),
    NavigationItem(
      path: '/create-post',
      icon: Icons.add_box_outlined,
      activeIcon: Icons.add_box,
      label: 'Create',
    ),
    NavigationItem(
      path: '/conversations',
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      label: 'Messages',
    ),
    NavigationItem(
      path: '/profile',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  @override
  void didUpdateWidget(MainNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateCurrentIndex();
  }

  @override
  void initState() {
    super.initState();
    _updateCurrentIndex();
  }

  void _updateCurrentIndex() {
    for (int i = 0; i < _items.length; i++) {
      if (widget.currentPath.startsWith(_items[i].path)) {
        setState(() => _currentIndex = i);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (_currentIndex != index) {
            context.go(_items[index].path);
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: _items.map((item) {
          final isSelected = _items.indexOf(item) == _currentIndex;
          return BottomNavigationBarItem(
            icon: Icon(isSelected ? item.activeIcon : item.icon),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }
}

class NavigationItem {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  NavigationItem({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}