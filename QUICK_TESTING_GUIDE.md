# 🎯 Quick Testing Guide - Free Trial & Payment

## ✅ What's Ready

You can now test the payment flow **immediately** without waiting 2 months!

---

## 🚀 How to Test (3 Simple Steps)

### Step 1: Open Your App
- Run the app: `flutter run`
- Sign in as a surgeon
- Go to your surgeon profile screen

### Step 2: Access Testing Screen
Look for the **orange flask icon** (🧪) in the top-right corner of the surgeon profile screen.

Click it to open the **Subscription Testing Screen**.

### Step 3: Test Payment Flow

**On the Testing Screen:**

1. Click **"Set Free Trial EXPIRED (false)"**
   - Status will show as ❌ RED

2. Click **"View Subscription Plan Screen"**
   - You'll see the payment screen with "Your free trial has ended!"

3. Click **"Subscribe Now"**
   - Razorpay payment will open
   - **BEFORE THIS WORKS**: Update your Razorpay API key (see below)

4. Complete test payment
   - Use test card: `4111 1111 1111 1111`
   - Any future expiry date
   - Any 3-digit CVV
   - OTP: `1234`

5. Payment succeeds → Navigate to "Subscription Activated" ✅

---

## ⚠️ CRITICAL: Update Razorpay Key First

**File**: `lib/Subscription Plan Screen/freetrial _endedscreen.dart`  
**Line**: ~176

**Find:**
```dart
'key': 'rzp_test_YOUR_KEY_HERE',
```

**Replace with your actual key:**
```dart
'key': 'rzp_test_abc123xyz456',  // Your real key here
```

**Where to get your key**:
1. https://dashboard.razorpay.com/
2. Settings → API Keys
3. Copy "Key ID"

---

## 🧪 Testing Feature Location

### Orange Flask Icon (🧪)
- **Location**: Surgeon Profile screen, top-right corner
- **Next to**: Logout button (red)
- **Tooltip**: "🧪 Test Subscription"

### What It Opens
The **Subscription Testing Screen** with:
- ✅ Current free trial status display
- ✅ Buttons to set status (Active/Expired/Clear)
- ✅ Quick navigation to test screens
- ✅ Built-in instructions and tips

---

## 📋 Test Scenarios

### Test #1: Free Trial Active (Default State)
```
1. Click 🧪 icon
2. Click "Set Free Trial ACTIVE (true)"
3. Click "View Subscription Plan Screen"
➡️ Should show: "Enjoy 2 months free!"
```

### Test #2: Free Trial Expired (Payment Required)
```
1. Click 🧪 icon
2.Click "Set Free Trial EXPIRED (false)"
3. Click "View Subscription Plan Screen"
➡️ Should show: Payment screen with "Subscribe Now"
```

### Test #3: Complete Payment
```
1. Set trial to EXPIRED
2. Click "View Subscription Plan Screen"
3. Click "Subscribe Now"
4. Complete payment with test card
➡️ Should show: "Subscription Activated" screen
```

---

## 📁 What Was Created

### New Files
1. **`lib/utils/subscription_testing_screen.dart`**
   - Testing utility screen
   - Toggle free trial status
   - Navigate to test screens

2. **`TESTING_FREE_TRIAL.md`**
   - Complete testing guide
   - Detailed instructions
   - Troubleshooting tips

3. **`RAZORPAY_INTEGRATION.md`**
   - Payment integration docs
   - API details
   - Security notes

4. **`RAZORPAY_KEY_SETUP.md`**
   - Quick setup guide
   - Key update instructions

### Modified Files
1. **`lib/profileprofile/surgeon_profile.dart`**
   - Added 🧪 testing button
   - Quick access to testing screen

2. **`lib/Subscription Plan Screen/freetrial _endedscreen.dart`**
   - Full Razorpay integration
   - Payment handling
   - ₹600 subscription for surgeons

3. **`pubspec.yaml`**
   - Added `razorpay_flutter: ^1.3.7`

---

## 🎬 Complete Test Walkthrough

### Before You Start:
- [ ] App is running
- [ ] Signed in as surgeon
- [ ] On profile screen

### Testing Steps:
1. **Access Testing**
   - [ ] Click orange 🧪 icon in top-right

2. **Check Current Status**
   - [ ] See current trial status (likely ACTIVE initially)

3. **Test Free Trial Active**
   - [ ] Click "Set Free Trial ACTIVE"
   - [ ] Status shows GREEN ✅
   - [ ] Click "View Subscription Plan Screen"
   - [ ] See "Enjoy 2 months free!" screen

4. **Test Free Trial Expired**
   - [ ] Go back to testing screen (🧪 icon)
   - [ ] Click "Set Free Trial EXPIRED"
   - [ ] Status shows RED ❌
   - [ ] Click "View Subscription Plan Screen"
   - [ ] See "Your free trial has ended!" screen

5. **Test Payment** (requires Razorpay key)
   - [ ] From expired state, click "Subscribe Now"
   - [ ] Razorpay payment opens
   - [ ] Enter test card: 4111 1111 1111 1111
   - [ ] Complete payment
   - [ ] See "Payment Successful" message
   - [ ] Navigate to "Subscription Activated"

---

## 💡 Key Points

### How It Works:
- New surgeons get `freetrail2month: true` by default
- After 60 days, backend sets it to `false`
- Testing screen lets you manually toggle this
- No need to wait 2 months!

### Status Values:
- **true** = Free trial active (can use app for free)
- **false** = Free trial expired (must pay ₹600)
- **null** = Not set (treated as true/free)

### What to Test:
1. ✅ Free trial active UI
2. ✅ Payment screen UI
3. ✅ Razorpay payment flow
4. ✅ Success navigation
5. ✅ Failure handling

---

## 🐛 Troubleshooting

### Can't See🧪 Icon
**Solution**: Hot restart the app (`R` in terminal)

### Razorpay Doesn't Open
**Problem**: API key not updated  
**Solution**: Update key in `freetrial _endedscreen.dart` line ~176

### Status Keeps Resetting
**Problem**: Backend overwrites on login
**Solution**: Set status again after login using testing screen

### Payment Succeeds But Nothing Happens
**Problem**: Navigation issue  
**Solution**: Check console for errors, verify SubscriptionActivatedScreen exists

---

## 🎯 Next Steps

1. ✅ **Test Now** - Use the 🧪 button to test immediately

2. ✅ **Update Razorpay Key** - Required for payment testing

3. ✅ **Test All Scenarios** - Active, Expired, Payment

4. ✅ **Backend Setup** - Create cron job to expire trials after 60 days

5. ✅ **Production** - Remove/hide 🧪 button before release

---

## 📞 Quick Reference

### Test Card Details:
```
Card: 4111 1111 1111 1111
Expiry: Any future date
CVV: Any 3 digits
OTP: 1234
```

### Testing Button:
- Icon: 🧪 (Orange flask)
- Location: Surgeon profile, top-right
- Opens: Subscription Testing Screen

### Price:
- Surgeon Plan: ₹600 for 6 months
- Auto-renewal: Every 6 months
- Can cancel anytime

---

## ✨ Summary

You can now:
- ✅ Test payment flow immediately (no 2-month wait)
- ✅ Toggle trial status easily (Active ↔ Expired)
- ✅ Access testing via orange 🧪 icon
- ✅ Complete Razorpay payments
- ✅ Test all subscription scenarios

**Just click the 🧪 icon and start testing!** 🚀

---

**Remember**: Remove or hide the testing button before production release!
