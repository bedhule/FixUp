import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supbase;
import '../models/models.dart';

class FirebaseHelper {
  FirebaseHelper._();
  static final FirebaseHelper _instance = FirebaseHelper._();
  factory FirebaseHelper() => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  supbase.SupabaseClient? _supabaseClient;

  supbase.SupabaseClient _getSupabaseClient() {
    if (_supabaseClient != null) return _supabaseClient!;
    try {
      _supabaseClient = supbase.Supabase.instance.client;
      return _supabaseClient!;
    } catch (e) {
      throw Exception(
        'Supabase belum diinisialisasi. Pastikan Supabase.initialize() '
        'dipanggil dengan benar di main.dart sebelum mengirim laporan. '
        'Periksa juga konfigurasi URL dan Anon Key di SupabaseConfig.\n'
        'Detail error: $e',
      );
    }
  }

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Email/Password ───

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String nim,
    required UserRole role,
    String? nip,
    String? divisi,
  }) async {
    debugPrint('[FirebaseHelper] registerWithEmail: email=$email, name=$name, role=${role.name}');

    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    debugPrint('[FirebaseHelper] Auth success: uid=${cred.user?.uid}');

    if (cred.user == null) {
      throw Exception('Registrasi berhasil tetapi user object null');
    }

    await cred.user!.updateDisplayName(name);
    debugPrint('[FirebaseHelper] DisplayName updated');

    await createUserDocument(
      uid: cred.user!.uid,
      name: name,
      email: email,
      role: role,
      nim: nim,
      nip: nip,
      divisi: divisi,
    );

    return cred;
  }

  Future<UserCredential> loginWithEmail(String email, String password) async {
    debugPrint('[FirebaseHelper] loginWithEmail: email=$email');
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ─── Social Login ───

  Future<UserCredential> signInWithGoogle() async {
    debugPrint('[FirebaseHelper] signInWithGoogle');
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Login Google dibatalkan');
    }
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCred = await _auth.signInWithCredential(credential);
    debugPrint('[FirebaseHelper] Google login success: uid=${userCred.user?.uid}');
    return userCred;
  }

  Future<UserCredential> signInWithFacebook() async {
    debugPrint('[FirebaseHelper] signInWithFacebook');
    final result = await FacebookAuth.instance.login();
    if (result.status != LoginStatus.success || result.accessToken == null) {
      throw Exception('Login Facebook dibatalkan atau gagal');
    }
    final credential = FacebookAuthProvider.credential(result.accessToken!.tokenString);
    final userCred = await _auth.signInWithCredential(credential);
    debugPrint('[FirebaseHelper] Facebook login success: uid=${userCred.user?.uid}');
    return userCred;
  }

  Future<UserCredential> signInWithApple() async {
    debugPrint('[FirebaseHelper] signInWithApple');
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: credential.identityToken,
      accessToken: credential.authorizationCode,
    );
    final userCred = await _auth.signInWithCredential(oauthCredential);
    debugPrint('[FirebaseHelper] Apple login success: uid=${userCred.user?.uid}');
    return userCred;
  }

  // ─── Phone / OTP ───

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(FirebaseAuthException error) onError,
  }) async {
    debugPrint('[FirebaseHelper] verifyPhoneNumber: $phoneNumber');
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        debugPrint('[FirebaseHelper] Auto verification completed');
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        debugPrint('[FirebaseHelper] verificationFailed: ${e.code} - ${e.message}');
        onError(e);
      },
      codeSent: (String verificationId, int? resendToken) {
        debugPrint('[FirebaseHelper] codeSent: verificationId=$verificationId');
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        debugPrint('[FirebaseHelper] codeAutoRetrievalTimeout');
      },
    );
  }

  Future<UserCredential> signInWithPhoneVerification({
    required String verificationId,
    required String smsCode,
  }) async {
    debugPrint('[FirebaseHelper] signInWithPhoneVerification');
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final userCred = await _auth.signInWithCredential(credential);
    debugPrint('[FirebaseHelper] Phone login success: uid=${userCred.user?.uid}');
    return userCred;
  }

  // ─── Password Reset ───

  Future<void> sendPasswordResetEmail(String email) async {
    debugPrint('[FirebaseHelper] sendPasswordResetEmail: $email');
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ─── User Document ───

  Future<bool> isUserDocumentExists(String uid) async {
    debugPrint('[FirebaseHelper] isUserDocumentExists: uid=$uid');
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists;
  }

  Future<void> createUserDocument({
    required String uid,
    required String name,
    required String email,
    required UserRole role,
    String? nim,
    String? nip,
    String? divisi,
    String photoUrl = '',
  }) async {
    debugPrint('[FirebaseHelper] createUserDocument: uid=$uid, role=${role.name}');

    final Map<String, dynamic> data = {
      'name': name,
      'email': email,
      'role': role.name,
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Hanya simpan photoUrl jika tidak kosong — agar tidak memicu NetworkImage("")
    if (photoUrl.isNotEmpty) {
      data['photoUrl'] = photoUrl;
    }

    if (role == UserRole.sarpras) {
      data['nip'] = nip ?? '';
      data['divisi'] = divisi ?? '';
    } else {
      data['nim'] = nim ?? '';
    }

    await _firestore.collection('users').doc(uid).set(data);
    debugPrint('[FirebaseHelper] User document created');
  }

  // ─── Existing methods (unchanged) ───

  Future<void> logout() async {
    debugPrint('[FirebaseHelper] logout');
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    debugPrint('[FirebaseHelper] getUserData: uid=$uid');
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<UserRole> getUserRole(String uid) async {
    debugPrint('[FirebaseHelper] getUserRole: uid=$uid');
    final data = await getUserData(uid);
    if (data == null) {
      debugPrint('[FirebaseHelper] getUserRole: data null, default ke pelapor');
      return UserRole.pelapor;
    }
    return UserRole.values.firstWhere(
      (e) => e.name == data['role'],
      orElse: () {
        debugPrint('[FirebaseHelper] getUserRole: role tidak dikenal, default ke pelapor');
        return UserRole.pelapor;
      },
    );
  }

  Future<String> uploadReportImage(String reportId, String localPath) async {
    debugPrint('[FirebaseHelper] uploadReportImage: reportId=$reportId');
    final file = File(localPath);
    if (!file.existsSync()) {
      throw Exception('File tidak ditemukan: $localPath');
    }
    const bucketName = 'report-images';
    final filePath = 'report_images/$reportId.jpg';
    try {
      final supabase = _getSupabaseClient();
      await supabase.storage.from(bucketName).upload(filePath, file);
      final url = supabase.storage.from(bucketName).getPublicUrl(filePath);
      debugPrint('[FirebaseHelper] uploadReportImage done: $url');
      return url;
    } on supbase.StorageException catch (e) {
      debugPrint('[FirebaseHelper] Supabase upload gagal: ${e.message}');
      if (e.message.contains('bucket')) {
        throw Exception('Bucket "$bucketName" tidak ditemukan. Periksa konfigurasi Supabase.');
      }
      throw Exception('Upload gambar gagal: ${e.message}');
    } catch (e) {
      debugPrint('[FirebaseHelper] Supabase upload error: $e');
      rethrow;
    }
  }

  Future<String> uploadProfileImage(String uid, String localPath) async {
    debugPrint('[FirebaseHelper] uploadProfileImage: uid=$uid');
    final file = File(localPath);
    if (!file.existsSync()) {
      throw Exception('File tidak ditemukan: $localPath');
    }
    const bucketName = 'report-images';
    final filePath = 'profile_images/$uid.jpg';
    try {
      final supabase = _getSupabaseClient();
      await supabase.storage.from(bucketName).upload(filePath, file);
      final url = supabase.storage.from(bucketName).getPublicUrl(filePath);
      debugPrint('[FirebaseHelper] uploadProfileImage done: $url');
      return url;
    } on supbase.StorageException catch (e) {
      debugPrint('[FirebaseHelper] Supabase upload gagal: ${e.message}');
      if (e.message.contains('bucket')) {
        throw Exception('Bucket "$bucketName" tidak ditemukan. Periksa konfigurasi Supabase.');
      }
      throw Exception('Upload gambar gagal: ${e.message}');
    } catch (e) {
      debugPrint('[FirebaseHelper] Supabase upload error: $e');
      rethrow;
    }
  }

  Future<void> saveReport(Report report) async {
    debugPrint('[FirebaseHelper] saveReport: id=${report.id}');
    await _firestore.collection('reports').doc(report.id).set(report.toFirestoreMap());
  }

  Future<void> updateReport(Report report) async {
    debugPrint('[FirebaseHelper] updateReport: id=${report.id}');
    await _firestore.collection('reports').doc(report.id).update(report.toFirestoreMap());
  }

  Future<void> deleteReport(String id) async {
    debugPrint('[FirebaseHelper] deleteReport: id=$id');
    await _firestore.collection('reports').doc(id).delete();
  }

  Future<List<Report>> getReports() async {
    debugPrint('[FirebaseHelper] getReports');
    final snapshot = await _firestore
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => Report.fromFirestoreMap(doc.data(), doc.id)).toList();
  }

  Stream<List<Report>> getReportsStream() {
    debugPrint('[FirebaseHelper] getReportsStream: subscribing');
    return _firestore
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          debugPrint('[FirebaseHelper] getReportsStream: ${snapshot.docs.length} docs');
          return snapshot.docs
              .map((doc) => Report.fromFirestoreMap(doc.data(), doc.id))
              .toList();
        });
  }

  Future<void> saveRating(String reportId, int rating, String feedback) async {
    debugPrint('[FirebaseHelper] saveRating: reportId=$reportId, rating=$rating');
    await _firestore.collection('reports').doc(reportId).update({
      'rating': rating.toDouble(),
      'feedback': feedback,
    });
  }

  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? nim,
    String? nip,
    String? divisi,
    String? photoUrl,
    String? role,
  }) async {
    debugPrint('[FirebaseHelper] updateUserProfile: uid=$uid');
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (nim != null) data['nim'] = nim;
    if (nip != null) data['nip'] = nip;
    if (divisi != null) data['divisi'] = divisi;
    if (photoUrl != null) data['photoUrl'] = photoUrl;
    if (role != null) data['role'] = role;
    if (data.isNotEmpty) {
      await _firestore.collection('users').doc(uid).update(data);
      if (name != null) await _auth.currentUser?.updateDisplayName(name);
      if (photoUrl != null) await _auth.currentUser?.updatePhotoURL(photoUrl);
      debugPrint('[FirebaseHelper] updateUserProfile done');
    }
  }

  Stream<List<AppNotification>> getNotificationsStream(String uid) {
    debugPrint('[FirebaseHelper] getNotificationsStream: uid=$uid');
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .orderBy('time', descending: true)
        .snapshots()
        .map((snapshot) {
          debugPrint('[FirebaseHelper] getNotificationsStream: ${snapshot.docs.length} docs');
          return snapshot.docs
              .map((doc) => AppNotification.fromFirestoreMap(doc.data(), doc.id))
              .toList();
        });
  }

  Future<void> addNotification(AppNotification notif) async {
    debugPrint('[FirebaseHelper] addNotification: title=${notif.title}');
    await _firestore.collection('notifications').add(notif.toFirestoreMap());
  }

  Future<void> markNotificationRead(String notifId) async {
    debugPrint('[FirebaseHelper] markNotificationRead: id=$notifId');
    await _firestore.collection('notifications').doc(notifId).update({
      'isRead': true,
    });
  }

  Future<void> markAllNotificationsRead(String uid) async {
    debugPrint('[FirebaseHelper] markAllNotificationsRead: uid=$uid');
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in snapshot.docs) {
      await doc.reference.update({'isRead': true});
    }
    debugPrint('[FirebaseHelper] markAllNotificationsRead: ${snapshot.docs.length} updated');
  }
}