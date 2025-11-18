import 'package:flutter/material.dart';
import 'package:doc/healthcare/hospital_profile.dart';

class Navbar extends StatefulWidget {
  final Map<String, dynamic> hospitalData;

  const Navbar({super.key, required this.hospitalData});

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  int selectedIndex = 0;

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = [
      HospitalProfile(
        data: widget.hospitalData,
        showBottomBar: false,
      ),
      const ApplicantsPage(),
      const MyJobsPage(),
      const ScheduleInterviewPage(),
    ];
  }

  void onTabSelected(int index) {
    setState(() => selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: pages[selectedIndex],

      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(color: Colors.white),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(index: 0, icon: Icons.home, label: "Profile"),
            _navItem(index: 1, icon: Icons.group, label: "Applicants"),
            _navItem(index: 2, icon: Icons.add, label: "Post Job"),
            _navItem(index: 3, icon: Icons.calendar_month, label: "Interviews"),
          ],
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = selectedIndex == index;

    const Color selectedColor = Color(0xFF094277); // Dark Blue
    const Color unselectedColor = Color(0xFF117BDD); // Light Blue

    return GestureDetector(
      onTap: () => onTabSelected(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 28,
            color: isSelected ? selectedColor : unselectedColor,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? selectedColor : unselectedColor,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class ApplicantsPage extends StatelessWidget {
  const ApplicantsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          'Applicants screen coming soon',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

class MyJobsPage extends StatelessWidget {
  const MyJobsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          'My Jobs screen coming soon',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

class ScheduleInterviewPage extends StatelessWidget {
  const ScheduleInterviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          'Interviews screen coming soon',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
