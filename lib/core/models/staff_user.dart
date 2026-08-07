class StaffUser {
  const StaffUser({
    required this.id,
    required this.name,
    required this.email,
    required this.roles,
    required this.isReviewer,
    required this.isProduction,
  });

  final int id;
  final String name;
  final String email;
  final List<String> roles;
  final bool isReviewer;
  final bool isProduction;

  factory StaffUser.fromJson(Map<String, dynamic> json) {
    return StaffUser(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      roles: (json['roles'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      isReviewer: json['is_reviewer'] as bool? ?? false,
      isProduction: json['is_production'] as bool? ?? false,
    );
  }
}
