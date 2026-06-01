import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/habit.dart';
import '../widgets/glass_widgets.dart';

class AddEditHabitSheet extends StatefulWidget {
  final Habit? habit; // Null if creating new, present if editing

  const AddEditHabitSheet({super.key, this.habit});

  @override
  State<AddEditHabitSheet> createState() => _AddEditHabitSheetState();
}

class _AddEditHabitSheetState extends State<AddEditHabitSheet> {
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCategory = 'Health';
  String _selectedIcon = '💪';
  Color _selectedColor = const Color(0xff4FACFE);
  int _targetGoal = 1;

  // Frequency
  String _frequencyType = 'daily'; // daily, weekly, specific, interval
  int _weeklyHits = 3;
  int _intervalDays = 2;
  final List<bool> _specificDays = List.generate(7, (_) => false); // index 0=Mon, 6=Sun

  // Reminders
  final List<String> _reminderTimes = [];

  final List<Color> _presetColors = [
    const Color(0xff4FACFE), // Aurora Blue
    const Color(0xff00F2C3), // Mint Glass
    const Color(0xffFF6B9D), // Rose Petal
    const Color(0xffFFB347), // Amber Glow
    const Color(0xffC77DFF), // Lavender Mist
    const Color(0xff0077B6), // Ocean Depth
    const Color(0xffFF6B6B), // Coral Reef
    const Color(0xff74C69D), // Sage
  ];

  final List<String> _emojis = [
    '💪', '🏋️‍♂️', '🧘‍♂️', '🧪', '🎨', '💧', '🏃‍♂️', '🍎', '💤',
    '🧠', '📚', '💻', '📝', '💵', '🤝', '🧹', '🌿', '🎯'
  ];

  final List<String> _categories = ['Health', 'Mind', 'Relationships', 'Work', 'Finance', 'Custom'];

