class AppConstants {
  static const String baseUrl = 'https://aotms-lms-5vzs.onrender.com';
  static const String apiUrl = '$baseUrl/api';

  // Auth
  static const String loginEndpoint = '/auth/login';
  static const String signupEndpoint = '/auth/signup';
  static const String sendOtpEndpoint = '/auth/send-otp';
  static const String verifyOtpEndpoint = '/auth/verify-otp';
  static const String refreshEndpoint = '/auth/refresh';
  static const String logoutEndpoint = '/auth/logout';
  static const String forgotPasswordEndpoint = '/auth/forgot-password';
  static const String resetPasswordEndpoint = '/auth/reset-password';

  // User
  static const String profileEndpoint = '/user/profile';

  // Admin
  static const String adminUsersEndpoint = '/admin/users';
  static const String adminEnrollmentsEndpoint = '/admin/enrollments-list';
  static const String adminCoursesEndpoint = '/admin/courses-list';
  static const String adminInstructorsEndpoint = '/admin/instructors';
  static const String adminLeaderboardEndpoint = '/data/leaderboard';
  static const String adminStudentPerformanceEndpoint = '/admin/student-performance';
  static const String adminDataSummaryEndpoint = '/admin/data-summary';
  static const String adminChatMonitorEndpoint = '/admin/conversations';
  static const String adminCoursesWithInstructors = '/admin/courses-with-instructors';

  // Generic data endpoint
  static const String dataEndpoint = '/data';

  // Instructor
  static const String instructorCoursesEndpoint = '/instructor/courses';
  static const String instructorPulseRatingsEndpoint = '/instructor/pulse-ratings';

  // Student
  static const String studentAttendanceEndpoint = '/student/my-attendance';
  static const String coursesEnrollEndpoint = '/courses/enroll';
  static const String coursesEnrollmentEndpoint = '/courses/enrollments';

  // Chat
  static const String chatConversationsEndpoint = '/chat/conversations';
  static const String chatContactsEndpoint = '/chat/contacts';
  static const String chatSendEndpoint = '/chat/send';
  static const String chatStartEndpoint = '/chat/start';

  // Roles
  static const String roleAdmin = 'admin';
  static const String roleSuperAdmin = 'super_admin';
  static const String roleManager = 'manager';
  static const String roleInstructor = 'instructor';
  static const String roleStudent = 'student';
  static const String roleIntern = 'intern';

  // Colors
  static const int primaryColorValue = 0xFF6C63FF;
  static const int secondaryColorValue = 0xFF03DAC6;
}
