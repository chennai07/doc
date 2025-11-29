# 🚀 How to Implement Subscription Guard

## Quick Implementation Guide

### ✅ What You Have Now
1. **SubscriptionGuard** utility (`lib/utils/subscription_guard.dart`)
2. **Payment screen** (`FreeTrialEndedScreen`)
3. **Testing utility** (to test expiry without waiting)

---

## 📝 Step-by-Step Implementation

### Step 1: Guard the Search Jobs Screen

**File**: `lib/homescreen/SearchjobScreen.dart`

**Add this to your SearchScreen widget:**

```dart
import 'package:doc/utils/subscription_guard.dart';

class _SearchScreenState extends State<SearchScreen> {
  @override
  void initState() {
    super.initState();
    // Check subscription when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSubscription();
    });
  }
  
  Future<void> _checkSubscription() async {
    final canAccess = await SubscriptionGuard.checkPremiumAccess(context);
    
    if (!canAccess) {
      // User's trial expired, payment screen was shown
      // Navigate back to dashboard
      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      // User has active trial/subscription
      // Load jobs normally
      _loadJobs();
    }
  }
  
  // ... rest of your code
}
```

---

### Step 2: Guard Job Application

**File**: `lib/homescreen/job_details_screen.dart`

**In your Apply button:**

```dart
ElevatedButton(
  onPressed: () async {
    // Check subscription before allowing apply
    final canAccess = await SubscriptionGuard.checkPremiumAccess(context);
    
    if (canAccess) {
      // User has active subscription - allow apply
      await _applyForJob();
    } else {
      // Payment screen was shown automatically
      // If user paid and came back, canAccess will be true
      // If they dismissed, nothing happens
    }
  },
  child: const Text('Apply Now'),
)
```

---

### Step 3: Add Banner to Home/Dashboard

**File**: Your surgeon profile or main dashboard screen

**Add banner at the top:**

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Dashboard'),
    ),
    body: Column(
      children: [
        // Show banner if trial expired
        FutureBuilder<bool?>(
          future: SessionManager.getFreeTrialFlag(),
          builder: (context, snapshot) {
            if (snapshot.data == false) {
              // Trial expired - show warning banner
              return SubscriptionGuard.buildTrialExpiredBanner(context);
            }
            return const SizedBox.shrink();
          },
        ),
        
        // Rest of your dashboard content
        Expanded(
          child: SingleChildScrollView(
            child: _buildDashboardContent(),
          ),
        ),
      ],
    ),
  );
}
```

---

### Step 4: Test the Flow

**Using the Testing Utility:**

1. **Open testing screen** (click 🧪 icon)
2. **Set trial to EXPIRED**
3. **Try to search jobs** → Should be blocked and show payment
4. **Go back to dashboard** → Should see orange warning banner
5. **Set trial to ACTIVE** → Can access all features

---

## 🎯 What Gets Blocked vs Allowed

### ✅ Allowed (Free Access)
- View own profile
- Update profile information
- View subscription status
- Check settings
- Logout

### ❌ Blocked (Requires Subscription)
- **Search jobs** ← Add guard here
- **View job details** ← Add guard here  
- **Apply to jobs** ← Add guard here
- Save/bookmark jobs
- Direct hospital contact

---

## 💡 Different Ways to Use the Guard

### Method 1: Check on Screen Load (Recommended for full screens)
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _checkAccess();
  });
}

Future<void> _checkAccess() async {
  final canAccess = await SubscriptionGuard.checkPremiumAccess(context);
  if (!canAccess) {
    Navigator.pop(context); // Go back
  }
}
```

### Method 2: Check on Button Press (Recommended for actions)
```dart
onPressed: () async {
  final canAccess = await SubscriptionGuard.checkPremiumAccess(context);
  if (canAccess) {
    // Perform action
  }
}
```

