# 🧪 Testing Free Trial & Payment Flow

## Problem
You want to test the payment flow when the free trial ends, but new surgeons get a 2-month free trial by default. **How can you test without waiting 2 months?**

## Solution: Testing Utility Screen

I've created a **Subscription Testing Screen** that lets you manually control the free trial status for testing purposes.

---

## Quick Start Guide

### 1. Navigate to Testing Screen

Add this import to any screen (e.g., surgeon profile):
```dart
import 'package:doc/utils/subscription_testing_screen.dart';
```

Then add a button to navigate:
```dart
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SubscriptionTestingScreen(),
      ),
    );
  },
  child: const Text('🧪 Test Subscription'),
),
```

### 2. Or Navigate Directly (Quick Test)

**TEMPORARY**: Add to your surgeon profile screen for quick access:

In `lib/profileprofile/surgeon_profile.dart`, add a floating action button:
```dart
floatingActionButton: FloatingActionButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SubscriptionTestingScreen(),
      ),
    );
  },
  backgroundColor: Colors.orange,
  child: const Icon(Icons.science, color: Colors.white),
),
```

---

## How Free Trial Works

### Backend (Signup):
When a surgeon signs up, the backend sets:
```json
{
  "freetrail2month": true
}
```

This is stored in the user's profile.

### Frontend (Session):
The app stores this in session storage:
```dart
await SessionManager.saveFreeTrialFlag(true);
```

### Checking Status:
```dart
final isTrialActive = await SessionManager.getFreeTrialFlag();

if (isTrialActive == false) {
  // Show payment screen
} else {
  // Show free trial active screen
}
```

---

## Testing Workflow

### Scenario 1: Test Payment Flow (Free Trial Expired)

1. **Open Testing Screen**
   - Navigate to `SubscriptionTestingScreen`

2. **Set Trial to Expired**
   - Click "Set Free Trial EXPIRED (false)"
   - Status shows: ❌ FREE TRIAL EXPIRED

3. **View Subscription Screen**
   - Click "View Subscription Plan Screen"
   - Should show: `FreeTrialEndedScreen` (payment screen)

4. **Test Payment**
   - Click "Subscribe Now" button
   - Razorpay payment opens (make sure you updated API key)
   - Complete test payment
   - Should navigate to "Subscription Activated" screen

### Scenario 2: Test Free Trial Active

1. **Set Trial to Active**
   - Click "Set Free Trial ACTIVE (true)"
   - Status shows: ✅ FREE TRIAL ACTIVE

2. **View Subscription Screen**
   - Click "View Subscription Plan Screen"
   - Should show: "Enjoy 2 months free!" screen

3. **Access Features**
   - User can search/apply for jobs
   - No payment required

---

## Testing Screen Features

### Current Status Display
Shows real-time status with color coding:
- **GREEN**: Free trial active (true)
- **RED**: Free trial expired (false)
- **ORANGE**: Not set (null)

### Control Buttons
1. **Set ACTIVE** - Simulates active 2-month trial
2. **Set EXPIRED** - Simulates trial ended (test payment)
3. **Clear Status** - Reset to default

### Test Navigation
1. **View Subscription Plan Screen** - Shows correct screen based on status
2. **View Payment Screen Directly** - Jump to payment for testing

### Instructions & Tips
- Built-in guide on how to test
- Tips on Razorpay integration
- Testing best practices

---

## How to Check Status Manually

### Method 1: Using Testing Screen ✅ (Recommended)
- Easiest and most visual
- Shows current status clearly
- One-click status changes

### Method 2: Check Session Storage (Developer)
```dart
final prefs = await SharedPreferences.getInstance();
final status = prefs.getBool('free_trial_flag');
print('Free Trial Status: $status');
```

### Method 3: Check Backend API
Query the surgeon's profile:
```
GET /api/surgeons/profile/{profileId}
```

Response should include:
```json
{
  "freetrail2month": true
}
```

---

## Production Flow (How It Actually Works)

### Day 1 - Signup
```
1. Surgeon signs up
2. Backend creates profile with freetrail2month: true
3. Frontend saves to session
4. User sees "Enjoy 2 months free!" screen
```

### Day 60 - Trial Ends
```
1. Backend job/cron runs daily
2. Finds users where signup_date + 60 days = today
3. Updates freetrail2month: false
4. Next time user logs in:
   - Frontend checks flag
   - Sees false
   - Shows payment screen
```

