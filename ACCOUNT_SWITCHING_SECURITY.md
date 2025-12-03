# Account Switching Security - How It Works

## The Concern
**Question:** What happens when User A logs out and User B logs in on the same device?

**Answer:** User B will ONLY access their own account, never User A's account.

---

## How It Works Now (After Fix)

### Scenario 1: Normal Account Switching
```
1. User A logs in with he@gmail.com
   → Backend returns: { "_id": "111111", "email": "he@gmail.com" }
   → App saves: healthcare_id = "111111"
   → User A sees their dashboard

2. User A logs out
   → App calls: SessionManager.clearAll()
   → ALL session data is deleted (including healthcare_id)
   
3. User B logs in with wwwwww@gmail.com
   → Backend returns: { "_id": "222222", "email": "wwwwww@gmail.com" }
   → App extracts: _id = "222222" from CURRENT response
   → App saves: healthcare_id = "222222"
   → User B sees THEIR dashboard (not User A's!)
```

### Scenario 2: What if logout doesn't clear session?
```
1. User A logs in: healthcare_id = "111111" saved
2. User A logs out: Session SHOULD be cleared
3. Session data might still have: healthcare_id = "111111" (hypothetical bug)

4. User B logs in with wwwwww@gmail.com
   → Backend returns: { "_id": "222222", ... }
   → Old code would check: Is there an old stored ID?
   → Old code would fall back to: "111111" ❌ WRONG!
   
   → NEW CODE:
   → Extracts: _id = "222222" from response
   → IGNORES old stored ID completely
   → Uses ONLY: "222222" ✅ CORRECT!
   → User B sees their own account
```

---

## The Fix (What Changed)

### Before (INSECURE):
```dart
// ❌ BAD: Falls back to old stored ID
final existingHid = await SessionManager.getHealthcareId();

final baseHid = (healthcareIdFromResponse != null)
    ? healthcareIdFromResponse
    : (existingHid != null)      // ❌ Uses previous user's ID!
        ? existingHid
        : profileId;
```

### After (SECURE):
```dart
// ✅ GOOD: Only uses current sign-in response
final String baseHid;

if (healthcareIdFromResponse != null && healthcareIdFromResponse.isNotEmpty) {
  // Use the _id from current sign-in response ONLY
  baseHid = healthcareIdFromResponse;
} else {
  // If no _id in response, generate new one (NOT old stored ID!)
  baseHid = profileId;
}

// Never checks old stored IDs!
```

---

## Security Guarantees

### ✅ What IS Protected:
1. **Account Isolation**: User B can NEVER access User A's data
2. **Fresh Sessions**: Each login creates a fresh session with current user's ID
3. **No Fallback Mixing**: We never fall back to IDs from previous users
4. **Logout Protection**: Even if logout fails to clear session, new login won't use old IDs

### ✅ How We Ensure This:
1. Extract `_id` from **current** sign-in API response
2. Use **ONLY** that `_id` - never check old stored IDs
3. Save the new `_id` to session (overwrites any old one)
4. Fetch profile using **ONLY** the new `_id`

---

## Code Flow Diagram

```
┌─────────────────────────────────────────┐
│  User B Signs In                        │
│  Email: wwwwww@gmail.com                │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│  Backend Returns                        │
│  {                                      │
│    "_id": "691c158b53460678985bf8f8",   │
│    "email": "wwwwww@gmail.com",         │
│    "healthprofile": true                │
│  }                                      │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│  Extract _id from RESPONSE              │
│  healthcareIdFromResponse =             │
│    "691c158b53460678985bf8f8"           │
│                                         │
│  ❌ IGNORE any old stored healthcare_id │
│  ❌ DO NOT check previous session       │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│  Use ONLY the new ID                    │
│  baseHid = "691c158b53460678985bf8f8"   │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│  Save to Session (overwrites old)       │
│  SessionManager.saveHealthcareId(...)   │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│  Fetch Profile Using New ID             │
│  GET /api/healthcare/                   │
│      healthcare-profile/                │
│      691c158b53460678985bf8f8           │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│  Navigate to User B's Dashboard         │
│  (NOT User A's!)                        │
└─────────────────────────────────────────┘
```

---

## Testing Scenarios

### Test 1: Sequential Logins
```
1. Login as he@gmail.com → See he's profile ✅
2. Logout
3. Login as wwwwww@gmail.com → See wwwwww's profile ✅
4. Logout
5. Login as he@gmail.com again → See he's profile ✅
```

### Test 2: Without Logout (Edge Case)
```
1. Login as he@gmail.com
2. Close app WITHOUT logging out
3. Reopen app
4. Login as wwwwww@gmail.com
   → Should see wwwwww's profile (NOT he's) ✅
```

### Test 3: Backend ID Format Changes
```
If backend changes ID format:
- Old: "_id": "abc123"
- New: "_id": { "$oid": "abc123" }

App extracts it correctly both ways ✅
```

---

## Console Output (Success)

When User B logs in, you should see:
```
🔑 Found ID in userData: 691c158b53460678985bf8f8
🔑 Healthcare ID from login response: 691c158b53460678985bf8f8
🔑 ✅ Using healthcare ID from current sign-in response: 691c158b53460678985bf8f8
🔑 💾 Saved healthcare_id to session: 691c158b53460678985bf8f8
🔑 📋 healthProfile flag: true
🔑 📋 User _id: 691c158b53460678985bf8f8
🔑 Fetching profile with ID from current sign-in: 691c158b53460678985bf8f8
```

**All IDs should match the CURRENT user's ID!**

---

## Summary

✅ **Secure**: User B can never access User A's data  
✅ **Reliable**: Works even if logout fails to clear session  
✅ **Predictable**: Always uses ID from current sign-in response  
✅ **Fallback Safe**: Email lookup uses authenticated email from current sign-in only  

**The key principle:** Each sign-in is treated as a **NEW**, **FRESH** login. We never trust or reuse data from previous sessions.

## Update: Email-Based Fallback (Latest Fix)

### Why We Added It Back:
The previous fix removed email-based lookup entirely, which prevented existing users from logging in when ID-based lookup failed.

### How It's Safe:
1. **Email comes from backend**: We use the email from the current sign-in API response, not stored emails
2. **After authentication**: Backend only returns email if credentials are valid
3. **As fallback only**: We try ID-based lookup first, email lookup only if that fails
4. **No stored data**: We don't use any emails from previous sessions

### Example Flow:
```
User B logs in with wwwwww@gmail.com
→ Backend authenticates and returns: { "email": "wwwwww@gmail.com", "_id": "222222" }
→ App tries ID lookup with "222222" (fails if profile has different ID)
→ App tries email lookup with "wwwwww@gmail.com" (from current response!)
→ Finds User B's profile (NOT User A's, because we used User B's email)
→ User B sees their own dashboard ✅
```

**Key Point:** The email is tied to the authenticated user from the current sign-in, so there's no way to access another user's profile.
