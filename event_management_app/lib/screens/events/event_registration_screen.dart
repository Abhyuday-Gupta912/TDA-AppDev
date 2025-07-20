import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/event_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/event_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';

class EventRegistrationScreen extends StatefulWidget {
  final String eventId;

  const EventRegistrationScreen({super.key, required this.eventId});

  @override
  State<EventRegistrationScreen> createState() =>
      _EventRegistrationScreenState();
}

class _EventRegistrationScreenState extends State<EventRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  Event? _event;
  bool _isLoading = true;
  bool _isRegistering = false;
  bool _agreedToTerms = false;
  late Razorpay _razorpay;
  String? _registrationId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _loadEventDetails();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
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
        appBar: AppBar(title: const Text('Event Not Found')),
        body: const Center(
          child: Text('Event not found'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.grey50,
      appBar: AppBar(
        title: const Text('Event Registration'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Event Summary
            _buildEventSummary(),

            // Registration Form
            _buildRegistrationForm(),

            // Terms and Conditions
            _buildTermsSection(),

            const SizedBox(height: 100), // Space for bottom button
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  Widget _buildEventSummary() {
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
            'Event Summary',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.grey900,
                ),
          ),

          const SizedBox(height: 16),

          // Event Title
          Text(
            _event!.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.grey900,
                ),
          ),

          const SizedBox(height: 12),

          // Event Details
          _buildSummaryRow(
            Icons.access_time,
            'Date & Time',
            AppDateUtils.formatDateRange(_event!.startDate, _event!.endDate),
          ),

          const SizedBox(height: 8),

          _buildSummaryRow(
            Icons.location_on,
            'Location',
            _event!.location,
          ),

          const SizedBox(height: 8),

          _buildSummaryRow(
            Icons.person,
            'Organizer',
            _event!.organizerName,
          ),

          const SizedBox(height: 16),

          // Price Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _event!.isFree
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : AppTheme.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _event!.isFree ? Icons.card_giftcard : Icons.payments,
                  color: _event!.isFree
                      ? AppTheme.primaryColor
                      : AppTheme.successColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Registration Fee',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.grey600,
                            ),
                      ),
                      Text(
                        _event!.isFree
                            ? 'FREE'
                            : '₹${_event!.price.toStringAsFixed(0)}',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: _event!.isFree
                                      ? AppTheme.primaryColor
                                      : AppTheme.successColor,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.grey500),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.grey600,
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.grey900,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationForm() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey100),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Registration Confirmation',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.grey900,
                  ),
            ),

            const SizedBox(height: 20),

            // Show user's details for confirmation
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                final user = authProvider.user;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.grey50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.grey200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Registration Details',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.grey800,
                                ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                          Icons.person, 'Name', user?.fullName ?? ''),
                      const SizedBox(height: 8),
                      _buildDetailRow(Icons.email, 'Email', user?.email ?? ''),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                          Icons.phone, 'Phone', user?.phone ?? 'Not provided'),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsSection() {
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
            'Terms & Conditions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.grey900,
                ),
          ),

          const SizedBox(height: 16),

          // Terms List
          _buildTermItem('• Registration is subject to availability'),
          _buildTermItem(
              '• Cancellation policy applies as per event guidelines'),
          _buildTermItem('• Attendees must follow event code of conduct'),
          _buildTermItem(
              '• Organizers reserve the right to modify event details'),
          if (!_event!.isFree)
            _buildTermItem(
                '• Refunds will be processed according to cancellation policy'),

          const SizedBox(height: 16),

          // Agreement Checkbox
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _agreedToTerms,
                onChanged: (value) {
                  setState(() {
                    _agreedToTerms = value ?? false;
                  });
                },
                activeColor: AppTheme.primaryColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'I agree to the terms and conditions and understand the event policies',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.grey700,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTermItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.grey600,
            ),
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
        child: CustomButton(
          text: _getButtonText(),
          isLoading: _isRegistering,
          onPressed: _canRegister() ? _handleRegistration : null,
          backgroundColor: AppTheme.primaryColor,
          textColor: AppTheme.white,
          icon: _event!.isFree ? Icons.how_to_reg : Icons.payment,
        ),
      ),
    );
  }

  String _getButtonText() {
    if (_event!.isFree) {
      return 'REGISTER FOR FREE';
    } else {
      return 'PAY ₹${_event!.price.toStringAsFixed(0)} & REGISTER';
    }
  }

  bool _canRegister() {
    return _agreedToTerms && !_event!.isFull && !_event!.isPast;
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.grey600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: AppTheme.grey600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: AppTheme.grey800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleRegistration() async {
    setState(() {
      _isRegistering = true;
    });

    try {
      if (_event!.isFree) {
        await _registerForFreeEvent();
      } else {
        await _initiatePayment();
      }
    } catch (e) {
      _showError('Registration failed: ${e.toString()}');
    } finally {
      setState(() {
        _isRegistering = false;
      });
    }
  }

  Future<void> _registerForFreeEvent() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final success = await userProvider.registerForEvent(_event!.id);

    if (success) {
      _showRegistrationSuccess();
    } else {
      _showError(userProvider.error ?? 'Registration failed');
    }
  }

  Future<void> _initiatePayment() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;

    var options = {
      'key': 'rzp_test_your_key_here', // Replace with your Razorpay key
      'amount': (_event!.price * 100).toInt(), // Amount in paise
      'name': 'Event Registration',
      'description': _event!.title,
      'prefill': {
        'contact': user?.phone ?? '',
        'email': user?.email ?? '',
      },
      'theme': {
        'color': '#6366F1',
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      _showError('Payment initialization failed');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Complete registration after successful payment
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final success = await userProvider.registerForEvent(
      _event!.id,
      amount: _event!.price,
    );

    if (success) {
      _showRegistrationSuccess();
    } else {
      _showError('Registration failed after payment');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _showError('Payment failed: ${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _showError('External wallet not supported');
  }

  void _showRegistrationSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildSuccessDialog(),
    );
  }

  Widget _buildSuccessDialog() {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Success Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 48,
              color: AppTheme.successColor,
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Registration Successful! 🎉',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.grey900,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            'You\'re all set for ${_event!.title}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.grey600,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.grey50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                QrImageView(
                  data:
                      '${_event!.id}:${Provider.of<AuthProvider>(context, listen: false).user?.id}:${_registrationId ?? 'temp'}',
                  version: QrVersions.auto,
                  size: 120,
                ),
                const SizedBox(height: 8),
                Text(
                  'Show this QR code to event staff for check-in',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.grey600,
                        fontWeight: FontWeight.w500,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go('/home');
                  },
                  child: const Text('Done'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go('/event/${_event!.id}');
                  },
                  child: const Text('View Event'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }
}
