# CRITICAL: Backend Profile Corruption After Job Posting

## The Issue

**User Report:** After a hospital user posts a job listing, they get logged out. When they try to log in again, they see:
```
⚠️ Your profile exists but couldn't be loaded.
Please check your internet connection and try signing in again.
```

## Console Analysis

```
I/flutter: 🔑 Found ID in userData: 692f099618319d98bf5d4f67
I/flutter: 🔑 Healthcare ID from login response: 692f099618319d98bf5d4f67
I/flutter: 🔑 User email: hangersmens@gmail.com
I/flutter: 🔑 Attempt 1/1: Fetching with ID: 692f099618319d98bf5d4f67
I/flutter: 🔑 Response status: 200  ← Backend finds the profile!
I/flutter: 🔑 ⚠️ ID 692f099618319d98bf5d4f67 returned empty data  ← But data is EMPTY!
I/flutter: 🔑 ⚠️ ID-based lookup failed. Trying email lookup...
I/flutter: 🔑 Email lookup response status: 404  ← Email lookup also fails!
```

### What This Tells Us:

1. ✅ **Sign-in works**: Backend authenticates user and returns ID
2. ✅ **Profile exists**: GET request returns 200 (not 404)
3. ❌ **Profile data is empty**: Response has no hospitalName, email, phoneNumber
4. ❌ **Email lookup fails**: Profile cannot be found by email (404)

## Root Cause

**The backend is corrupting or deleting hospital profile data when a job is posted.**

### Possible Backend Issues:

#### Issue 1: Job Posting Overwrites Hospital Profile
```javascript
// BAD BACKEND CODE (example):
await HealthcareProfile.findByIdAndUpdate(
  healthcare_id,
  { $set: jobData }  // ❌ This overwrites the entire profile!
);
```

**Should be:**
```javascript
// GOOD BACKEND CODE:
await JobPosting.create({
  healthcare_id: healthcare_id,
  ...jobData
});
// Keep hospital profile separate!
```

#### Issue 2: Job Posting Deletes Required Fields
```javascript
// BAD BACKEND CODE (example):
await HealthcareProfile.findByIdAndUpdate(
  healthcare_id,
  { $unset: { hospitalName: "", email: "", phoneNumber: "" } }  // ❌ Deletes fields!
);
```

#### Issue 3: Wrong ID Used in Job Posting
```javascript
// BAD BACKEND CODE (example):
// Job posting uses healthcare_id as the profile _id
// But then updates the wrong document
await HealthcareProfile.findByIdAndUpdate(
  req.body.healthcare_id,  // This might be user._id, not profile._id!
  { ...updates }
);
```

## What Needs to Be Fixed (Backend)

### 1. Check Job Posting Endpoint
**File**: Backend `/api/healthcare/jobpost` endpoint

**What to check:**
- Does it modify the hospital profile?
- Does it use the correct healthcare_id?
- Does it accidentally delete or overwrite profile fields?

### 2. Check Profile Fetch Endpoint
**File**: Backend `/api/healthcare/healthcare-profile/:id` endpoint

**What to check:**
- Why does it return 200 with empty data?
- Is it looking up the wrong collection?
- Is it returning a deleted/corrupted document?

### 3. Check Email Lookup Endpoint
**File**: Backend `/api/healthcare/healthcare-profile/email/:email` endpoint

**What to check:**
- Why does it return 404 after job posting?
- Is the email field being deleted from the profile?
- Is it searching the wrong collection?

## Debugging Steps for Backend Developer

### Step 1: Check Database After Job Posting
```javascript
// After a job is posted, check the hospital profile:
const profile = await HealthcareProfile.findById(healthcare_id);
console.log('Profile after job posting:', profile);

// Check if required fields still exist:
console.log('hospitalName:', profile.hospitalName);
console.log('email:', profile.email);
console.log('phoneNumber:', profile.phoneNumber);
```

### Step 2: Check Job Posting Code
```javascript
// In the job posting endpoint, add logging:
router.post('/jobpost', async (req, res) => {
  const { healthcare_id } = req.body;
  
  console.log('Job posting for healthcare_id:', healthcare_id);
  
  // Check profile BEFORE job posting
  const profileBefore = await HealthcareProfile.findById(healthcare_id);
  console.log('Profile BEFORE job posting:', profileBefore);
  
  // ... job posting logic ...
  
  // Check profile AFTER job posting
  const profileAfter = await HealthcareProfile.findById(healthcare_id);
  console.log('Profile AFTER job posting:', profileAfter);
  
  // Compare to see what changed
  if (JSON.stringify(profileBefore) !== JSON.stringify(profileAfter)) {
    console.error('⚠️ PROFILE WAS MODIFIED BY JOB POSTING!');
  }
});
```