### Method 3: Check for UI Decisions (Hide/show features)
```dart
FutureBuilder<bool>(
  future: SubscriptionGuard.hasActiveSubscription(),
  builder: (context, snapshot) {
    if (snapshot.data == true) {
      return ElevatedButton(
        onPressed: _applyJob,
        child: const Text('Apply'),
      );
    } else {
      return ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const FreeTrialEndedScreen(),
            ),
          );
        },
        child: const Text('Subscribe to Apply'),
      );
    }
  },
)
```

---

## 🔄 Complete User Journey

### Scenario 1: Active Trial User
```
1. Login ✅
2. Dashboard ✅
3. Search Jobs ✅
4. Apply ✅
5. Everything works normally
```

### Scenario 2: Expired Trial - First Time
```
1. Login ✅
2. Dashboard ✅ (sees orange warning banner)
3. Clicks "Search Jobs"
   ↓
   🚫 Payment screen appears
   ↓
   User sees: "Your free trial has ended!"
   ↓
   Options:
   - Pay ₹600 → Full access restored
   - Cancel → Goes back to dashboard
```

### Scenario 3: Expired Trial - Returning
```
1. Login ✅
2. Dashboard (banner: "Trial expired")
3. Profile ✅ (can view)
4. Try Search → 🚫 Payment screen
5. Try Apply → 🚫 Payment screen
6. Can only view profile until payment
```

---

## 📋 Implementation Checklist

### Phase 1: Basic Protection (This Week)
- [ ] Add guard to Search Jobs screen
- [ ] Add guard to Apply button
- [ ] Add banner to dashboard
- [ ] Test with testing utility

### Phase 2: Enhanced UX (Next Week)
- [ ] Add guard to job details view
- [ ] Add guard to saved jobs
- [ ] Show subscription status page
- [ ] Email notifications

### Phase 3: Backend (Next Week)
- [ ] Create trial expiry cron job
- [ ] Payment verification endpoint
- [ ] Update subscription status after payment
- [ ] Send confirmation emails

---

## 🐛 Troubleshooting

### Issue: Payment screen keeps showing even after payment
**Fix**: Make sure payment success updates the flag:
```dart
// In payment success handler
await SessionManager.saveFreeTrialFlag(true);
// or
await SessionManager.saveSubscriptionStatus('active');
```

### Issue: Banner doesn't disappear after payment
**Fix**: Rebuild the widget after payment:
```dart
Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (_) => Dashboard()),
);
```

### Issue: User can still access features after expiry
**Fix**: Make sure you're checking BEFORE the action:
```dart
// ✅ CORRECT
final canAccess = await SubscriptionGuard.checkPremiumAccess(context);
if (canAccess) {
  _doAction();
}

// ❌ WRONG
_doAction();
await SubscriptionGuard.checkPremiumAccess(context);
```

---

## 🎯 Priority Implementation Order

**1. MUST HAVE (This Week):**
- ✅ Search Jobs guard
- ✅ Apply button guard
- ✅ Dashboard banner

**2. SHOULD HAVE (Next Week):**
- Job details guard
- Subscription status page
- Backend cron job

**3. NICE TO HAVE (Later):**
- Grace period
- Limited freemium access
- Reminder emails
- Analytics

---

## 💰 About Razorpay Error

The error you saw ("Something went wrong") is because:
1. API key not updated (`rzp_test_YOUR_KEY_HERE`)
2. Or test mode not enabled
3. Or order creation failed

**Fix:**
1. Get your key from https://dashboard.razorpay.com/
2. Update in `freetrial _endedscreen.dart` line ~176
3. Make sure your backend creates the order correctly

---

## ✨ Summary

**Best approach:** ✅ **Guard premium features, not login**

**Where to add guards:**
1. Search Jobs screen (on load)
2. Apply button (on click)
3. Job details (on load)

**User experience:**
- Can still see profile ✅
- Clear what they're paying for ✅
- Not immediately blocked ✅
- Professional UX ✅

**Files to modify:**
1. `SearchjobScreen.dart` - Add guard
2. `job_details_screen.dart` - Add guard
3. Dashboard/Profile - Add banner
4. Payment screen - Update Razorpay key

Start with Search Jobs screen - that's the main premium feature! 🚀
