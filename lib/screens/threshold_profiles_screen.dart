import 'package:flutter/material.dart';
import '../services/database_service.dart';

class ThresholdProfilesScreen extends StatefulWidget {
  const ThresholdProfilesScreen({super.key});

  @override
  State<ThresholdProfilesScreen> createState() =>
      _ThresholdProfilesScreenState();
}

class _ThresholdProfilesScreenState extends State<ThresholdProfilesScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Map<String, dynamic>> _profiles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() => _loading = true);
    final profiles = await _databaseService.getThresholdProfiles();
    setState(() {
      _profiles = profiles;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Threshold Profiles'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProfileDialog(),
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _profiles.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _profiles.length,
                  itemBuilder: (context, index) {
                    return _buildProfileCard(_profiles[index]);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.tune, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No profiles saved',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create a new profile',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(Map<String, dynamic> profile) {
    final isActive = profile['is_active'] == 1;

    return Card(
      elevation: isActive ? 4 : 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isActive
            ? BorderSide(color: Colors.green[700]!, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showProfileDetails(profile),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green[100] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.eco,
                      color: isActive ? Colors.green[700] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile['name'] ?? 'Unnamed',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isActive)
                          Text(
                            'Currently Active',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleProfileAction(value, profile),
                    itemBuilder: (context) => [
                      if (!isActive)
                        const PopupMenuItem(
                          value: 'activate',
                          child: Text('Set as Active'),
                        ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      if (profile['name'] != 'Default')
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete',
                              style: TextStyle(color: Colors.red)),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildThresholdChip(
                      'Temp',
                      '${profile['temp_min']}-${profile['temp_max']}°C',
                      Colors.orange),
                  _buildThresholdChip('pH',
                      '${profile['ph_min']}-${profile['ph_max']}', Colors.blue),
                  _buildThresholdChip(
                      'TDS',
                      '${profile['tds_min']?.toInt()}-${profile['tds_max']?.toInt()}',
                      Colors.purple),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThresholdChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style:
            TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _handleProfileAction(String action, Map<String, dynamic> profile) async {
    switch (action) {
      case 'activate':
        await _databaseService.setActiveProfile(profile['id'] as int);
        _loadProfiles();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${profile['name']} is now active')),
          );
        }
        break;
      case 'edit':
        _showEditProfileDialog(profile);
        break;
      case 'delete':
        _showDeleteConfirmation(profile);
        break;
    }
  }

  void _showProfileDetails(Map<String, dynamic> profile) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              profile['name'] ?? '',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildDetailRow('Temperature',
                '${profile['temp_min']}°C - ${profile['temp_max']}°C'),
            _buildDetailRow(
                'pH Level', '${profile['ph_min']} - ${profile['ph_max']}'),
            _buildDetailRow('Water Level',
                '${profile['water_min']}% - ${profile['water_max']}%'),
            _buildDetailRow('TDS',
                '${profile['tds_min']?.toInt()} - ${profile['tds_max']?.toInt()} ppm'),
            _buildDetailRow('Light',
                '${profile['light_min']?.toInt()} - ${profile['light_max']?.toInt()} lux'),
            const SizedBox(height: 20),
            if (profile['is_active'] != 1)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _databaseService
                        .setActiveProfile(profile['id'] as int);
                    _loadProfiles();
                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Activate Profile',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showAddProfileDialog() {
    _showProfileFormDialog(null);
  }

  void _showEditProfileDialog(Map<String, dynamic> profile) {
    _showProfileFormDialog(profile);
  }

  void _showProfileFormDialog(Map<String, dynamic>? existingProfile) {
    final nameController =
        TextEditingController(text: existingProfile?['name'] ?? '');
    final tempMinController = TextEditingController(
        text: existingProfile?['temp_min']?.toString() ?? '18');
    final tempMaxController = TextEditingController(
        text: existingProfile?['temp_max']?.toString() ?? '28');
    final phMinController = TextEditingController(
        text: existingProfile?['ph_min']?.toString() ?? '5.5');
    final phMaxController = TextEditingController(
        text: existingProfile?['ph_max']?.toString() ?? '6.5');
    final tdsMinController = TextEditingController(
        text: existingProfile?['tds_min']?.toInt().toString() ?? '800');
    final tdsMaxController = TextEditingController(
        text: existingProfile?['tds_max']?.toInt().toString() ?? '1500');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingProfile == null ? 'New Profile' : 'Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Profile Name'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: tempMinController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Temp Min'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: tempMaxController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Temp Max'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: phMinController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'pH Min'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: phMaxController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'pH Max'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: tdsMinController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'TDS Min'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: tdsMaxController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'TDS Max'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final profile = {
                'name': nameController.text,
                'temp_min': double.tryParse(tempMinController.text) ?? 18,
                'temp_max': double.tryParse(tempMaxController.text) ?? 28,
                'ph_min': double.tryParse(phMinController.text) ?? 5.5,
                'ph_max': double.tryParse(phMaxController.text) ?? 6.5,
                'water_min': 20.0,
                'water_max': 100.0,
                'tds_min': double.tryParse(tdsMinController.text) ?? 800,
                'tds_max': double.tryParse(tdsMaxController.text) ?? 1500,
                'light_min': 200.0,
                'light_max': 1000.0,
                'is_active': 0,
              };

              if (existingProfile == null) {
                await _databaseService.addThresholdProfile(profile);
              } else {
                await _databaseService.updateThresholdProfile(
                    existingProfile['id'] as int, profile);
              }

              _loadProfiles();
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            child: Text(
              existingProfile == null ? 'Create' : 'Save',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Profile'),
        content: Text('Are you sure you want to delete "${profile['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _databaseService
                  .deleteThresholdProfile(profile['id'] as int);
              _loadProfiles();
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
