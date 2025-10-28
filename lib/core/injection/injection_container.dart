import 'package:get_it/get_it.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/meter_reading_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/repositories/consumer_repository.dart';
import '../../domain/repositories/issue_report_repository.dart';
import '../../domain/repositories/billing_repository.dart';
import '../../domain/repositories/recent_activity_repository.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../../domain/usecases/meter_reading_usecases.dart';
import '../../domain/usecases/meter_reader_usecases.dart';
import '../../domain/usecases/user_usecases.dart';
import '../../domain/usecases/consumer_usecases.dart';
import '../../domain/usecases/submit_issue_report.dart';
import '../../domain/usecases/get_issue_reports_by_consumer_id.dart';
import '../../domain/usecases/billing_usecases.dart';
import '../../domain/usecases/recent_activity_usecases.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/supabase_accounts_auth_repository_impl.dart';
import '../../data/repositories/meter_reading_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../data/repositories/consumer_repository_impl.dart';
import '../../data/repositories/issue_report_repository_impl.dart';
import '../../data/repositories/billing_repository_impl.dart';
import '../../data/repositories/recent_activity_repository_impl.dart';
import '../../presentation/bloc/auth/auth_bloc.dart';
import '../../presentation/bloc/meter_reading_bloc.dart';
import '../../presentation/bloc/consumer_bloc.dart';
import '../../presentation/bloc/billing_bloc.dart';
import '../../presentation/bloc/recent_activity_bloc.dart';
import '../../presentation/bloc/consumption_bloc.dart';
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

  // Features - Issue Report
  sl.registerLazySingleton<IssueReportRepository>(
    () => IssueReportRepositoryImpl(),
  );

  // Features - Billing
  sl.registerLazySingleton<BillingRepository>(() => BillingRepositoryImpl());

  // Features - Recent Activity
  sl.registerLazySingleton<RecentActivityRepository>(
    () => RecentActivityRepositoryImpl(
      meterReadingRepository: sl(),
      billingRepository: sl(),
      issueReportRepository: sl(),
    ),
  );

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

  // Use cases - Meter Reader
  sl.registerLazySingleton(() => GetConsumersForMeterReaderUseCase(sl()));

  // Use cases - Consumer
  sl.registerLazySingleton(() => GetConsumerDetailsUseCase(sl()));
  sl.registerLazySingleton(() => GetConsumerByUserIdUseCase(sl()));

  // Use cases - Issue Report
  sl.registerLazySingleton(() => SubmitIssueReport(sl()));
  sl.registerLazySingleton(() => GetIssueReportsByConsumerIdUseCase(sl()));

  // Use cases - Billing
  sl.registerLazySingleton(() => GetCurrentBill(sl()));
  sl.registerLazySingleton(() => GetBillingHistory(sl()));
  sl.registerLazySingleton(() => GetBillingHistoryByPeriod(sl()));
  sl.registerLazySingleton(() => GetAllBills(sl()));
  sl.registerLazySingleton(() => GetOverdueBills(sl()));
  sl.registerLazySingleton(() => GetBillsByConsumerId(sl()));

  // Use cases - Recent Activity
  sl.registerLazySingleton(() => GetRecentActivitiesUseCase(sl()));

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
  sl.registerLazySingleton(
    () => BillingBloc(
      getCurrentBill: sl(),
      getBillingHistory: sl(),
      getBillingHistoryByPeriod: sl(),
      getAllBills: sl(),
      getOverdueBills: sl(),
      getBillsByConsumerId: sl(),
    ),
  );
  sl.registerLazySingleton(
    () => RecentActivityBloc(getRecentActivitiesUseCase: sl()),
  );
  sl.registerLazySingleton(
    () => ConsumptionBloc(getUserMeterReadingsUseCase: sl()),
  );
}
