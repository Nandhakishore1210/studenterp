class SupabaseConstants {
  SupabaseConstants._();

  // Replace with your actual Supabase project URL and anon key
  static const String supabaseUrl = 'https://kdgydzkqphlovuthjxcn.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtkZ3lkemtxcGhsb3Z1dGhqeGNuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMxNDQ1ODUsImV4cCI6MjA4ODcyMDU4NX0.PZM7mgN7jTnv22x9K7PVIIpPXfscg5N9LFXMn86Hip0';

  static const String currentAcademicYear = '2024-25';
  static const int currentSemester = 1;

  // Storage buckets
  static const String materialsBucket = 'study-materials';
  static const String submissionsBucket = 'submissions';
  static const String avatarsBucket = 'avatars';

  // Edge function names
  static const String fnCalculateAttendance = 'calculate-attendance';
  static const String fnApproveMlOd = 'approve-ml-od';
}
