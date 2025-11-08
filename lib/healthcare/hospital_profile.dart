import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class HospitalProfile extends StatelessWidget {
  const HospitalProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Back",
          style: GoogleFonts.poppins(color: Colors.black, fontSize: 15),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ✅ Hospital Logo
            Center(
              child: Image.asset('assets/images/apollo_logo.png', height: 100),
            ),
            const SizedBox(height: 10),

            // ✅ Hospital Name & City
            Text(
              "Apollo Hospital",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              "Bangalore",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.blue),
            ),

            const SizedBox(height: 20),

            // ✅ Contact Info Section
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 15,
              children: [
                _contactInfo(Iconsax.sms, "Email", "hello@apollo.com"),
                _contactInfo(
                  Iconsax.global,
                  "Website",
                  "https://www.apollohospitals.com",
                ),
                _contactInfo(Iconsax.call, "Phone", "1860-500-1066"),
                _contactInfo(
                  Iconsax.location,
                  "Address",
                  "4th Cross Road, 212, Dr Parvathamma Rajkumar Rd, Jayanagar, Bangalore 560011",
                ),
              ],
            ),

            const SizedBox(height: 25),

            // ✅ About Section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "About :",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Apollo Hospitals is a leading Indian multinational healthcare group and one of Asia's largest integrated healthcare providers. Apollo is known for its Centers of Excellence in specialties such as cardiac sciences, oncology, and neurosciences, utilizing advanced medical technology to achieve superior clinical outcomes.",
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.black87,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 25),

            // ✅ Departments Section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Departments:",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _departmentChip("Cardiology"),
                _departmentChip("Orthopedics"),
                _departmentChip("Neurosurgery"),
                _departmentChip("Urology"),
                _departmentChip("Oncology"),
              ],
            ),

            const SizedBox(height: 30),

            // ✅ Job Listings Section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Open Job Listings:",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 15),

            _jobCard(),
            const SizedBox(height: 15),
            _jobCard(),
            const SizedBox(height: 50),
          ],
        ),
      ),

      // ✅ Bottom Navigation Bar
      bottomNavigationBar: Container(
        height: 65,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _bottomIcon(Iconsax.search_normal, "Search", false),
            _bottomIcon(Iconsax.document, "Applied Jobs", false),
            _bottomIcon(Iconsax.user, "Profile", true),
          ],
        ),
      ),
    );
  }

  // 🔹 Contact Info Widget
  Widget _contactInfo(IconData icon, String label, String value) {
    return SizedBox(
      width: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Department Chip
  Widget _departmentChip(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFD6EDFF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        name,
        style: GoogleFonts.poppins(
          color: Colors.black87,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // 🔹 Job Listing Card
  Widget _jobCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/images/apollo_logo.png',
                height: 40,
                width: 40,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Neuro Surgeon",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      "Apollo Hospital",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "Bangalore • India",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD6EDFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.people, color: Colors.blue, size: 15),
                    const SizedBox(width: 4),
                    Text(
                      "35 Applicants",
                      style: GoogleFonts.poppins(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          Text(
            "Lorem ipsum dolor sit amet consectetur ut sagittis arcu nunc commodo morbi sem aliquet.",
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
          ),

          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _tag("Cerebro Vascular"),
              _tag("Full Time"),
              _tag("Exp: 1-3 Years"),
            ],
          ),
        ],
      ),
    );
  }

  // 🔹 Job Tag Widget
  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFD6EDFF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.blue.shade900),
      ),
    );
  }

  // 🔹 Bottom Navigation Item
  Widget _bottomIcon(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: isActive ? Colors.blue : Colors.grey, size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: isActive ? Colors.blue : Colors.grey,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
