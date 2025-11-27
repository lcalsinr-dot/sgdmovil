class User {
  final String id;
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String siteId;
  final String dni;
  final String token;

  User({
    required this.id,
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.siteId,
    required this.dni,
    this.token = '',
  });
  
  // Crear un mapa para almacenar en base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'siteId': siteId,
      'dni': dni,
      'token': token,
    };
  }
  
  // Crear un objeto User desde un mapa de base de datos
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      email: map['email'],
      password: '',
      firstName: map['firstName'],
      lastName: map['lastName'],
      siteId: map['siteId'],
      dni: map['dni'],
      token: map['token'],
    );
  }
  
  // Nombre completo para mostrar
  String get fullName => '$firstName $lastName';
}