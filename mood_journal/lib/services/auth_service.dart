import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firebase Authentication servis katmanı.
///
/// Tüm kullanıcı yetkilendirme işlemlerini (giriş, kayıt, çıkış)
/// Firebase Auth üzerinden yönetir. Singleton pattern ile çalışır.
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Mevcut oturum açmış kullanıcı (null ise oturum yok).
  User? get currentUser => _auth.currentUser;

  /// Auth durumu değişikliklerini dinleyen stream.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Kullanıcının oturum açıp açmadığını kontrol eder.
  bool get isSignedIn => _auth.currentUser != null;

  // ═══════════════════════════════════════════════════════════════
  // E-POSTA İLE GİRİŞ
  // ═══════════════════════════════════════════════════════════════

  /// E-posta ve şifre ile giriş yapar.
  ///
  /// Başarılı olursa [User] döner, hata oluşursa Türkçe hata mesajı fırlatır.
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      notifyListeners();
      debugPrint('✅ Giriş başarılı: ${credential.user?.email}');
      return credential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Giriş hatası: ${e.code}');
      throw _mapFirebaseAuthError(e.code);
    } catch (e) {
      debugPrint('❌ Beklenmeyen giriş hatası: $e');
      throw 'Giriş sırasında beklenmeyen bir hata oluştu.';
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // E-POSTA İLE KAYIT
  // ═══════════════════════════════════════════════════════════════

  /// Yeni kullanıcı kaydı oluşturur.
  ///
  /// Başarılı olursa [User] döner, hata oluşursa Türkçe hata mesajı fırlatır.
  Future<User?> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      notifyListeners();
      debugPrint('✅ Kayıt başarılı: ${credential.user?.email}');
      return credential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Kayıt hatası: ${e.code}');
      throw _mapFirebaseAuthError(e.code);
    } catch (e) {
      debugPrint('❌ Beklenmeyen kayıt hatası: $e');
      throw 'Kayıt sırasında beklenmeyen bir hata oluştu.';
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ÇIKIŞ
  // ═══════════════════════════════════════════════════════════════

  /// Kullanıcının oturumunu kapatır.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      notifyListeners();
      debugPrint('✅ Çıkış başarılı');
    } catch (e) {
      debugPrint('❌ Çıkış hatası: $e');
      throw 'Çıkış yapılırken bir hata oluştu.';
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ŞİFRE SIFIRLAMA
  // ═══════════════════════════════════════════════════════════════

  /// Şifre sıfırlama e-postası gönderir.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      debugPrint('✅ Şifre sıfırlama e-postası gönderildi: $email');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Şifre sıfırlama hatası: ${e.code}');
      throw _mapFirebaseAuthError(e.code);
    } catch (e) {
      debugPrint('❌ Beklenmeyen şifre sıfırlama hatası: $e');
      throw 'Şifre sıfırlama sırasında bir hata oluştu.';
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // HATA HARİTALAMA
  // ═══════════════════════════════════════════════════════════════

  /// Firebase Auth hata kodlarını Türkçe kullanıcı mesajlarına çevirir.
  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Bu e-posta adresine ait bir hesap bulunamadı.';
      case 'wrong-password':
        return 'Girilen şifre yanlış.';
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda.';
      case 'weak-password':
        return 'Şifre en az 6 karakter olmalıdır.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış.';
      case 'too-many-requests':
        return 'Çok fazla deneme yaptınız. Lütfen bir süre bekleyin.';
      case 'operation-not-allowed':
        return 'E-posta/şifre girişi henüz etkinleştirilmemiş.';
      case 'network-request-failed':
        return 'İnternet bağlantısı bulunamadı.';
      default:
        return 'Bir hata oluştu. Lütfen tekrar deneyin. ($code)';
    }
  }
}
