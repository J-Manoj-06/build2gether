# GitHub Copilot Prompt Guide for Uzhavu Sei AI

Quick reference for generating code with GitHub Copilot for this project.

## 🎯 General Prompt Template

```
Generate [FILE_TYPE] for: [FILE_PATH]
Purpose: [ONE_SENTENCE_DESCRIPTION]
Requirements:
- Use Provider for state management
- Follow existing project structure
- Use AppTheme for styling
- Add doc comments
- Include error handling
- Keep secrets server-side
Output: Only Dart code, no explanations
```

## 📝 File Generation Prompts

### 1. New Page
```
Generate Flutter page for: lib/pages/marketplace/product_list.dart
Purpose: Display paginated list of products with search and category filters
Requirements:
- Use ProductProvider for state
- Include RefreshIndicator
- Show LoadingIndicator while loading
- Use Card widgets for product items
- Add floating action button to add product
- Handle empty state and errors
- Navigate to product detail on tap
```

### 2. New Service Method
```
In file: lib/services/firestore_service.dart
Add method: getNearbyProducts(double lat, double lon, double radiusKm)
Purpose: Get products within specified radius of coordinates
Requirements:
- Query Firestore using GeoPoint
- Filter by isAvailable = true
- Order by distance (calculate using Haversine)
- Return List<ProductModel>
- Include error handling
```

### 3. New Widget
```
Generate reusable widget for: lib/widgets/product_card.dart
Purpose: Display product information in a card format
Requirements:
- Accept ProductModel as parameter
- Show product image (cached_network_image)
- Display name, price, category
- Show availability badge
- Add onTap callback
- Use AppTheme colors
- Responsive layout
```

### 4. New Provider
```
Generate Provider for: lib/providers/booking_provider.dart
Purpose: Manage booking state and operations
Requirements:
- Extend ChangeNotifier
- Include: bookings list, loading state, error message
- Methods: createBooking, getUserBookings, updateBookingStatus
- Use FirestoreService
- Notify listeners appropriately
- Handle all errors
```

### 5. New Model
```
Generate model for: lib/models/booking_model.dart
Purpose: Represent equipment booking data
Requirements:
- Fields: id, userId, productId, startDate, endDate, totalCost, status
- Include fromFirestore() factory
- Include toFirestore() method
- Add copyWith() method
- Include validation methods
- Add doc comments
```

## 🔧 Feature-Specific Prompts

### Marketplace Implementation
```
Generate complete marketplace feature:
Files needed:
1. lib/pages/marketplace/product_list.dart
2. lib/pages/marketplace/product_detail.dart
3. lib/pages/marketplace/add_product.dart

Requirements:
- List products with pagination
- Search and filter functionality
- Product detail with image gallery
- Add/edit product form with image picker
- Use firebase_storage for images
- Update ProductProvider
- Use existing services
```

### Image Upload Flow
```
In file: lib/pages/marketplace/add_product.dart
Add image picker functionality:
- Use image_picker package
- Allow multiple images (max 5)
- Show thumbnail previews
- Upload to Firebase Storage
- Store URLs in Firestore
- Show upload progress
- Handle errors gracefully
```

### Real-time Chat
```
Generate chat feature for: lib/pages/chat/
Files:
1. chat_list_page.dart - List of conversations
2. chat_room_page.dart - Individual chat
3. lib/services/chat_service.dart - Firestore chat ops

Requirements:
- Real-time message updates (Stream)
- Send text messages
- Show timestamps
- Mark messages as read
- Group by date
- Handle offline state
```

### Push Notifications
```
Update lib/services/push_service.dart
Add functionality:
- Subscribe to user-specific topics
- Handle notification tap navigation
- Show local notification when app in foreground
- Store notification history in Firestore
- Send notifications on booking updates
```

## 🧪 Test Generation Prompts

