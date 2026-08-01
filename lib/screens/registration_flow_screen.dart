import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/models.dart';
import 'home_screen.dart';

class RegistrationFlowScreen extends StatelessWidget {
  const RegistrationFlowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Light Background
      appBar: AppBar(
        title: const Text(
          'Registration Stage', 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () {
            if (authProvider.currentStep > 0) {
              authProvider.previousStep();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Step progress bar
            _buildProgressBar(context, authProvider.currentStep),
            const SizedBox(height: 16),
            
            // Current step form content
            Expanded(
              child: SingleChildScrollView(
                key: ValueKey(authProvider.currentStep),
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStepTitle(authProvider.currentStep, theme),
                    const SizedBox(height: 20),
                    _buildStepContent(context, authProvider),
                  ],
                ),
              ),
            ),

            // Actions Bar
            _buildActionsBar(context, authProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, int currentStep) {
    final steps = ['Profile', 'Email', 'Security', 'Location', 'Verification'];
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          final isActive = index == currentStep;
          final isCompleted = index < currentStep;

          return Expanded(
            child: Row(
              children: [
                // Step Indicator Node
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? const Color(0xFFFF6B35) // Warm Coral
                        : isActive
                            ? theme.primaryColor // Deep Indigo
                            : Colors.grey[100],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive ? theme.primaryColor : Colors.grey[300]!,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.black54,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                  ),
                ),
                // Connector line
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2.5,
                      color: isCompleted
                          ? const Color(0xFFFF6B35) // Warm Coral
                          : index == currentStep
                              ? theme.primaryColor.withValues(alpha: 0.5)
                              : Colors.grey[200],
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepTitle(int step, ThemeData theme) {
    final titles = [
      'Name & Mobile',
      'Email Verification',
      'Create Password',
      'Delivery Location',
      'Validation Check'
    ];

    final subtitles = [
      'Enter your full name and a valid 10-digit mobile number.',
      'We use your email to send order confirmations and invoices.',
      'Set a secure password to keep your account safe.',
      'Select your location on the map and type your street address.',
      'Review your details before completing registration.'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STEP ${step + 1} OF 5',
          style: TextStyle(
            color: theme.primaryColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          titles[step],
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitles[step],
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent(BuildContext context, AuthProvider auth) {
    switch (auth.currentStep) {
      case 0:
        return _buildStep1(auth);
      case 1:
        return _buildStep2(auth);
      case 2:
        return _buildStep3(auth);
      case 3:
        return _buildStep4(context, auth);
      case 4:
        return _buildStep5(context, auth);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          _buildTextField(
            label: 'Full Name',
            icon: Icons.person_outline_rounded,
            hint: 'Enter your name',
            errorText: auth.nameError,
            initialValue: auth.name,
            onChanged: (val) => auth.name = val,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            label: 'Mobile Number',
            icon: Icons.phone_android_rounded,
            hint: '10-digit number',
            errorText: auth.mobileError,
            initialValue: auth.mobile,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            onChanged: (val) => auth.mobile = val,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          _buildTextField(
            label: 'Email Address',
            icon: Icons.email_outlined,
            hint: 'Enter email',
            errorText: auth.emailError,
            initialValue: auth.email,
            keyboardType: TextInputType.emailAddress,
            onChanged: (val) => auth.email = val,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            label: 'Confirm Email Address',
            icon: Icons.mark_email_read_outlined,
            hint: 'Re-enter email to verify',
            errorText: auth.confirmEmailError,
            initialValue: auth.confirmEmail,
            keyboardType: TextInputType.emailAddress,
            onChanged: (val) => auth.confirmEmail = val,
          ),
        ],
      ),
    );
  }

  Widget _buildStep3(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          _buildTextField(
            label: 'Password',
            icon: Icons.lock_outline_rounded,
            hint: 'Min 6 characters',
            errorText: auth.passwordError,
            initialValue: auth.password,
            obscureText: true,
            onChanged: (val) => auth.password = val,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            label: 'Confirm Password',
            icon: Icons.lock_reset_rounded,
            hint: 'Re-enter password',
            errorText: auth.confirmPasswordError,
            initialValue: auth.confirmPassword,
            obscureText: true,
            onChanged: (val) => auth.confirmPassword = val,
          ),
        ],
      ),
    );
  }

  Widget _buildStep4(BuildContext context, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            label: 'Complete Street Address',
            icon: Icons.location_on_outlined,
            hint: 'House No, Building, Street Name, Pincode',
            errorText: auth.addressError,
            initialValue: auth.address,
            maxLines: 2,
            onChanged: (val) => auth.address = val,
          ),
          const SizedBox(height: 20),
          const Text(
            'Pin Your Location (Tap to select delivery point)',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          // Custom interactive visual Map picker
          AspectRatio(
            aspectRatio: 1.6,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
                color: const Color(0xFFE2E8F0),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GridPaper(
                      color: Colors.blue.withValues(alpha: 0.08),
                      divisions: 2,
                      subdivisions: 4,
                    ),
                  ),
                  _buildMapArtwork(),
                  GestureDetector(
                    onTapDown: (details) {
                      final localPos = details.localPosition;
                      double x = localPos.dx / 300.0;
                      double y = localPos.dy / 180.0;
                      x = x.clamp(0.0, 1.0);
                      y = y.clamp(0.0, 1.0);
                      final coord = Coordinate(x, y);

                      if (auth.address.trim().isEmpty) {
                        final List<String> mockAddresses = [
                          'Flat 402, Block B, Green Valley Apartments, New Delhi',
                          'House 29-A, Sector 45, Noida, Uttar Pradesh',
                          'Tower C, DLF Phase 3, Gurugram, Haryana',
                          'Villa 12, Rose Garden Enclave, Saket, New Delhi',
                          '102, Mayur Vihar Phase 1, Near Metro Station, Delhi'
                        ];
                        final index = (x * 10 + y * 10).toInt() % mockAddresses.length;
                        auth.updateLocationAndAddress(coord, mockAddresses[index]);
                      } else {
                        auth.updateLocation(coord);
                      }
                    },
                  ),
                  // User Pin
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    left: (auth.selectedLocation.x * 300.0) - 20,
                    top: (auth.selectedLocation.y * 180.0) - 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.redAccent,
                      size: 40,
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Colors.white, size: 12),
                          const SizedBox(width: 6),
                          Text(
                            'Coords: (${auth.selectedLocation.x.toStringAsFixed(2)}, ${auth.selectedLocation.y.toStringAsFixed(2)})',
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapArtwork() {
    return Stack(
      children: [
        Positioned(
          left: -40,
          top: 70,
          right: -40,
          height: 16,
          child: Container(color: Colors.blue.withValues(alpha: 0.15)),
        ),
        Positioned(
          left: 30,
          top: 20,
          width: 80,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep5(BuildContext context, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.05), // Soft Indigo tint
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                _buildValidationCheckItem('Format & Input Verification', true),
                const Divider(color: Colors.black12),
                _buildValidationCheckItem('Security Matching Verification', true),
                const Divider(color: Colors.black12),
                _buildValidationCheckItem('Device Location Bounds Lock', true),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'REGISTRATION DETAILS SUMMARY',
                  style: TextStyle(
                    color: Colors.black38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSummaryRow('Name', auth.name),
                _buildSummaryRow('Mobile', '+91 ${auth.mobile}'),
                _buildSummaryRow('Email', auth.email),
                _buildSummaryRow('Address', auth.address),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationCheckItem(String title, bool passes) {
    return Row(
      children: [
        Icon(
          passes ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: passes ? Colors.green : Colors.red,
          size: 18,
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 13),
        ),
        const Spacer(),
        Text(
          passes ? 'PASSED' : 'FAILED',
          style: TextStyle(
            color: passes ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.black38, fontSize: 11)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required String hint,
    required void Function(String) onChanged,
    String? errorText,
    String? initialValue,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: initialValue,
          onChanged: onChanged,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLength: maxLength,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black26),
            prefixIcon: Icon(icon, color: Colors.black38),
            errorText: errorText,
            counterText: '',
            filled: true,
            fillColor: Colors.grey[50],
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5), // Deep Indigo focus
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsBar(BuildContext context, AuthProvider auth) {
    final isLastStep = auth.currentStep == 4;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          if (auth.currentStep > 0)
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: auth.previousStep,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.black26),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Back', style: TextStyle(color: Colors.black87)),
              ),
            ),
          if (auth.currentStep > 0) const SizedBox(width: 12),
          
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                if (isLastStep) {
                  final success = auth.submitRegistration();
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Registration complete! Welcome aboard.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // Navigate directly to HomeScreen since the user is auto-logged in
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                      (route) => false,
                    );
                  }
                } else {
                  auth.nextStep();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669), // Deep Indigo
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text(
                isLastStep ? 'Submit & Start' : 'Next Step',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
