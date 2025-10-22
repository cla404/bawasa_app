import '../entities/consumer.dart';

abstract class ConsumerRepository {
  Future<Consumer?> getConsumerDetails(String consumerId);
  Future<Consumer?> getConsumerByUserId(String userId);
}
