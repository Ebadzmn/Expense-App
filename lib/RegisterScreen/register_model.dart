class RegisterRequest {
  final String name;
  final String email;
  final String password;
  final String preferredLanguage;
  final String? contact;
  final String role;
  final String? fcmToken;

  RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
    this.preferredLanguage = 'English',
    this.contact,
    this.role = 'USER',
    this.fcmToken,  
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'password': password,
    'preferredLanguage': preferredLanguage,
    'contact': contact,
    'role': role,
    'fcmToken': fcmToken,
  };
}