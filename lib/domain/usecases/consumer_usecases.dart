import '../entities/consumer.dart';
import '../repositories/consumer_repository.dart';
import '../../core/usecases/usecase.dart';

class GetConsumerDetailsUseCase implements UseCase<Consumer?, String> {
  final ConsumerRepository _repository;

  GetConsumerDetailsUseCase(this._repository);

  @override
  Future<Consumer?> call(String consumerId) async {
    try {
      print(
        '🔍 [GetConsumerDetailsUseCase] Fetching consumer details for ID: $consumerId',
      );
      return await _repository.getConsumerDetails(consumerId);
    } catch (e) {
      print(
        '❌ [GetConsumerDetailsUseCase] Error fetching consumer details: $e',
      );
      return null;
    }
  }
}

class GetConsumerByUserIdUseCase implements UseCase<Consumer?, String> {
  final ConsumerRepository _repository;

  GetConsumerByUserIdUseCase(this._repository);

  @override
  Future<Consumer?> call(String userId) async {
    try {
      print(
        '🔍 [GetConsumerByUserIdUseCase] Fetching consumer by user ID: $userId',
      );
      return await _repository.getConsumerByUserId(userId);
    } catch (e) {
      print(
        '❌ [GetConsumerByUserIdUseCase] Error fetching consumer by user ID: $e',
      );
      return null;
    }
  }
}