  @override
  void initState() {
    super.initState();
    if (widget.habit != null) {
      final h = widget.habit!;
      _nameController.text = h.name;
      _notesController.text = h.notes;
      _selectedCategory = h.category;
      _selectedIcon = h.icon;
      _selectedColor = Color(h.colorValue);
      _targetGoal = h.targetGoal;
      _frequencyType = h.frequencyType;
      _reminderTimes.addAll(h.reminderTimes);

      if (_frequencyType == 'weekly' && h.frequencyDays.isNotEmpty) {
        _weeklyHits = h.frequencyDays.first;
      } else if (_frequencyType == 'specific') {
        for (final day in h.frequencyDays) {
          if (day >= 1 && day <= 7) {
            _specificDays[day - 1] = true;
          }
        }
      } else if (_frequencyType == 'interval') {
        _intervalDays = h.frequencyInterval;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addReminder() async {
    if (_reminderTimes.length >= 3) {
      showSystemToast('Maximum of 3 reminder nudges supported per flow.');
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: _selectedColor,
              onPrimary: Colors.black,
              surface: const Color(0xff131929),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null && mounted) {
      final formattedTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (!_reminderTimes.contains(formattedTime)) {
          _reminderTimes.add(formattedTime);
          _reminderTimes.sort();
        }
      });
    }
  }

  void _saveHabit() async {
    if (_nameController.text.trim().isEmpty) {
      showSystemToast('Please name this flow.');
      return;
    }

    final habitBox = Hive.box<Habit>('habits');
    
    // Resolve frequency days depending on category
    List<int> freqDays = [];
    int freqInterval = 1;
    if (_frequencyType == 'weekly') {
      freqDays = [_weeklyHits];
    } else if (_frequencyType == 'specific') {
      for (int i = 0; i < 7; i++) {
        if (_specificDays[i]) freqDays.add(i + 1); // 1=Mon, 7=Sun
      }
      if (freqDays.isEmpty) {
        showSystemToast('Please select at least 1 day for specific day schedules.');
        return;
      }
    } else if (_frequencyType == 'interval') {
      freqInterval = _intervalDays;
    }

    if (widget.habit != null) {
      // ✏️ Edit Mode: Update properties and save box
      final h = widget.habit!;
      h.name = _nameController.text.trim();
      h.notes = _notesController.text.trim();
      h.category = _selectedCategory;
      h.icon = _selectedIcon;
      h.colorValue = _selectedColor.value;
      h.targetGoal = _targetGoal;
      h.frequencyType = _frequencyType;
      h.frequencyDays = freqDays;
      h.frequencyInterval = freqInterval;
      h.reminderTimes = _reminderTimes;
      await h.save();
    } else {
      // ➕ Create Mode: Insert new record
      final newHabit = Habit(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        notes: _notesController.text.trim(),
        category: _selectedCategory,
        icon: _selectedIcon,
        colorValue: _selectedColor.value,
        streak: 0,
        isCompletedToday: false,
        currentProgress: 0,
        targetGoal: _targetGoal,
        frequencyType: _frequencyType,
        frequencyDays: freqDays,
        frequencyInterval: freqInterval,
        reminderTimes: _reminderTimes,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      await habitBox.put(newHabit.id, newHabit);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;
    return StatefulBuilder(
      builder: (context, setModalState) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32.0)),
          child: Container(
            color: const Color(0xff111625),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(bottom: keyboardSpace),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pull drag indicator bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.habit != null ? 'Edit Flow' : 'Create Flow',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (widget.habit != null)
                            IconButton(
                              icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                              onPressed: () async {
                                final navigator = Navigator.of(context);
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => GlassDialog(
                                    title: 'Purge Habit?',
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Delete this habit logs and stats permanently?',
                                          style: TextStyle(color: Colors.white.withOpacity(0.6)),
                                        ),
                                        const SizedBox(height: 24),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              child: const Text('Purge', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                                if (confirm == true && mounted) {
                                  await widget.habit!.delete();
                                  navigator.pop(); // Close sheet
                                  navigator.pop(); // Close detail screen
                                }
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Glass Preview Card
                      Text(
                        'Live Preview Card',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.4),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          height: 94,
                          decoration: BoxDecoration(
                            color: _selectedColor.withOpacity(0.12),
                            border: Border.all(color: _selectedColor.withOpacity(0.35), width: 1.0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Container(width: 5, height: double.infinity, color: _selectedColor),
                              const SizedBox(width: 14),
                              Text(_selectedIcon, style: const TextStyle(fontSize: 28)),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _nameController.text.trim().isEmpty ? 'Workout Flow' : _nameController.text.trim(),
                                      style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('🔥 0 day streak', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                                  ],
                                ),
                              ),
                              Icon(Icons.check_circle, color: _selectedColor, size: 30),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Habit Name
                      GlassTextField(
                        controller: _nameController,
                        hintText: 'Habit Name (e.g. Drink Water, Gym)',
                        prefixIcon: Icons.task_alt,
                        focusColor: _selectedColor,
                        onChanged: (val) => setState(() {}),
                      ),
                      const SizedBox(height: 14),

                      // Notes Input
                      GlassTextField(
                        controller: _notesController,
                        hintText: 'Notes (e.g. 8 glasses daily, target 6 AM)',
                        prefixIcon: Icons.edit_note_outlined,
                        focusColor: _selectedColor,
                      ),
                      const SizedBox(height: 20),

                      // Category Selector
                      Text('Category Area', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.6))),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final cat = _categories[index];
                            final isSel = _selectedCategory == cat;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedCategory = cat),
                              child: Container(
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSel ? _selectedColor.withOpacity(0.15) : Colors.white.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isSel ? _selectedColor.withOpacity(0.4) : Colors.white.withOpacity(0.08)),
                                ),
                                child: Center(
                                  child: Text(
                                    cat,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isSel ? _selectedColor : Colors.white60,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Daily Target Count
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Daily Target Goal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.6))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(color: _selectedColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                            child: Text('$_targetGoal target hits', style: TextStyle(color: _selectedColor, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ),
                      Slider(
                        value: _targetGoal.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        activeColor: _selectedColor,
                        inactiveColor: Colors.white.withOpacity(0.05),
                        onChanged: (val) => setState(() => _targetGoal = val.toInt()),
                      ),
                      const SizedBox(height: 12),

                      // Icon Emoji Picker
                      Text('Select Icon Symbol', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.6))),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, mainAxisSpacing: 10, crossAxisSpacing: 10),
                          itemCount: _emojis.length,
                          itemBuilder: (context, index) {
                            final emoji = _emojis[index];
                            final isSel = _selectedIcon == emoji;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedIcon = emoji),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSel ? _selectedColor.withOpacity(0.15) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isSel ? _selectedColor.withOpacity(0.4) : Colors.transparent),
                                ),
                                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Color Picker presets
                      Text('Accent Palette Theme', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.6))),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _presetColors.map((color) {
                          final isSel = _selectedColor == color;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedColor = color),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(color: isSel ? Colors.white : Colors.transparent, width: 2.5),
                                boxShadow: isSel ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 10, spreadRadius: 1)] : [],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Frequency Configurations
                      Text('Recurrence Frequency', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.6))),
                      const SizedBox(height: 12),
                      Row(
                        children: ['daily', 'weekly', 'specific', 'interval'].map((type) {
                          final isSel = _frequencyType == type;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _frequencyType = type),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSel ? _selectedColor.withOpacity(0.15) : Colors.white.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: isSel ? _selectedColor.withOpacity(0.4) : Colors.white.withOpacity(0.06)),
                                ),
                                child: Center(
                                  child: Text(
                                    type.substring(0, 1).toUpperCase() + type.substring(1),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isSel ? _selectedColor : Colors.white60,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // Render Dynamic Sub-frequency controllers
                      if (_frequencyType == 'weekly') ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Times per Week', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5))),
                            Text('$_weeklyHits hits/week', style: TextStyle(color: _selectedColor, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Slider(
                          value: _weeklyHits.toDouble(),
                          min: 1, max: 7, divisions: 6,
                          activeColor: _selectedColor,
                          inactiveColor: Colors.white.withOpacity(0.05),
                          onChanged: (val) => setState(() => _weeklyHits = val.toInt()),
                        ),
                      ] else if (_frequencyType == 'specific') ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(7, (index) {
                            final List<String> shortDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                            final isSelected = _specificDays[index];
                            return GestureDetector(
                              onTap: () => setState(() => _specificDays[index] = !isSelected),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isSelected ? _selectedColor.withOpacity(0.18) : Colors.white.withOpacity(0.04),
                                  border: Border.all(color: isSelected ? _selectedColor.withOpacity(0.4) : Colors.white.withOpacity(0.08)),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    shortDays[index],
                                    style: TextStyle(
                                      color: isSelected ? _selectedColor : Colors.white60,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ] else if (_frequencyType == 'interval') ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Custom Interval Repeat', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5))),
                            Text('Every $_intervalDays days', style: TextStyle(color: _selectedColor, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Slider(
                          value: _intervalDays.toDouble(),
                          min: 2, max: 30, divisions: 28,
                          activeColor: _selectedColor,
                          inactiveColor: Colors.white.withOpacity(0.05),
                          onChanged: (val) => setState(() => _intervalDays = val.toInt()),
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Reminders List
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Reminder Nudges', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.6))),
                          TextButton.icon(
                            icon: const Icon(Icons.alarm_add, size: 16),
                            label: const Text('Add Nudge', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: TextButton.styleFrom(foregroundColor: _selectedColor),
                            onPressed: _addReminder,
                          ),
                        ],
                      ),
                      if (_reminderTimes.isEmpty)
                        Text('No active reminder nudges configured.', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.3)))
                      else
                        Wrap(
                          spacing: 8,
                          children: _reminderTimes.map((time) {
                            return Chip(
                              backgroundColor: Colors.white.withOpacity(0.04),
                              side: BorderSide(color: Colors.white.withOpacity(0.08)),
                              label: Text(
                                time,
                                style: GoogleFonts.spaceGrotesk(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              deleteIcon: Icon(Icons.cancel, color: Colors.white.withOpacity(0.4), size: 16),
                              onDeleted: () => setState(() => _reminderTimes.remove(time)),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 32),

                      // Save Flow Button
                      GlassButton(
                        text: widget.habit != null ? 'Apply Changes 🌊' : 'Commit Flow 🌊',
                        color: _selectedColor,
                        onPressed: _saveHabit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
