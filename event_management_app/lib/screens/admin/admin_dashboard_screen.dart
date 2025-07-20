import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/event_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/event_card.dart';
import '../../core/theme/app_theme.dart';
import '../../models/event_model.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EventProvider>(context, listen: false).loadEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.grey50,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Statistics Cards
            _buildStatisticsCards(),

            // Tab Bar
            _buildTabBar(),

            // Content
            Expanded(
              child: _buildTabContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Container(
          padding: const EdgeInsets.all(20),
          color: AppTheme.white,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Dashboard 👋',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.grey900,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your events and monitor performance',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.grey500,
                          ),
                    ),
                  ],
                ),
              ),

              // Admin Actions
              Row(
                children: [
                  // Promote User Button
                  IconButton(
                    onPressed: _showPromoteUserDialog,
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.person_add,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // QR Scanner for Check-ins
                  IconButton(
                    onPressed: () => context.push('/qr-scanner'),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatisticsCards() {
    return Consumer<EventProvider>(
      builder: (context, eventProvider, _) {
        final totalEvents = eventProvider.events.length;
        final liveEvents = eventProvider.liveEvents.length;
        final upcomingEvents = eventProvider.upcomingEvents.length;
        final totalAttendees = eventProvider.events.fold<int>(
          0,
          (sum, event) => sum + event.attendeesCount,
        );

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Events',
                  totalEvents.toString(),
                  Icons.event,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Live Events',
                  liveEvents.toString(),
                  Icons.live_tv,
                  AppTheme.errorColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Upcoming',
                  upcomingEvents.toString(),
                  Icons.schedule,
                  AppTheme.warningColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Attendees',
                  totalAttendees.toString(),
                  Icons.group,
                  AppTheme.successColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.grey900,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.grey500,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.grey100),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: AppTheme.grey500,
        indicator: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorPadding: const EdgeInsets.all(4),
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
        tabs: const [
          Tab(text: 'All Events'),
          Tab(text: 'Live'),
          Tab(text: 'Upcoming'),
          Tab(text: 'Analytics'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return Consumer<EventProvider>(
      builder: (context, eventProvider, _) {
        if (eventProvider.isLoading && eventProvider.events.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return TabBarView(
          controller: _tabController,
          children: [
            _buildEventsList(eventProvider.events, 'No events created yet'),
            _buildEventsList(eventProvider.liveEvents, 'No live events'),
            _buildEventsList(
                eventProvider.upcomingEvents, 'No upcoming events'),
            _buildAnalyticsView(),
          ],
        );
      },
    );
  }

  Widget _buildEventsList(List<Event> events, String emptyMessage) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.event_busy,
              size: 64,
              color: AppTheme.grey400,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.grey600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first event to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.grey500,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/create-event'),
              icon: const Icon(Icons.add),
              label: const Text('Create Event'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildAdminEventCard(event),
        );
      },
    );
  }

  Widget _buildAdminEventCard(Event event) {
    return CustomCard(
      onTap: () => context.push('/event/${event.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.grey900,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.category,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.grey500,
                          ),
                    ),
                  ],
                ),
              ),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getEventStatusColor(event).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getEventStatus(event),
                  style: TextStyle(
                    color: _getEventStatusColor(event),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // More Options
              PopupMenuButton<String>(
                onSelected: (value) => _handleEventAction(value, event),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(
                      value: 'registrations',
                      child: Text('View Registrations')),
                  const PopupMenuItem(
                      value: 'analytics', child: Text('Analytics')),
                  const PopupMenuItem(
                      value: 'duplicate', child: Text('Duplicate')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete',
                        style: TextStyle(color: AppTheme.errorColor)),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Event Metrics
          Row(
            children: [
              _buildMetric(
                  Icons.group, '${event.attendeesCount}/${event.maxAttendees}'),
              const SizedBox(width: 16),
              _buildMetric(Icons.calendar_today, _formatDate(event.startDate)),
              const SizedBox(width: 16),
              _buildMetric(
                  Icons.payments, event.isFree ? 'FREE' : '₹${event.price}'),
            ],
          ),

          const SizedBox(height: 12),

          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Registration Progress',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.grey600,
                        ),
                  ),
                  Text(
                    '${event.availabilityPercentage.toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.grey700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: event.availabilityPercentage / 100,
                backgroundColor: AppTheme.grey200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  event.availabilityPercentage > 80
                      ? AppTheme.errorColor
                      : AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.grey500),
        const SizedBox(width: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.grey600,
              ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Overview Cards
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'Total Revenue',
                  '₹25,400',
                  Icons.trending_up,
                  AppTheme.successColor,
                  '+12% from last month',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnalyticsCard(
                  'Avg. Attendance',
                  '87%',
                  Icons.group,
                  AppTheme.primaryColor,
                  '+5% from last month',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Event Performance
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top Performing Events',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),
                _buildPerformanceItem(
                    'Tech Workshop Series', '145 attendees', 0.9),
                _buildPerformanceItem(
                    'Annual Sports Meet', '280 attendees', 0.85),
                _buildPerformanceItem(
                    'Cultural Fest 2024', '320 attendees', 0.78),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Quick Actions
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickAction(
                        'Create Event',
                        Icons.add_circle,
                        AppTheme.primaryColor,
                        () => context.push('/create-event'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickAction(
                        'Check-in',
                        Icons.qr_code_scanner,
                        AppTheme.successColor,
                        () => context.push('/qr-scanner'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(
      String title, String value, IconData icon, Color color, String subtitle) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.grey900,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.grey600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.successColor,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceItem(String title, String subtitle, double progress) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.grey500,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.grey200,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.grey900,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _getEventStatus(Event event) {
    if (event.isLive) return 'LIVE';
    if (event.isPast) return 'ENDED';
    if (event.isFull) return 'FULL';
    return 'UPCOMING';
  }

  Color _getEventStatusColor(Event event) {
    if (event.isLive) return AppTheme.errorColor;
    if (event.isPast) return AppTheme.grey500;
    if (event.isFull) return AppTheme.warningColor;
    return AppTheme.successColor;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference > 0) return '${difference}d';
    return '${-difference}d ago';
  }

  void _handleEventAction(String action, Event event) {
    switch (action) {
      case 'edit':
        _editEvent(event);
        break;
      case 'registrations':
        _viewRegistrations(event);
        break;
      case 'analytics':
        _viewEventAnalytics(event);
        break;
      case 'duplicate':
        _duplicateEvent(event);
        break;
      case 'delete':
        _deleteEvent(event);
        break;
    }
  }

  void _editEvent(Event event) {
    context.push('/create-event?eventId=${event.id}');
  }

  void _viewRegistrations(Event event) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registration view coming soon!')),
    );
  }

  void _viewEventAnalytics(Event event) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event analytics coming soon!')),
    );
  }

  void _duplicateEvent(Event event) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event duplication coming soon!')),
    );
  }

  void _deleteEvent(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text(
            'Are you sure you want to delete "${event.title}"? This action cannot be undone.'),
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
              final success = await eventProvider.deleteEvent(event.id);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Event deleted successfully'
                        : 'Failed to delete event'),
                    backgroundColor:
                        success ? AppTheme.successColor : AppTheme.errorColor,
                  ),
                );
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

  void _showPromoteUserDialog() {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person_add, color: AppTheme.successColor),
            SizedBox(width: 8),
            Text('Promote User to Admin'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the email address of the user you want to promote to admin:',
              style: TextStyle(color: AppTheme.grey600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'user@example.com',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.warningColor.withOpacity(0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: AppTheme.warningColor, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Only super admins can promote users to admin.',
                      style: TextStyle(
                        color: AppTheme.warningColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return ElevatedButton(
                onPressed: () async {
                  final email = emailController.text.trim();
                  if (email.isEmpty) return;

                  Navigator.of(context).pop();

                  final success = await authProvider.promoteToAdmin(email);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? 'User promoted to admin successfully!'
                            : authProvider.error ?? 'Failed to promote user'),
                        backgroundColor: success
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                ),
                child: authProvider.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.white,
                        ),
                      )
                    : const Text('Promote',
                        style: TextStyle(color: AppTheme.white)),
              );
            },
          ),
        ],
      ),
    );
  }
}
