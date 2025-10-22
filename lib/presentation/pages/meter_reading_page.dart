import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/meter_reading_bloc.dart';
import '../bloc/consumer_bloc.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_state.dart';
import '../../services/camera_service.dart';
import 'dart:io';

class MeterReadingPage extends StatefulWidget {
  const MeterReadingPage({super.key});

  @override
  State<MeterReadingPage> createState() => _MeterReadingPageState();
}

class _MeterReadingPageState extends State<MeterReadingPage> {
  final TextEditingController _readingController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedMeterType = 'Water';
  File? _selectedPhoto;
  final CameraService _cameraService = CameraService();

  final List<String> _meterTypes = ['Water'];

  @override
  void initState() {
    super.initState();
    print('📱 [MeterReadingPage] Initializing meter reading page...');
    // Load meter readings when the page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('📱 [MeterReadingPage] Dispatching LoadMeterReadings event...');
      context.read<MeterReadingBloc>().add(LoadMeterReadings());
      print(
        '📱 [MeterReadingPage] Dispatching LoadLatestMeterReading event...',
      );
      context.read<MeterReadingBloc>().add(LoadLatestMeterReading());

      // Load consumer details
      print('📱 [MeterReadingPage] Dispatching LoadConsumerDetails event...');
      // Get current user ID from auth state
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        context.read<ConsumerBloc>().add(
          LoadConsumerDetails(authState.user.id),
        );
      }
    });
  }

  @override
  void dispose() {
    _readingController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _showPhotoOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _takePhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _pickPhotoFromGallery();
                },
              ),
              if (_selectedPhoto != null)
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Remove Photo'),
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _selectedPhoto = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _takePhoto() async {
    try {
      final photo = await _cameraService.pickPhotoFromCamera();
      if (photo != null) {
        setState(() {
          _selectedPhoto = photo;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo captured successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error taking photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickPhotoFromGallery() async {
    try {
      final photo = await _cameraService.pickPhotoFromGallery();
      if (photo != null) {
        setState(() {
          _selectedPhoto = photo;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo selected successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _submitReading() {
    if (_readingController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a meter reading'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final readingValue = double.tryParse(_readingController.text);
    if (readingValue == null || readingValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid meter reading'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if photo is required
    if (_selectedPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please take a photo of your meter reading'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if user can submit reading (must be at least 1 month from last reading)
    final currentState = context.read<MeterReadingBloc>().state;
    if (currentState is MeterReadingLoaded &&
        currentState.latestReading != null) {
      final lastReadingDate = currentState.latestReading!.readingDate;
      final oneMonthFromLastReading = DateTime(
        lastReadingDate.year,
        lastReadingDate.month + 1,
        lastReadingDate.day,
      );

      if (_selectedDate.isBefore(oneMonthFromLastReading)) {
        final daysRemaining = oneMonthFromLastReading
            .difference(DateTime.now())
            .inDays;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You can only submit a new reading after 1 month from your last reading. '
              'Next submission allowed on: ${oneMonthFromLastReading.day}/${oneMonthFromLastReading.month}/${oneMonthFromLastReading.year}'
              '${daysRemaining > 0 ? ' (${daysRemaining} days remaining)' : ''}',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }
    }

    // Submit meter reading using BLoC
    print('📱 [MeterReadingPage] Dispatching SubmitMeterReading event...');
    print(
      '📱 [MeterReadingPage] Data: meterType=$_selectedMeterType, readingValue=$readingValue, readingDate=$_selectedDate, hasPhoto=${_selectedPhoto != null}',
    );

    context.read<MeterReadingBloc>().add(
      SubmitMeterReading(
        meterType: _selectedMeterType,
        readingValue: readingValue,
        readingDate: _selectedDate,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        photoFile: _selectedPhoto,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MeterReadingBloc, MeterReadingState>(
      listener: (context, state) {
        print('📱 [MeterReadingPage] State changed: ${state.runtimeType}');

        if (state is MeterReadingSubmitted) {
          print('✅ [MeterReadingPage] Meter reading submitted successfully!');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Meter reading submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Clear form
          _readingController.clear();
          _notesController.clear();
          setState(() {
            _selectedPhoto = null;
          });
        } else if (state is MeterReadingError) {
          print('❌ [MeterReadingPage] Meter reading error: ${state.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        } else if (state is MeterReadingLoading) {
          print('🔄 [MeterReadingPage] Meter reading operation in progress...');
        } else if (state is MeterReadingLoaded) {
          print(
            '📊 [MeterReadingPage] Meter readings loaded: ${state.readings.length} readings',
          );
        }
      },
      child: BlocBuilder<MeterReadingBloc, MeterReadingState>(
        builder: (context, meterReadingState) {
          return BlocBuilder<ConsumerBloc, ConsumerState>(
            builder: (context, consumerState) {
              return Scaffold(
                backgroundColor: const Color(0xFFF5F7FA),
                appBar: AppBar(
                  title: const Text(
                    'Meter Reading',
                    style: TextStyle(
                      color: Color(0xFF1A3A5C),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Colors.white,
                  elevation: 0,
                  iconTheme: const IconThemeData(color: Color(0xFF1A3A5C)),
                ),
                body: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Consumer Details Card
                        _buildConsumerDetailsCard(consumerState),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildConsumerDetailsCard(ConsumerState state) {
    if (state is ConsumerLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state is ConsumerError) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error loading consumer details',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A3A5C),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (state is ConsumerLoaded) {
      final consumer = state.consumer;
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90E2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF4A90E2),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Consumer Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A3A5C),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDetailRow('Water Meter No.', consumer.waterMeterNo),
            const SizedBox(height: 12),
            _buildDetailRow('Full Name', consumer.fullName),
            const SizedBox(height: 12),
            _buildDetailRow('Address', consumer.fullAddress),
            const SizedBox(height: 12),
            _buildDetailRow('Phone', consumer.phone),
            const SizedBox(height: 12),
            _buildDetailRow('Email', consumer.email),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Current Reading',
              '${consumer.currentReading.toStringAsFixed(0)} cubic meters',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Previous Reading',
              '${consumer.previousReading.toStringAsFixed(0)} cubic meters',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Consumption',
              '${consumer.consumptionCubicMeters.toStringAsFixed(0)} cubic meters',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Amount Due',
              '₱${consumer.amountCurrentBilling.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Billing Month', consumer.billingMonth),
            const SizedBox(height: 12),
            _buildDetailRow('Due Date', consumer.dueDate),
            const SizedBox(height: 12),
            _buildDetailRow('Status', consumer.status),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'No consumer details available',
          style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildReadingItem({
    required String reading,
    required String date,
    required String status,
    required Color statusColor,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF4A90E2).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.speed, color: Color(0xFF4A90E2), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$reading cubic meters',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3A5C),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                date,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }
}
