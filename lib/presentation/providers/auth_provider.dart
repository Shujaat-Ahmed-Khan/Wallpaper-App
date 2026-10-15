import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class CurrentUserNotifier extends AsyncNotifier<UserModel> {
  @override
  Future<UserModel> build() async {
    final repo = ref.read(authRepositoryProvider);
    return repo.getCurrentUserModel();
  }

  Future<void> switchToCreatorMode(String displayName, String bio) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final current = state.asData?.value ?? await repo.getCurrentUserModel();
      return repo.switchToCreatorMode(
        uid: current.uid,
        displayName: displayName,
        bio: bio,
      );
    });
  }

  Future<void> switchToUserMode() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final current = state.asData?.value ?? await repo.getCurrentUserModel();
      return repo.switchToUserMode(uid: current.uid);
    });
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      return repo.getCurrentUserModel();
    });
  }
}

final currentUserProvider = AsyncNotifierProvider<CurrentUserNotifier, UserModel>(() {
  return CurrentUserNotifier();
});
