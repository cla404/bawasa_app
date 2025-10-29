import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../domain/repositories/meter_reading_repository.dart';

class MeterReaderHistoryPage extends StatefulWidget {
  const MeterReaderHistoryPage({super.key});

  @override
  State<MeterReaderHistoryPage> createState() => _MeterReaderHistoryPageState();
}

class _MeterReaderHistoryPageState extends State<MeterReaderHistoryPage> {
  List<Map<String, dynamic>> _completedReadings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompletedReadings();
  }

  Future<void> _loadCompletedReadings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final repository = GetIt.instance<MeterReadingRepository>();
      final completedReadings = await repository.getCompletedMeterReadings();

      setState(() {
        _completedReadings = completedReadings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading completed readings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _normalizeImageUrl(String url) {
    // Fix duplicated bucket name in URL
    return url.replaceAll('/meter_image/meter_image/', '/meter_image/');
  }

  void _showReadingDetails(Map<String, dynamic> reading) {
    final consumer = reading['consumers'] as Map<String, dynamic>;
    final account = consumer['accounts'] as Map<String, dynamic>?;
    final meterReadings = reading['bawasa_meter_readings'] as List;
    final latestReading = meterReadings.isEmpty
        ? null
        : meterReadings[0] as Map<String, dynamic>;

    if (latestReading == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reading Details',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A3A5C),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Consumer Information
                      const Text(
                        'Consumer Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A3A5C),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        'Name',
                        account?['full_name'] ?? 'Unknown',
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow('Meter No.', consumer['water_meter_no']),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Address',
                        account?['full_address'] ?? 'N/A',
                      ),
                      const SizedBox(height: 24),

                      // Meter Reading Information
                      const Text(
                        'Meter Reading Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A3A5C),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        'Previous Reading',
                        '${latestReading['previous_reading']?.toStringAsFixed(2) ?? '0.00'} m³',
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Present Reading',
                        '${latestReading['present_reading']?.toStringAsFixed(2) ?? '0.00'} m³',
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Consumption',
                        '${latestReading['consumption_cubic_meters']?.toStringAsFixed(2) ?? '0.00'} m³',
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Reading Date',
                        DateTime.parse(
                          latestReading['created_at'],
                        ).toLocal().toString().split('.')[0],
                      ),
                      if (latestReading['remarks'] != null) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Remarks',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A3A5C),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(
                            latestReading['remarks'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],

                      // Photo Section
                      if (latestReading['meter_image'] != null &&
                          latestReading['meter_image']
                              .toString()
                              .isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Meter Photo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A3A5C),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _normalizeImageUrl(latestReading['meter_image']),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade100,
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.broken_image,
                                          color: Colors.grey,
                                          size: 48,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Unable to load image',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1A3A5C)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Reading History',
          style: TextStyle(
            color: Color(0xFF1A3A5C),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A3A5C)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCompletedReadings,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _completedReadings.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No completed readings yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A3A5C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your completed meter readings will appear here',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadCompletedReadings,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _completedReadings.length,
                itemBuilder: (context, index) {
                  final reading = _completedReadings[index];
                  final consumer = reading['consumers'] as Map<String, dynamic>;
                  final account = consumer['accounts'] as Map<String, dynamic>?;
                  final meterReadings =
                      reading['bawasa_meter_readings'] as List;

                  if (meterReadings.isEmpty) return const SizedBox.shrink();

                  final latestReading =
                      meterReadings[0] as Map<String, dynamic>;

                  return GestureDetector(
                    onTap: () => _showReadingDetails(reading),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A90E2).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: Color(0xFF4A90E2),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  account?['full_name'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A3A5C),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Meter: ${consumer['water_meter_no']}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      'Reading: ${latestReading['present_reading']?.toStringAsFixed(2) ?? 'N/A'} m³',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF4A90E2),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Completed',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF6B7280),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
