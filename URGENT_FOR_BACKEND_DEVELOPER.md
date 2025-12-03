# 🚨 URGENT: Backend Is Corrupting Hospital Profiles After Job Posting

## The Problem (Simple Explanation)

When a hospital user posts a job, **the backend is deleting or corrupting their hospital profile data**. After this happens, they cannot log in anymore.

## Evidence

### Console Output:
```
🔑 Attempt 1/1: Fetching with ID: 692f099618319d98bf5d4f67
🔑 Response status: 200  ← Profile exists!
🔑 ⚠️ ID 692f099618319d98bf5d4f67 returned empty data  ← But it's EMPTY!
```

### What This Means:
- ✅ Profile document exists in database (status 200)
- ❌ Profile has NO data (no hospitalName, email, phoneNumber)
- ❌ Email lookup also fails (404)

## What You Need to Check (Backend)

### 1. Job Posting Endpoint
**File**: `/api/healthcare/jobpost`

**Question**: Does this endpoint modify the hospital profile?

**Check for:**
```javascript
// ❌ BAD - This overwrites the entire profile!
await HealthcareProfile.findByIdAndUpdate(
  healthcare_id,
  { $set: jobData }  // This replaces all profile data with job data!
);

// ❌ BAD - This deletes profile fields!
await HealthcareProfile.findByIdAndUpdate(
  healthcare_id,
  { $unset: { hospitalName: "", email: "" } }
);

// ✅ GOOD - Job posting should NOT touch the profile at all!
await JobPosting.create({
  healthcare_id: healthcare_id,
  ...jobData
});
```

### 2. Profile Fetch Endpoint
**File**: `/api/healthcare/healthcare-profile/:id`

**Question**: Why does it return 200 with empty data?

**Add logging:**
```javascript
router.get('/healthcare-profile/:id', async (req, res) => {
  const profile = await HealthcareProfile.findById(req.params.id);
  
  console.log('Profile found:', profile);
  console.log('Has hospitalName?', !!profile?.hospitalName);
  console.log('Has email?', !!profile?.email);
  
  if (profile && !profile.hospitalName) {
    console.error('⚠️ PROFILE IS CORRUPTED - NO DATA!');
  }
  
  res.json({ data: profile });
});
```

### 3. Email Lookup Endpoint
**File**: `/api/healthcare/healthcare-profile/email/:email`

**Question**: Why does it return 404 after job posting?

**Check:**
- Is the email field being deleted from the profile?
- Is it searching the correct collection?

## How to Debug

### Step 1: Check Profile Before and After Job Posting
```javascript
router.post('/jobpost', async (req, res) => {
  const { healthcare_id } = req.body;
  
  // Check BEFORE
  const before = await HealthcareProfile.findById(healthcare_id);
  console.log('Profile BEFORE job posting:', {
    _id: before?._id,
    hospitalName: before?.hospitalName,
    email: before?.email,
    phoneNumber: before?.phoneNumber
  });
  
  // ... your job posting logic ...
  
  // Check AFTER
  const after = await HealthcareProfile.findById(healthcare_id);
  console.log('Profile AFTER job posting:', {
    _id: after?._id,
    hospitalName: after?.hospitalName,
    email: after?.email,
    phoneNumber: after?.phoneNumber
  });
  
  // Compare
  if (before?.hospitalName && !after?.hospitalName) {
    console.error('🚨 JOB POSTING DELETED THE HOSPITAL NAME!');
  }
  if (before?.email && !after?.email) {
    console.error('🚨 JOB POSTING DELETED THE EMAIL!');
  }
});
```

### Step 2: Check Database Directly
```bash
# Connect to MongoDB
mongo your_database

# Find the affected profile
db.healthcareprofiles.findOne({ _id: ObjectId("692f099618319d98bf5d4f67") })

# Check what fields it has
# Expected: hospitalName, email, phoneNumber, etc.
# Actual: Probably empty or has job data instead!
```

## The Fix (Backend)

### Option 1: Separate Collections (RECOMMENDED)
```javascript
// Keep hospital profiles and job postings SEPARATE!

// Hospital Profile Collection
const HealthcareProfile = mongoose.model('HealthcareProfile', {
  _id: ObjectId,
  healthcare_id: String,
  hospitalName: String,
  email: String,
  phoneNumber: String,
  // ... other hospital fields
});

// Job Posting Collection (SEPARATE!)
const JobPosting = mongoose.model('JobPosting', {
  _id: ObjectId,
  healthcare_id: String,  // Reference to hospital
  jobTitle: String,
  department: String,
  // ... other job fields
});

// Job posting endpoint should ONLY create job, NOT modify profile!
router.post('/jobpost', async (req, res) => {
  const job = await JobPosting.create({
    healthcare_id: req.body.healthcare_id,
    jobTitle: req.body.jobTitle,
    // ... other job fields
  });
  
  // DO NOT TOUCH HealthcareProfile!
  
  res.json({ success: true, data: job });
});
```

### Option 2: If You Must Update Profile
```javascript
// If you need to update profile (e.g., increment job count)
// Use $inc or $push, NOT $set!

router.post('/jobpost', async (req, res) => {
  // Create job posting
  const job = await JobPosting.create({ ...jobData });
  
  // Update profile (SAFELY!)
  await HealthcareProfile.findByIdAndUpdate(
    req.body.healthcare_id,
    { 
      $inc: { jobPostCount: 1 },  // ✅ Only increment counter
      $push: { jobIds: job._id }   // ✅ Only add job ID to array
    }
    // DO NOT use $set with job data!
  );
  
  res.json({ success: true });
});
```

## Test Case

### Before Fix:
```
1. Create hospital profile
   → Profile has: hospitalName, email, phoneNumber ✅

2. Post a job
   → Profile becomes: {} (empty) ❌

3. Try to log in
   → Cannot log in ❌
```

### After Fix:
```
1. Create hospital profile
   → Profile has: hospitalName, email, phoneNumber ✅

2. Post a job
   → Profile STILL has: hospitalName, email, phoneNumber ✅
   → Job created in separate collection ✅

3. Try to log in
   → Can log in successfully ✅
```

## Affected User

**Email**: hangersmens@gmail.com  
**User ID**: 692f099618319d98bf5d4f67  
**Issue**: Profile exists but has no data  

**Action Required**: Restore this user's profile data from backup or ask them to recreate it.

## Priority

**CRITICAL** - This breaks the entire app for hospital users after they post jobs!

## Questions?

If you need help debugging or implementing the fix, let me know!

