
class User {
    final String email;
    final String password;
    final String fname;
    final String lname;
    final String role;
    final String id_cabang;
    User({
      required this.email,
      required this.password,
      required this.fname,
      required this.lname,
      required this.role,
      required this.id_cabang,
    });

    factory User.fromJson(Map<String, dynamic> json) {
      return User(
        email: json['email'],
        password: json['password'],
        fname: json['fname'],
        lname: json['lname'],
        role: json['role'],
        id_cabang: json['id_cabang'],
        
      );
    }
  }