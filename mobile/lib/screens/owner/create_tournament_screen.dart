import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tournament_provider.dart';
import '../../providers/futsal_provider.dart';
import '../../models/tournament.dart';
import 'add_teams_screen.dart';

class CreateTournamentScreen extends StatefulWidget {
  const CreateTournamentScreen({super.key});

  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prizePoolController = TextEditingController();
  final _entryFeeController = TextEditingController();
  final _rulesController = TextEditingController();
  
  // Selected values
  int? _selectedFutsalId;
  TournamentType _selectedType = TournamentType.knockout;
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  DateTime? _endDate;
  int _numberOfTeams = 8;
  int? _maxTeams;
  bool _isPublished = false;
  
  // Prize list
  final List<String> _prizes = [];
  final TextEditingController _prizeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _prizePoolController.dispose();
    _entryFeeController.dispose();
    _rulesController.dispose();
    _prizeController.dispose();
    super.dispose();
  }

  void _addPrize() {
    if (_prizeController.text.isNotEmpty) {
      setState(() {
        _prizes.add(_prizeController.text);
        _prizeController.clear();
      });
    }
  }

  void _removePrize(int index) {
    setState(() {
      _prizes.removeAt(index);
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : (_endDate ?? _startDate.add(const Duration(days: 30))),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _createTournament() async {
    if (!_formKey.currentState!.validate()) return;

    // Prepare tournament data
    final tournamentData = {
      'futsalId': _selectedFutsalId,
      'name': _nameController.text,
      'description': _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
      'type': _selectedType == TournamentType.knockout ? 'knockout' : 'round_robin',
      'startDate': _startDate.toIso8601String(),
      'endDate': _endDate?.toIso8601String(),
      'numberOfTeams': _numberOfTeams,
      'maxTeams': _maxTeams,
      'entryFee': _entryFeeController.text.isNotEmpty ? double.parse(_entryFeeController.text) : null,
      'prizePool': _prizePoolController.text.isNotEmpty ? double.parse(_prizePoolController.text) : null,
      'rules': _rulesController.text.isNotEmpty ? _rulesController.text : null,
      'prizes': _prizes.isEmpty ? null : _prizes,
      'isPublished': _isPublished,
    };

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: Colors.green),
      ),
    );

    // Call API
    final provider = Provider.of<TournamentProvider>(context, listen: false);
    final response = await provider.createTournament(tournamentData);

    // Close loading dialog
    if (!mounted) return;
    Navigator.pop(context);

    // Show result
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response['message']),
        backgroundColor: response['status'] == 'success' ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );

if (response['status'] == 'success') {
  Navigator.pop(context); // Close loading
  Navigator.pop(context, true); // Return success to previous screen
  
  // Navigate to add teams screen
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AddTeamsScreen(
        tournamentId: response['tournamentId'],
        maxTeams: _numberOfTeams,
        tournamentType: _selectedType,
      ),
    ),
  );
}
  }

  @override
  Widget build(BuildContext context) {
    final futsalProvider = Provider.of<FutsalProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Tournament'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Basic Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Futsal Selection
                    DropdownButtonFormField<int>(
                      value: _selectedFutsalId,
                      decoration: InputDecoration(
                        labelText: 'Select Futsal *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.sports_soccer, color: Colors.green),
                      ),
                      items: futsalProvider.myFutsals.map((futsal) {
                        return DropdownMenuItem<int>(
                          value: futsal.id,
                          child: Text(futsal.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedFutsalId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) return 'Please select a futsal';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Tournament Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Tournament Name *',
                        hintText: 'e.g., Summer Cup 2024',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.emoji_events, color: Colors.green),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter tournament name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Describe your tournament...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.description, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tournament Type Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tournament Type',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Type Selection
                    Row(
                      children: [
                        Expanded(
                          child: _buildTypeCard(
                            type: TournamentType.knockout,
                            title: 'Knockout',
                            icon: Icons.emoji_events,
                            description: 'Single elimination bracket',
                            isSelected: _selectedType == TournamentType.knockout,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTypeCard(
                            type: TournamentType.roundRobin,
                            title: 'Round Robin',
                            icon: Icons.people,
                            description: 'Everyone plays everyone',
                            isSelected: _selectedType == TournamentType.roundRobin,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Schedule Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Schedule',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Start Date
                    ListTile(
                      leading: const Icon(Icons.calendar_today, color: Colors.green),
                      title: const Text('Start Date *'),
                      subtitle: Text(
                        '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                      ),
                      trailing: TextButton(
                        onPressed: () => _selectDate(context, true),
                        child: const Text('Select'),
                      ),
                    ),
                    const Divider(),

                    // End Date (Optional)
                    ListTile(
                      leading: const Icon(Icons.calendar_today, color: Colors.orange),
                      title: const Text('End Date (Optional)'),
                      subtitle: Text(
                        _endDate == null
                            ? 'Not set'
                            : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_endDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                setState(() {
                                  _endDate = null;
                                });
                              },
                            ),
                          TextButton(
                            onPressed: () => _selectDate(context, false),
                            child: const Text('Select'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Teams Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Teams',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Number of Teams
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Number of Teams: $_numberOfTeams',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _numberOfTeams > 2
                              ? () {
                                  setState(() {
                                    _numberOfTeams--;
                                  });
                                }
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: _numberOfTeams < 32
                              ? () {
                                  setState(() {
                                    _numberOfTeams++;
                                  });
                                }
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Max Teams (Optional)
                    TextFormField(
                      controller: TextEditingController(
                        text: _maxTeams?.toString() ?? '',
                      ),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Maximum Teams (Optional)',
                        hintText: 'e.g., 16',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.people, color: Colors.green),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _maxTeams = value.isNotEmpty ? int.parse(value) : null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Prizes & Fees Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Prizes & Fees',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Entry Fee
                    TextFormField(
                      controller: _entryFeeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Entry Fee (Optional)',
                        hintText: 'रू 0',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.currency_rupee, color: Colors.green),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Prize Pool
                    TextFormField(
                      controller: _prizePoolController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Prize Pool (Optional)',
                        hintText: 'रू 0',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.emoji_events, color: Colors.orange),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Prizes
                    const Text(
                      'Prizes',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    
                    // Prize input row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _prizeController,
                            decoration: InputDecoration(
                              hintText: 'e.g., Trophy + रू 5000',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.green),
                          onPressed: _addPrize,
                        ),
                      ],
                    ),

                    // Prize list
                    if (_prizes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ..._prizes.asMap().entries.map((entry) {
                        return Chip(
                          label: Text(entry.value),
                          onDeleted: () => _removePrize(entry.key),
                          deleteIconColor: Colors.red,
                          backgroundColor: Colors.green.shade50,
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Rules Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rules & Regulations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Rules
                    TextFormField(
                      controller: _rulesController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Enter tournament rules...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Publish Option
            Card(
              child: SwitchListTile(
                title: const Text('Publish Tournament'),
                subtitle: const Text('Make tournament visible to players'),
                value: _isPublished,
                activeColor: Colors.green,
                onChanged: (value) {
                  setState(() {
                    _isPublished = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _createTournament,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Create Tournament',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard({
    required TournamentType type,
    required String title,
    required IconData icon,
    required String description,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.green : Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.green : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}