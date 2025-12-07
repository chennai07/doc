import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:doc/utils/session_manager.dart';

class ScheduledInterviewScreen extends StatefulWidget {
  final String? healthcareId;
  
  const ScheduledInterviewScreen({super.key, this.healthcareId});

  @override
  State<ScheduledInterviewScreen> createState() =>
      _ScheduledInterviewScreenState();
}

class _ScheduledInterviewScreenState extends State<ScheduledInterviewScreen> {
  int selectedTab = 0;
  bool isLoading = true;
  List<dynamic> allInterviews = [];
  List<dynamic> filteredInterviews = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchInterviews();
  }

  Future<void> _fetchInterviews() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Get healthcare_id
      final healthcareId = widget.healthcareId ?? 
                          await SessionManager.getHealthcareId() ?? 
                          await SessionManager.getProfileId() ?? '';

      if (healthcareId.isEmpty) {
        setState(() {
          errorMessage = 'Healthcare ID not found. Please log in again.';
          isLoading = false;
        });
        return;
      }

      print('📅 Fetching interviews for healthcare_id: $healthcareId');

      final url = Uri.parse(
        'http://13.203.67.154:3000/api/interview/Interview-list/$healthcareId',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 15));

      print('📅 Response status: ${response.statusCode}');
      print('📅 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Handle the actual API response structure
        List<dynamic> interviews = [];
        if (data is Map) {
          if (data['data'] != null) {
            interviews = data['data'] as List;
          } else if (data['interviews'] != null) {
            interviews = data['interviews'] as List;
          }
        } else if (data is List) {
          interviews = data;
        }

        print('📅 ✅ Loaded ${interviews.length} interviews');

        setState(() {
          allInterviews = interviews;
          _filterInterviews();
          isLoading = false;
        });
      } else {
        print('📅 ❌ API error: ${response.statusCode}');
        setState(() {
          errorMessage = 'Failed to load interviews (${response.statusCode})';
          isLoading = false;
        });
      }
    } catch (e) {
      print('📅 ❌ Exception: $e');
      setState(() {
        errorMessage = 'Error loading interviews: $e';
        isLoading = false;
      });
    }
  }

  void _filterInterviews() {
    // Since the API doesn't return a status field, we'll check the interview date
    final now = DateTime.now();
    
    if (selectedTab == 0) {
      // All
      filteredInterviews = allInterviews;
    } else if (selectedTab == 1) {
      // Upcoming - interviews with future dates
      filteredInterviews = allInterviews.where((interview) {
        try {
          final dateStr = interview['interviewDate']?.toString() ?? '';
          if (dateStr.isNotEmpty) {
            final interviewDate = DateTime.parse(dateStr);
            return interviewDate.isAfter(now);
          }
        } catch (e) {
          print('Error parsing date: $e');
        }
        return false;
      }).toList();
    } else if (selectedTab == 2) {
      // Completed - interviews with past dates
      filteredInterviews = allInterviews.where((interview) {
        try {
          final dateStr = interview['interviewDate']?.toString() ?? '';
          if (dateStr.isNotEmpty) {
            final interviewDate = DateTime.parse(dateStr);
            return interviewDate.isBefore(now);
          }
        } catch (e) {
          print('Error parsing date: $e');
        }
        return false;
      }).toList();
    }
    
    print('📅 Filtered to ${filteredInterviews.length} interviews for tab $selectedTab');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? _buildErrorView()
                : _buildContent(),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _fetchInterviews,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ---------- HEADER SECTION ----------
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: 45,
                ),
                const SizedBox(width: 10),
                const Text(
                  "Interviews",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue.shade50,
                  child: const Icon(Icons.notifications_none, color: Colors.blue),
                )
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// ---------- Title ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  "Scheduled Interviews",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87),
                ),
                const Spacer(),
                Text(
                  '${filteredInterviews.length} total',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          /// ---------- TABS ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                buildTab("All", 0),
                const SizedBox(width: 10),
                buildTab("Upcoming", 1),
                const SizedBox(width: 10),
                buildTab("Completed", 2),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// ---------- INTERVIEW CARDS ----------
          if (filteredInterviews.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 60, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No interviews found',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...filteredInterviews.map((interview) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: buildInterviewCard(interview),
              );
            }).toList(),

          const SizedBox(height: 25),
        ],
      ),
    );
  }

  Widget buildTab(String label, int index) {
    bool isActive = selectedTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          selectedTab = index;
          _filterInterviews();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: isActive ? Colors.white : Colors.blue,
              fontSize: 14,
              fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget buildInterviewCard(Map<String, dynamic> interview) {
    // Extract data from actual API response structure
    // final jobId = interview['job_id']?.toString() ?? 'N/A'; // Removed as per request
    final coordinatorName = interview['coordinatorName']?.toString() ?? 'Coordinator';
    final coordinatorPhone = interview['coordinatorPhone']?.toString() ?? '';
    final startTime = interview['startTime']?.toString() ?? '';
    final endTime = interview['endTime']?.toString() ?? '';
    final instructions = interview['additionalInstructions']?.toString() ?? '';
    
    // Format date
    String formattedDate = 'Date TBD';
    DateTime? interviewDate;
    try {
      final dateStr = interview['interviewDate']?.toString() ?? '';
      if (dateStr.isNotEmpty) {
        interviewDate = DateTime.parse(dateStr);
        formattedDate = '${interviewDate.day}/${interviewDate.month}/${interviewDate.year}';
      }
    } catch (e) {
      print('Error parsing date: $e');
    }
    
    // Determine status based on date
    bool isUpcoming = false;
    if (interviewDate != null) {
      isUpcoming = interviewDate.isAfter(DateTime.now());
    }
    
    Color badgeColor = isUpcoming ? Colors.orange.shade300 : Colors.green.shade400;
    String badgeText = isUpcoming ? 'Upcoming' : 'Completed';
    
    // Combine start and end time
    String timeRange = '';
    if (startTime.isNotEmpty && endTime.isNotEmpty) {
      timeRange = '$startTime - $endTime';
    } else if (startTime.isNotEmpty) {
      timeRange = startTime;
    } else {
      timeRange = 'Time TBD';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Job ID Row - (Job ID removed, keeping badge)
          Row(
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(
                  badgeText,
                  style: TextStyle(
                      color: badgeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          const Text(
            'Interview Scheduled',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black),
          ),
          const SizedBox(height: 4),
          const Text('In-Person', style: TextStyle(fontSize: 14, color: Colors.grey)),

          const SizedBox(height: 12),

          /// Coordinator Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.blue.shade100,
                backgroundImage: (interview['profilePicture'] != null && interview['profilePicture'].toString().isNotEmpty)
                    ? NetworkImage(
                        interview['profilePicture'].toString().startsWith('http')
                            ? interview['profilePicture'].toString()
                            : 'http://13.203.67.154:3000/${interview['profilePicture']}',
                      )
                    : null,
                child: (interview['profilePicture'] == null || interview['profilePicture'].toString().isEmpty)
                    ? Text(
                        coordinatorName.isNotEmpty
                            ? coordinatorName[0].toUpperCase()
                            : 'C',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coordinatorName,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text('Coordinator', style: const TextStyle(color: Colors.grey)),
                    if (coordinatorPhone.isNotEmpty)
                      Text(coordinatorPhone, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (instructions.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      instructions,
                      style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          /// Bottom Date & Time Row
          Row(
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 18),
                  const SizedBox(width: 6),
                  Text("Date: $formattedDate"),
                ],
              ),
              const SizedBox(width: 25),
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 18),
                    const SizedBox(width: 6),
                    Flexible(child: Text(timeRange)),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
