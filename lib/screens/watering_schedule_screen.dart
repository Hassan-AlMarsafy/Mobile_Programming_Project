import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../services/firestore_service.dart';
import '../models/watering_schedule.dart';

class WateringScheduleScreen extends StatefulWidget {
  const WateringScheduleScreen({super.key});

  @override
  State<WateringScheduleScreen> createState() => _WateringScheduleScreenState();
}

class _WateringScheduleScreenState extends State<WateringScheduleScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  WateringSchedule _schedule = WateringSchedule.defaultSchedule();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      final schedule = await _firestoreService.getWateringSchedule(user.uid);
      setState(() {
        _schedule = schedule ?? WateringSchedule.defaultSchedule();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSchedule() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final updatedSchedule = _schedule.copyWith(
      lastUpdated: DateTime.now(),
    );

    final result = await _firestoreService.saveWateringSchedule(user.uid, updatedSchedule);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] 
              ? Theme.of(context).colorScheme.primary
              : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watering Schedule'),
        elevation: 0,
        actions: [
          if (!_isLoading)
            TextButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save'),
              onPressed: _saveSchedule,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildScheduleEnabledSection(),
                if (_schedule.enabled) ...[
                  const SizedBox(height: 24),
                  _buildTimeSection(),
                  const SizedBox(height: 24),
                  _buildDurationSection(),
                  const SizedBox(height: 24),
                  _buildFrequencySection(),
                  const SizedBox(height: 24),
                  _buildDaysOfWeekSection(),
                  const SizedBox(height: 24),
                  _buildScheduleSummary(),
                ],
              ],
            ),
    );
  }

  Widget _buildScheduleEnabledSection() {
    return Card(
      child: SwitchListTile(
        title: const Text(
          'Enable Auto-Watering Schedule',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          _schedule.enabled
              ? 'Automatic watering is active'
              : 'Automatic watering is disabled',
        ),
        value: _schedule.enabled,
        activeColor: Theme.of(context).colorScheme.primary,
        onChanged: (val) {
          setState(() {
            _schedule = _schedule.copyWith(enabled: val);
          });
        },
      ),
    );
  }

  Widget _buildTimeSection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.access_time, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                const Text(
                  'Start Time',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Watering starts at'),
            trailing: InkWell(
              onTap: () => _selectTime(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_schedule.startHour.toString().padLeft(2, '0')}:${_schedule.startMinute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationSection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.timer, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                const Text(
                  'Duration',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_schedule.durationMinutes} minutes',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _schedule.durationMinutes.toDouble(),
                  min: 1,
                  max: 60,
                  divisions: 59,
                  label: '${_schedule.durationMinutes} min',
                  activeColor: Theme.of(context).colorScheme.primary,
                  onChanged: (val) {
                    setState(() {
                      _schedule = _schedule.copyWith(durationMinutes: val.toInt());
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1 min', style: Theme.of(context).textTheme.bodySmall),
                    Text('60 min', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencySection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.repeat, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                const Text(
                  'Frequency',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          RadioListTile<int>(
            title: const Text('Once per day'),
            subtitle: const Text('Water once at the scheduled time'),
            value: 0,
            groupValue: _schedule.intervalHours,
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: (val) {
              setState(() {
                _schedule = _schedule.copyWith(intervalHours: val);
              });
            },
          ),
          RadioListTile<int>(
            title: const Text('Every 4 hours'),
            subtitle: const Text('Water multiple times throughout the day'),
            value: 4,
            groupValue: _schedule.intervalHours,
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: (val) {
              setState(() {
                _schedule = _schedule.copyWith(intervalHours: val);
              });
            },
          ),
          RadioListTile<int>(
            title: const Text('Every 6 hours'),
            subtitle: const Text('Water 4 times per day'),
            value: 6,
            groupValue: _schedule.intervalHours,
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: (val) {
              setState(() {
                _schedule = _schedule.copyWith(intervalHours: val);
              });
            },
          ),
          RadioListTile<int>(
            title: const Text('Every 8 hours'),
            subtitle: const Text('Water 3 times per day'),
            value: 8,
            groupValue: _schedule.intervalHours,
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: (val) {
              setState(() {
                _schedule = _schedule.copyWith(intervalHours: val);
              });
            },
          ),
          RadioListTile<int>(
            title: const Text('Every 12 hours'),
            subtitle: const Text('Water twice per day'),
            value: 12,
            groupValue: _schedule.intervalHours,
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: (val) {
              setState(() {
                _schedule = _schedule.copyWith(intervalHours: val);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDaysOfWeekSection() {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                const Text(
                  'Days of Week',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (index) {
                final dayNum = index + 1;
                final isSelected = _schedule.daysOfWeek.contains(dayNum);
                
                return FilterChip(
                  label: Text(dayNames[index]),
                  selected: isSelected,
                  selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                  onSelected: (selected) {
                    setState(() {
                      final newDays = List<int>.from(_schedule.daysOfWeek);
                      if (selected) {
                        newDays.add(dayNum);
                      } else {
                        newDays.remove(dayNum);
                      }
                      newDays.sort();
                      _schedule = _schedule.copyWith(daysOfWeek: newDays);
                    });
                  },
                );
              }),
            ),
          ),
          const Divider(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _schedule = _schedule.copyWith(daysOfWeek: [1, 2, 3, 4, 5, 6, 7]);
                  });
                },
                child: const Text('Select All'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _schedule = _schedule.copyWith(daysOfWeek: [1, 2, 3, 4, 5]);
                  });
                },
                child: const Text('Weekdays'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _schedule = _schedule.copyWith(daysOfWeek: [6, 7]);
                  });
                },
                child: const Text('Weekends'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSummary() {
    return Card(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                const Text(
                  'Schedule Summary',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _schedule.getScheduleSummary(),
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _schedule.startHour, minute: _schedule.startMinute),
    );

    if (picked != null) {
      setState(() {
        _schedule = _schedule.copyWith(
          startHour: picked.hour,
          startMinute: picked.minute,
        );
      });
    }
  }
}
