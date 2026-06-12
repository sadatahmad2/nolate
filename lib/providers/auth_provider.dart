import 'package:flutter/material.dart';
import '../models/models.dart';

class AuthProvider extends ChangeNotifier {
  // Registered Users (starts with a default test user)
  final List<AppUser> _users = [
    AppUser(
      name: 'Rohit Sharma',
      mobile: '9876543210',
      email: 'test@example.com',
      password: 'password123',
      address: '123, Green Park, New Delhi - 110016',
      location: const Coordinate(0.5, 0.5),
    ),
  ];

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  // Registration wizard state
  int _currentStep = 0;
  int get currentStep => _currentStep;

  // Temporary registration fields
  String name = '';
  String mobile = '';
  String email = '';
  String confirmEmail = '';
  String password = '';
  String confirmPassword = '';
  String address = '';
  Coordinate selectedLocation = const Coordinate(0.5, 0.5);

  // Errors for fields
  String? nameError;
  String? mobileError;
  String? emailError;
  String? confirmEmailError;
  String? passwordError;
  String? confirmPasswordError;
  String? addressError;

  void resetRegistration() {
    _currentStep = 0;
    name = '';
    mobile = '';
    email = '';
    confirmEmail = '';
    password = '';
    confirmPassword = '';
    address = '';
    selectedLocation = const Coordinate(0.5, 0.5);
    clearErrors();
    notifyListeners();
  }

  void clearErrors() {
    nameError = null;
    mobileError = null;
    emailError = null;
    confirmEmailError = null;
    passwordError = null;
    confirmPasswordError = null;
    addressError = null;
  }

  void updateLocation(Coordinate location) {
    selectedLocation = location;
    notifyListeners();
  }

  void updateLocationAndAddress(Coordinate location, String newAddress) {
    selectedLocation = location;
    address = newAddress;
    notifyListeners();
  }

  bool validateStep(int step) {
    clearErrors();
    bool isValid = true;

    if (step == 0) {
      if (name.trim().isEmpty) {
        nameError = 'Name is required';
        isValid = false;
      } else if (name.trim().length < 3) {
        nameError = 'Name must be at least 3 characters';
        isValid = false;
      }

      final mobileRegex = RegExp(r'^\d{10}$');
      if (mobile.trim().isEmpty) {
        mobileError = 'Mobile number is required';
        isValid = false;
      } else if (!mobileRegex.hasMatch(mobile.trim())) {
        mobileError = 'Mobile must be exactly 10 digits';
        isValid = false;
      }
    } else if (step == 1) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (email.trim().isEmpty) {
        emailError = 'Email is required';
        isValid = false;
      } else if (!emailRegex.hasMatch(email.trim())) {
        emailError = 'Enter a valid email address';
        isValid = false;
      }

      if (confirmEmail.trim().isEmpty) {
        confirmEmailError = 'Please confirm your email';
        isValid = false;
      } else if (confirmEmail.trim() != email.trim()) {
        confirmEmailError = 'Emails do not match';
        isValid = false;
      }
    } else if (step == 2) {
      if (password.isEmpty) {
        passwordError = 'Password is required';
        isValid = false;
      } else if (password.length < 6) {
        passwordError = 'Password must be at least 6 characters';
        isValid = false;
      }

      if (confirmPassword.isEmpty) {
        confirmPasswordError = 'Please confirm your password';
        isValid = false;
      } else if (confirmPassword != password) {
        confirmPasswordError = 'Passwords do not match';
        isValid = false;
      }
    } else if (step == 3) {
      if (address.trim().isEmpty) {
        addressError = 'Address is required to deliver your food!';
        isValid = false;
      }
    }

    notifyListeners();
    return isValid;
  }

  void nextStep() {
    if (validateStep(_currentStep)) {
      if (_currentStep < 4) {
        _currentStep++;
        notifyListeners();
      }
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      clearErrors();
      notifyListeners();
    }
  }

  bool submitRegistration() {
    if (!validateStep(3)) return false;

    // Create new user
    final newUser = AppUser(
      name: name,
      mobile: mobile,
      email: email,
      password: password,
      address: address,
      location: selectedLocation,
    );

    // Save user
    _users.add(newUser);
    
    // Auto login
    _currentUser = newUser;
    resetRegistration();
    notifyListeners();
    return true;
  }

  bool login(String emailInput, String passwordInput) {
    for (var user in _users) {
      if (user.email.trim().toLowerCase() == emailInput.trim().toLowerCase() &&
          user.password == passwordInput) {
        _currentUser = user;
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  void updateCurrentUserLocation(Coordinate coord, String newAddress) {
    if (_currentUser != null) {
      _currentUser = AppUser(
        name: _currentUser!.name,
        mobile: _currentUser!.mobile,
        email: _currentUser!.email,
        password: _currentUser!.password,
        address: newAddress,
        location: coord,
      );
      notifyListeners();
    }
  }
}
