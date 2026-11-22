import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../data/repositories/app_lock_repository_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../data/sources/local/app_lock_local_source.dart';
import '../../data/sources/local/transaction_local_source.dart';
import '../../data/sources/remote/auth_remote_source.dart';
import '../../data/sources/remote/transaction_remote_source.dart';
import '../../data/sources/remote/user_remote_source.dart';
import '../../domain/repositories/app_lock_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/usecases/add_transaction_with_user_update.dart';
import '../../domain/usecases/change_password.dart';
import '../../domain/usecases/set_app_lock_password.dart';
import '../../domain/usecases/sign_in_with_email.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up_with_email.dart';
import '../../domain/usecases/update_currency.dart';
import '../../domain/usecases/update_profile.dart';
import '../../domain/usecases/verify_app_lock_password.dart';
import '../../domain/usecases/watch_auth_state.dart';
import '../../presentation/providers/app_lock_provider.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/home_provider.dart';
import '../../presentation/providers/transaction_list_provider.dart';
import '../../presentation/providers/transaction_provider.dart';
import '../../presentation/providers/user_provider.dart';
import '../network/api_client.dart';
import '../storage/currency_preferences.dart';
import '../storage/secure_storage_service.dart';

/// Composition root. Register clients, data sources, repositories, use cases,
/// and presentation providers here as features are added.
class AppProviders {
  const AppProviders._();

  static List<SingleChildWidget> get list {
    // Auth, App Lock, Profile and Currency now run against the Node.js +
    // PostgreSQL REST API through the shared [ApiClient].
    final secureStorage = SecureStorageService();
    final apiClient = ApiClient(secureStorage);
    final currencyPreferences = CurrencyPreferences();
    final authRemoteSource = AuthRemoteSource(apiClient, secureStorage);
    final authRepository = AuthRepositoryImpl(authRemoteSource);
    final appLockLocalSource = AppLockLocalSource(secureStorage);
    final appLockRepository = AppLockRepositoryImpl(appLockLocalSource);

    // Every feature now runs against the Node.js + PostgreSQL REST API through
    // the shared [ApiClient].
    final userRemoteSource = UserRemoteSource(
      apiClient,
      secureStorage,
      currencyPreferences,
    );
    final transactionRemoteSource = TransactionRemoteSource(apiClient);
    final transactionLocalSource = TransactionLocalSource();
    final userRepository = UserRepositoryImpl(userRemoteSource);
    final transactionRepository = TransactionRepositoryImpl(
      transactionRemoteSource,
      transactionLocalSource,
      secureStorage,
    );
    final addTransactionWithUserUpdate = AddTransactionWithUserUpdate(
      transactionRepository,
    );
    final updateProfile = UpdateProfile(authRepository, userRepository);
    final changePassword = ChangePassword(authRepository);
    final updateCurrency = UpdateCurrency(userRepository);
    final setAppLockPassword = SetAppLockPassword(appLockRepository);
    final verifyAppLockPassword = VerifyAppLockPassword(appLockRepository);

    return [
      Provider<SecureStorageService>.value(value: secureStorage),
      Provider<ApiClient>.value(value: apiClient),
      Provider<AuthRepository>.value(value: authRepository),
      Provider<UserRepository>.value(value: userRepository),
      Provider<TransactionRepository>.value(value: transactionRepository),
      Provider<AppLockRepository>.value(value: appLockRepository),
      Provider<AddTransactionWithUserUpdate>.value(
        value: addTransactionWithUserUpdate,
      ),
      Provider<UpdateProfile>.value(value: updateProfile),
      Provider<ChangePassword>.value(value: changePassword),
      Provider<UpdateCurrency>.value(value: updateCurrency),
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(
          signInWithEmail: SignInWithEmail(authRepository),
          signUpWithEmail: SignUpWithEmail(authRepository),
          signOutUseCase: SignOut(authRepository),
          setAppLockPassword: setAppLockPassword,
          watchAuthState: WatchAuthState(authRepository),
          initialUser: authRepository.currentUser,
        ),
      ),
      ChangeNotifierProvider<AppLockProvider>(
        create: (_) => AppLockProvider(
          setPasswordUseCase: setAppLockPassword,
          verifyPasswordUseCase: verifyAppLockPassword,
          repository: appLockRepository,
        ),
      ),
      ChangeNotifierProxyProvider<AuthProvider, HomeProvider>(
        create: (context) => HomeProvider(
          userRepository: context.read<UserRepository>(),
          transactionRepository: context.read<TransactionRepository>(),
        ),
        update: (_, auth, home) {
          home!.bindUid(auth.user?.id);
          return home;
        },
      ),
      ChangeNotifierProvider<TransactionProvider>(
        create: (context) => TransactionProvider(
          addTransactionUseCase:
              context.read<AddTransactionWithUserUpdate>(),
        ),
      ),
      ChangeNotifierProxyProvider<AuthProvider, TransactionListProvider>(
        create: (context) => TransactionListProvider(
          transactionRepository: context.read<TransactionRepository>(),
          userRepository: context.read<UserRepository>(),
        ),
        update: (_, auth, listProvider) {
          listProvider!.bindUid(auth.user?.id);
          return listProvider;
        },
      ),
      ChangeNotifierProxyProvider<AuthProvider, UserProvider>(
        create: (context) => UserProvider(
          updateProfileUseCase: context.read<UpdateProfile>(),
          changePasswordUseCase: context.read<ChangePassword>(),
          updateCurrencyUseCase: context.read<UpdateCurrency>(),
          authRepository: context.read<AuthRepository>(),
          appLockRepository: context.read<AppLockRepository>(),
          initialUser: authRepository.currentUser,
        ),
        update: (_, auth, userProvider) {
          userProvider!.bindAuthUser(auth.user);
          return userProvider;
        },
      ),
    ];
  }
}
