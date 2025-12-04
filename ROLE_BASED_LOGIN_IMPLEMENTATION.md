# Role-Based Login Implementation

## Overview

Civildesk now enforces **strict role-based login** where:
- **Admin App** - Only ADMIN and HR_MANAGER can login
- **Employee App** - Only EMPLOYEE can login

This ensures users can only access the appropriate application for their role.

---

## Implementation Details

### 1. Backend Changes

#### New Login Endpoints

**Admin/HR Login Endpoint:**
```
POST /api/auth/login/admin
```
- ✅ Accepts: ADMIN and HR_MANAGER roles
- ❌ Rejects: EMPLOYEE role
- ✅ Requires: Email verification for ADMIN/HR_MANAGER

**Employee Login Endpoint:**
```
POST /api/auth/login/employee
```
- ✅ Accepts: EMPLOYEE role only
- ❌ Rejects: ADMIN and HR_MANAGER roles
- ✅ No email verification required for employees

**Legacy Endpoint (Still Available):**
```
POST /api/auth/login
```
- Accepts all roles (for backward compatibility)
- Frontend apps now use role-specific endpoints

#### Backend Validation

**Admin Login (`/login/admin`):**
```java
// Only allow ADMIN and HR_MANAGER roles
if (user.getRole() != User.Role.ADMIN && user.getRole() != User.Role.HR_MANAGER) {
    throw new BadRequestException("Access denied. This login is for administrators and HR managers only. Please use the Employee app.");
}
```

**Employee Login (`/login/employee`):**
```java
// Only allow EMPLOYEE role
if (user.getRole() != User.Role.EMPLOYEE) {
    throw new BadRequestException("Access denied. This login is for employees only. Please use the Admin app.");
}
```

---

### 2. Frontend Changes

#### Admin Frontend (`civildesk_frontend`)

**Auth Provider:**
- ✅ Added role validation after successful login
- ✅ Rejects EMPLOYEE role with clear error message
- ✅ Only allows ADMIN and HR_MANAGER to proceed

**Login Screen:**
- ✅ Updated title: "Admin Portal"
- ✅ Added badge: "For Administrators & HR Managers Only"
- ✅ Visual distinction from employee login

**API Endpoint:**
- ✅ Changed from `/auth/login` to `/auth/login/admin`

#### Employee Frontend (`civildesk_employee_frontend`)

**Auth Provider:**
- ✅ Already had role validation (only EMPLOYEE)
- ✅ Rejects ADMIN and HR_MANAGER with clear error message

**Login Screen:**
- ✅ Updated title: "Employee Portal"
- ✅ Added badge: "For Employees Only"
- ✅ Visual distinction from admin login

**API Endpoint:**
- ✅ Changed from `/auth/login` to `/auth/login/employee`

---

## User Experience

### Admin App Login Flow

1. **User opens Admin App**
2. **Sees login screen with:**
   - "Civildesk" title
   - "Admin Portal" subtitle
   - "For Administrators & HR Managers Only" badge
3. **Enters credentials**
4. **If ADMIN/HR_MANAGER:**
   - ✅ Login successful
   - Redirected to appropriate dashboard
5. **If EMPLOYEE:**
   - ❌ Error: "Access denied. This app is for administrators and HR managers only. Please use the Employee app."
   - Stays on login screen

### Employee App Login Flow

1. **User opens Employee App**
2. **Sees login screen with:**
   - "Civildesk" title
   - "Employee Portal" subtitle
   - "For Employees Only" badge
3. **Enters credentials**
4. **If EMPLOYEE:**
   - ✅ Login successful
   - Redirected to dashboard
5. **If ADMIN/HR_MANAGER:**
   - ❌ Error: "Access denied. This app is for employees only. Please use the Admin app."
   - Stays on login screen

---

## Security Benefits

### 1. **Prevents Unauthorized Access**
- Users cannot accidentally access wrong app
- Clear error messages guide users to correct app
- Backend enforces role restrictions

### 2. **Better User Experience**
- Users know which app to use
- Clear visual indicators on login screens
- Helpful error messages

### 3. **Defense in Depth**
- Frontend validation (early rejection)
- Backend validation (server-side enforcement)
- Role-specific endpoints (API-level security)

---

## Error Messages

### Admin App Errors

**When EMPLOYEE tries to login:**
```
"Access denied. This app is for administrators and HR managers only. Please use the Employee app."
```

**When email not verified:**
```
"Please verify your email before logging in"
```

### Employee App Errors

**When ADMIN/HR_MANAGER tries to login:**
```
"Access denied. This app is for employees only. Please use the Admin app."
```

**When invalid credentials:**
```
"Invalid email or password"
```

---

## Database Impact

### No Database Changes Required ✅

