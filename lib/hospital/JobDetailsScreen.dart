import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class JobDetailScreen extends StatelessWidget {
  final Map<String, dynamic> job;
  final void Function(Map<String, dynamic>) onEdit;
  final VoidCallback onClose;
  final VoidCallback onDelete;
  final VoidCallback onViewApplicants;
  final void Function(String candidateId)? onScheduleInterview;

  const JobDetailScreen({
    super.key,
    required this.job,
    required this.onEdit,
    required this.onClose,
    required this.onDelete,
    required this.onViewApplicants,
    this.onScheduleInterview,
  });

  @override
  Widget build(BuildContext context) {
    // local presentation values (not mutable here)
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar + posted date + action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back_ios, size: 16),
                        SizedBox(width: 6),
                        Text("Back", style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Posted on ${(job['postedOn'] ?? '').toString()}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ],
              ),
            ),
            // Take Action dropdown mock
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => _showTakeActionMenu(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Take Action",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.keyboard_arrow_down, color: Colors.blue),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 6),
                    Center(child: Image.asset("assets/logo.png", height: 90)),
                    const SizedBox(height: 8),
                    Text(
                      (job['jobTitle'] ?? job['title'] ?? '').toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _iconText(Icons.local_hospital, "Apollo Hospital"),
                        const SizedBox(width: 18),
                        _iconText(
                          Icons.location_on_outlined,
                          job['location'] ?? "",
                        ),
                        const SizedBox(width: 18),
                        _iconText(Icons.school, job['experience'] ?? ""),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // full-time + salary pill
                    // ---------- FULL TIME + SALARY BOX (Exact UI) ----------
                    Container(
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0062FF), Color(0xFF3E8BFF)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          // ---------- LEFT SIDE ----------
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.work,
                                  color: Colors.white,
                                  size: 26,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  job['type'] ?? 'Full Time',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ---------- DIVIDER ----------
                          Container(
                            width: 1,
                            height: 45,
                            color: Colors.white.withOpacity(0.45),
                          ),

                          // ---------- RIGHT SIDE ----------
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.attach_money,
                                  color: Colors.white,
                                  size: 26,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  job['salary'] ?? '₹28,00,000 / yr',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    _sectionTitle("Department:"),
                    _sectionText(job['department'] ?? ''),
                    _sectionTitle("Sub-Speciality:"),
                    _sectionText(job['subSpeciality'] ?? ''),
                    _sectionTitle("Interview Mode:"),
                    _sectionText("In-person"),
                    _sectionTitle("About the Role:"),
                    _sectionText(job['description'] ?? ''),
                    _sectionTitle("Key Responsibilities:"),
                    _bulletList([
                      "Evaluate patients and perform assessments.",
                      "Conduct surgeries with precision.",
                      "Provide pre- and post-operative care.",
                      "Collaborate with multi-disciplinary teams.",
                      "Stay updated with latest clinical advancements.",
                    ]),
                    _sectionTitle("Preferred Qualifications:"),
                    _bulletList([
                      "MBBS with relevant specialization.",
                      "Registration with Medical Council.",
                      "Minimum 5 years of experience preferred.",
                    ]),
                    _sectionTitle("Application Deadline:"),
                    _sectionText(job['deadline'] ?? ''),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff0062FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: onViewApplicants,
                        child: const Text(
                          "View Applicants",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pillItem({required IconData icon, required String label}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  Widget _iconText(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 6),
        Text(title, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Widget _sectionTitle(String text) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 16, bottom: 6),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
    ),
  );

  Widget _sectionText(String text) => Container(
    width: double.infinity,
    child: Text(
      text,
      textAlign: TextAlign.left,
      style: const TextStyle(fontSize: 14, height: 1.6),
    ),
  );

  Widget _bulletList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("•  ", style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(
                      e,
                      style: const TextStyle(fontSize: 14, height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  // Take Action menu: shows Edit / Close / Delete (mock)
  void _showTakeActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text("Edit Job"),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text("Close Job"),
                onTap: () {
                  Navigator.pop(ctx);
                  onClose();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Job marked Closed")),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("Delete Job"),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context) {
    final titleController = TextEditingController(
      text: (job['jobTitle'] ?? job['title'] ?? '').toString(),
    );
    final deadlineController = TextEditingController(
      text: (job['deadline'] ?? '').toString(),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Job'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: deadlineController,
              decoration: const InputDecoration(labelText: 'Deadline'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final jobId = (job['_id'] ?? job['id'] ?? '').toString();
              if (jobId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Job id not found')), 
                );
                Navigator.pop(ctx);
                return;
              }

              final uri = Uri.parse(
                'http://13.203.67.154:3000/api/jobs/applied-jobs/jobs-edit/$jobId',
              );

              final payload = {
                'jobTitle': titleController.text,
                'deadline': deadlineController.text,
              };

              try {
                final response = await http.put(
                  uri,
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(payload),
                );

                if (response.statusCode == 200 || response.statusCode == 201) {
                  onEdit({
                    'jobTitle': titleController.text,
                    'title': titleController.text,
                    'deadline': deadlineController.text,
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Job updated')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to update job $jobId (${response.statusCode})',
                      ),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating job: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Job'),
        content: const Text('This action cannot be undone. Delete the job?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              onDelete();
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // close detail screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Job deleted (mock)')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ----------------- ApplicantsListPage -----------------
class ApplicantsListPage extends StatelessWidget {
  final String jobId;
  final List<Map<String, dynamic>> applicants;

  const ApplicantsListPage({
    super.key,
    required this.jobId,
    required this.applicants,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Applicants for $jobId"),
        backgroundColor: Colors.blue,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: applicants.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final a = applicants[index];
          final firstName = (a['firstName'] ?? a['name'] ?? '').toString();
          final lastName = (a['lastName'] ?? '').toString();
          final name = [firstName, lastName]
              .where((s) => s.isNotEmpty)
              .join(' ')
              .trim();
          final experience = (a['experience'] ?? '').toString();
          final createdRaw =
              (a['createdAt'] ?? a['appliedOn'] ?? '').toString();
          final appliedOn = createdRaw.contains('T')
              ? createdRaw.split('T').first
              : createdRaw;
          final status = (a['status'] ?? '').toString();
          final isShortlisted = status.toLowerCase() == 'shortlisted';
          return ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            leading: CircleAvatar(
              child: Text(
                name.isNotEmpty ? name[0] : '?',
              ),
            ),
            title: Text(name.isNotEmpty ? name : 'Unknown'),
            subtitle: Text(
              "${experience.isNotEmpty ? experience : 'Experience N/A'} • ${appliedOn.isNotEmpty ? appliedOn : 'Date N/A'}",
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color:
                    isShortlisted ? Colors.green[100] : const Color(0xffe8f1ff),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status.isNotEmpty ? status : 'N/A',
                style: const TextStyle(color: Colors.blue),
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ApplicantProfilePage(
                    applicant: a,
                    qualification: '',
                    currentRole: '',
                    imagePath: '',
                    role: '',
                    location: '',
                    name: '',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ----------------- ApplicantProfilePage -----------------
class ApplicantProfilePage extends StatelessWidget {
  final Map<String, dynamic> applicant;

  const ApplicantProfilePage({
    super.key,
    required this.applicant,
    required String qualification,
    required String currentRole,
    required String imagePath,
    required String role,
    required String location,
    required String name,
  });

  @override
  Widget build(BuildContext context) {
    final firstName =
        (applicant['firstName'] ?? applicant['name'] ?? '').toString();
    final lastName = (applicant['lastName'] ?? '').toString();
    final fullName = [firstName, lastName]
        .where((s) => s.isNotEmpty)
        .join(' ')
        .trim();
    final createdRaw = (applicant['createdAt'] ?? applicant['appliedOn'] ?? '')
        .toString();
    final appliedOn = createdRaw.contains('T')
        ? createdRaw.split('T').first
        : createdRaw;
    final status = (applicant['status'] ?? '').toString();
    final resume = (applicant['cvResume'] ?? applicant['resume'] ?? '').toString();
    final experience = (applicant['experience'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(fullName.isNotEmpty ? fullName : 'Applicant'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  child: Text(
                    fullName.isNotEmpty ? fullName[0] : '?',
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName.isNotEmpty ? fullName : 'Unknown',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      experience.isNotEmpty ? experience : 'Experience N/A',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              "Applied On: ${appliedOn.isNotEmpty ? appliedOn : 'N/A'}",
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Text(
              "Status: ${status.isNotEmpty ? status : 'N/A'}",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            const Text("Resume", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              tileColor: const Color(0xfff8f9ff),
              leading: const Icon(Icons.picture_as_pdf),
              title: Text(
                resume.isNotEmpty
                    ? resume.split('/').last
                    : 'No resume uploaded',
              ),
              subtitle: Text(
                resume.isNotEmpty ? 'Tap to view' : 'No file available',
              ),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening resume...')),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Shortlisted')),
                    ),
                    child: const Text("Shortlist"),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Rejected')),
                  ),
                  child: const Text("Reject"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------- ApplicantsOverview (simple) -----------------
class ApplicantsOverview extends StatelessWidget {
  final Map<String, List<Map<String, dynamic>>> applicantsByJobId;
  const ApplicantsOverview({super.key, required this.applicantsByJobId});

  @override
  Widget build(BuildContext context) {
    final total = applicantsByJobId.values.fold<int>(0, (p, e) => p + e.length);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Applicants",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              "Total applicants across jobs: $total",
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: applicantsByJobId.entries
                    .map(
                      (e) => Card(
                        child: ListTile(
                          title: Text(e.key),
                          subtitle: Text("${e.value.length} applicants"),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ApplicantsListPage(
                                  jobId: e.key,
                                  applicants: e.value,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------- PostJobPlaceholder -----------------
class PostJobPlaceholder extends StatelessWidget {
  const PostJobPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    return const SafeArea(child: Center(child: Text("Post Job (placeholder)")));
  }
}

// ----------------- InterviewsPlaceholder -----------------
class InterviewsPlaceholder extends StatelessWidget {
  final void Function(BuildContext) onScheduleInterview;
  const InterviewsPlaceholder({super.key, required this.onScheduleInterview});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 60),
          const Text(
            "Interviews",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => onScheduleInterview(context),
            child: const Text("Schedule Interview (global)"),
          ),
        ],
      ),
    );
  }
}

// ----------------- ScheduleInterviewPage -----------------
class ScheduleInterviewPage extends StatefulWidget {
  final String? jobId;
  final String? candidateId;
  const ScheduleInterviewPage({super.key, this.jobId, this.candidateId});

  @override
  State<ScheduleInterviewPage> createState() => _ScheduleInterviewPageState();
}

class _ScheduleInterviewPageState extends State<ScheduleInterviewPage> {
  DateTime? pickedDate;
  TimeOfDay? pickedTime;
  final TextEditingController noteController = TextEditingController();

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (d != null) setState(() => pickedDate = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (t != null) setState(() => pickedTime = t);
  }

  void _submit() {
    if (pickedDate == null || pickedTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please pick date & time')));
      return;
    }
    final scheduled = DateTime(
      pickedDate!.year,
      pickedDate!.month,
      pickedDate!.day,
      pickedTime!.hour,
      pickedTime!.minute,
    );
    // Mock: show confirmation
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Interview Scheduled'),
        content: Text(
          'Interview scheduled on ${scheduled.toString()}.\nNote: ${noteController.text}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.jobId != null
        ? 'Schedule Interview for ${widget.jobId}'
        : 'Schedule Interview';
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: Colors.blue),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Select Date'),
              subtitle: Text(
                pickedDate == null
                    ? 'Not chosen'
                    : pickedDate!.toLocal().toString().split(' ')[0],
              ),
              onTap: _pickDate,
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Select Time'),
              subtitle: Text(
                pickedTime == null ? 'Not chosen' : pickedTime!.format(context),
              ),
              onTap: _pickTime,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _submit, child: const Text('Schedule')),
          ],
        ),
      ),
    );
  }
}
