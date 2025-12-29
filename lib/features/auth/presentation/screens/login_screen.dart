import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/bloc/language_cubit.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/auth_exception.dart';
import '../bloc/auth_cubit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final Color _primaryColor = const Color(0xFF003366);

  // Hàm tiện ích để dịch mã lỗi AuthErrorCode
  String _mapErrorCodeToMessage(AuthErrorCode code, AppLocalizations l10n) {
    switch (code) {
      case AuthErrorCode.loginFailed:
        return l10n.errorLoginFailed;
      case AuthErrorCode.networkError:
        return l10n.errorNetwork;
      case AuthErrorCode.tokenMissing:
      case AuthErrorCode.userFetchFailed:
        return l10n.errorRequired;
      case AuthErrorCode.systemError:
        return l10n.erpSystemName; // Fallback hoặc key lỗi hệ thống
    }
  }

  // Hàm xử lý login chung để gọi từ Button hoặc Enter
  void _performLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().login(
            _usernameController.text,
            _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/dashboard');
        } else if (state is AuthError) {
          final errorMessage = _mapErrorCodeToMessage(state.code, l10n);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        body: ResponsiveLayout(
          mobile: _buildMobileLayout(context, l10n),
          desktop: _buildDesktopLayout(context, l10n),
        ),
      ),
    );
  }

  // --- GIAO DIỆN MOBILE ---
  Widget _buildMobileLayout(BuildContext context, AppLocalizations l10n) {
    return Container(
      color: Colors.white,
      height: double.infinity,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: _buildLanguageSelector(context),
              ),
              const SizedBox(height: 40),
              Icon(Icons.verified_user, size: 60, color: _primaryColor),
              const SizedBox(height: 20),
              Text(
                "Production App",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor),
              ),
              const SizedBox(height: 40),
              _buildLoginForm(context, l10n),
            ],
          ),
        ),
      ),
    );
  }

  // --- GIAO DIỆN DESKTOP ---
  Widget _buildDesktopLayout(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: Container(
            decoration: BoxDecoration(
              color: _primaryColor,
              image: DecorationImage(
                image: const NetworkImage(
                    'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?q=80&w=2070&auto=format&fit=crop'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                    _primaryColor.withOpacity(0.85), BlendMode.srcOver),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(60),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.apartment, size: 80, color: Colors.white70),
                  const SizedBox(height: 20),
                  Text(
                    l10n.companyName.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.erpSystemName,
                    style: const TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Container(
            color: Colors.white,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: _buildLanguageSelector(context),
                    ),
                    const SizedBox(height: 40),
                    Icon(Icons.verified_user, size: 64, color: _primaryColor),
                    const SizedBox(height: 16),
                    Text(
                      l10n.loginSystemHeader,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.loginSubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: _buildLoginForm(context, l10n),
                    ),
                    const SizedBox(height: 40),
                    Text(l10n.copyright,
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- WIDGET CHỌN NGÔN NGỮ ---
  Widget _buildLanguageSelector(BuildContext context) {
    final currentLocale = context.watch<LanguageCubit>().state;

    return PopupMenuButton<String>(
      tooltip: 'Select Language',
      onSelected: (String code) {
        context.read<LanguageCubit>().changeLanguage(code);
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'en',
          child: Row(children: [
            Text("🇺🇸", style: TextStyle(fontSize: 20)),
            SizedBox(width: 12),
            Text('English')
          ]),
        ),
        const PopupMenuItem<String>(
          value: 'vi',
          child: Row(children: [
            Text("🇻🇳", style: TextStyle(fontSize: 20)),
            SizedBox(width: 12),
            Text('Tiếng Việt')
          ]),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(currentLocale.languageCode == 'vi' ? "🇻🇳" : "🇺🇸",
                style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
                currentLocale.languageCode == 'vi' ? "Tiếng Việt" : "English",
                style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // --- FORM INPUT (ĐÃ CẬP NHẬT) ---
  Widget _buildLoginForm(BuildContext context, AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _usernameController,
            style: const TextStyle(fontSize: 16),
            // [MỚI] Nhấn Enter ở ô user thì nhảy xuống ô pass
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.username,
              labelStyle: TextStyle(color: Colors.grey.shade600),
              prefixIcon: Icon(Icons.person_outline, color: _primaryColor),
              border: const UnderlineInputBorder(),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade400)),
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: _primaryColor, width: 2)),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
            validator: (v) => v!.isEmpty ? l10n.errorRequired : null,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            style: const TextStyle(fontSize: 16),
            // [MỚI] Nhấn Enter ở ô pass thì thực hiện login
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _performLogin(), 
            decoration: InputDecoration(
              labelText: l10n.password,
              labelStyle: TextStyle(color: Colors.grey.shade600),
              prefixIcon: Icon(Icons.lock_outline, color: _primaryColor),
              border: const UnderlineInputBorder(),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade400)),
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: _primaryColor, width: 2)),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
            validator: (v) => v!.isEmpty ? l10n.errorRequired : null,
          ),
          const SizedBox(height: 40),
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              if (state is AuthLoading) {
                return Center(
                    child: CircularProgressIndicator(color: _primaryColor));
              }
              return SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _performLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(
                    l10n.btnLogin.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}