class Elector {
  final String id;
  final String firstName;
  final String lastName;
  final String passportNumber;

  Elector({required this.id, required this.firstName, required this.lastName, required this.passportNumber});

  factory Elector.fromJson(Map<String, dynamic> json) {
    return Elector(
      id: json['id'].toString(),
      firstName: json['firstName'],
      lastName: json['lastName'],
      passportNumber: json['passportNumber'],
    );
  }
}