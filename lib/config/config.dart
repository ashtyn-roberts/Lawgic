
class AppConfig {

  // API Configuration
  static const String voterApiBaseUrl = 'http://localhost:5000'; // Change for production
  
  // Feature Flags
  static const bool enableVoterInfoFetch = true;
  static const bool cacheVoterInfo = true;
  
  // Cache Settings
  static const int voterInfoCacheDays = 30; // Refresh voter info every 30 days
  
  // API Timeout
  static const int apiTimeoutSeconds = 15;
  
  // Production URLs (comment out for local dev)
  // static const String voterApiBaseUrl = 'https://your-api-domain.com';
  
  // Development mode
  static const bool isDevelopment = true; // Set to false for production
}

// Usage in app:
// final voterService = VoterService(baseUrl: AppConfig.voterApiBaseUrl);