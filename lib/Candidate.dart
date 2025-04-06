class Candidate {
  final int id;
  final String firstName;
  final String lastName;

  Candidate({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  factory Candidate.fromJson(Map<String, dynamic> json) {
    return Candidate(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
    );
  }
}