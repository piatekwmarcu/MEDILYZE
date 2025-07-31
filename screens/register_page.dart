import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final surnameController = TextEditingController();
  final loginController = TextEditingController();
  final conditionsController = TextEditingController();

  String? selectedGender;
  DateTime? selectedBirthdate;

  bool loading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final response = await supabase.auth.signUp(
        email: emailController.text,
        password: passwordController.text,
      );

      await Future.delayed(const Duration(seconds: 1));

      final userId = response.user?.id;
      if (userId == null) throw Exception("Brak ID użytkownika");

      await supabase.from('profiles').insert({
        'id': userId,
        'email': emailController.text,
        'name': nameController.text,
        'surname': surnameController.text,
        'gender': selectedGender,
        'login': loginController.text,
        'birthdate': selectedBirthdate?.toIso8601String(),
        'diagnosed_conditions': conditionsController.text.split(',').map((e) => e.trim()).toList(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Konto utworzone! Zaloguj się.')),
        );
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wystąpił błąd: $e')),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (date != null) {
      setState(() {
        selectedBirthdate = date;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE6FDFF), // Azure
              Color(0xFFD9D7DD), // Platinum
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Image.asset('assets/logo.png', height: 100),
              const SizedBox(height: 16),
              Text(
                'Załóż konto',
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF312F2F), // Jet
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _textField(emailController, 'Email', validator: _validateEmail),
                      _textField(passwordController, 'Hasło', isPassword: true),
                      _textField(nameController, 'Imię'),
                      _textField(surnameController, 'Nazwisko'),
                      _textField(loginController, 'Login (unikalny)'),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedGender,
                        items: ['Kobieta', 'Mężczyzna', 'Inna'].map((e) {
                          return DropdownMenuItem(value: e, child: Text(e));
                        }).toList(),
                        onChanged: (value) => setState(() => selectedGender = value),
                        decoration: const InputDecoration(labelText: 'Płeć'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              selectedBirthdate == null
                                  ? 'Data urodzenia nie wybrana'
                                  : 'Data urodzenia: ${DateFormat('yyyy-MM-dd').format(selectedBirthdate!)}',
                              style: GoogleFonts.montserrat(),
                            ),
                          ),
                          TextButton(
                            onPressed: _pickBirthdate,
                            child: const Text("Wybierz datę"),
                          )
                        ],
                      ),
                      _textField(
                        conditionsController,
                        'Choroby (oddziel przecinkiem)',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA5668B), // Chinese Violet
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: loading ? null : _register,
                        child: loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                          'Zarejestruj się',
                          style: GoogleFonts.montserrat(fontSize: 16),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // wraca do loginu
                        },
                        child: Text(
                          "Masz już konto? Zaloguj się",
                          style: GoogleFonts.montserrat(
                            color: Color(0xFF4E6E58),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  String? _validateEmail(String? value) {
    if (value == null || !value.contains('@')) return 'Niepoprawny email';
    return null;
  }

  Widget _textField(TextEditingController controller, String label,
      {bool isPassword = false, int maxLines = 1, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        obscureText: isPassword,
        maxLines: maxLines,
        validator: validator,
      ),
    );
  }
}