The existing `users` table already has:
- `role` field (ADMIN, HR_MANAGER, EMPLOYEE)
- `email_verified` field
- All necessary fields for role-based authentication

---

## API Endpoints Summary

| Endpoint | Allowed Roles | Purpose |
|----------|--------------|---------|
| `POST /api/auth/login` | All | Legacy endpoint (backward compatibility) |
| `POST /api/auth/login/admin` | ADMIN, HR_MANAGER | Admin app login |
| `POST /api/auth/login/employee` | EMPLOYEE | Employee app login |
| `POST /api/auth/logout` | All | Logout (all apps) |

---

## Testing Checklist

### Admin App Testing:
- [x] ADMIN can login ✅
- [x] HR_MANAGER can login ✅
- [x] EMPLOYEE cannot login ❌ (shows error)
- [x] Error message is clear and helpful
- [x] Login screen shows "Admin Portal" badge

### Employee App Testing:
- [x] EMPLOYEE can login ✅
- [x] ADMIN cannot login ❌ (shows error)
- [x] HR_MANAGER cannot login ❌ (shows error)
- [x] Error message is clear and helpful
- [x] Login screen shows "For Employees Only" badge

### Backend Testing:
- [x] `/login/admin` accepts ADMIN ✅
- [x] `/login/admin` accepts HR_MANAGER ✅
- [x] `/login/admin` rejects EMPLOYEE ❌
- [x] `/login/employee` accepts EMPLOYEE ✅
- [x] `/login/employee` rejects ADMIN ❌
- [x] `/login/employee` rejects HR_MANAGER ❌

---

## Migration Guide

### For Existing Users:

1. **No Action Required for Users**
   - Existing credentials work
   - Users just need to use correct app

2. **For Developers:**
   - Update API calls to use role-specific endpoints
   - Test both apps with different roles
   - Verify error messages are clear

3. **For Administrators:**
   - Inform users about app separation
   - Provide clear instructions on which app to use
   - Share error message meanings

---

## Visual Differences

### Admin Login Screen:
```
┌─────────────────────────┐
│      [Business Icon]    │
│                         │
│      Civildesk          │
│    Admin Portal         │
│ ┌─────────────────────┐ │
│ │ For Administrators  │ │
│ │ & HR Managers Only  │ │
│ └─────────────────────┘ │
│                         │
│  Email: [___________]  │
│  Password: [________]  │
│                         │
│    [Login Button]       │
└─────────────────────────┘
```

### Employee Login Screen:
```
┌─────────────────────────┐
│      [Business Icon]    │
│                         │
│      Civildesk          │
│    Employee Portal      │
│ ┌─────────────────────┐ │
│ │  For Employees Only │ │
│ └─────────────────────┘ │
│                         │
│  Email: [___________]  │
│  Password: [________]  │
│                         │
│    [Login Button]       │
└─────────────────────────┘
```

---

## Code Changes Summary

### Backend Files Modified:
1. `AuthController.java`
   - Added `adminLogin()` method
   - Added `employeeLogin()` method
   - Both methods include role validation

### Admin Frontend Files Modified:
1. `lib/core/providers/auth_provider.dart`
   - Added role validation after login
   - Rejects EMPLOYEE role

2. `lib/core/constants/app_constants.dart`
   - Changed endpoint to `/auth/login/admin`

3. `lib/screens/common/login_screen.dart`
   - Updated UI with "Admin Portal" title
   - Added role badge
   - Updated error handling

### Employee Frontend Files Modified:
1. `lib/core/constants/app_constants.dart`
   - Changed endpoint to `/auth/login/employee`

2. `lib/screens/common/login_screen.dart`
   - Updated UI with "Employee Portal" title
   - Added role badge
   - (Role validation already existed)

---

## Future Enhancements

### Potential Improvements:
1. **QR Code Login** - Different QR codes for each app
2. **SSO Integration** - Single sign-on with role routing
3. **App Store Separation** - Different app listings
4. **Custom Branding** - Different colors/themes per app
5. **Biometric Login** - Role-based biometric verification

---

## Troubleshooting

### Issue: User can't login to either app
**Solution:**
- Check user role in database
- Verify user exists and is active
- Check email verification status (for ADMIN/HR)

### Issue: Wrong error message shown
**Solution:**
- Verify correct endpoint is being used
- Check frontend auth provider logic
- Review backend error handling

### Issue: User sees "Access denied" but has correct role
**Solution:**
- Check database role field
- Verify role name matches exactly (case-sensitive)
- Check JWT token claims

---

## Conclusion

✅ **Role-based login fully implemented**
✅ **Separate endpoints for security**
✅ **Clear visual distinctions**
✅ **Helpful error messages**
✅ **Defense in depth security**

The system now ensures users can only access the appropriate application for their role, providing better security and user experience.

---

**Last Updated**: [Current Date]
**Version**: 2.0

