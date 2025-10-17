import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/meter_reading_bloc.dart';
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
        builder: (context, state) {
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
                    // Current Reading Card
                    _buildCurrentReadingCard(state),
                    const SizedBox(height: 24),

                    // Next Reading Info Card
                    _buildNextReadingInfoCard(state),
                    const SizedBox(height: 24),

                    // Submit Reading Form
                    _buildSubmitReadingForm(state),
                    const SizedBox(height: 24),

                    // Recent Readings
                    _buildRecentReadingsSection(state),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentReadingCard(MeterReadingState state) {
    String lastReading = 'No readings yet';
    String lastDate = 'N/A';

    if (state is MeterReadingLoaded && state.latestReading != null) {
      final reading = state.latestReading!;
      lastReading = '${reading.readingValue.toStringAsFixed(0)} cubic meters';
      lastDate =
          '${reading.readingDate.day}/${reading.readingDate.month}/${reading.readingDate.year}';
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
                  Icons.speed,
                  color: Color(0xFF4A90E2),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Current Reading',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3A5C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Last Reading:',
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
              Text(
                lastReading,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3A5C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Date:',
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
              Text(
                lastDate,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3A5C),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextReadingInfoCard(MeterReadingState state) {
    if (state is MeterReadingLoaded && state.latestReading != null) {
      final lastReadingDate = state.latestReading!.readingDate;
      final oneMonthFromLastReading = DateTime(
        lastReadingDate.year,
        lastReadingDate.month + 1,
        lastReadingDate.day,
      );

      final daysRemaining = oneMonthFromLastReading
          .difference(DateTime.now())
          .inDays;
      final canSubmitNow =
          DateTime.now().isAfter(oneMonthFromLastReading) ||
          DateTime.now().isAtSameMomentAs(oneMonthFromLastReading);

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: canSubmitNow
              ? Colors.green.withOpacity(0.1)
              : Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: canSubmitNow
                ? Colors.green.withOpacity(0.3)
                : Colors.orange.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: canSubmitNow
                    ? Colors.green.withOpacity(0.2)
                    : Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                canSubmitNow ? Icons.check_circle : Icons.schedule,
                color: canSubmitNow ? Colors.green : Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    canSubmitNow ? 'Ready to Submit' : 'Next Reading Available',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: canSubmitNow
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    canSubmitNow
                        ? 'You can submit a new meter reading now'
                        : 'Next submission allowed on: ${oneMonthFromLastReading.day}/${oneMonthFromLastReading.month}/${oneMonthFromLastReading.year}',
                    style: TextStyle(
                      fontSize: 14,
                      color: canSubmitNow
                          ? Colors.green.shade600
                          : Colors.orange.shade600,
                    ),
                  ),
                  if (!canSubmitNow && daysRemaining > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '$daysRemaining days remaining',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // If no readings exist, show that user can submit
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add_circle, color: Colors.green, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'First Reading',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'You can submit your first meter reading',
                  style: TextStyle(fontSize: 14, color: Colors.green),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitReadingForm(MeterReadingState state) {
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
          const Text(
            'Submit New Reading',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A3A5C),
            ),
          ),
          const SizedBox(height: 20),

          // Meter Type Dropdown
          const Text(
            'Meter Type',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A3A5C),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedMeterType,
                isExpanded: true,
                items: _meterTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedMeterType = newValue;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Reading Input
          const Text(
            'Meter Reading',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A3A5C),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _readingController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter current reading',
              suffixText: 'cubic meters',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF4A90E2)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Date Picker
          const Text(
            'Reading Date',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A3A5C),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Color(0xFF6B7280)),
                  const SizedBox(width: 12),
                  Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Photo Capture Section
          const Text(
            'Meter Photo (Required)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A3A5C),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _showPhotoOptions,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedPhoto != null
                      ? const Color(0xFF4A90E2)
                      : Colors.grey.withOpacity(0.3),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _selectedPhoto != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        _selectedPhoto!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          size: 48,
                          color: Colors.grey.withOpacity(0.6),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to take a photo of your meter',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Notes Input
          const Text(
            'Notes (Optional)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A3A5C),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add any notes about the reading...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF4A90E2)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Submit Button
          Builder(
            builder: (context) {
              final isLoading = state is MeterReadingLoading;
              bool canSubmit = true;
              String? submitButtonText = 'Submit Reading';
              Color buttonColor = const Color(0xFF4A90E2);

              // Check if photo is missing
              if (_selectedPhoto == null) {
                canSubmit = false;
                submitButtonText = 'Photo Required';
                buttonColor = Colors.grey;
              }

              // Check if user can submit reading (must be at least 1 month from last reading)
              if (state is MeterReadingLoaded && state.latestReading != null) {
                final lastReadingDate = state.latestReading!.readingDate;
                final oneMonthFromLastReading = DateTime(
                  lastReadingDate.year,
                  lastReadingDate.month + 1,
                  lastReadingDate.day,
                );

                if (DateTime.now().isBefore(oneMonthFromLastReading)) {
                  canSubmit = false;
                  final daysRemaining = oneMonthFromLastReading
                      .difference(DateTime.now())
                      .inDays;
                  submitButtonText = 'Next reading in $daysRemaining days';
                  buttonColor = Colors.grey;
                }
              }

              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (isLoading || !canSubmit) ? null : _submitReading,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          submitButtonText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReadingsSection(MeterReadingState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Readings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A3A5C),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
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
          child: state is MeterReadingLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : state is MeterReadingLoaded && state.readings.isNotEmpty
              ? Column(
                  children: state.readings.take(5).map((reading) {
                    final isLast =
                        state.readings.indexOf(reading) ==
                        state.readings.take(5).length - 1;
                    return Column(
                      children: [
                        _buildReadingItem(
                          reading: reading.readingValue.toStringAsFixed(0),
                          date:
                              '${reading.readingDate.day}/${reading.readingDate.month}/${reading.readingDate.year}',
                          status: reading.status,
                          statusColor: _getStatusColor(reading.status),
                        ),
                        if (!isLast) const Divider(height: 24),
                      ],
                    );
                  }).toList(),
                )
              : const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'No meter readings found',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 16),
                  ),
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