### Step 3: Check Profile Fetch Code
```javascript
// In the profile fetch endpoint:
router.get('/healthcare-profile/:id', async (req, res) => {
  const { id } = req.params;
  
  console.log('Fetching profile with ID:', id);
  
  const profile = await HealthcareProfile.findById(id);
  
  console.log('Found profile:', profile);
  console.log('Profile fields:', {
    _id: profile?._id,
    healthcare_id: profile?.healthcare_id,
    hospitalName: profile?.hospitalName,
    email: profile?.email,
    phoneNumber: profile?.phoneNumber
  });
  
  // Check if profile is empty
  if (profile && !profile.hospitalName && !profile.email) {
    console.error('⚠️ PROFILE EXISTS BUT HAS NO DATA!');
  }
  
  res.json({ data: profile });
});
```

## Expected Backend Behavior

### Correct Flow:
```
1. User creates hospital profile
   → HealthcareProfile document created with all fields
   → _id: "abc123"
   → healthcare_id: "user_id_xyz"
   → hospitalName: "Test Hospital"
   → email: "hangersmens@gmail.com"
   → etc.

2. User posts a job
   → JobPosting document created (separate collection!)
   → healthcare_id: "abc123" (references the profile)
   → jobTitle: "Surgeon"
   → etc.
   → HealthcareProfile document UNCHANGED ✅

3. User logs in again
   → Backend returns user._id: "user_id_xyz"
   → Frontend fetches profile with healthcare_id
   → Backend returns full profile with all fields ✅
```

### Current (Broken) Flow:
```
1. User creates hospital profile
   → HealthcareProfile document created ✅

2. User posts a job
   → Something goes wrong here! ❌
   → HealthcareProfile document gets corrupted/deleted
   → OR email field gets removed
   → OR document gets replaced with job data

3. User logs in again
   → Backend returns user._id
   → Frontend fetches profile
   → Backend returns 200 but with empty data ❌
   → Email lookup returns 404 ❌
```

## Frontend Workaround (Temporary)

While the backend is being fixed, I can add a frontend workaround to detect this issue and guide the user:

```dart
// In signin_screen.dart, after detecting empty profile:
if (resp.statusCode == 200 && !hasValidProfile) {
  // Profile exists but is corrupted
  print('🔑 ⚠️ Profile is corrupted (empty data)');
  
  // Show helpful error message
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        '⚠️ Your profile data was corrupted.\n'
        'This is a known issue after posting jobs.\n'
        'Please contact support or recreate your profile.',
      ),
      duration: Duration(seconds: 10),
      backgroundColor: Colors.orange,
    ),
  );
  
  // Option: Navigate to profile form to recreate
  // (But this would create duplicate profiles!)
}
```

## Recommended Backend Fix

### Option 1: Separate Collections (BEST)
```javascript
// Keep hospital profiles and job postings in separate collections
const HealthcareProfile = mongoose.model('HealthcareProfile', ...);
const JobPosting = mongoose.model('JobPosting', ...);

// Job posting should NEVER modify HealthcareProfile
router.post('/jobpost', async (req, res) => {
  const job = await JobPosting.create({
    healthcare_id: req.body.healthcare_id,
    jobTitle: req.body.jobTitle,
    // ... other job fields
  });
  
  // DO NOT touch HealthcareProfile!
  
  res.json({ success: true, data: job });
});
```

### Option 2: Use Transactions (SAFE)
```javascript
// If you must update both, use transactions
const session = await mongoose.startSession();
session.startTransaction();

try {
  // Create job posting
  const job = await JobPosting.create([{
    healthcare_id: req.body.healthcare_id,
    ...jobData
  }], { session });
  
  // Update profile (if needed)
  await HealthcareProfile.findByIdAndUpdate(
    req.body.healthcare_id,
    { $inc: { jobPostCount: 1 } },  // Only increment counter
    { session }
  );
  
  await session.commitTransaction();
  res.json({ success: true });
} catch (error) {
  await session.abortTransaction();
  res.status(500).json({ error: error.message });
} finally {
  session.endSession();
}
```

### Option 3: Add Validation (PREVENT)
```javascript
// Add validation to prevent profile corruption
router.post('/jobpost', async (req, res) => {
  const { healthcare_id } = req.body;
  
  // Verify profile exists and has required fields
  const profile = await HealthcareProfile.findById(healthcare_id);
  
  if (!profile) {
    return res.status(404).json({ error: 'Hospital profile not found' });
  }
  
  if (!profile.hospitalName || !profile.email) {
    return res.status(400).json({ 
      error: 'Hospital profile is incomplete. Please complete your profile first.' 
    });
  }
  
  // Create job posting (in separate collection!)
  const job = await JobPosting.create({ ...jobData });
  
  res.json({ success: true, data: job });
});
```

## Summary

**Problem**: Backend corrupts hospital profile data after job posting  
**Evidence**: Profile returns 200 but with empty data, email lookup fails  
**Impact**: Users cannot log in after posting jobs  
**Fix Required**: Backend developer must fix job posting endpoint  
**Priority**: CRITICAL - This breaks the entire app for hospital users  

## Next Steps

1. **Backend Developer**: Check the job posting endpoint code
2. **Backend Developer**: Add logging to see what's happening to the profile
3. **Backend Developer**: Fix the issue (separate collections or use transactions)
4. **Test**: Post a job, log out, log in again - should work!

