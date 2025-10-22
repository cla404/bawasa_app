import 'package:get_it/get_it.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/meter_reading_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/repositories/consumer_repository.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../../domain/usecases/meter_reading_usecases.dart';
import '../../domain/usecases/user_usecases.dart';
import '../../domain/usecases/consumer_usecases.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/supabase_accounts_auth_repository_impl.dart';
import '../../data/repositories/meter_reading_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../data/repositories/consumer_repository_impl.dart';
import '../../presentation/bloc/auth/auth_bloc.dart';
import '../../presentation/bloc/meter_reading_bloc.dart';
import '../../presentation/bloc/consumer_bloc.dart';
import '../config/supabase_config.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Features - Auth
  sl.registerLazySingleton(() => SupabaseAuthDataSource(SupabaseConfig.client));
  sl.registerLazySingleton<AuthRepository>(
    () => SupabaseAccountsAuthRepositoryImpl(),
  );
  sl.registerLazySingleton(() => SupabaseAccountsAuthRepositoryImpl());

  // Features - User Profile
  sl.registerLazySingleton<UserRepository>(() => SupabaseUserRepository());

  // Features - Meter Reading
  sl.registerLazySingleton<MeterReadingRepository>(
    () => MeterReadingRepositoryImpl(),
  );

  // Features - Consumer
  sl.registerLazySingleton<ConsumerRepository>(() => ConsumerRepositoryImpl());

  // Use cases - Auth
  sl.registerLazySingleton(() => SignInUseCase(sl()));
  sl.registerLazySingleton(() => SignUpUseCase(sl()));
  sl.registerLazySingleton(() => SignOutUseCase(sl()));
  sl.registerLazySingleton(() => ResetPasswordUseCase(sl()));
  sl.registerLazySingleton(() => ResendConfirmationEmailUseCase(sl()));

  // Use cases - User Profile
  sl.registerLazySingleton(() => CreateUserProfileUseCase(sl()));
  sl.registerLazySingleton(() => GetUserProfileUseCase(sl()));
  sl.registerLazySingleton(() => UpdateUserProfileUseCase(sl()));

  // Use cases - Meter Reading
  sl.registerLazySingleton(() => GetUserMeterReadingsUseCase(sl()));
  sl.registerLazySingleton(() => GetLatestMeterReadingUseCase(sl()));
  sl.registerLazySingleton(() => SubmitMeterReadingUseCase(sl()));
  sl.registerLazySingleton(() => SubmitMeterReadingWithPhotoUseCase(sl()));
  sl.registerLazySingleton(() => UpdateMeterReadingUseCase(sl()));
  sl.registerLazySingleton(() => DeleteMeterReadingUseCase(sl()));

  // Use cases - Consumer
  sl.registerLazySingleton(() => GetConsumerDetailsUseCase(sl()));
  sl.registerLazySingleton(() => GetConsumerByUserIdUseCase(sl()));

  // Blocs
  sl.registerLazySingleton(() => AuthBloc());
  sl.registerLazySingleton(
    () => MeterReadingBloc(
      getUserMeterReadingsUseCase: sl(),
      getLatestMeterReadingUseCase: sl(),
      submitMeterReadingUseCase: sl(),
      submitMeterReadingWithPhotoUseCase: sl(),
      updateMeterReadingUseCase: sl(),
      deleteMeterReadingUseCase: sl(),
    ),
  );
  sl.registerLazySingleton(
    () => ConsumerBloc(getConsumerByUserIdUseCase: sl()),
  );
}
