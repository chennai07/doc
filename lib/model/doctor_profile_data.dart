class DoctorProfileData {
  final String name;
  final String speciality;
  final String summary;
  final String degree;
  final String subSpeciality;
  final String designation;
  final String organization;
  final String period;
  final String workLocation;
  final String phone;
  final String email;
  final String location;
  final String portfolio;

  DoctorProfileData({
    required this.name,
    required this.speciality,
    required this.summary,
    required this.degree,
    required this.subSpeciality,
    required this.designation,
    required this.organization,
    required this.period,
    required this.workLocation,
    required this.phone,
    required this.email,
    required this.location,
    required this.portfolio,
  });

  factory DoctorProfileData.fromMap(Map<String, dynamic> data) {
    // Handle nested data structures
    final profile = data['data'] is Map ? data['data'] : data;
    final profileData = profile['profile'] is Map ? profile['profile'] : profile;
    
    // Extract work experience for designation, organization, etc.
    String designation = '';
    String organization = '';
    String period = '';
    String workLocation = '';
    
    if (profileData['workExperience'] is List && (profileData['workExperience'] as List).isNotEmpty) {
      final firstExp = (profileData['workExperience'] as List).first;
      if (firstExp is Map) {
        designation = firstExp['designation']?.toString() ?? '';
        organization = firstExp['healthcareOrganization']?.toString() ?? firstExp['organization']?.toString() ?? '';
        final from = firstExp['from']?.toString() ?? '';
        final to = firstExp['to']?.toString() ?? '';
        period = from.isNotEmpty && to.isNotEmpty ? '$from - $to' : '';
        workLocation = firstExp['location']?.toString() ?? '';
      }
    }

    return DoctorProfileData(
      name: profileData['fullName']?.toString() ?? profileData['fullname']?.toString() ?? '',
      speciality: profileData['speciality']?.toString() ?? '',
      summary: profileData['summaryProfile']?.toString() ?? '',
      degree: profileData['degree']?.toString() ?? '',
      subSpeciality: profileData['subSpeciality']?.toString() ?? '',
      designation: designation,
      organization: organization,
      period: period,
      workLocation: workLocation,
      phone: profileData['phoneNumber']?.toString() ?? '',
      email: profileData['email']?.toString() ?? '',
      location: profileData['location']?.toString() ?? profileData['state']?.toString() ?? '',
      portfolio: profileData['portfolioLinks']?.toString() ?? '',
    );
  }
}
