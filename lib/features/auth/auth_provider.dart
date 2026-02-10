import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final String? userName;
  final String? userDesignation;
  final String? userEmail;
  final String? userPhone;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.userName,
    this.userDesignation,
    this.userEmail,
    this.userPhone,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    String? userName,
    String? userDesignation,
    String? userEmail,
    String? userPhone,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      userName: userName ?? this.userName,
      userDesignation: userDesignation ?? this.userDesignation,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    // Simulate network request
    await Future.delayed(const Duration(seconds: 2));

    if (email.isNotEmpty && password.isNotEmpty) {
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        userName: "John Doe",
        userDesignation: "Field Surveyor",
        userEmail: email,
        userPhone: "+1 (555) 123-4567",
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: "Please enter valid credentials",
      );
    }
  }

  void logout() {
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
