import 'dart:convert';

DoctorProfile doctorProfileFromJson(String str) =>
    DoctorProfile.fromJson(json.decode(str));

String doctorProfileToJson(DoctorProfile data) => json.encode(data.toJson());

class DoctorProfile {
  String fullName;
  String? profilePicture;
  String summaryProfile;
  String speciality;
  List<WorkExperience> workExperience;

  DoctorProfile({
    required this.fullName,
    this.profilePicture,
    required this.summaryProfile,
    required this.speciality,
    required this.workExperience,
  });

  factory DoctorProfile.fromJson(Map<String, dynamic> json) {
    // ✅ Auto-handle missing or renamed fields (about / summaryProfile / bio)
    final aboutValue =
        json["summaryProfile"] ??
        json["about"] ??
        json["bio"] ??
        "No summary available.";

    return DoctorProfile(
      fullName: json["fullName"] ?? 'No name available',
      profilePicture: json["profilePicture"],
      summaryProfile: aboutValue,
      speciality: json["speciality"] ?? 'Not specified',
      workExperience: json["workExperience"] == null
          ? []
          : List<WorkExperience>.from(
              json["workExperience"].map((x) => WorkExperience.fromJson(x)),
            ),
    );
  }

  Map<String, dynamic> toJson() => {
    "fullName": fullName,
    "profilePicture": profilePicture,
    "summaryProfile": summaryProfile,
    "speciality": speciality,
    "workExperience": List<dynamic>.from(workExperience.map((x) => x.toJson())),
  };
}

class WorkExperience {
  String designation;
  String healthcareOrganization;
  String from;
  String to;
  String location;

  WorkExperience({
    required this.designation,
    required this.healthcareOrganization,
    required this.from,
    required this.to,
    required this.location,
  });

  factory WorkExperience.fromJson(Map<String, dynamic> json) => WorkExperience(
    designation: json["designation"] ?? 'Not specified',
    healthcareOrganization: json["healthcareOrganization"] ?? 'Unknown',
    from: json["from"] ?? '',
    to: json["to"] ?? '',
    location: json["location"] ?? '',
  );

  Map<String, dynamic> toJson() => {
    "designation": designation,
    "healthcareOrganization": healthcareOrganization,
    "from": from,
    "to": to,
    "location": location,
  };
}
