import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/event_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../core/theme/app_theme.dart';
import '../../models/event_model.dart';

class CreateEventScreen extends StatefulWidget {
  final String? eventId; // For editing existing events

  const CreateEventScreen({super.key, this.eventId});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _maxAttendeesController = TextEditingController();
  final _tagsController = TextEditingController();

  String _selectedCategory = 'Workshop';
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  File? _selectedImage;
  bool _isLoading = false;
  bool _isEditing = false;
  Event? _editingEvent;

  final List<String> _categories = [
    'Workshop',
    'Competition',
    'Social',
    'Conference',
    'Seminar',
    'Sports',
    'Cultural',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.eventId != null) {
      _isEditing = true;
      _loadEventForEditing();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _maxAttendeesController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _loadEventForEditing() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      final event = await eventProvider.getEventById(widget.eventId!);

      if (event != null) {
        setState(() {
          _editingEvent = event;
          _titleController.text = event.title;
          _descriptionController.text = event.description;
          _locationController.text = event.location;
          _priceController.text = event.price.toString();
          _maxAttendeesController.text = event.maxAttendees.toString();
          _tagsController.text = event.tags.join(', ');
          _selectedCategory = event.category;
          _startDate = event.startDate;
          _endDate = event.endDate;
          _startTime = TimeOfDay.fromDateTime(event.startDate);
          _endTime = TimeOfDay.fromDateTime(event.endDate);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load event: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.grey50,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Event' : 'Create Event'),
        elevation: 0,
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: _showDeleteConfirmation,
              icon: const Icon(Icons.delete, color: AppTheme.errorColor),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Basic Information
              _buildBasicInfoSection(),

              // Date & Time
              _buildDateTimeSection(),

              // Event Details
              _buildDetailsSection(),

              // Media Upload
              _buildMediaSection(),

              const SizedBox(height: 100), // Space for bottom button
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.grey900,
                ),
          ),

          const SizedBox(height: 20),

          // Event Title
          CustomTextField(
            controller: _titleController,
            labelText: 'Event Title',
            hintText: 'Enter event title',
            prefixIcon: Icons.event,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Event title is required';
              }
              if (value.length < 3) {
                return 'Title must be at least 3 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Category Dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Category',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.grey700,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.grey50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.grey200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.grey200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppTheme.primaryColor, width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  prefixIcon: const Icon(Icons.category,
                      color: AppTheme.grey400, size: 20),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Description
          CustomTextField(
            controller: _descriptionController,
            labelText: 'Description',
            hintText: 'Describe your event in detail...',
            maxLines: 4,
            prefixIcon: Icons.description,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Event description is required';
              }
              if (value.length < 20) {
                return 'Description must be at least 20 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Location
          CustomTextField(
            controller: _locationController,
            labelText: 'Location',
            hintText: 'Enter event location',
            prefixIcon: Icons.location_on,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Event location is required';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Date & Time',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.grey900,
                ),
          ),

          const SizedBox(height: 20),

          // Start Date and Time
          Row(
            children: [
              Expanded(
                child: _buildDateTimeField(
                  'Start Date',
                  _startDate,
                  Icons.calendar_today,
                  () => _selectDate(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateTimeField(
                  'Start Time',
                  _startTime,
                  Icons.access_time,
                  () => _selectTime(true),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // End Date and Time
          Row(
            children: [
              Expanded(
                child: _buildDateTimeField(
                  'End Date',
                  _endDate,
                  Icons.calendar_today,
                  () => _selectDate(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateTimeField(
                  'End Time',
                  _endTime,
                  Icons.access_time,
                  () => _selectTime(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeField(
      String label, dynamic value, IconData icon, VoidCallback onTap) {
    String displayText = 'Select $label';

    if (value != null) {
      if (value is DateTime) {
        displayText = '${value.day}/${value.month}/${value.year}';
      } else if (value is TimeOfDay) {
        displayText = value.format(context);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.grey700,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.grey50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.grey200),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.grey400, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    displayText,
                    style: TextStyle(
                      color:
                          value != null ? AppTheme.grey900 : AppTheme.grey400,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Details',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.grey900,
                ),
          ),

          const SizedBox(height: 20),

          // Price and Max Attendees Row
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _priceController,
                  labelText: 'Price (₹)',
                  hintText: '0 for free event',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.currency_rupee,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Price is required';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price < 0) {
                      return 'Enter valid price';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  controller: _maxAttendeesController,
                  labelText: 'Max Attendees',
                  hintText: 'Enter limit',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.group,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Max attendees is required';
                    }
                    final count = int.tryParse(value);
                    if (count == null || count <= 0) {
                      return 'Enter valid number';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Tags
          CustomTextField(
            controller: _tagsController,
            labelText: 'Tags',
            hintText:
                'Enter tags separated by commas (e.g., tech, workshop, coding)',
            prefixIcon: Icons.tag,
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Image',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.grey900,
                ),
          ),

          const SizedBox(height: 16),

          // Image Upload Area
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.grey50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.grey200,
                  style: BorderStyle.solid,
                ),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : (_editingEvent?.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _editingEvent!.imageUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_upload,
                              size: 48,
                              color: AppTheme.grey400,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap to upload event image',
                              style: TextStyle(
                                color: AppTheme.grey500,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Recommended: 16:9 aspect ratio',
                              style: TextStyle(
                                color: AppTheme.grey400,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )),
            ),
          ),

          if (_selectedImage != null || _editingEvent?.imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedImage = null;
                  });
                },
                icon: const Icon(Icons.delete, size: 18),
                label: const Text('Remove Image'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_isEditing) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.grey300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: _isEditing ? 2 : 1,
              child: CustomButton(
                text: _isEditing ? 'UPDATE EVENT' : 'CREATE EVENT',
                isLoading: _isLoading,
                onPressed: _handleSubmit,
                backgroundColor: AppTheme.primaryColor,
                textColor: AppTheme.white,
                icon: _isEditing ? Icons.update : Icons.add,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // If end date is before start date, reset it
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image =
                      await picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    setState(() {
                      _selectedImage = File(image.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image =
                      await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() {
                      _selectedImage = File(image.path);
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate date and time
    if (_startDate == null ||
        _endDate == null ||
        _startTime == null ||
        _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select all date and time fields'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Combine date and time
    final startDateTime = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );

    final endDateTime = DateTime(
      _endDate!.year,
      _endDate!.month,
      _endDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    );

    // Validate that end is after start
    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date/time must be after start date/time'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;

      final event = Event(
        id: _isEditing ? _editingEvent!.id : '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        startDate: startDateTime,
        endDate: endDateTime,
        location: _locationController.text.trim(),
        price: double.parse(_priceController.text),
        maxAttendees: int.parse(_maxAttendeesController.text),
        organizerId: user?.id ?? '',
        organizerName: user?.fullName ?? '',
        tags: _tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList(),
        createdAt: _isEditing ? _editingEvent!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final eventProvider = Provider.of<EventProvider>(context, listen: false);

      bool success;
      if (_isEditing) {
        success = await eventProvider.updateEvent(event.id, event.toJson());
      } else {
        success = await eventProvider.createEvent(event);
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing
                  ? 'Event updated successfully!'
                  : 'Event created successfully!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          context.pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(eventProvider.error ??
                  'Failed to ${_isEditing ? 'update' : 'create'} event'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text(
            'Are you sure you want to delete "${_editingEvent?.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();

              final eventProvider =
                  Provider.of<EventProvider>(context, listen: false);
              final success =
                  await eventProvider.deleteEvent(_editingEvent!.id);

              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Event deleted successfully'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                  context.pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text(eventProvider.error ?? 'Failed to delete event'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}
