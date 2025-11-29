# Hospital Profile - Real Job Data Integration

## Summary
Updated the Hospital Profile screen to display **real job listings** from the backend API, replacing the previously hardcoded placeholder data.

## Changes Made

### 1. Converted to StatefulWidget (`hospital_profile.dart`)
- Changed from `StatelessWidget` to `StatefulWidget` to support API calls
- Added state management for job data, loading states, and errors

### 2. Added Job Fetching Functionality
```dart
Future<void> _fetchJobs() async
```
- **API Endpoint**: `http://13.203.67.154:3000/api/healthcare/joblist-healthcare/{healthcareId}`
- Same endpoint used in `MyJobsPage` for consistency
- Fetches jobs specific to the hospital using `healthcare_id` from profile data
- Handles loading states, errors, and empty states

### 3. Dynamic Job Cards
Updated `_jobCard()` to accept and display real job data:
- **Job Title**: `job['jobTitle']`
- **Hospital Name**: From profile data
- **Location**: `job['location']` with fallback to hospital location
- **Description**: `job['aboutRole']`
- **Tags**: Dynamically shows subspeciality, employment type, and experience
- **Applicant Count**: `job['applicantCount']` (shows "0 Applicants" if not available)

### 4. UI States
The "Open Job Listings" section now shows:
- **Loading**: Spinner while fetching jobs
- **Error**: Error message if fetch fails
- **Empty**: "No job openings available at the moment" if no jobs
- **Job Cards**: List of actual job postings with real data

## API Response Structure
The component expects job data in this format:
```json
{
  "data": [
    {
      "jobTitle": "Neuro Surgeon",
      "location": "Bangalore",
      "aboutRole": "Description of the role...",
      "subSpeciality": "Cerebro Vascular",
      "employmentType": "Full Time",
      "experienceRequired": "1-3 Years",
      "applicantCount": "35"
    }
  ]
}
```

## Data Flow
1. **Hospital Profile Loads** → Gets `healthcare_id` from `widget.data`
2. **Fetch Jobs** → Calls API with `healthcare_id`
3. **Display Results** → Shows jobs or appropriate state (loading/error/empty)

## Screenshot Reference
The implementation matches the provided screenshot showing:
- Hospital profile information at top
- Departments section
- **"Open Job Listings:"** section with real job cards
- Each job card shows:
  - Job title (blue, clickable-looking)
  - Hospital name
  - Location
  - Applicant count badge
  - Job description
  - Tags (subspeciality, employment type, experience)

## Code Location
**File**: `lib/healthcare/hospital_profile.dart`

**Key Sections**:
- Lines 17-119: State class with job fetching logic
- Lines 260-306: Job listings display with state handling
- Lines 391-505: Dynamic job card widget

## Testing
To test the implementation:
1. **Sign in** as a hospital user
2. **Navigate** to Hospital Profile
3. **Verify**: Real job listings appear in the "Open Job Listings" section
4. **Check**: Job titles, locations, descriptions match actual posted jobs
5. **Test Empty State**: Should show "No job openings" if hospital has no jobs
6. **Test Error**: If API fails, should show error message

## Logging
Added console logging for debugging:
- `🏥 Fetching jobs for healthcare_id: [id]`
- `🏥 Jobs API response status: [status]`
- `🏥 ✅ Fetched [count] jobs`
- `🏥 No jobs found for this hospital`
- `🏥 ❌ Failed to fetch jobs: [error]`

## Benefits
✅ **Real Data**: Shows actual job postings from the hospital  
✅ **Consistency**: Uses same API as MyJobsPage  
✅ **User Experience**: Proper loading and error states  
✅ **Dynamic**: Automatically updates when jobs are added/removed  
✅ **Accurate**: Displays correct applicant counts and job details  

## Next Steps (Optional Enhancements)
1. **Fetch Actual Applicant Counts**: Query applications API for each job
2. **Make Jobs Clickable**: Navigate to job details when clicked
3. **Add Refresh**: Pull-to-refresh functionality
4. **Filter Options**: Filter by status (Active/Closed)
5. **Pagination**: If hospital has many jobs
