# Subscription Plan Screen Flow Mapping

## 📁 Files in `lib/Subscription Plan Screen/`

### **For Surgeons:**
1. **`subscription_planScreen.dart`** 
   - Main screen shown after surgeon profile creation
   - Shows "Enjoy 2 months free!" message
   - Has "Active" button for free trial users
   - Switches to `freetrial_endedscreen.dart` when trial expires

2. **`Subscription _activatedPopup.dart`** (SubscriptionActivatedScreen)
   - Popup shown when clicking "Active" button
   - Confirms subscription is active
   - Navigates to ProfessionalProfileViewPage (surgeon dashboard)

3. **`freetrial _endedscreen.dart`**
   - Shown when free trial period ends (after 2 months)
   - Shows "Subscribe Now" button
   - For surgeons who need to pay ₹600 for 6 months

---

### **For Hospitals:**
1. **`hospital_subscriptionPlanScreen.dart`**
   - Main subscription screen for hospitals
   - Shows different pricing tiers (Small/Medium/Large hospitals)

2. **`Hospital _SubscriptionScreen.dart`**
   - Hospital-specific subscription details

3. **`Hospital_After 2 Months.dart`**
   - Hospital free trial ended screen
   - Shows selected hospital plan

4. **`subscription_active.dart`** (HospitalSubscriptionActivatedPopup)
   - Popup for hospitals confirming subscription
   - Different from surgeon version

---

## 🔄 Complete Surgeon Sign-Up Flow

```
1. Sign Up Screen
   ↓
2. Sign In Screen
   ↓
3. Surgeon Form (Fill profile details)
   ↓
4. SubscriptionPlanScreen (Shows "Enjoy 2 months free!")
   ↓
5. Click "Active" button
   ↓
6. SubscriptionActivatedScreen (Popup overlay)
   ↓
7. Click "Continue"
   ↓
8. ProfessionalProfileViewPage (Surgeon Dashboard)
```

---

## 🎯 Key Updates Made

### 1. **`subscription_planScreen.dart`**
   - ✅ Checks `SessionManager.getFreeTrialFlag()` on load
   - ✅ If `true`: Shows "Enjoy 2 months free!" screen with "Active" button
   - ✅ If `false`: Shows `FreeTrialEndedScreen` 
   - ✅ "Active" button now opens `SubscriptionActivatedScreen` popup

### 2. **`Subscription _activatedPopup.dart`**
   - ✅ Updated to navigate to `ProfessionalProfileViewPage` (surgeon dashboard)
   - ✅ No longer navigates to hospital screens

### 3. **`surgeon_form.dart`**
   - ✅ Navigates to `SubscriptionPlanScreen` after profile creation
   - ✅ Saves `freetrail2month: true` flag to session

### 4. **`api_service.dart`**
   - ✅ Sends `freetrail2month: true` to backend on profile creation

---

## 🗺️ File Purpose Mapping

| File | Purpose | User Type | When Shown |
|------|---------|-----------|------------|
| `subscription_planScreen.dart` | Main subscription screen | Surgeon | After profile creation |
| `Subscription _activatedPopup.dart` | Confirmation popup | Surgeon | Click "Active" |
| `freetrial _endedscreen.dart` | Trial expired | Surgeon | After 2 months |
| `hospital_subscriptionPlanScreen.dart` | Plan selection | Hospital | After hospital form |
| `Hospital_After 2 Months.dart` | Trial expired | Hospital | After 2 months |
| `subscription_active.dart` | Confirmation popup | Hospital | Subscribe clicked |
| `Hospital _SubscriptionScreen.dart` | Details screen | Hospital | Plan management |

---

## ✅ Current Status

All surgeon subscription flows are now properly connected:
- ✅ Sign up → Profile Form → Subscription Screen
- ✅ Free trial flag saved and checked
- ✅ "Active" button shows confirmation popup
- ✅ Popup navigates to dashboard
- ✅ Trial expiration shows payment screen
