import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:add_2_calendar/add_2_calendar.dart' as add2calendar;
import '../../providers/event_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/event_model.dart';
import '../../widgets/custom_button.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  Event? _event;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEventDetails();
  }

  Future<void> _loadEventDetails() async {
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    final event = await eventProvider.getEventById(widget.eventId);

    setState(() {
      _event = event;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_event == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppTheme.grey400),
              SizedBox(height: 16),
              Text(
                'Event not found',
                style: TextStyle(fontSize: 18, color: AppTheme.grey600),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          _buildSliverAppBar(),

          // Event Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildEventHeader(),
                _buildEventDetails(),
                _buildEventDescription(),
                _buildOrganizerInfo(),
                _buildLocationSection(),
                _buildAttendeesSection(),
                const SizedBox(height: 100), // Space for bottom button
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppTheme.white,
      foregroundColor: AppTheme.grey900,
      actions: [
        // Share Button
        IconButton(
          onPressed: _shareEvent,
          icon: const Icon(Icons.share, color: AppTheme.grey900),
        ),

        // Bookmark Button
        Consumer<EventProvider>(
          builder: (context, eventProvider, _) {
            return IconButton(
              onPressed: () => eventProvider.toggleBookmark(_event!.id),
              icon: Icon(
                _event!.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: _event!.isBookmarked
                    ? AppTheme.primaryColor
                    : AppTheme.grey900,
              ),
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black26],
            ),
          ),
          child: _event!.imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: _event!.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppTheme.grey100,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppTheme.grey100,
                    child: const Icon(Icons.event,
                        size: 64, color: AppTheme.grey400),
                  ),
                )
              : Container(
                  color: AppTheme.grey100,
                  child: const Icon(Icons.event,
                      size: 64, color: AppTheme.grey400),
                ),
        ),
      ),
    );
  }

  Widget _buildEventHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category and Live Badge
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getCategoryColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _event!.category.toUpperCase(),
                  style: TextStyle(
                    color: _getCategoryColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              if (_event!.isLive) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppTheme.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: AppTheme.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Event Title
          Text(
            _event!.title,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.grey900,
                  height: 1.2,
                ),
          ),

          const SizedBox(height: 16),

          // Price
          if (_event!.price > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '₹${_event!.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: AppTheme.successColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'FREE EVENT',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventDetails() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey100),
      ),
      child: Column(
        children: [
          // Date and Time
          _buildDetailRow(
            icon: Icons.access_time,
            title: 'Date & Time',
            subtitle: AppDateUtils.formatDateRange(
                _event!.startDate, _event!.endDate),
            onTap: _addToCalendar,
            actionIcon: Icons.calendar_today,
          ),

          const Divider(height: 32, color: AppTheme.grey100),

          // Location
          _buildDetailRow(
            icon: Icons.location_on,
            title: 'Location',
            subtitle: _event!.location,
            onTap: _openLocation,
            actionIcon: Icons.directions,
          ),

          const Divider(height: 32, color: AppTheme.grey100),

          // Organizer
          _buildDetailRow(
            icon: Icons.person,
            title: 'Organized by',
            subtitle: _event!.organizerName,
            onTap: _contactOrganizer,
            actionIcon: Icons.message,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    IconData? actionIcon,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.grey600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.grey900,
                    ),
              ),
            ],
          ),
        ),
        if (onTap != null && actionIcon != null)
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.grey100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(actionIcon, color: AppTheme.grey600, size: 20),
            ),
          ),
      ],
    );
  }

  Widget _buildEventDescription() {
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
            'About This Event',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.grey900,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            _event!.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.grey700,
                  height: 1.5,
                ),
          ),
          if (_event!.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _event!.tags
                  .map((tag) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.grey100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '#$tag',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.grey600,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrganizerInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: Text(
              _event!.organizerName.isNotEmpty
                  ? _event!.organizerName[0].toUpperCase()
                  : 'O',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _event!.organizerName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.grey900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Event Organizer',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.grey500,
                      ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: _contactOrganizer,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Contact'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
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
          Row(
            children: [
              Text(
                'Location',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.grey900,
                    ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _openLocation,
                icon: const Icon(Icons.directions, size: 18),
                label: const Text('Directions'),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            _event!.location,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.grey700,
                ),
          ),

          const SizedBox(height: 16),

          // Map placeholder
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: AppTheme.grey100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 48, color: AppTheme.grey400),
                  SizedBox(height: 8),
                  Text(
                    'Map View',
                    style: TextStyle(color: AppTheme.grey500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendeesSection() {
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
          Row(
            children: [
              Text(
                'Attendees',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.grey900,
                    ),
              ),
              const Spacer(),
              Text(
                '${_event!.attendeesCount}/${_event!.maxAttendees}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress Bar
          LinearProgressIndicator(
            value: _event!.availabilityPercentage / 100,
            backgroundColor: AppTheme.grey200,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),

          const SizedBox(height: 8),

          Text(
            '${(100 - _event!.availabilityPercentage).toStringAsFixed(0)}% spots available',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.grey500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
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
            child: CustomButton(
              text: _getButtonText(),
              onPressed: _getButtonAction(),
              backgroundColor: _getButtonColor(),
              textColor: AppTheme.white,
              icon: _getButtonIcon(),
            ),
          ),
        );
      },
    );
  }

  String _getButtonText() {
    if (_event!.isPast) return 'Event Ended';
    if (_event!.isFull) return 'Event Full';
    if (_event!.isLive) return 'Join Live Event';
    return 'Register Now';
  }

  VoidCallback? _getButtonAction() {
    if (_event!.isPast || _event!.isFull) return null;
    if (_event!.isLive) return _joinLiveEvent;
    return _registerForEvent;
  }

  Color _getButtonColor() {
    if (_event!.isPast || _event!.isFull) return AppTheme.grey400;
    if (_event!.isLive) return AppTheme.errorColor;
    return AppTheme.primaryColor;
  }

  IconData? _getButtonIcon() {
    if (_event!.isLive) return Icons.play_arrow;
    if (!_event!.isPast && !_event!.isFull) return Icons.person_add;
    return null;
  }

  Color _getCategoryColor() {
    switch (_event!.category.toLowerCase()) {
      case 'workshop':
        return AppTheme.primaryColor;
      case 'competition':
        return AppTheme.warningColor;
      case 'social':
        return AppTheme.successColor;
      default:
        return AppTheme.grey500;
    }
  }

  void _shareEvent() {
    Share.share(
      'Check out this amazing event: ${_event!.title}\n\n'
      '📅 ${AppDateUtils.formatEventDateTime(_event!.startDate)}\n'
      '📍 ${_event!.location}\n\n'
      'Register now!',
      subject: _event!.title,
    );
  }

  void _addToCalendar() {
    final event = add2calendar.Event(
      title: _event!.title,
      description: _event!.description,
      location: _event!.location,
      startDate: _event!.startDate,
      endDate: _event!.endDate,
    );

    add2calendar.Add2Calendar.addEvent2Cal(event);
  }

  void _openLocation() {
    // Implement map opening functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening map...')),
    );
  }

  void _contactOrganizer() {
    // Implement contact organizer functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Organizer'),
        content: const Text(
            'Contact organizer functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _registerForEvent() {
    context.push('/event/${_event!.id}/register');
  }

  void _joinLiveEvent() {
    // Implement live event joining
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Joining live event...')),
    );
  }
}
