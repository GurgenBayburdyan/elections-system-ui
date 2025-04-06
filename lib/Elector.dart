class Elector {
  final int id;
  final String firstName;
  final String lastName;

  Elector({required this.id, required this.firstName, required this.lastName});

  factory Elector.fromJson(Map<String, dynamic> json) {
    return Elector(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
    );
  }
}