### After Payment
```
1. User clicks "Subscribe Now"
2. Order created via API
3. Razorpay payment completes
4. Backend verifies payment
5. Updates subscription status
6. User gets full access
```

---

## Testing Checklist

### Before Testing
- [ ] Razorpay API key updated in code
- [ ] Backend API is running
- [ ] Testing screen is accessible

### Test Free Trial Active
- [ ] Set status to ACTIVE
- [ ] View subscription screen → Shows "Enjoy 2 months free"
- [ ] Can access job search
- [ ] Can apply for jobs

### Test Free Trial Expired
- [ ] Set status to EXPIRED
- [ ] View subscription screen → Shows payment screen
- [ ] Click "Subscribe Now"
- [ ] Razorpay opens
- [ ] Complete test payment (use test card)
- [ ] Payment succeeds
- [ ] Navigates to "Subscription Activated"
- [ ] Success message shows

### Test Payment Failure
- [ ] Set status to EXPIRED
- [ ] Click "Subscribe Now"
- [ ] Cancel Razorpay payment
- [ ] Error message shows
- [ ] Can retry payment
- [ ] Status remains expired

---

## Backend Setup (What You Need)

### 1. Trial Expiry Check (Cron Job)
Create a daily cron job to check and expire trials:

```javascript
// Pseudo-code
const expiryDate = new Date();
expiryDate.setDate(expiryDate.getDate() - 60); // 60 days ago

// Find users whose trial should expire
const expiredUsers = await Surgeon.find({
  createdAt: { $lte: expiryDate },
  freetrail2month: true
});

// Update their status
for (const user of expiredUsers) {
  user.freetrail2month = false;
  await user.save();
}
```

### 2. Payment Verification Endpoint
After Razorpay payment succeeds:

```javascript
POST /api/payment/verify-surgeon-payment

// Verify signature
// Update subscription status
// Send confirmation email
```

---

## Common Issues & Solutions

### Issue 1: Payment screen doesn't show
**Problem**: Status is still `true`  
**Solution**: Use testing screen to set to `false`

### Issue 2: Razorpay doesn't open
**Problem**: API key not updated  
**Solution**: Update key in `freetrial _endedscreen.dart` line ~176

### Issue 3: Status keeps resetting
**Problem**: Backend overrides on login  
**Solution**: For testing, manually set after login

### Issue 4: Can't find testing screen
**Problem**: Not added to navigation  
**Solution**: Add FAB or button to access it (see Quick Start)

---

##Files Involved

### Testing Utility
- `lib/utils/subscription_testing_screen.dart` - Testing screen (NEW)

### Subscription Logic
- `lib/Subscription Plan Screen/subscription_planScreen.dart` - Checks status
- `lib/Subscription Plan Screen/freetrial _endedscreen.dart` - Payment screen
- `lib/utils/session_manager.dart` - Stores/retrieves status

### Profile Creation
- `lib/model/api_service.dart` - Sets `freetrail2month: true` on signup
- `lib/screens/signin_screen.dart` - Reads status from backend

---

## Quick Reference

### Set Trial Active (for testing free access):
```dart
await SessionManager.saveFreeTrialFlag(true);
```

### Set Trial Expired (for testing payment):
```dart
await SessionManager.saveFreeTrialFlag(false);
```

### Check Current Status:
```dart
final status = await SessionManager.getFreeTrialFlag();
// true = active, false = expired, null = not set
```

---

## Next Steps

1. **Access Testing Screen**
   - Add navigation button (see Quick Start)
   - Or use FAB for quick access

2. **Test Both Scenarios**
   - Active trial (free access)
   - Expired trial (payment required)

3. **Update Razorpay Key**
   - In `freetrial _endedscreen.dart`
   - Line ~176

4. **Test Payment**
   - Use Razorpay test card
   - Verify success/failure flows

5. **Backend: Set Up Cron Job**
   - Auto-expire trials after 60 days
   - Update `freetrail2month` to `false`

6. **Production: Remove Testing Screen**
   - Comment out or remove navigation
   - Or hide behind developer mode

---

## Summary

✅ **Testing Screen Created**: `lib/utils/subscription_testing_screen.dart`  
✅ **Can Toggle Status**: Active ↔ Expired  
✅ **No 2-Month Wait**: Test immediately  
✅ **Visual Interface**: See status clearly  
✅ **Quick Navigation**: Jump to any screen  
✅ **Built-in Guide**: Instructions included  

**You can now test the entire payment flow without waiting 2 months!** 🎉

---

**Pro Tip**: Keep the testing screen accessible during development, but remove or hide it before production release.
