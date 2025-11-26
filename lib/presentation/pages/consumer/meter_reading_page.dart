import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/meter_reading_bloc.dart';
import '../../bloc/consumer_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../../domain/entities/meter_reading.dart';
import '../../../services/camera_service.dart';
import 'dart:io';

class MeterReadingPage extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const MeterReadingPage({super.key, this.onBackToHome});

  @override
  State<MeterReadingPage> createState() => _MeterReadingPageState();
}

class _MeterReadingPageState extends State<MeterReadingPage> {
  final TextEditingController _readingController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedMeterType = 'Water';
  File? _selectedPhoto;
  final CameraService _cameraService = CameraService();
  List<MeterReading> _filteredReadings = [];

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
    _searchController.dispose();
    super.dispose();
  }

  void _filterReadings(List<MeterReading> readings) {
    final query = _searchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      setState(() {
        _filteredReadings = readings;
      });
      return;
    }

    setState(() {
      _filteredReadings = readings.where((reading) {
        // Search by reading value
        final readingValue = reading.readingValue.toString().toLowerCase();
        if (readingValue.contains(query)) return true;

        // Search by date
        final dateStr =
            '${reading.readingDate.day}/${reading.readingDate.month}/${reading.readingDate.year}';
        if (dateStr.contains(query)) return true;

        // Search by month name
        final monthNames = [
          'january',
          'february',
          'march',
          'april',
          'may',
          'june',
          'july',
          'august',
          'september',
          'october',
          'november',
          'december',
        ];
        final monthName = monthNames[reading.readingDate.month - 1];
        if (monthName.contains(query)) return true;

        // Search by year
        if (reading.readingDate.year.toString().contains(query)) return true;

        // Search by notes if available
        if (reading.notes != null &&
            reading.notes!.toLowerCase().contains(query)) {
          return true;
        }

        return false;
      }).toList();
    });
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
          // Filter readings when they're loaded
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _filterReadings(state.readings);
            }
          });
        }
      },
      child: BlocBuilder<MeterReadingBloc, MeterReadingState>(
        builder: (context, meterReadingState) {
          return BlocBuilder<ConsumerBloc, ConsumerState>(
            builder: (context, consumerState) {
              return Scaffold(
                backgroundColor: const Color(0xFFF5F7FA),
                appBar: AppBar(
                  leading: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF1A3A5C),
                    ),
                    onPressed: () {
                      if (widget.onBackToHome != null) {
                        widget.onBackToHome!();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  title: const Text(
                    'Meter Reading History',
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final screenWidth = constraints.maxWidth;
                      final isTablet = screenWidth > 600;
                      final padding = isTablet ? 24.0 : 16.0;

                      return SingleChildScrollView(
                        padding: EdgeInsets.all(padding),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isTablet ? 800 : double.infinity,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Search Bar
                              _buildSearchBar(isTablet),
                              const SizedBox(height: 16),
                              // Meter Readings List
                              _buildMeterReadingsList(meterReadingState),
                            ],
                          ),
                        ),
                      );
                    },
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

  Widget _buildDetailRow(String label, String value, {bool isTablet = false}) {
    final labelWidth = isTablet ? 180.0 : 120.0;
    final fontSize = isTablet ? 16.0 : 14.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              color: const Color(0xFF1A3A5C),
            ),
          ),
        ),
      ],
    );
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

  Widget _buildSearchBar(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
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
      child: StatefulBuilder(
        builder: (context, setState) {
          return TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by reading, date, or month...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Color(0xFF6B7280)),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                        final currentState = context
                            .read<MeterReadingBloc>()
                            .state;
                        if (currentState is MeterReadingLoaded) {
                          _filterReadings(currentState.readings);
                        }
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF4A90E2)),
              ),
              filled: true,
              fillColor: Colors.grey.withOpacity(0.05),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isTablet ? 20 : 16,
                vertical: isTablet ? 16 : 12,
              ),
            ),
            style: TextStyle(fontSize: isTablet ? 16 : 14),
            onChanged: (value) {
              setState(() {});
              final currentState = context.read<MeterReadingBloc>().state;
              if (currentState is MeterReadingLoaded) {
                _filterReadings(currentState.readings);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildMeterReadingsList(MeterReadingState state) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final padding = isTablet ? 24.0 : 16.0;
    final spacing = isTablet ? 24.0 : 16.0;

    if (state is MeterReadingLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: spacing),
          Container(
            padding: EdgeInsets.all(padding),
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
          ),
        ],
      );
    }

    if (state is MeterReadingError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: spacing),
          Container(
            padding: EdgeInsets.all(padding),
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
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: isTablet ? 64 : 48,
                ),
                SizedBox(height: spacing),
                Text(
                  'Error loading meter readings',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A3A5C),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  state.message,
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: const Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (state is MeterReadingLoaded) {
      if (state.readings.isEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: spacing),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(padding),
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
                  Icon(
                    Icons.speed,
                    color: const Color(0xFF6B7280),
                    size: isTablet ? 64 : 48,
                  ),
                  SizedBox(height: spacing),
                  Text(
                    'No meter readings yet',
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A3A5C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your meter reading history will appear here',
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      color: const Color(0xFF6B7280),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        );
      }

      // Initialize filtered readings if empty
      if (_filteredReadings.isEmpty && _searchController.text.isEmpty) {
        _filteredReadings = state.readings;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: spacing),
          Container(
            padding: EdgeInsets.all(padding),
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
            child:
                _filteredReadings.isEmpty && _searchController.text.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(padding),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: isTablet ? 64 : 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No readings found',
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A3A5C),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your search terms',
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              color: const Color(0xFF6B7280),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: _filteredReadings.asMap().entries.map((entry) {
                      final index = entry.key;
                      final reading = entry.value;
                      // Find the index in the original list to calculate consumption correctly
                      final originalIndex = state.readings.indexOf(reading);
                      final consumption =
                          reading.readingValue -
                          (originalIndex < state.readings.length - 1
                              ? state.readings[originalIndex + 1].readingValue
                              : 0.0);
                      final previousReading =
                          originalIndex < state.readings.length - 1
                          ? state.readings[originalIndex + 1].readingValue
                          : 0.0;

                      return Column(
                        children: [
                          _buildMeterReadingItem(
                            reading: reading.readingValue,
                            consumption: consumption,
                            date: reading.readingDate,
                            status: reading.status,
                            onViewDetails: () => _showMeterReadingDetails(
                              reading: reading,
                              consumption: consumption,
                              previousReading: previousReading,
                            ),
                          ),
                          if (index < _filteredReadings.length - 1)
                            SizedBox(height: spacing),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: spacing),
        Container(
          padding: EdgeInsets.all(padding),
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
        ),
      ],
    );
  }

  Widget _buildMeterReadingItem({
    required double reading,
    required double consumption,
    required DateTime date,
    required String status,
    required VoidCallback onViewDetails,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final iconSize = isTablet ? 56.0 : 48.0;
    final fontSize = isTablet ? 16.0 : 14.0;
    final smallFontSize = isTablet ? 14.0 : 12.0;
    final spacing = isTablet ? 16.0 : 12.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: const Color(0xFF4A90E2).withOpacity(0.1),
            borderRadius: BorderRadius.circular(iconSize / 2),
          ),
          child: Icon(
            Icons.speed,
            color: const Color(0xFF4A90E2),
            size: iconSize / 2,
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reading',
                          style: TextStyle(
                            fontSize: smallFontSize,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${reading.toStringAsFixed(2)} m³',
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A3A5C),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Consumption',
                          style: TextStyle(
                            fontSize: smallFontSize,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${consumption.toStringAsFixed(2)} m³',
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF4A90E2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${date.day}/${date.month}/${date.year}',
                style: TextStyle(
                  fontSize: smallFontSize,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: spacing),
        ElevatedButton.icon(
          onPressed: onViewDetails,
          icon: Icon(Icons.visibility, size: isTablet ? 18 : 16),
          label: Text(
            'View',
            style: TextStyle(
              fontSize: smallFontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A90E2),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 16 : 12,
              vertical: isTablet ? 8 : 6,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  String _normalizeImageUrl(String url) {
    // Fix duplicated bucket name in URL
    // e.g., /meter_image/meter_image/ -> /meter_image/
    final normalized = url.replaceAll(
      '/meter_image/meter_image/',
      '/meter_image/',
    );
    return normalized;
  }

  void _showMeterReadingDetails({
    required MeterReading reading,
    required double consumption,
    required double previousReading,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final padding = isTablet ? 32.0 : 20.0;
    final spacing = isTablet ? 32.0 : 24.0;
    final titleFontSize = isTablet ? 28.0 : 24.0;
    final sectionFontSize = isTablet ? 18.0 : 16.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: isTablet ? 0.7 : 0.8,
        minChildSize: isTablet ? 0.5 : 0.5,
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
                  padding: EdgeInsets.all(padding),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 800 : double.infinity,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meter Reading Details',
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A3A5C),
                          ),
                        ),
                        SizedBox(height: spacing),

                        // Photo Section
                        if (reading.photoUrl != null &&
                            reading.photoUrl!.isNotEmpty) ...[
                          Text(
                            'Meter Photo',
                            style: TextStyle(
                              fontSize: sectionFontSize,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A3A5C),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: isTablet ? 300 : 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _normalizeImageUrl(reading.photoUrl!),
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: Colors.grey.shade100,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value:
                                                loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                : null,
                                          ),
                                        ),
                                      );
                                    },
                                errorBuilder: (context, error, stackTrace) {
                                  print(
                                    '❌ [MeterReadingPage] Error loading image: $error',
                                  );
                                  print(
                                    '❌ [MeterReadingPage] URL: ${reading.photoUrl}',
                                  );
                                  return Container(
                                    color: Colors.grey.shade100,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.broken_image,
                                            color: Colors.grey,
                                            size: isTablet ? 64 : 48,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Unable to load image',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: isTablet ? 16 : 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: spacing),
                        ],

                        // Reading Information
                        Text(
                          'Reading Information',
                          style: TextStyle(
                            fontSize: sectionFontSize,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A3A5C),
                          ),
                        ),
                        SizedBox(height: spacing),
                        _buildDetailRow(
                          'Previous Reading',
                          '${previousReading.toStringAsFixed(2)} m³',
                          isTablet: isTablet,
                        ),
                        SizedBox(height: isTablet ? 16 : 12),
                        _buildDetailRow(
                          'Present Reading',
                          '${reading.readingValue.toStringAsFixed(2)} m³',
                          isTablet: isTablet,
                        ),
                        SizedBox(height: isTablet ? 16 : 12),
                        _buildDetailRow(
                          'Consumption',
                          '${consumption.toStringAsFixed(2)} m³',
                          isTablet: isTablet,
                        ),
                        SizedBox(height: isTablet ? 16 : 12),
                        _buildDetailRow(
                          'Reading Date',
                          '${reading.readingDate.day}/${reading.readingDate.month}/${reading.readingDate.year}',
                          isTablet: isTablet,
                        ),
                        SizedBox(height: isTablet ? 16 : 12),
                        _buildDetailRow(
                          'Reading Time',
                          '${reading.readingDate.hour.toString().padLeft(2, '0')}:${reading.readingDate.minute.toString().padLeft(2, '0')}',
                          isTablet: isTablet,
                        ),
                        SizedBox(height: isTablet ? 16 : 12),
                        _buildDetailRow(
                          'Meter Type',
                          reading.meterType,
                          isTablet: isTablet,
                        ),

                        // Remarks
                        if (reading.notes != null &&
                            reading.notes!.isNotEmpty) ...[
                          SizedBox(height: spacing),
                          Text(
                            'Remarks',
                            style: TextStyle(
                              fontSize: sectionFontSize,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A3A5C),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: EdgeInsets.all(isTablet ? 16 : 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              reading.notes!,
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 14,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
