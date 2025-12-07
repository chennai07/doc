import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:doc/utils/session_manager.dart';

class ScheduleInterviewPage extends StatefulWidget {
  final String? jobId;
  final String? candidateId;
  final String? healthcareId;

  const ScheduleInterviewPage({
    super.key,
    this.jobId,
    this.candidateId,
    this.healthcareId,
  });

  @override
  State<ScheduleInterviewPage> createState() => _ScheduleInterviewPageState();
}

class _ScheduleInterviewPageState extends State<ScheduleInterviewPage> {
  bool confirm = false;

  String selectedDate = "DD/MM/YYYY";
  String startTime = "Start time";
  String endTime = "End time";

  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _coordinatorNameController =
      TextEditingController();
  final TextEditingController _coordinatorPhoneController =
      TextEditingController();

  Future<void> pickDate() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2040),
      initialDate: DateTime.now(),
    );

    if (d != null) {
      setState(() {
        selectedDate = "${d.day}/${d.month}/${d.year}";
      });
    }
  }

  Future<void> pickStartTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (t != null) {
      setState(() => startTime = t.format(context));
    }
  }

  Future<void> pickEndTime() async {
    if (startTime == "Start time") {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Please select Start Time first')),
       );
       return;
    }

    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (t != null) {
      try {
        final start = _parseTime(startTime);
        final double startVal = start.hour + start.minute / 60.0;
        final double endVal = t.hour + t.minute / 60.0;

        if (endVal <= startVal) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('End time must be after start time')),
          );
          return;
        }
      } catch (e) {
        print('Time comparison error: $e');
      }

      setState(() => endTime = t.format(context));
    }
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    _coordinatorNameController.dispose();
    _coordinatorPhoneController.dispose();
    super.dispose();
  }

  Future<void> _scheduleInterview() async {
    if (!confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please confirm the interview details.')),
      );
      return;
    }

    if (selectedDate == 'DD/MM/YYYY' ||
        startTime == 'Start time' ||
        endTime == 'End time') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time slot.')),
      );
      return;
    }

    // Validate Start Time < End Time
    try {
      final start = _parseTime(startTime);
      final end = _parseTime(endTime);
      
      final now = DateTime.now();
      final startDt = DateTime(now.year, now.month, now.day, start.hour, start.minute);
      final endDt = DateTime(now.year, now.month, now.day, end.hour, end.minute);
      
      if (endDt.isBefore(startDt) || endDt.isAtSameMomentAs(startDt)) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time must be greater than start time')),
        );
        return;
      }
    } catch (e) {
      print('Error parsing time: $e');
    }

    // Get healthcare_id
    final healthcareId = widget.healthcareId ?? 
                        await SessionManager.getHealthcareId() ?? 
                        await SessionManager.getProfileId() ?? '';

    if (healthcareId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Healthcare ID not found. Please log in again.')),
      );
      return;
    }

    print('📅 Scheduling interview with healthcare_id: $healthcareId');

    // Convert date format from DD/MM/YYYY to ISO format
    String isoDate = '';
    try {
      final parts = selectedDate.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        isoDate = DateTime(year, month, day).toIso8601String();
      }
    } catch (e) {
      print('Error parsing date: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid date format')),
      );
      return;
    }

    final uri = Uri.parse(
      'http://13.203.67.154:3000/api/interview/schedule-Interview',
    );

    // Use the correct field names that the backend expects
    final payload = {
      'job_id': widget.jobId ?? '',
      'healthcare_id': healthcareId,
      'surgeonprofile_id': widget.candidateId ?? '',
      'interviewDate': isoDate,
      'startTime': startTime,
      'endTime': endTime,
      'additionalInstructions': _instructionsController.text.trim(),
      'coordinatorName': _coordinatorNameController.text.trim(),
      'coordinatorPhone': _coordinatorPhoneController.text.trim(),
      'confirmAgreement': confirm,
    };

    print('📅 Payload: ${jsonEncode(payload)}');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      print('📅 Response status: ${response.statusCode}');
      print('📅 Response body: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Interview scheduled successfully!')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        String errorMsg = 'Failed to schedule interview (${response.statusCode})';
        try {
          final data = jsonDecode(response.body);
          if (data is Map && data['message'] != null) {
            errorMsg = data['message'].toString();
          }
        } catch (_) {}
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    } catch (e) {
      print('📅 Error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scheduling interview: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- HEADER ----------
              const Text(
                "Schedule an Interview",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                "Finalize interview details with the shortlisted surgeon.",
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),

              const SizedBox(height: 30),

              // ---------- INTERVIEW MODE ----------
              const Text(
                "Interview Mode: In Person",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 12),

              const SizedBox(height: 12),

              const SizedBox(height: 25),

              // ---------- INTERVIEW DATE ----------
              const Text(
                "Interview Date:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),

              GestureDetector(
                onTap: pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(selectedDate, style: const TextStyle(fontSize: 15)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // ---------- TIME SLOT ----------
              const Text(
                "Preferred Time Slot:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: pickStartTime,
                      child: _timeBox(startTime),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: pickEndTime,
                      child: _timeBox(endTime),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // ---------- ADDITIONAL INSTRUCTIONS ----------
              const Text(
                "Additional Instructions (Optional)",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _instructionsController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText:
                      "Add in details you want to share with the applicant",
                  hintStyle: const TextStyle(color: Colors.grey),
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // ---------- COORDINATOR DETAILS ----------
              const Text(
                "Interview Co-ordinator Details:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),

              const Text("Name:"),
              const SizedBox(height: 6),
              _inputBox("Enter Name", _coordinatorNameController),

              const SizedBox(height: 20),

              const Text("Phone Number:"),
              const SizedBox(height: 6),
              _inputBox("Enter Phone Number", _coordinatorPhoneController),

              const SizedBox(height: 20),

              // ---------- CHECKBOX ----------
              Row(
                children: [
                  Checkbox(
                    value: confirm,
                    activeColor: Colors.blue,
                    onChanged: (val) {
                      setState(() => confirm = val ?? false);
                    },
                  ),
                  const Expanded(
                    child: Text(
                      "I confirm the interview details and agree to notify the surgeon",
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // ---------- BUTTONS ----------
              Row(
                children: [
                  // Schedule Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _scheduleInterview,

                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff0072FF),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Schedule Interview",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Cancel Button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.blue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Colors.blue, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- COMPONENTS ----------

  Widget _timeBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time, color: Colors.grey, size: 18),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }

  Widget _inputBox(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
  TimeOfDay _parseTime(String timeStr) {
    try {
      // Clean up the string (trim spaces/non-breaking spaces)
      timeStr = timeStr.trim().replaceAll('\u00A0', ' ');
      
      if (timeStr.toUpperCase().contains("AM") || timeStr.toUpperCase().contains("PM")) {
        final parts = timeStr.split(" ");
        if (parts.length < 2) throw FormatException("Invalid time format");
        
        final timeParts = parts[0].split(":");
        if (timeParts.length < 2) throw FormatException("Invalid time parts");

        int hour = int.parse(timeParts[0]);
        int minute = int.parse(timeParts[1]);
        final period = parts[1].toUpperCase();

        if (period == "PM" && hour != 12) hour += 12;
        if (period == "AM" && hour == 12) hour = 0;
        return TimeOfDay(hour: hour, minute: minute);
      } else {
        final parts = timeStr.split(":");
         if (parts.length < 2) throw FormatException("Invalid 24h format");
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    } catch (e) {
      print('Time parsing error: $e');
      throw e;
    }
  }
}
