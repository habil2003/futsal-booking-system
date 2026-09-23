import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';

import '../../widgets/auth/auth_logo.dart';
import '../../widgets/auth/auth_form_fields.dart';
import '../../widgets/auth/auth_submit_button.dart';

import '../../providers/auth_provider.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/login_screen.dart' show LoginScreen;   // ✅ only import LoginScreen, not the arguments class

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  // Owner business fields
  final _businessNameController = TextEditingController();
  final _panVatController = TextEditingController();

  String _selectedRole = 'PLAYER';
  bool _isSubmitting = false;
  bool _acceptTerms = false;

  @override
  void initState() {
    super.initState();
    // Check for selected role passed via arguments (optional)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        // adapt to whatever argument type you use
        setState(() {
          _selectedRole = args['selectedRole'] ?? 'PLAYER';
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _businessNameController.dispose();
    _panVatController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRole == 'OWNER' && !_acceptTerms) {
      _showErrorSnackBar("Please accept the Terms & Conditions and Commission Policy");
      return;
    }

    setState(() => _isSubmitting = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final Map<String, dynamic> regData = {
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'fullName': _nameController.text.trim(),
        'role': _selectedRole,
      };
      if (_selectedRole == 'OWNER') {
        regData.addAll({
          'businessName': _businessNameController.text.trim(),
          'panVatNumber': _panVatController.text.trim(),
        });
      }

      final response = await auth.register(regData);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (response['status'] == 'success') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              email: _emailController.text.trim(),
              type: OtpScreenType.emailVerification,
            ),
          ),
        );
      } else if (response['requiresVerification'] == true) {
        _showErrorSnackBar("Email not verified. Redirecting...");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              email: _emailController.text.trim(),
              type: OtpScreenType.emailVerification,
            ),
          ),
        );
      } else {
        _showErrorSnackBar(response['message'] ?? "Registration failed");
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showErrorSnackBar("Server connection failed. Please try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  children: [
                    const AuthLogo(),
                    const SizedBox(height: 20),
                    _buildRegisterCard(auth),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterCard(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // ✅ Register form – onRememberMeChanged & onForgotPassword are not used,
            // so we pass empty callbacks to satisfy the required parameters.
            AuthFormFields(
              isLogin: false,
              emailController: _emailController,
              passwordController: _passwordController,
              nameController: _nameController,
              selectedRole: _selectedRole,
              rememberMe: false,
              onRememberMeChanged: () {},   // ✅ empty callback
              onForgotPassword: () {},      // ✅ empty callback
              onRoleChanged: (role) => setState(() => _selectedRole = role),
            ),
            // Owner extra fields
            if (_selectedRole == 'OWNER') ...[
              const SizedBox(height: 16),
              const Text('Business Details (optional)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              _buildTextField(_businessNameController, 'Business/Futsal Name'),
              const SizedBox(height: 12),
              _buildTextField(_panVatController, 'PAN/VAT Number (optional)'),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _acceptTerms,
                onChanged: (val) => setState(() => _acceptTerms = val ?? false),
                title: const Text(
                    'I accept the Terms & Conditions and Commission Policy'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
            const SizedBox(height: 24),
            AuthSubmitButton(
              isLoading: _isSubmitting || auth.isLoading,
              isLogin: false,
              onPressed: _submit,
            ),
            const SizedBox(height: 16),
            _buildLoginLink(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildLoginLink() {
    return RichText(
      text: TextSpan(
        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        children: [
          const TextSpan(text: "Already have an account? "),
          TextSpan(
            text: 'Login',
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
          ),
        ],
      ),
    );
  }
}