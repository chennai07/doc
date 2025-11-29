# 🔐 RAZORPAY API KEY SETUP

## ⚠️ CRITICAL: You MUST update the Razorpay API key before using the payment feature!

### Location
**File**: `lib/Subscription Plan Screen/freetrial _endedscreen.dart`  
**Line**: ~176

### Current Code (NEEDS UPDATE):
```dart
'key': 'rzp_test_YOUR_KEY_HERE', // TODO: Replace with your Razorpay API key
```

### Steps to Update:

#### 1. Get Your Razorpay API Key

**Option A: From Razorpay Dashboard**
1. Go to https://dashboard.razorpay.com/
2. Log in to your account
3. Navigate to **Settings** → **API Keys**
4. Copy your **Key ID**

**Option B: From Postman (as shown in your screenshot)**
Based on your Postman screenshot, you already have a test key!

#### 2. Update the Code

Replace this line in `freetrial _endedscreen.dart`:
```dart
'key': 'rzp_test_YOUR_KEY_HERE',
```

With your actual key:
```dart
'key': 'rzp_test_YourActualKeyHere',
```

### Example:
```dart
var options = {
  'key': 'rzp_test_abc123xyz456', // Your actual key here
  'amount': orderData['amount'],
  'currency': orderData['currency'] ?? 'INR',
  // ... rest of options
};
```

### API Key Format:
- **Test Key**: `rzp_test_` followed by alphanumeric characters
- **Live Key**: `rzp_live_` followed by alphanumeric characters

### ⚠️ Important Notes:

1. **NEVER commit your API key to public repositories**
2. **Use Test key for development**
3. **Switch to Live key only for production**
4. **Keep your keys secure**

### After Updating:

1. Save the file
2. Hot restart the app (Press R in terminal)
3. Test the payment flow
4. Use Razorpay test cards for testing

### Test Cards (for Testing):
- **Card Number**: `4111 1111 1111 1111`
- **Expiry**: Any future date
- **CVV**: Any 3 digits
- **OTP**: `1234`

---

## Quick Checklist:
- [ ] Got Razorpay API key from dashboard
- [ ] Updated key in `freetrial _endedscreen.dart` line ~176
- [ ] Saved the file
- [ ] Hot restarted the app
- [ ] Tested payment with test card
- [ ] Verified payment success flow
- [ ] Verified payment failure flow

---

**Need Help?**
- Razorpay Dashboard: https://dashboard.razorpay.com/
- Razorpay Docs: https://razorpay.com/docs/
- Test Cards: https://razorpay.com/docs/payments/payments/test-card-upi-details/
