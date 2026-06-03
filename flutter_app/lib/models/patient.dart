class Patient {
  final String name;
  final String email;
  final int age;
  final String gender;
  final double weight;
  final List allergies;
  final List chronicDiseases;
  final List medications;

  Patient({
    required this.name,
    required this.email,
    required this.age,
    required this.gender,
    required this.weight,
    required this.allergies,
    required this.chronicDiseases,
    required this.medications,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      weight: (json['weight'] ?? 0).toDouble(),
      allergies: json['allergies'] ?? [],
      chronicDiseases: json['chronic_diseases'] ?? [],
      medications: json['current_medication'] ?? [],
    );
  }
}