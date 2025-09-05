class Account {
  String username;
  String email;
  String password;
  bool isVerified;

  Account({required this.username, required this.email, required this.password, this.isVerified = false});
}
