class Farm {
  final int id;
  final String name;
  final String location;
  final String status;

  Farm({
    required this.id,
    required this.name,
    required this.location,
    required this.status,
  });

  factory Farm.fromJson(Map<String, dynamic> json) {
    return Farm(
      id: json['id'],
      name: json['name'],
      location: json['location'],
      status: json['status'],
    );
  }
}
