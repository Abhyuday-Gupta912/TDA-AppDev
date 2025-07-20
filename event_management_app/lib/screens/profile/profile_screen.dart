import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/event_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/event_card.dart';
import '../../core/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadUserRegistrations();
      Provider.of<UserProvider>(context, listen: false).loadUserBookmarks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.grey50,
      body: SafeArea(
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(),

            // Statistics Row
            _buildStatisticsRow(),

            // Tab Bar
            _buildTabBar(),

            // Tab Content
            Expanded(
              child: _buildTabContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.user;
        if (user == null) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(20),
          color: AppTheme.white,
          child: Column(
            children: [
              // Profile Avatar and Info
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        width: 3,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 37,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      backgroundImage: user.profileImage != null
                          ? CachedNetworkImageProvider(user.profileImage!)
                          : null,
                      child: user.profileImage == null
                          ? Text(
                              user.initials,
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(width: 20),

                  // User Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.grey900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.grey500,
                                  ),
                        ),
                        if (user.isAdmin) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ADMIN',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Settings Button
                  IconButton(
                    onPressed: _showSettingsMenu,
                    icon: const Icon(Icons.settings, color: AppTheme.grey600),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _editProfile,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit Profile'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/qr-scanner'),
                    icon: const Icon(Icons.qr_code_scanner, size: 18),
                    label: const Text('Scan QR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppTheme.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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

  Widget _buildStatisticsRow() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        return Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.grey100),
          ),
          child: Row(
            children: [
              _buildStatItem(
                'Events Attended',
                '${userProvider.attendedEventsCount}',
                Icons.event_available,
                AppTheme.successColor,
              ),
              Container(
                width: 1,
                height: 40,
                color: AppTheme.grey200,
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
              _buildStatItem(
                'Registered',
                '${userProvider.registeredEvents.length}',
                Icons.how_to_reg,
                AppTheme.primaryColor,
              ),
              Container(
                width: 1,
                height: 40,
                color: AppTheme.grey200,
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
              _buildStatItem(
                'Bookmarked',
                '${userProvider.bookmarkedEvents.length}',
                Icons.bookmark,
                AppTheme.warningColor,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
      String label, String count, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.grey900,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
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
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'Inter',
        ),
        tabs: const [
          Tab(text: 'Registered'),
          Tab(text: 'Bookmarked'),
          Tab(text: 'Attended'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        return TabBarView(
          controller: _tabController,
          children: [
            _buildEventsList(
                userProvider.registeredEvents, 'No registered events'),
            _buildEventsList(
                userProvider.bookmarkedEvents, 'No bookmarked events'),
            _buildEventsList(userProvider.attendedEvents, 'No attended events'),
          ],
        );
      },
    );
  }

  Widget _buildEventsList(List events, String emptyMessage) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
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
              'Start exploring events to see them here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.grey500,
                  ),
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
          child: EventCard(
            event: event,
            onTap: () => context.push('/event/${event.id}'),
          ),
        );
      },
    );
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: AppTheme.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Menu Items
            const SizedBox(height: 20),
            _buildMenuItem(Icons.person, 'Edit Profile', _editProfile),
            _buildMenuItem(
                Icons.notifications, 'Notifications', _manageNotifications),
            _buildMenuItem(Icons.privacy_tip, 'Privacy', _privacySettings),
            _buildMenuItem(Icons.help, 'Help & Support', _showHelp),
            _buildMenuItem(Icons.info, 'About', _showAbout),
            const Divider(),
            _buildMenuItem(Icons.logout, 'Logout', _logout,
                color: AppTheme.errorColor),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap,
      {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppTheme.grey600),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? AppTheme.grey900,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _editProfile() {
    // Implement edit profile functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit profile feature coming soon!')),
    );
  }

  void _manageNotifications() {
    // Implement notification settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification settings coming soon!')),
    );
  }

  void _privacySettings() {
    // Implement privacy settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy settings coming soon!')),
    );
  }

  void _showHelp() {
    // Implement help & support
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Help & support coming soon!')),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About'),
        content: const Text(
          'Event Management App v1.0.0\n\n'
          'A comprehensive platform for discovering and managing college events.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await Provider.of<AuthProvider>(context, listen: false).logout();
              if (mounted) {
                context.go('/login');
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}
