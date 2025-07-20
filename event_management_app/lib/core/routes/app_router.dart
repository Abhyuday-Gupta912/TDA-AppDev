import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/events/event_detail_screen.dart';
import '../../screens/events/create_event_screen.dart';
import '../../screens/events/event_registration_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/qr/qr_scanner_screen.dart';
import '../../widgets/main_layout.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isInitialized = authProvider.isInitialized;

        // If auth is not initialized yet, stay on current route
        if (!isInitialized) {
          return null;
        }

        final isOnAuthPage =
            state.fullPath == '/login' || state.fullPath == '/signup';

        // If user is not authenticated and not on auth page, redirect to login
        if (!isAuthenticated && !isOnAuthPage) {
          return '/login';
        }

        // If user is authenticated and on auth page, redirect to home
        if (isAuthenticated && isOnAuthPage) {
          return '/home';
        }

        // Otherwise, no redirect needed
        return null;
      },
      routes: [
        // Authentication Routes
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          name: 'signup',
          builder: (context, state) => const SignUpScreen(),
        ),

        // Main App Routes with Bottom Navigation
        ShellRoute(
          builder: (context, state, child) => MainLayout(child: child),
          routes: [
            GoRoute(
              path: '/home',
              name: 'home',
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/profile',
              name: 'profile',
              builder: (context, state) => const ProfileScreen(),
            ),
            GoRoute(
              path: '/admin',
              name: 'admin',
              builder: (context, state) => const AdminDashboardScreen(),
            ),
          ],
        ),

        // Event Routes
        GoRoute(
          path: '/event/:eventId',
          name: 'eventDetail',
          builder: (context, state) {
            final eventId = state.pathParameters['eventId']!;
            return EventDetailScreen(eventId: eventId);
          },
        ),
        GoRoute(
          path: '/event/:eventId/register',
          name: 'eventRegistration',
          builder: (context, state) {
            final eventId = state.pathParameters['eventId']!;
            return EventRegistrationScreen(eventId: eventId);
          },
        ),
        GoRoute(
          path: '/create-event',
          name: 'createEvent',
          builder: (context, state) => const CreateEventScreen(),
        ),

        // QR Scanner Route
        GoRoute(
          path: '/qr-scanner',
          name: 'qrScanner',
          builder: (context, state) => const QRScannerScreen(),
        ),
      ],
    );
  }
}
