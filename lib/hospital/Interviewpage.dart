import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ScheduleInterviewPage extends StatefulWidget {
  final String? jobId;
  final String? candidateId;

  const ScheduleInterviewPage({
    super.key,
    this.jobId,
    this.candidateId,
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
      firstDate: DateTime(2020),
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
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (t != null) {
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

    final uri = Uri.parse(
      'http://13.203.67.154:3000/api/interview/schedule-Interview',
    );

    final payload = {
      'jobId': widget.jobId,
      'candidateId': widget.candidateId,
      'date': selectedDate,
      'startTime': startTime,
      'endTime': endTime,
      'instructions': _instructionsController.text.trim(),
      'coordinatorName': _coordinatorNameController.text.trim(),
      'coordinatorPhone': _coordinatorPhoneController.text.trim(),
    };

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Interview scheduled successfully.')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to schedule interview (${response.statusCode})',
            ),
          ),
        );
      }
    } catch (e) {
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

              const Text(
                "Address: Apollo Spectra Hospitals, 143, 1st Cross Rd, near\n"
                "Nagarjuna Hotel, KHB Colony, 5th Block, Koramangala,\n"
                "Bengaluru, Karnataka 560095",
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),

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
                      onPressed: () {},
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
}
