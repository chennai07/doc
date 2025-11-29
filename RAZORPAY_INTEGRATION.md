# Razorpay Payment Integration - Surgeon Free Trial Ended Screen

## Overview
Integrated Razorpay payment gateway into the Free Trial Ended screen for surgeon subscriptions. When a surgeon's 2-month free trial expires, they will see this screen and can subscribe for ₹600 for 6 months.

## Implementation Details

### API Endpoint
```
POST http://13.203.67.154:3000/api/payment/surgeonorder
```

### Request Payload
```json
{
  "success": true,
  "profileId": "string",
  "amount": 600
}
```

### Files Modified

#### 1. `pubspec.yaml`
Added Razorpay Flutter package:
```yaml
dependencies:
  razorpay_flutter: ^1.3.7
```

#### 2. `lib/Subscription Plan Screen/freetrial _endedscreen.dart`
Complete rewrite with Razorpay integration:

**Key Features:**
- ✅ Matches Figma design
- ✅ Shows "Surgeon Plan - ₹600 for 6 months"
- ✅ Lists plan features:
  - Unlimited job search
  - Unlimited job applications
  - Direct contact with hospitals
  - Secure and private data handling
- ✅ Razorpay payment integration
- ✅ Loading state during payment processing
- ✅ Payment success/failure handling
- ✅ Auto-navigation on successful payment

## Payment Flow

### 1. User Clicks "Subscribe Now"
```dart
_initiatePayment()
```
- Gets user's profileId from session
- Shows loading state on button

### 2. Create Order on Backend
```dart
_createOrder(profileId)
```
- Calls: `POST /api/payment/surgeonorder`
- Sends: `profileId`, `amount: 600`
- Receives: `orderId`, `amount` (in paise), `currency`

### 3. Open Razorpay Checkout
```dart
_openRazorpayCheckout(orderData)
```
- Opens Razorpay payment interface
- User selects payment method
- Completes payment

### 4. Payment Callbacks

**Success** (`_handlePaymentSuccess`):
```
✅ Payment Successful!
→ Show success message
→ Navigate to SubscriptionActivatedScreen
```

**Failure** (`_handlePaymentError`):
```
❌ Payment Failed
→ Show error message
→ Stay on current screen
→ User can retry
```

**External Wallet** (`_handleExternalWallet`):
```
🔄 Shows wallet name
→ User continues with external wallet
```

## Configuration Required

### ⚠️ IMPORTANT: Update Razorpay API Key
In `freetrial _endedscreen.dart`, line ~176:

```dart
'key': 'rzp_test_YOUR_KEY_HERE', // TODO: Replace with your actual key
```

**Replace with your actual Razorpay key:**
- **Test Mode**: `rzp_test_xxxxxxxxxxxxx`
- **Live Mode**: `rzp_live_xxxxxxxxxxxxx`

