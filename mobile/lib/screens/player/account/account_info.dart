import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:futsal_mobile/providers/auth_provider.dart';
import 'package:futsal_mobile/services/api_service.dart';

class AccountInfoScreen extends StatefulWidget {
  const AccountInfoScreen({super.key});

  @override
  State<AccountInfoScreen> createState() =>
      _AccountInfoScreenState();
}

class _AccountInfoScreenState
    extends State<AccountInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController =
      TextEditingController();

  final _phoneController =
      TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final user =
        Provider.of<AuthProvider>(
          context,
          listen: false,
        ).user;

    _nameController.text =
        user?.fullName ?? '';

    _phoneController.text =
        user?.phoneNumber ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final response = await ApiService.put(
        'auth/profile',
        {
          'fullName':
              _nameController.text.trim(),
          'phoneNumber':
              _phoneController.text.trim(),
        },
      );

      if (!mounted) return;

      if (response['status'] == 'success') {
        await Provider.of<AuthProvider>(
          context,
          listen: false,
        ).refreshUser();

        if (!mounted) return;

        _showSnackBar(
          'Profile updated successfully',
          Colors.green,
        );

        Navigator.pop(context);
      } else {
        _showSnackBar(
          response['message'] ?? 'Update failed',
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar(
        'Something went wrong',
        Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnackBar(
    String message,
    Color color,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user =
        Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FA),

      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            elevation: 0,
            backgroundColor:
                const Color(0xFF0F172A),

            foregroundColor: Colors.white,

            centerTitle: true,

            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Account Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=1200&auto=format&fit=crop',
                    fit: BoxFit.cover,
                  ),

                  Container(
                    decoration: BoxDecoration(
                      gradient:
                          LinearGradient(
                        begin:
                            Alignment.topCenter,
                        end: Alignment
                            .bottomCenter,
                        colors: [
                          Colors.black
                              .withValues(alpha: 
                            0.25,
                          ),
                          Colors.black
                              .withValues(alpha: 
                            0.8,
                          ),
                        ],
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundColor:
                              Colors.white,
                          child: CircleAvatar(
                            radius: 42,
                            backgroundColor:
                                const Color(
                              0xFF16A34A,
                            ),
                            foregroundImage:
                                (user?.profileImage !=
                                        null &&
                                    user!.profileImage!
                                        .isNotEmpty)
                                    ? NetworkImage(
                                        user.profileImage!,
                                      )
                                    : null,
                            child:
                                (user?.profileImage ==
                                            null ||
                                        user!.profileImage!
                                            .isEmpty)
                                    ? Text(
                                        user?.fullName
                                                .substring(
                                                  0,
                                                  1,
                                                )
                                                .toUpperCase() ??
                                            'U',
                                        style:
                                            const TextStyle(
                                          color: Colors
                                              .white,
                                          fontSize: 24,
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                        ),
                                      )
                                    : null,
                          ),
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        Text(
                          user?.fullName ??
                              'User',
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontSize: 24,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),

                        const SizedBox(
                          height: 2,
                        ),

                        Text(
                          user?.email ??
                              'No email',
                          style:
                              const TextStyle(
                            color:
                                Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.all(20),

              child: Form(
                key: _formKey,

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    _buildInfoCard(),

                    const SizedBox(
                      height: 24,
                    ),

                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Color(0xFF0F172A),
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    _buildTextField(
                      controller:
                          _nameController,
                      label:
                          'Full Name',
                      icon:
                          Icons.person_outline,
                      validator: (v) {
                        if (v == null ||
                            v
                                .trim()
                                .isEmpty) {
                          return 'Name is required';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    _buildTextField(
                      controller:
                          _phoneController,
                      label:
                          'Phone Number',
                      icon:
                          Icons.phone_outlined,
                      keyboardType:
                          TextInputType
                              .phone,
                    ),

                    const SizedBox(
                      height: 28,
                    ),

                    Container(
                      width:
                          double.infinity,

                      decoration:
                          BoxDecoration(
                        gradient:
                            const LinearGradient(
                          colors: [
                            Color(
                              0xFF22C55E,
                            ),
                            Color(
                              0xFF16A34A,
                            ),
                          ],
                        ),

                        borderRadius:
                            BorderRadius
                                .circular(
                          20,
                        ),
                      ),

                      child:
                          ElevatedButton(
                        onPressed:
                            _isSaving
                                ? null
                                : _save,

                        style:
                            ElevatedButton
                                .styleFrom(
                          elevation: 0,
                          backgroundColor:
                              Colors
                                  .transparent,
                          shadowColor:
                              Colors
                                  .transparent,
                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 18,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              20,
                            ),
                          ),
                        ),

                        child:
                            _isSaving
                                ? const SizedBox(
                                    height:
                                        24,
                                    width:
                                        24,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2.5,
                                      color:
                                          Colors.white,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.save_rounded,
                                        color:
                                            Colors.white,
                                      ),

                                      SizedBox(
                                        width:
                                            10,
                                      ),

                                      Text(
                                        'Save Changes',
                                        style:
                                            TextStyle(
                                          color:
                                              Colors.white,
                                          fontSize:
                                              16,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                      ),
                    ),

                    const SizedBox(
                      height: 30,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: const Row(
        children: [
          Icon(
            Icons.verified_user_rounded,
            color: Color(0xFF16A34A),
            size: 40,
          ),

          SizedBox(width: 16),

          Expanded(
            child: Text(
              'Keep your profile information updated for a better booking experience.',
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController
        controller,
    required String label,
    required IconData icon,
    String? Function(String?)?
        validator,
    TextInputType?
        keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,

      decoration: InputDecoration(
        filled: true,
        fillColor:
            const Color(0xFFFFFFFF),

        labelText: label,

        prefixIcon: Icon(
          icon,
          color:
              const Color(0xFF16A34A),
        ),

        contentPadding:
            const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 18,
        ),

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: Color(0xFF16A34A),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}