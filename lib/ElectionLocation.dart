class ElectionLocation {
  final int id;
  final String address;

  ElectionLocation({required this.id, required this.address});

  factory ElectionLocation.fromJson(Map<String, dynamic> json) {
    return ElectionLocation(
      id: json['id'],
      address: json['address'],
    );
  }
}