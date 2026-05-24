import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'dart:html' as html;
import 'dart:async';

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
import '../screens/player/home_screen.dart';
import '../../providers/favorite_provider.dart';

// Social sign‑in packages
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

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
  bool _socialLoading = false;

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

    // Initialize Facebook SDK
    _initFacebookSDK();
  }

  void _initFacebookSDK() {
    // Use the package's built-in initialization
    FacebookAuth.instance.webAndDesktopInitialize(
      appId: '1524694529192803',
      cookie: true,
      xfbml: true,
      version: 'v18.0',
    );
    print('✅ Facebook SDK initialized via package');
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
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => OtpScreen(
                    email: email, type: OtpScreenType.passwordReset)));
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

// 🔥 Google Sign‑In
  // ────────────────────────────────────────────────
  Future<void> _handleGoogleSignIn() async {
    setState(() => _socialLoading = true);

    try {
      // Configure Google Sign-In for web
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _socialLoading = false);
        return; // User cancelled
      }

      // For web, we need to get the auth headers differently
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // On web, idToken might be null - use accessToken as fallback
      String? token = googleAuth.idToken;
      String? accessToken = googleAuth.accessToken;

      print('🔵 ID Token: ${token != null ? "Present" : "NULL"}');
      print('🔵 Access Token: ${accessToken != null ? "Present" : "NULL"}');

      if (token == null && accessToken == null) {
        throw Exception('No token returned from Google');
      }

      // Use idToken if available, otherwise use accessToken
      final idToken = token ?? accessToken;

      print('📦 Token being sent: ${idToken?.substring(0, 50)}...');
      print('📦 Token type: ${token == null ? "accessToken" : "idToken"}');

      // Call backend
      final response = await ApiService.socialLogin('google', {
        'idToken': idToken,
      });

      if (!mounted) return;
      setState(() => _socialLoading = false);

      if (response['status'] == 'success') {
        await _handleSocialAuthSuccess(response);
      } else {
        _showErrorSnackBar(response['message'] ?? 'Google sign-in failed');
      }
    } catch (e) {
      print('❌ Google Sign-In Error: $e');
      if (mounted) {
        setState(() => _socialLoading = false);
        _showErrorSnackBar("Google sign-in error: ${e.toString()}");
      }
    }
  }

  // ────────────────────────────────────────────────
  // 🔥 Facebook Sign‑In
  // ────────────────────────────────────────────────
  Future<void> _handleFacebookSignIn() async {
    setState(() => _socialLoading = true);

    try {
      print('Starting Facebook login...');

      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      print('Login result status: ${result.status}');

      if (result.status == LoginStatus.cancelled) {
        print('User cancelled login');
        setState(() => _socialLoading = false);
        return;
      }

      if (result.status != LoginStatus.success) {
        throw Exception('Login failed: ${result.message}');
      }

      final accessToken = result.accessToken?.tokenString;
      print('Access token obtained: ${accessToken != null}');

      if (accessToken == null) {
        throw Exception('No access token');
      }

      // Send to backend
      final response = await ApiService.socialLogin('facebook', {
        'accessToken': accessToken,
      });

      print('Backend response status: ${response['status']}');

      if (!mounted) return;
      setState(() => _socialLoading = false);

      if (response['status'] == 'success') {
        await _handleSocialAuthSuccess(response);
      } else {
        _showErrorSnackBar(response['message'] ?? 'Facebook sign-in failed');
      }
    } catch (e) {
      print('❌ Facebook error: $e');
      if (mounted) {
        setState(() => _socialLoading = false);
        _showErrorSnackBar("Facebook error: ${e.toString()}");
      }
    }
  }
  //  Common handler after social auth success

  Future<void> _handleSocialAuthSuccess(Map<String, dynamic> response) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.setUserAndToken(response['token'], response['user']);

    // Navigate based on role (same as normal login)
    if (auth.isPlayer) {
      await Provider.of<FavoriteProvider>(context, listen: false)
          .loadFavorites();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const PlayerHomeScreen()),
        (route) => false,
      );
    } else if (auth.isOwner) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const OwnerDashboard()),
        (route) => false,
      );
    } else if (auth.isAdmin) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AdminAccountScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (!_isLogin && _selectedRole == 'OWNER' && !_acceptTerms) {
      _showErrorSnackBar(
          "Please accept the Terms & Conditions and Commission Policy");
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
          ? await auth.login(
              _emailController.text.trim(), _passwordController.text.trim())
          : await auth.register(regData);

      if (!mounted) return;
      setState(() => _loginSubmitting = false);

      if (response['status'] == 'success') {
        if (_isLogin) {
          await _handleRememberMe(_emailController.text.trim());
          _passwordController.clear();
          final auth = Provider.of<AuthProvider>(context, listen: false);

          if (auth.isPlayer) {
            await Provider.of<FavoriteProvider>(context, listen: false)
                .loadFavorites();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const PlayerHomeScreen()),
              (route) => false,
            );
          } else if (auth.isOwner) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const OwnerDashboard()),
              (route) => false,
            );
          } else if (auth.isAdmin) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const AdminAccountScreen()),
              (route) => false,
            );
          }
        } else {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => OtpScreen(
                      email: _emailController.text.trim(),
                      type: OtpScreenType.emailVerification)));
        }
      } else if (response['requiresVerification'] == true) {
        _showErrorSnackBar("Email not verified. Redirecting...");
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => OtpScreen(
                    email: _emailController.text.trim(),
                    type: OtpScreenType.emailVerification)));
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
            onTap: () => Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const PlayerHomeScreen())),
            borderRadius: BorderRadius.circular(30),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_back_ios, color: Colors.green, size: 18),
                const SizedBox(width: 4),
                Text('Back',
                    style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 17,
                        fontWeight: FontWeight.w500)),
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
              onRememberMeChanged: () =>
                  setState(() => _rememberMe = !_rememberMe),
              onForgotPassword: _toggleForgotPassword,
              onRoleChanged: (role) => setState(() => _selectedRole = role),
            ),

            // 🆕 Owner extra fields (only in register mode)
            if (!_isLogin && _selectedRole == 'OWNER') ...[
              const SizedBox(height: 16),
              const Text('Business Details (optional)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
                  DropdownMenuItem(
                      value: 'Individual Owner',
                      child: Text('Individual Owner')),
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
                title: const Text(
                    'I accept the Terms & Conditions and Commission Policy'),
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
            const SizedBox(height: 24),
            _buildSocialSignInSection(),
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
            text: _isLogin
                ? "Don't have an account? "
                : "Already have an account? ",
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

  Widget _buildSocialSignInSection() {
    return Column(
      children: [
        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('or continue with',
                  style: TextStyle(color: Colors.grey)),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google Button
            _buildSocialButton(
              icon: 'assets/google_logo.png', // add your own asset
              assetIcon: false,
              iconData: Icons.g_mobiledata, // fallback icon
              color: Colors.red,
              onPressed: _handleGoogleSignIn,
            ),
            const SizedBox(width: 20),
            // Facebook Button
            _buildSocialButton(
              icon: 'assets/facebook_logo.png',
              assetIcon: false,
              iconData: Icons.facebook,
              color: const Color(0xFF1877F2),
              onPressed: _handleFacebookSignIn,
            ),
          ],
        ),
        if (_socialLoading)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }

  Widget _buildSocialButton({
    required String icon,
    required bool assetIcon,
    required IconData iconData,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: assetIcon
            ? Image.asset(icon, height: 24, width: 24)
            : Icon(iconData, color: color, size: 28),
      ),
    );
  }
}
