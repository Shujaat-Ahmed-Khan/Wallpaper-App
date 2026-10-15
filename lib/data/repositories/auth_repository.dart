import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/api_constants.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth? _customAuth;
  final FirebaseFirestore? _customFirestore;

  UserModel? _mockUser;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _customAuth = auth,
        _customFirestore = firestore;

  FirebaseAuth? get _auth {
    if (_customAuth != null) return _customAuth;
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseAuth.instance;
      }
    } catch (_) {}
    return null;
  }

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (_) {}
    return null;
  }

  Stream<User?> get authStateChanges => _auth?.authStateChanges() ?? const Stream.empty();

  User? get currentFirebaseUser => _auth?.currentUser;

  Future<UserModel> getCurrentUserModel() async {
    final auth = _auth;
    final firestore = _firestore;

    if (auth != null && firestore != null) {
      final user = auth.currentUser;
      if (user != null) {
        try {
          final doc = await firestore.collection(ApiConstants.colUsers).doc(user.uid).get();
          if (doc.exists) {
            return UserModel.fromFirestore(doc);
          } else {
            // Create initial user document
            final newUser = UserModel(
              uid: user.uid,
              email: user.email ?? 'explorer@neonglass.io',
              displayName: user.displayName ?? 'Cyber Pilot',
              avatarUrl: user.photoURL ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
              role: 'USER',
              createdAt: DateTime.now(),
            );
            await firestore.collection(ApiConstants.colUsers).doc(user.uid).set(newUser.toMap());
            return newUser;
          }
        } catch (_) {}
      }
    }

    // Default Guest / Demo profile
    _mockUser ??= UserModel(
      uid: 'guest_neon_user',
      email: 'pilot@neonglass.dev',
      displayName: 'Neon Explorer',
      bio: 'Cyberpunk enthusiast & 3D parallax collector.',
      avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=200&q=80',
      role: 'USER',
      stats: const UserStats(
        totalFollowers: 128,
        totalUploads: 4,
        averageRating: 4.85,
        ratingCount: 36,
      ),
      createdAt: DateTime.now(),
    );
    return _mockUser!;
  }

  Future<UserModel> switchToCreatorMode({
    required String uid,
    required String displayName,
    required String bio,
  }) async {
    final firestore = _firestore;
    if (firestore != null) {
      try {
        await firestore.collection(ApiConstants.colUsers).doc(uid).set({
          'display_name': displayName,
          'bio': bio,
          'role': 'CREATOR',
        }, SetOptions(merge: true)).timeout(const Duration(seconds: 2));
      } catch (_) {}
    }

    if (_mockUser != null && _mockUser!.uid == uid) {
      _mockUser = _mockUser!.copyWith(
        displayName: displayName,
        bio: bio,
        role: 'CREATOR',
      );
      return _mockUser!;
    }
    return getCurrentUserModel();
  }

  Future<UserModel> switchToUserMode({
    required String uid,
  }) async {
    final firestore = _firestore;
    if (firestore != null) {
      try {
        await firestore.collection(ApiConstants.colUsers).doc(uid).set({
          'role': 'EXPLORER',
        }, SetOptions(merge: true)).timeout(const Duration(seconds: 2));
      } catch (_) {}
    }

    if (_mockUser != null && _mockUser!.uid == uid) {
      _mockUser = _mockUser!.copyWith(
        role: 'EXPLORER',
      );
      return _mockUser!;
    }
    return getCurrentUserModel();
  }

  Future<void> signInAnonymously() async {
    try {
      await _auth?.signInAnonymously();
    } catch (_) {}
  }

  Future<void> signOut() async {
    try {
      await _auth?.signOut();
    } catch (_) {}
  }
}