### Where to Find Your Razorpay Key:
1. Go to [Razorpay Dashboard](https://dashboard.razorpay.com/)
2. Navigate to **Settings** → **API Keys**
3. Copy your **Key ID**
4. Paste it in the code

## UI Design (Matches Figma)

### Visual Elements:
- **Background**: Dimmed gray overlay with white curved bottom sheet
- **Icon**: Blue sad face icon in light blue circle
- **Title**: "Your free trial has ended!" (Blue, bold)
- **Message**: Instructions to subscribe
- **Plan Box**: Blue gradient container with:
  - Plan name: "Surgeon Plan"
  - Price: "₹600 for 6 months"
  - 4 feature bullet points
  - Auto-renew and cancel info
  - "Subscribe Now" button (white with blue text)

### Loading State:
- Button shows spinner during payment processing
- Button is disabled while processing
- Semi-transparent white button background

## Testing Instructions

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Update Razorpay Key
Replace `'rzp_test_YOUR_KEY_HERE'` with your actual key

### 3. Test Payment Flow

**Test Mode (Using Test Cards):**
- Card: `4111 1111 1111 1111`
- Expiry: Any future date
- CVV: Any 3 digits
- OTP: `1234`

**Success Scenario:**
1. Navigate to Free Trial Ended screen
2. Click "Subscribe Now"
3. Complete payment with test card
4. Should show success message
5. Should navigate to Subscription Activated screen

**Failure Scenario:**
1. Navigate to Free Trial Ended screen
2. Click "Subscribe Now"
3. Click "Back" or "Cancel" in Razorpay
4. Should show failure message
5. Should stay on current screen
6. Button should be clickable again (can retry)

### 4. Check Console Logs
Monitor these logs:
```
💳 Creating order for profile: [profileId]
📋 Order API Response Status: [status]
📋 Order API Response Body: [body]
💳 Order created successfully
✅ Payment Success! (on success)
❌ Payment Error! (on failure)
```

## Backend API Response

### Expected Response Structure
```json
{
  "orderId": "order_xxxxxxxxxxxxx",
  "amount": 60000,
  "currency": "INR"
}
```

**Note**: The code handles multiple response formats:
- `orderId` / `id` / `order_id`
- Defaults to 60000 paise (₹600) if amount not in response

## Price Details
- **Surgeon Plan**: ₹600 for 6 months
- **Amount in Paise**: 60000 (₹600 × 100)
- **Currency**: INR
- **Auto-renewal**: Every 6 months
- **Cancellation**: Anytime

## Error Handling

### 1. User Not Logged In
```
Error: User ID not found. Please log in again.
```
→ Shows error snackbar

### 2. Order Creation Failed
```
Error: Failed to create order
```
→ Shows error snackbar
→ Button becomes clickable again

### 3. Razorpay Open Failed
```
Error: [Exception details]
```
→ Shows error snackbar

### 4. Payment Failed
```
❌ Payment Failed: [Reason]
```
→ Shows error snackbar
→ User can retry

## Integration with App Flow

### When to Show This Screen
This screen should be shown when:
1. Surgeon's `freetrail2month` flag is `false` (trial ended)
2. Surgeon doesn't have an active subscription
3. Surgeon tries to access premium features (job search/apply)

### After Successful Payment
1. Backend should update subscription status
2. Navigate to `SubscriptionActivatedScreen`
3. User gets access to premium features

## Security Considerations

### ✅ Already Implemented:
- Order creation on backend (not client-side)
- User authentication via session
- Payment verification via Razorpay callbacks

### 🔒 Backend Should Verify:
- Payment signature (Razorpay provides this)
- Order status before activating subscription
- Profile ID matches the order

### Backend Verification Example:
```javascript
const crypto = require('crypto');

// Verify Razorpay signature
const generated_signature = crypto
  .createHmac('sha256', razorpay_secret)
  .update(order_id + "|" + razorpay_payment_id)
  .digest('hex');

if (generated_signature === razorpay_signature) {
  // Payment is genuine - activate subscription
}
```

## Additional Features

### 1. Retry Mechanism
- If payment fails, user can immediately retry
- No need to reload the screen

### 2. Loading States
- Button shows spinner during processing
- Prevents double-clicking
- User-friendly feedback

### 3. Success Navigation
- Automatic navigation on success
- Shows success message for 3 seconds
- Smooth transition to activated screen

### 4. Comprehensive Logging
- All payment events logged to console
- Helpful for debugging
- Production: Replace with analytics

## Next Steps

1. **Update Razorpay Key**: Replace test key with your actual key
2. **Test End-to-End**: Complete a test payment
3. **Verify Backend**: Ensure backend correctly handles the order
4. **Go Live**: Switch to live Razorpay key for production

## Troubleshooting

### Issue: Payment screen doesn't open
**Solution**: Check Razorpay key is correct

### Issue: Order creation fails
**Solution**: 
- Verify backend API is running
- Check request payload matches backend expectations
- Check network connectivity

### Issue: Payment succeeds but navigation doesn't work
**Solution**: 
- Check `SubscriptionActivatedScreen` route
- Verify context is still mounted

### Issue: Amount is wrong
**Solution**: 
- Amount should be in paise (₹600 = 60000 paise)
- Check backend returns correct amount

## Documentation Links
- [Razorpay Flutter Docs](https://razorpay.com/docs/payments/payment-gateway/flutter-integration/)
- [Razorpay Test Cards](https://razorpay.com/docs/payments/payments/test-card-upi-details/)
- [Razorpay Dashboard](https://dashboard.razorpay.com/)

## Summary

✅ **Razorpay integration complete**  
✅ **Matches Figma design**  
✅ **₹600 surgeon subscription**  
✅ **Payment success/failure handling**  
✅ **Loading states implemented**  
✅ **Error handling comprehensive**  
⚠️ **TODO: Replace Razorpay API key**  
⚠️ **TODO: Test with actual payment**  

---

**File**: `lib/Subscription Plan Screen/freetrial _endedscreen.dart`  
**API**: `POST http://13.203.67.154:3000/api/payment/surgeonorder`  
**Amount**: ₹600 for 6 months  
**Package**: `razorpay_flutter: ^1.3.7`
