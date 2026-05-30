import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';

class RegisterTeamScreen extends StatefulWidget {
  final int tournamentId;
  final String tournamentName;

  const RegisterTeamScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  @override
  State<RegisterTeamScreen> createState() => _RegisterTeamScreenState();
}

class _RegisterTeamScreenState extends State<RegisterTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _teamNameController = TextEditingController();
  final _captainNameController = TextEditingController();
  final _captainPhoneController = TextEditingController();
  final List<TextEditingController> _playerControllers = [];
  
  // State
  bool _isLoading = false;
  int _playerCount = 5; // Minimum 5 players for futsal
  
  @override
  void initState() {
    super.initState();
    _initializePlayerControllers();
  }
  
  void _initializePlayerControllers() {
    _playerControllers.clear();
    for (int i = 0; i < _playerCount; i++) {
      _playerControllers.add(TextEditingController());
    }
  }
  
  @override
  void dispose() {
    _teamNameController.dispose();
    _captainNameController.dispose();
    _captainPhoneController.dispose();
    for (var controller in _playerControllers) {
      controller.dispose();
    }
    super.dispose();
  }
  
  Future<void> _registerTeam() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Collect player names
    List<String> players = [];
    for (var controller in _playerControllers) {
      if (controller.text.trim().isNotEmpty) {
        players.add(controller.text.trim());
      }
    }
    
    if (players.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least 5 players'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final response = await ApiService.post(
        'tournaments/${widget.tournamentId}/register-team',
        {
          'teamName': _teamNameController.text.trim(),
          'captainName': _captainNameController.text.trim(),
          'captainPhone': _captainPhoneController.text.trim(),
          'players': players,
          'jerseyColor': null,
        },
      );
      
      setState(() => _isLoading = false);
      
      if (response['status'] == 'success') {
        // Show success and go back
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Team registered successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate registration success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Registration failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _addPlayer() {
    if (_playerCount < 12) {
      setState(() {
        _playerCount++;
        _playerControllers.add(TextEditingController());
      });
    }
  }
  
  void _removePlayer(int index) {
    if (_playerCount > 5) {
      setState(() {
        _playerControllers[index].dispose();
        _playerControllers.removeAt(index);
        _playerCount--;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register for ${widget.tournamentName}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Team Information Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Team Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Team Name
                          TextFormField(
                            controller: _teamNameController,
                            decoration: const InputDecoration(
                              labelText: 'Team Name *',
                              hintText: 'e.g., Pokhara United',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.people),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter team name';
                              }
                              if (value.length < 3) {
                                return 'Team name must be at least 3 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Captain Name
                          TextFormField(
                            controller: _captainNameController,
                            decoration: const InputDecoration(
                              labelText: 'Captain Name *',
                              hintText: 'Full name of team captain',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter captain name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Captain Phone
                          TextFormField(
                            controller: _captainPhoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Captain Phone *',
                              hintText: '98XXXXXXXX',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter captain phone number';
                              }
                              final phoneRegex = RegExp(r'^98[0-9]{8}$|^97[0-9]{8}$|^96[0-9]{8}$');
                              if (!phoneRegex.hasMatch(value)) {
                                return 'Enter valid Nepali mobile number (10 digits)';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Players Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Players',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '$_playerCount / 12',
                                style: TextStyle(
                                  color: _playerCount >= 12 ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Minimum 5 players required (futsal standard)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Player List
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _playerCount,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _playerControllers[index],
                                        decoration: InputDecoration(
                                          hintText: 'Player ${index + 1} name',
                                          border: const OutlineInputBorder(),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                        ),
                                        validator: (value) {
                                          if (index < 5 && (value == null || value.isEmpty)) {
                                            return 'Required';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    if (_playerCount > 5)
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                        onPressed: () => _removePlayer(index),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                          
                          if (_playerCount < 12)
                            Center(
                              child: TextButton.icon(
                                onPressed: _addPlayer,
                                icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                label: const Text('Add Another Player'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Submit Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _registerTeam,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Register Team',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Info Note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your registration will be reviewed by the tournament organizer. '
                            'You will be notified once approved.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text('Registering your team...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}