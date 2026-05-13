import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;
  String? _error;
  late AnimationController _animCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animCtrl, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
      CurvedAnimation(parent: _animCtrl, curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic)),
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await _auth.registerWithEmailAndPassword(
        email: _emailCtrl.text,
        password: _passCtrl.text,
      );
      // Başarılı kayıt — auth stream otomatik yönlendirecek, login'e geri dön
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: isDark
                ? [AppTheme.darkBg, const Color(0xFF151735), const Color(0xFF1A1D3A)]
                : [const Color(0xFFEEF0FF), const Color(0xFFF5F7FF), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Column(
                    children: [
                      _logo(),
                      const SizedBox(height: 12),
                      _title(),
                      const SizedBox(height: 6),
                      Text('Yeni bir yolculuğa başla',
                        style: GoogleFonts.inter(fontSize: 14,
                          color: isDark ? const Color(0xFF8A8AAA) : const Color(0xFF6A6A8A))),
                      const SizedBox(height: 36),
                      _formCard(isDark),
                      const SizedBox(height: 24),
                      _loginLink(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _logo() => Container(
    width: 90, height: 90,
    decoration: BoxDecoration(
      gradient: AppTheme.pinkGradient,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [BoxShadow(color: AppTheme.accentPink.withValues(alpha: 0.35), blurRadius: 30, offset: const Offset(0, 10))],
    ),
    child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 42),
  );

  Widget _title() => Text('Kayıt Ol',
    style: GoogleFonts.poppins(fontSize: 30, fontWeight: FontWeight.w800,
      foreground: Paint()..shader = const LinearGradient(
        colors: [AppTheme.accentPink, AppTheme.primaryColor],
      ).createShader(const Rect.fromLTWH(0, 0, 200, 40))));

  Widget _formCard(bool isDark) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: isDark ? AppTheme.darkCard : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.1)),
      boxShadow: [BoxShadow(
        color: isDark ? Colors.black.withValues(alpha: 0.3) : AppTheme.primaryColor.withValues(alpha: 0.08),
        blurRadius: 30, offset: const Offset(0, 10))],
    ),
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Hesap Oluştur', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFE0E0F0) : const Color(0xFF1A1A2E))),
          const SizedBox(height: 20),
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: GoogleFonts.inter(fontSize: 13, color: Colors.red[300]))),
              ]),
            ),
            const SizedBox(height: 16),
          ],
          _field(_emailCtrl, 'E-posta', Icons.email_outlined, isDark,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'E-posta gerekli';
              if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(v.trim())) return 'Geçerli e-posta girin';
              return null;
            }),
          const SizedBox(height: 14),
          _field(_passCtrl, 'Şifre', Icons.lock_outline, isDark,
            obscure: _obscure1,
            suffix: IconButton(
              icon: Icon(_obscure1 ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: isDark ? const Color(0xFF7A7A9A) : const Color(0xFFB0B0C0), size: 20),
              onPressed: () => setState(() => _obscure1 = !_obscure1)),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Şifre gerekli';
              if (v.length < 6) return 'En az 6 karakter';
              return null;
            }),
          const SizedBox(height: 14),
          _field(_confirmCtrl, 'Şifre Tekrar', Icons.lock_outline, isDark,
            obscure: _obscure2,
            suffix: IconButton(
              icon: Icon(_obscure2 ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: isDark ? const Color(0xFF7A7A9A) : const Color(0xFFB0B0C0), size: 20),
              onPressed: () => setState(() => _obscure2 = !_obscure2)),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Şifre tekrarı gerekli';
              if (v != _passCtrl.text) return 'Şifreler eşleşmiyor';
              return null;
            }),
          const SizedBox(height: 24),
          _registerBtn(),
        ],
      ),
    ),
  );

  Widget _field(TextEditingController ctrl, String label, IconData icon, bool isDark,
      {TextInputType? keyboardType, bool obscure = false, Widget? suffix, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl, keyboardType: keyboardType, obscureText: obscure,
      style: GoogleFonts.inter(fontSize: 15, color: isDark ? const Color(0xFFE0E0F0) : const Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 14, color: isDark ? const Color(0xFF7A7A9A) : const Color(0xFFB0B0C0)),
        prefixIcon: Icon(icon, color: AppTheme.primaryColor.withValues(alpha: 0.7), size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: isDark ? const Color(0xFF1B1D36) : const Color(0xFFF0F2FF),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.red, width: 1)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.red, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }

  Widget _registerBtn() => Container(
    height: 54,
    decoration: BoxDecoration(
      gradient: AppTheme.pinkGradient,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: AppTheme.accentPink.withValues(alpha: 0.35), blurRadius: 15, offset: const Offset(0, 6))],
    ),
    child: ElevatedButton(
      onPressed: _loading ? null : _register,
      style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      child: _loading
          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.person_add_rounded, size: 20, color: Colors.white),
              const SizedBox(width: 8),
              Text('Kayıt Ol', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ]),
    ),
  );

  Widget _loginLink() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text('Zaten hesabın var mı? ', style: GoogleFonts.inter(fontSize: 14,
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF8A8AAA) : const Color(0xFF6A6A8A))),
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Text('Giriş Yap', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
      ),
    ],
  );
}
