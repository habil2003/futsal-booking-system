import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Custom Widgets ---
import '../../widgets/auth/auth_logo.dart';
import '../../widgets/auth/auth_form_fields.dart';
import '../../widgets/auth/auth_submit_button.dart';
import '../../widgets/auth/forgot_password_view.dart';

// --- Providers & Screens ---
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/owner/owner_dashboard.dart';
import '../screens/admin/admin_account.dart';
import '../screens/home_screen.dart';

class LoginScreenArguments {
  final String? email;
  final bool? isLogin;
  final String? selectedRole;

  const LoginScreenArguments({this.email, this.isLogin, this.selectedRole});
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Basic controllers
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _forgotEmailController = TextEditingController();

  // Optional business controllers
  final _businessNameController = TextEditingController();
  final _businessTypeController = TextEditingController(); 
  final _panVatController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();

  // State
  bool _isLogin = true;
  String _selectedRole = 'PLAYER';
  bool _loginSubmitting = false;
  bool _forgotPasswordSubmitting = false;
  bool _rememberMe = false;
  bool _showForgotPassword = false;
  bool _acceptTerms = false;                                 

  // Business type dropdown
  String _selectedBusinessType = 'Individual Owner';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadRememberedEmail();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is LoginScreenArguments) {
        setState(() {
          if (args.email != null) _emailController.text = args.email!;
          if (args.isLogin != null) _isLogin = args.isLogin!;
          if (args.selectedRole != null) _selectedRole = args.selectedRole!;
        });
      }
    });
  }

  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('remembered_email');
    final isRemembered = prefs.getBool('remember_me_status') ?? false;
    if (isRemembered && savedEmail != null) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _forgotEmailController.dispose();
    _businessNameController.dispose();
    _businessTypeController.dispose();
    _panVatController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleForgotPassword() {
    setState(() {
      _showForgotPassword = !_showForgotPassword;
      if (_showForgotPassword) {
        _animationController.forward();
        _forgotEmailController.clear();
      } else {
        _animationController.reverse();
      }
    });
  }

  Future<void> _handleForgotPassword() async {
    FocusScope.of(context).unfocus();
    if (_forgotEmailController.text.isEmpty) {
      _showErrorSnackBar("Please enter your email first");
      return;
    }
    setState(() => _forgotPasswordSubmitting = true);
    try {
      final email = _forgotEmailController.text.trim();
      final response = await ApiService.forgotPassword(email);
      if (!mounted) return;
      setState(() => _forgotPasswordSubmitting = false);
      if (response['status'] == 'success') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => OtpScreen(email: email, type: OtpScreenType.passwordReset)));
        _toggleForgotPassword();
      } else {
        _showErrorSnackBar(response['message'] ?? "Something went wrong");
      }
    } catch (e) {
      if (mounted) {
        setState(() => _forgotPasswordSubmitting = false);
        _showErrorSnackBar("Connection error. Please try again.");
      }
    }
  }

  Future<void> _handleRememberMe(String email) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('remembered_email', email);
      await prefs.setBool('remember_me_status', true);
    } else {
      await prefs.remove('remembered_email');
      await prefs.setBool('remember_me_status', false);
    }
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
    if (!_isLogin && _selectedRole == 'OWNER' && !_acceptTerms) {
      _showErrorSnackBar("Please accept the Terms & Conditions and Commission Policy");
      return;
    }

    setState(() => _loginSubmitting = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      // 🆕 Build registration payload with optional owner fields
      final Map<String, dynamic> regData = {
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'fullName': _nameController.text.trim(),
        'role': _selectedRole,
      };
      if (_selectedRole == 'OWNER') {
        regData.addAll({
          'businessName': _businessNameController.text.trim(),
          'businessType': _selectedBusinessType,
          'panVatNumber': _panVatController.text.trim(),
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'province': _provinceController.text.trim(),
        });
      }

      final response = _isLogin
          ? await auth.login(_emailController.text.trim(), _passwordController.text.trim())
          : await auth.register(regData);

      if (!mounted) return;
      setState(() => _loginSubmitting = false);

      if (response['status'] == 'success') {
        if (_isLogin) {
          await _handleRememberMe(_emailController.text.trim());
          _passwordController.clear();
          final auth = Provider.of<AuthProvider>(context, listen: false);
          if (auth.isPlayer) {
            if (Navigator.canPop(context)) {
              Navigator.pop(context, true);
            } else {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
            }
          } else if (auth.isOwner) {
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const OwnerDashboard()), (route) => false);
          } else if (auth.isAdmin) {
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AdminAccountScreen()), (route) => false);
          }
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => OtpScreen(email: _emailController.text.trim(), type: OtpScreenType.emailVerification)));
        }
      } else if (response['requiresVerification'] == true) {
        _showErrorSnackBar("Email not verified. Redirecting...");
        Navigator.push(context, MaterialPageRoute(builder: (_) => OtpScreen(email: _emailController.text.trim(), type: OtpScreenType.emailVerification)));
      } else {
        _showErrorSnackBar(response['message'] ?? "Authentication failed");
      }
    } catch (e) {
      setState(() => _loginSubmitting = false);
      _showErrorSnackBar("Server connection failed. Please try again.");
    }
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
      _emailController.clear();
      _passwordController.clear();
      _nameController.clear();
      _businessNameController.clear();
      _panVatController.clear();
      _addressController.clear();
      _cityController.clear();
      _provinceController.clear();
      _rememberMe = false;
      _acceptTerms = false;
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: InkWell(
            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen())),
            borderRadius: BorderRadius.circular(30),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_back_ios, color: Colors.green, size: 18),
                const SizedBox(width: 4),
                Text('Back', style: TextStyle(color: Colors.green.shade700, fontSize: 17, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
        leadingWidth: 90,
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                    if (_showForgotPassword)
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: ForgotPasswordView(
                          controller: _forgotEmailController,
                          submitting: _forgotPasswordSubmitting,
                          onBack: _toggleForgotPassword,
                          onSubmit: _handleForgotPassword,
                        ),
                      )
                    else
                      _buildMainAuthCard(auth),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainAuthCard(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            AuthFormFields(
              isLogin: _isLogin,
              emailController: _emailController,
              passwordController: _passwordController,
              nameController: _nameController,
              selectedRole: _selectedRole,
              rememberMe: _rememberMe,
              onRememberMeChanged: () => setState(() => _rememberMe = !_rememberMe),
              onForgotPassword: _toggleForgotPassword,
              onRoleChanged: (role) => setState(() => _selectedRole = role),
            ),

            // 🆕 Owner extra fields (only in register mode)
            if (!_isLogin && _selectedRole == 'OWNER') ...[
              const SizedBox(height: 16),
              const Text('Business Details (optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              _buildTextField(_businessNameController, 'Business/Futsal Name'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedBusinessType,
                decoration: const InputDecoration(
                  labelText: 'Business Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Individual Owner', child: Text('Individual Owner')),
                  DropdownMenuItem(value: 'Company', child: Text('Company')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedBusinessType = val);
                },
              ),
              const SizedBox(height: 12),
              _buildTextField(_panVatController, 'PAN/VAT Number (optional)'),
              const SizedBox(height: 12),
              _buildTextField(_addressController, 'Address'),
              const SizedBox(height: 12),
              _buildTextField(_cityController, 'City'),
              const SizedBox(height: 12),
              _buildTextField(_provinceController, 'Province'),
              const SizedBox(height: 12),

              // Terms & Conditions checkbox
              CheckboxListTile(
                value: _acceptTerms,
                onChanged: (val) => setState(() => _acceptTerms = val ?? false),
                title: const Text('I accept the Terms & Conditions and Commission Policy'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],

            const SizedBox(height: 24),
            AuthSubmitButton(
              isLoading: _loginSubmitting || auth.isLoading,
              isLogin: _isLogin,
              onPressed: _submit,
            ),
            const SizedBox(height: 16),
            _buildToggleAuthMode(),
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

  Widget _buildToggleAuthMode() {
    return RichText(
      text: TextSpan(
        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        children: [
          TextSpan(
            text: _isLogin ? "Don't have an account? " : "Already have an account? ",
          ),
          TextSpan(
            text: _isLogin ? 'Sign Up' : 'Login',
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            recognizer: TapGestureRecognizer()..onTap = _toggleAuthMode,
          ),
        ],
      ),
    );
  }
}