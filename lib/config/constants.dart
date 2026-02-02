class AppConstants {
  // Configuration Supabase
  // URL du projet Supabase
  static const String supabaseUrl = 'https://iotejoftrghvzloxknxw.supabase.co';
  
  // Clé publique 'anon' (Utilisée pour l'initialisation du client dans l'application)
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlvdGVqb2Z0cmdodnpsb3hrbnh3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk0Mzc0MDQsImV4cCI6MjA4NTAxMzQwNH0.6-KCmRCJnlwS_WNBQucwvX3dy-0SWtCyJrFrtQHqCZk';
  
  // Clé secrète 'service_role' (ATTENTION : Ne jamais utiliser côté client en production normalement)
  // Nous la stockons ici car vous l'avez fournie, mais l'initialisation standard utilise 'anon'.
  static const String supabaseServiceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlvdGVqb2Z0cmdodnpsb3hrbnh3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2OTQzNzQwNCwiZXhwIjoyMDg1MDEzNDA0fQ.OsxgLIPVlLr9kt06FDzqkHdpac9H96CHmdMHT807Bt0';
}
