# JobAllocate Mobile App - Development Guide

## Folder Structure

```
lib/
├── main.dart                       # App entry point & role selection
├── screens/
│   ├── auth/
│   │   ├── job_seeker_otp_login.dart
│   │   └── employer_otp_login.dart
│   ├── job_seeker/
│   │   ├── job_seeker_home.dart
│   │   ├── job_search_screen.dart [TODO]
│   │   ├── job_detail_screen.dart [TODO]
│   │   ├── profile_screen.dart [TODO]
│   │   ├── resume_builder_screen.dart [TODO]
│   │   └── applications_screen.dart [TODO]
│   └── employer/
│       ├── employer_home.dart
│       ├── post_job_screen.dart [TODO]
│       ├── manage_jobs_screen.dart [TODO]
│       ├── applications_screen.dart [TODO]
│       └── analytics_screen.dart [TODO]
├── models/
│   ├── user.dart          ✅ Created
│   └── job.dart           ✅ Created
├── services/
│   └── api_service.dart   ✅ Created
├── widgets/
│   ├── custom_button.dart         ✅ Created
│   ├── otp_input_field.dart       ✅ Created
│   └── job_card.dart              ✅ Created
└── utils/
    ├── constants.dart [TODO]
    └── validators.dart [TODO]
```

## Completed Components

### 1. ✅ Models
- **user.dart**: User, JobSeekerProfile, EmployerProfile classes
- **job.dart**: Job, JobApplication classes with utility methods

### 2. ✅ Services
- **api_service.dart**: HTTP client for all API endpoints

### 3. ✅ Widgets
- **custom_button.dart**: Reusable elevated button with loading state
- **otp_input_field.dart**: 6-digit OTP input field
- **job_card.dart**: Job listing card with details

### 4. ✅ Screens
- **main.dart**: Role selection screen (Job Seeker / Employer)
- **job_seeker_otp_login.dart**: Phone/Email OTP login
- **employer_otp_login.dart**: Email OTP login
- **job_seeker_home.dart**: Job seeker home page (placeholder)
- **employer_home.dart**: Employer home page (placeholder)

## Next Steps - TODO Items

### Phase 1: Job Seeker Flow

#### 1. Job Search Screen
- [ ] Advanced search filters (location, salary, job type, skills)
- [ ] Search result listing using JobCardWidget
- [ ] Pagination
- [ ] Filter panel
- [ ] Recent searches

#### 2. Job Detail Screen
- [ ] Full job details display
- [ ] Company information
- [ ] About section
- [ ] Related jobs
- [ ] Apply button

#### 3. Profile Screen
- [ ] Edit profile
- [ ] Add/edit skills
- [ ] Update experience
- [ ] Upload profile picture
- [ ] Save changes

#### 4. Resume Builder Screen
- [ ] Template selection
- [ ] Resume sections (Contact, Skills, Experience, Education)
- [ ] Add/edit sections
- [ ] Save drafts
- [ ] PDF download
- [ ] Multiple resume versions

#### 5. Applications Screen
- [ ] List of applications
- [ ] Filter by status
- [ ] Application details
- [ ] Timeline view
- [ ] Notifications

### Phase 2: Employer Flow

#### 1. Post Job Screen
- [ ] Job form (title, description, requirements)
- [ ] Location selection
- [ ] Salary range
- [ ] Skills selection
- [ ] Job type dropdown
- [ ] Publish/Save draft

#### 2. Manage Jobs Screen
- [ ] List of posted jobs
- [ ] Filter by status (active, draft, closed)
- [ ] Edit job
- [ ] View analytics
- [ ] Close job posting

#### 3. Applications Screen
- [ ] List of applications
- [ ] Filter by status
- [ ] Applicant details
- [ ] Shortlist/Reject buttons
- [ ] Notes/comments

#### 4. Analytics Screen
- [ ] Job views count
- [ ] Applications count
- [ ] Charts and graphs
- [ ] Performance metrics

## Implementation Strategy

### Week 1-2: Job Seeker Job Search
1. Implement JobSearchScreen
2. Add search/filter functionality
3. Integrate with API service
4. Display results with JobCardWidget

### Week 3-4: Job Details & Profile
1. Implement JobDetailScreen
2. Create JobSeekerProfileScreen
3. Add profile editing
4. Picture upload

### Week 5-6: Resume Builder
1. Create ResumeBuilderScreen
2. Implement section-based editing
3. Add PDF generation
4. Save multiple versions

### Week 7-8: Application Tracking
1. Create ApplicationsScreen
2. Show status timeline
3. Add filters
4. Integrate push notifications

### Week 9-10: Employer Flow - Post Job
1. Create PostJobScreen
2. Form validation
3. API integration
4. Save drafts

### Week 11-12: Employer Management
1. ManageJobsScreen
2. ApplicationsScreen for employers
3. AnalyticsScreen
4. Shortlist/Interview scheduling

## UI/UX Guidelines

### Colors
```dart
primary: Colors.blue
secondary: Colors.blueAccent
success: Colors.green
error: Colors.red
warning: Colors.orange
neutral: Colors.grey
background: Colors.white
```

### Typography
```dart
Headline: 24-28px, Bold
Subheading: 18-20px, Semi-bold
Body: 14-16px, Regular
Caption: 12-13px, Regular
```

### Spacing
```dart
Small: 8px
Medium: 12px
Large: 16px
XLarge: 20px
```

## State Management

Using Provider package:

```dart
// Example Provider setup
final jobProvider = Provider((ref) {
  return ApiService().getJobs();
});
```

## API Integration Example

```dart
// In your screen
final jobs = await ApiService().getJobs(filters);

// Handle loading/error states
try {
  final jobs = await apiService.getJobs();
  setState(() => _jobs = jobs);
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $e'))
  );
}
```

## Testing

```bash
# Run unit tests
flutter test

# Run widget tests
flutter test test/widgets/

# Run integration tests
flutter test integration_test/
```

## Performance Tips

1. Use cached_network_image for images
2. Implement pagination for lists
3. Use ListView.builder for large lists
4. Lazy load images
5. Implement search debouncing
6. Use const constructors where possible

## Known Limitations (Phase 1)

- No offline mode
- No resume versioning
- No video interviews
- No real-time chat
- Limited payment integration

## Future Enhancements

- Dark mode
- Multi-language support
- Offline mode
- Video interviews
- In-app chat
- AI job recommendations
- Skill assessments

## Debugging Tips

```bash
# Enable debug logging
flutter run -v

# Hot reload
Press 'r' in terminal

# Hot restart
Press 'R' in terminal

# View Flutter inspector
flutter pub global activate devtools
flutter pub global run devtools
```

## Common Issues & Solutions

### API Connection Issues
- Check backend is running on correct port
- Update baseUrl in api_service.dart
- Check network connectivity

### OTP Issues
- Check email/phone format
- Verify API endpoint
- Check Firebase Cloud Messaging setup

### Build Issues
- Run `flutter clean`
- Run `flutter pub get`
- Rebuild using `flutter run`

---

Last Updated: March 2026