### Unit Test
```
Generate unit tests for: test/unit/auth_service_test.dart
Test file: lib/services/auth_service.dart
Requirements:
- Use mocktail for mocking
- Test signInWithEmail (success and failure)
- Test registerWithEmail
- Test signOut
- Test Google Sign-In
- Mock FirebaseAuth
- Include setup and teardown
```

### Widget Test
```
Generate widget test for: test/widget/login_page_test.dart
Widget: lib/pages/auth/farmer_login_page.dart
Requirements:
- Test UI elements render
- Test form validation
- Test login button tap
- Test navigation to register
- Mock AuthProvider
- Use pumpWidget
```

## 🎨 UI Enhancement Prompts

### Add Animation
```
In file: lib/pages/home/home_page.dart
Add animations:
- Fade-in animation for recommendation cards
- Slide-in animation for quick actions
- Ripple effect on card tap
- Smooth transitions
- Use AnimationController
- Duration: 300ms
```

### Responsive Layout
```
Update lib/pages/marketplace/product_list.dart
Make responsive:
- Use MediaQuery for breakpoints
- Grid on tablet/desktop (2-3 columns)
- List on mobile (1 column)
- Adjust padding for screen size
- Scale images appropriately
```

## 🚀 Cloud Function Prompts

### AI Recommendation Function
```
Generate Cloud Function: functions/src/recommendations.ts
Purpose: Get AI recommendations using OpenAI API
Requirements:
- HTTPS endpoint accepting POST
- Validate: userId, context, items
- Call OpenAI API (gpt-4)
- Build prompt from user context
- Parse response to recommendations array
- Store in Firestore (cache)
- Return JSON response
- Use environment variable for API key
- Include error handling and logging
```

### Send Notification Function
```
Generate Cloud Function: functions/src/notifications.ts
Purpose: Send FCM push notification
Trigger: Firestore onCreate for bookings collection
Requirements:
- Get user FCM token
- Send notification via Firebase Admin SDK
- Include booking details in payload
- Handle offline users
- Log send results
```

## 💡 Quick Tips

### For Better Results:
1. ✅ **Be specific** about file paths
2. ✅ **Mention existing services** to use
3. ✅ **Specify state management** (Provider)
4. ✅ **Include error handling** requirement
5. ✅ **Request doc comments**

### For Consistent Style:
1. ✅ Always mention "Use AppTheme"
2. ✅ Include "Follow existing structure"
3. ✅ Request "Keep code under X lines"
4. ✅ Specify "Include all imports"

### For Debugging:
```
Debug issue in: [FILE_PATH]
Problem: [ERROR_DESCRIPTION]
Context: [RELEVANT_CODE_SNIPPET]
Expected: [WHAT_SHOULD_HAPPEN]
Actual: [WHAT_HAPPENS]
Fix with proper error handling
```

## 🔍 Code Review Prompt

```
Review this code for:
[PASTE_CODE]

Check for:
- Performance issues
- Memory leaks
- Security vulnerabilities
- Code style consistency
- Error handling
- Null safety
- Documentation
Suggest improvements
```

## ✨ Example: Complete Feature

```
Generate complete profile editing feature:

Files to create:
1. lib/pages/profile/farmer_profile.dart - View profile
2. lib/pages/profile/edit_profile.dart - Edit form

Requirements:
Profile View:
- Show user info from AuthProvider
- Display profile image with placeholder
- Show name, email, phone, location
- Edit button navigating to edit page
- Logout button

Edit Form:
- Use InputField widgets
- Fields: name, phone, location
- Image picker for profile photo
- Upload to Firebase Storage
- Update Firestore via AuthProvider.updateProfile()
- Show loading state
- Navigate back on success
- Handle all errors

Use existing:
- AuthProvider
- StorageService
- AppTheme
- InputField widget
- CommonButton widget

Output complete, production-ready code with comments.
```

---

## 🎓 Remember

- **Start small**: Generate one file at a time
- **Iterate**: Refine prompts based on output
- **Review**: Always review generated code
- **Test**: Test generated code thoroughly
- **Document**: Add comments to clarify intent

Happy coding with Copilot! 🚀
