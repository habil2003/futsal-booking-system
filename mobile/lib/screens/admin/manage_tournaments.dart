import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class ManageTournamentsScreen extends StatefulWidget {
  const ManageTournamentsScreen({super.key});

  @override
  State<ManageTournamentsScreen> createState() =>
      _ManageTournamentsScreenState();
}

class _ManageTournamentsScreenState extends State<ManageTournamentsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxTeamsController = TextEditingController();
  final _entryFeeController = TextEditingController();
  final _prizePoolController = TextEditingController();
  final _rulesController = TextEditingController();
  final _prizesController = TextEditingController();

  // Dropdown values
  int? _selectedFutsalId;
  String? _selectedType = 'LEAGUE';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isPublished = false;

  bool _isLoading = false;
  bool _isLoadingTournaments = false;
  List<Map<String, dynamic>> _tournaments = [];
  List<Map<String, dynamic>> _futsals = [];
  int? _editingId;

  @override
  void initState() {
    super.initState();
    _loadFutsals();
    _loadTournaments();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _maxTeamsController.dispose();
    _entryFeeController.dispose();
    _prizePoolController.dispose();
    _rulesController.dispose();
    _prizesController.dispose();
    super.dispose();
  }

  Future<void> _loadFutsals() async {
    try {
      final response = await ApiService.getList('tournaments/futsals/dropdown');
      setState(() {
        _futsals = response.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      debugPrint('Error loading futsals: $e');
    }
  }

  Future<void> _loadTournaments() async {
    setState(() => _isLoadingTournaments = true);
    try {
      final response = await ApiService.getList('tournaments');
      setState(() {
        _tournaments = response.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load tournaments: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoadingTournaments = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart)
          _startDate = picked;
        else
          _endDate = picked;
      });
    }
  }

  Future<void> _submitTournament() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFutsalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a futsal'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select start date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'futsalId': _selectedFutsalId,
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'type': _selectedType,
        'startDate': _startDate!.toIso8601String(),
        if (_endDate != null) 'endDate': _endDate!.toIso8601String(),
        'maxTeams': int.parse(_maxTeamsController.text.trim()),
        if (_entryFeeController.text.isNotEmpty)
          'entryFee': double.parse(_entryFeeController.text.trim()),
        if (_prizePoolController.text.isNotEmpty)
          'prizePool': double.parse(_prizePoolController.text.trim()),
        'rules': _rulesController.text.trim(),
        'prizes': _prizesController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        'isPublished': _isPublished,
      };

      final response = _editingId == null
          ? await ApiService.post('tournaments', data)
          : await ApiService.put('tournaments/${_editingId}', data);

      if (!mounted) return;

      if (response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _editingId == null ? 'Tournament created' : 'Tournament updated',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _clearForm();
        _loadTournaments();
      } else {
        throw response['message'] ?? 'Operation failed';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _editTournament(Map<String, dynamic> t) {
    setState(() {
      _editingId = t['id'];
      _selectedFutsalId = t['futsalId'];
      _nameController.text = t['name'] ?? '';
      _descriptionController.text = t['description'] ?? '';
      _selectedType = t['type'] ?? 'LEAGUE';
      _startDate = t['startDate'] != null ? DateTime.parse(t['startDate']) : null;
      _endDate = t['endDate'] != null ? DateTime.parse(t['endDate']) : null;
      _maxTeamsController.text = t['maxTeams']?.toString() ?? '';
      _entryFeeController.text = t['entryFee']?.toString() ?? '';
      _prizePoolController.text = t['prizePool']?.toString() ?? '';
      _rulesController.text = t['rules'] ?? '';
      _prizesController.text = (t['prizes'] as List?)?.join(', ') ?? '';
      _isPublished = t['isPublished'] ?? false;
    });
  }

  Future<void> _deleteTournament(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Tournament'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final response = await ApiService.delete('tournaments/$id');
      if (response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tournament deleted'),
            backgroundColor: Colors.green,
          ),
        );
        _loadTournaments();
        if (_editingId == id) _clearForm();
      } else {
        throw response['message'] ?? 'Delete failed';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _togglePublished(int id, bool current) async {
    try {
      final response = await ApiService.patch(
        'tournaments/$id',
        {'isPublished': !current},
      );
      if (response['status'] == 'success') {
        _loadTournaments();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _maxTeamsController.clear();
    _entryFeeController.clear();
    _prizePoolController.clear();
    _rulesController.clear();
    _prizesController.clear();
    setState(() {
      _editingId = null;
      _selectedFutsalId = null;
      _selectedType = 'LEAGUE';
      _startDate = null;
      _endDate = null;
      _isPublished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Tournaments'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_editingId != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _clearForm,
              tooltip: 'Cancel editing',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Create/Edit Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _editingId == null ? 'Create Tournament' : 'Edit Tournament',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  // Futsal dropdown
                  DropdownButtonFormField<int>(
                    value: _selectedFutsalId,
                    decoration: const InputDecoration(
                      labelText: 'Select Futsal',
                      border: OutlineInputBorder(),
                    ),
                    items: _futsals.map<DropdownMenuItem<int>>((f) {
                      return DropdownMenuItem<int>(
                        value: f['id'] as int,
                        child: Text(f['name'] as String),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedFutsalId = v),
                    validator: (v) => v == null ? 'Futsal is required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(_nameController, 'Name', 'e.g., Summer Cup'),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _descriptionController,
                    'Description',
                    'Details...',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  // Type dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Tournament Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'LEAGUE', child: Text('League')),
                      DropdownMenuItem(value: 'KNOCKOUT', child: Text('Knockout')),
                    ],
                    onChanged: (v) => setState(() => _selectedType = v),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _maxTeamsController,
                    'Max Teams',
                    'e.g., 8',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _entryFeeController,
                    'Entry Fee (optional)',
                    'e.g., 1000',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _prizePoolController,
                    'Prize Pool (optional)',
                    'e.g., 50000',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _rulesController,
                    'Rules (optional)',
                    'Tournament rules...',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _prizesController,
                    'Prizes (comma separated)',
                    '1st: Rs. 5000, 2nd: Rs. 3000',
                  ),
                  const SizedBox(height: 16),
                  // Date pickers
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: const Text('Start Date'),
                          subtitle: Text(
                            _startDate == null
                                ? 'Select'
                                : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                          ),
                          onTap: () => _selectDate(context, true),
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          title: const Text('End Date (optional)'),
                          subtitle: Text(
                            _endDate == null
                                ? 'Select'
                                : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                          ),
                          onTap: () => _selectDate(context, false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Published checkbox
                  CheckboxListTile(
                    title: const Text('Publish tournament'),
                    value: _isPublished,
                    onChanged: (v) => setState(() => _isPublished = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitTournament,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
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
                              : Text(
                                  _editingId == null ? 'Create' : 'Update',
                                ),
                        ),
                      ),
                      if (_editingId != null) ...[
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: _clearForm,
                          child: const Text('Cancel'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: 16),

            // Heading for existing tournaments
            const Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'All Tournaments',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Existing Tournaments List
            _isLoadingTournaments
                ? const Center(child: CircularProgressIndicator())
                : _tournaments.isEmpty
                    ? const Center(child: Text('No tournaments yet'))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _tournaments.length,
                        itemBuilder: (context, index) {
                          final t = _tournaments[index];
                          return _buildTournamentTile(t);
                        },
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (value) {
        if (label == 'Name' && (value == null || value.trim().isEmpty)) {
          return 'Name is required';
        }
        if (label == 'Max Teams' && (value == null || value.trim().isEmpty)) {
          return 'Max teams is required';
        }
        return null;
      },
    );
  }

  Widget _buildTournamentTile(Map<String, dynamic> t) {
    final bool isPublished = t['isPublished'] ?? false;
    final String startDate = _formatShortDate(t['startDate']);
    final String? endDate = _formatShortDate(t['endDate']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.emoji_events, color: Colors.green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t['name'] ?? 'Untitled',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t['description'] ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '$startDate${endDate != null ? ' - $endDate' : ''}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    isPublished ? Icons.visibility : Icons.visibility_off,
                    color: isPublished ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                  onPressed: () => _togglePublished(t['id'], isPublished),
                  tooltip: isPublished ? 'Published' : 'Draft',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                  onPressed: () => _editTournament(t),
                  tooltip: 'Edit',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => _deleteTournament(t['id']),
                  tooltip: 'Delete',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatShortDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }
}