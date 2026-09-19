class Employee {
  final dynamic id;
  final String? name;
  final String? email;
  final String? employeeId;
  final dynamic siteId;
  final String? designation;
  final Map<String, dynamic> raw;

  Employee({
    this.id,
    this.name,
    this.email,
    this.employeeId,
    this.siteId,
    this.designation,
    required this.raw,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      name: json['name']?.toString() ?? json['full_name']?.toString(),
      email: json['email']?.toString(),
      employeeId: json['employee_id']?.toString(),
      siteId: json['site_id'] ?? json['assigned_site_id'],
      designation: json['designation']?.toString() ?? json['position']?.toString(),
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => raw;
}
