import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../../domain/entities/consumer.dart';
import '../../../services/camera_service.dart';
import '../../../domain/usecases/meter_reader_usecases.dart';
import '../../../core/config/supabase_config.dart';
import 'package:get_it/get_it.dart';
import 'dart:io';

class MeterReaderSubmissionPage extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const MeterReaderSubmissionPage({super.key, this.onBackToHome});

  @override
  State<MeterReaderSubmissionPage> createState() =>
      _MeterReaderSubmissionPageState();
}

class _MeterReaderSubmissionPageState extends State<MeterReaderSubmissionPage> {
  final TextEditingController _previousReadingController =
      TextEditingController();
  final TextEditingController _presentReadingController =
      TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final CameraService _cameraService = CameraService();

  Consumer? _selectedConsumer;
  File? _selectedPhoto;
  bool _isLoading = false;
  bool _isSubmitting = false;
  List<Consumer> _consumers = [];
  final TextEditingController _searchController = TextEditingController();
  List<Consumer> _filteredConsumers = [];

  @override
  void initState() {
    super.initState();
    _loadConsumers();
    // Refresh user status when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(RefreshUserStatusRequested());
    });
  }

  @override
  void dispose() {
    _previousReadingController.dispose();
    _presentReadingController.dispose();
    _remarksController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConsumers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch actual consumers from repository
      final getConsumersUseCase = GetConsumersForMeterReaderUseCase(
        GetIt.instance(),
      );
      final consumers = await getConsumersUseCase();

      setState(() {
        _consumers = consumers;
        _filteredConsumers = consumers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading consumers: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchLatestReadingForConsumer(
    String consumerId,
    Consumer consumer,
  ) async {
    try {
      // Fetch the latest meter reading for this consumer (including remarks to check for meter change)
      final response = await SupabaseConfig.client
          .from('bawasa_meter_readings')
          .select('present_reading, remarks')
          .eq('consumer_id', consumerId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null && response['present_reading'] != null) {
        // Check if the meter was changed - if so, start from 0
        final remarks = response['remarks'] as String? ?? '';
        final meterWasChanged = remarks.contains('[METER_CHANGED]');
        
        if (meterWasChanged) {
          // Meter was changed, new meter starts from 0
          print('🔄 [MeterReader] Meter was changed for consumer $consumerId - starting from 0');
          setState(() {
            _previousReadingController.text = '0';
          });
        } else {
          // Normal case - use the last present reading
        final latestReading = (response['present_reading'] as num).toDouble();
        setState(() {
          _previousReadingController.text = latestReading.toStringAsFixed(0);
        });
        }
      } else {
        // No previous readings found, use the consumer's current reading or 0
        setState(() {
          _previousReadingController.text = consumer.currentReading
              .toStringAsFixed(0);
        });
      }
    } catch (e) {
      print('Error fetching latest reading: $e');
      // Fallback to consumer's current reading if fetch fails
      setState(() {
        _previousReadingController.text = consumer.currentReading
            .toStringAsFixed(0);
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

  Future<void> _selectConsumer() async {
    // Check if meter reader is suspended
    final authBloc = context.read<AuthBloc>();
    final customUser = authBloc.getCurrentCustomUser();
    if (customUser != null &&
        customUser.userType == 'meter_reader' &&
        customUser.status?.toLowerCase() == 'suspended') {
      // Show dialog indicating they are suspended
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red.shade700,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Account Suspended',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A3A5C),
                    ),
                  ),
                ),
              ],
            ),
            content: const Text(
              'Your account has been suspended. You cannot submit new meter readings or select consumers.\n\nPlease contact the administrator for assistance.',
              style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A90E2),
                  ),
                ),
              ),
            ],
          );
        },
      );
      return;
    }

    // Reset search when opening modal
    _searchController.clear();
    _filteredConsumers = List.from(_consumers);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            String _searchQuery = '';

            void _filterConsumers(String query) {
              _searchQuery = query;
              setModalState(() {
                if (query.isEmpty) {
                  _filteredConsumers = List.from(_consumers);
                } else {
                  _filteredConsumers = _consumers.where((consumer) {
                    final name = consumer.fullName.toLowerCase();
                    final meter = consumer.waterMeterNo.toLowerCase();
                    final address = consumer.fullAddress.toLowerCase();
                    final searchLower = query.toLowerCase();
                    return name.contains(searchLower) ||
                        meter.contains(searchLower) ||
                        address.contains(searchLower);
                  }).toList();
                }
              });
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Consumer',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A3A5C),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name, meter number, or address...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF6B7280),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Color(0xFF6B7280),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setModalState(() {
                                  _filterConsumers('');
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF4A90E2)),
                      ),
                      filled: true,
                      fillColor: Colors.grey.withOpacity(0.1),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setModalState(() {
                        _filterConsumers(value);
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _filteredConsumers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _searchQuery.isNotEmpty
                                      ? Icons.search_off
                                      : Icons.person_off,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'No consumers found'
                                      : 'No consumers available',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A3A5C),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                  ),
                                  child: Text(
                                    _searchQuery.isNotEmpty
                                        ? 'Try adjusting your search terms'
                                        : 'You have completed all meter readings for this month.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    if (_searchQuery.isNotEmpty) {
                                      _searchController.clear();
                                      setModalState(() {
                                        _filterConsumers('');
                                      });
                                    } else {
                                      Navigator.of(context).pop();
                                    }
                                  },
                                  icon: Icon(
                                    _searchQuery.isNotEmpty
                                        ? Icons.clear
                                        : Icons.arrow_back,
                                  ),
                                  label: Text(
                                    _searchQuery.isNotEmpty
                                        ? 'Clear Search'
                                        : 'Go Back',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4A90E2),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredConsumers.length,
                            itemBuilder: (context, index) {
                              final consumer = _filteredConsumers[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(
                                    consumer.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A3A5C),
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Meter: ${consumer.waterMeterNo}'),
                                      Text('Address: ${consumer.fullAddress}'),
                                      Text(
                                        'Current Reading: ${consumer.currentReading.toStringAsFixed(0)}',
                                      ),
                                    ],
                                  ),
                                  onTap: () async {
                                    // Fetch the latest meter reading for this consumer
                                    await _fetchLatestReadingForConsumer(
                                      consumer.id,
                                      consumer,
                                    );
                                    setState(() {
                                      _selectedConsumer = consumer;
                                      // Clear present reading and remarks when selecting a new consumer
                                      _presentReadingController.clear();
                                      _remarksController.clear();
                                      _selectedPhoto = null;
                                    });
                                    Navigator.of(context).pop();
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitReading() async {
    // Check if meter reader is suspended
    final authBloc = context.read<AuthBloc>();
    final customUser = authBloc.getCurrentCustomUser();
    if (customUser != null &&
        customUser.userType == 'meter_reader' &&
        customUser.status?.toLowerCase() == 'suspended') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your account has been suspended. You cannot submit new meter readings. Please contact the administrator for assistance.',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    if (_selectedConsumer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a consumer'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_previousReadingController.text.isEmpty ||
        _presentReadingController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both previous and present readings'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final previousReading = double.tryParse(_previousReadingController.text);
    final presentReading = double.tryParse(_presentReadingController.text);

    if (previousReading == null || presentReading == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid meter readings'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (presentReading <= previousReading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Present reading must be greater than previous reading',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please take a photo of the meter reading'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Submit the meter reading
      final submitUseCase = SubmitMeterReadingForConsumerUseCase(
        GetIt.instance(),
      );

      await submitUseCase.call(
        consumerId: _selectedConsumer!.id,
        previousReading: previousReading,
        presentReading: presentReading,
        remarks: _remarksController.text.isEmpty
            ? null
            : _remarksController.text,
        meterImageFile: _selectedPhoto,
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meter reading submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form
      setState(() {
        _selectedConsumer = null;
        _selectedPhoto = null;
      });
      _previousReadingController.clear();
      _presentReadingController.clear();
      _remarksController.clear();

      // Reload consumers to show updated information
      await _loadConsumers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting meter reading: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF1A3A5C)),
              onPressed: () {
                if (widget.onBackToHome != null) {
                  widget.onBackToHome!();
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
            title: const Text(
              'Submit Meter Reading',
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
                  // Suspended Status Banner
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final authBloc = context.read<AuthBloc>();
                      final customUser = authBloc.getCurrentCustomUser();
                      final isSuspended =
                          customUser != null &&
                          customUser.userType == 'meter_reader' &&
                          customUser.status?.toLowerCase() == 'suspended';

                      if (isSuspended) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red.shade700,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Your account has been suspended. You cannot submit new meter readings.',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Consumer Selection Card
                  _buildConsumerSelectionCard(),
                  const SizedBox(height: 24),

                  // Meter Reading Form Card
                  if (_selectedConsumer != null) _buildMeterReadingFormCard(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConsumerSelectionCard() {
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
                  color: const Color(0xFF2ECC71).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF2ECC71),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Select Consumer',
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
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_selectedConsumer == null)
            GestureDetector(
              onTap: () => _selectConsumer(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF2ECC71),
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF2ECC71).withOpacity(0.05),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.add, color: Color(0xFF2ECC71), size: 32),
                    SizedBox(height: 8),
                    Text(
                      'Tap to Select Consumer',
                      style: TextStyle(
                        color: Color(0xFF2ECC71),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2ECC71).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2ECC71)),
              ),
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
                              _selectedConsumer!.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF1A3A5C),
                              ),
                            ),
                            Text(
                              'Meter: ${_selectedConsumer!.waterMeterNo}',
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          await _selectConsumer();
                        },
                        icon: const Icon(Icons.edit, color: Color(0xFF2ECC71)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Address: ${_selectedConsumer!.fullAddress}',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Current Reading: ${_selectedConsumer!.currentReading.toStringAsFixed(0)} cubic meters',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMeterReadingFormCard() {
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
                  'Meter Reading Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3A5C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Previous Reading
          _buildInputField(
            label: 'Previous Reading (cubic meters)',
            controller: _previousReadingController,
            keyboardType: TextInputType.number,
            icon: Icons.history,
          ),
          const SizedBox(height: 16),

          // Present Reading
          _buildInputField(
            label: 'Present Reading (cubic meters)',
            controller: _presentReadingController,
            keyboardType: TextInputType.number,
            icon: Icons.speed,
          ),
          const SizedBox(height: 16),

          // Consumption Display
          if (_previousReadingController.text.isNotEmpty &&
              _presentReadingController.text.isNotEmpty)
            _buildConsumptionDisplay(),
          const SizedBox(height: 16),

          // Remarks
          _buildInputField(
            label: 'Remarks (Optional)',
            controller: _remarksController,
            keyboardType: TextInputType.multiline,
            maxLines: 3,
            icon: Icons.note,
          ),
          const SizedBox(height: 24),

          // Photo Section
          _buildPhotoSection(),
          const SizedBox(height: 24),

          // Submit Button
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final authBloc = context.read<AuthBloc>();
              final customUser = authBloc.getCurrentCustomUser();
              final isSuspended =
                  customUser != null &&
                  customUser.userType == 'meter_reader' &&
                  customUser.status?.toLowerCase() == 'suspended';

              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isSubmitting || isSuspended)
                      ? null
                      : _submitReading,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuspended
                        ? Colors.grey
                        : const Color(0xFF2ECC71),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Submitting...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          isSuspended
                              ? 'Account Suspended - Cannot Submit'
                              : 'Submit Meter Reading',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A3A5C),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF4A90E2)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4A90E2)),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
          ),
          onChanged: (value) {
            setState(() {}); // Trigger rebuild to show consumption
          },
        ),
      ],
    );
  }

  Widget _buildConsumptionDisplay() {
    final previousReading =
        double.tryParse(_previousReadingController.text) ?? 0;
    final presentReading = double.tryParse(_presentReadingController.text) ?? 0;
    final consumption = presentReading - previousReading;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4A90E2).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4A90E2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calculate, color: Color(0xFF4A90E2), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Consumption',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
                Text(
                  '${consumption.toStringAsFixed(0)} cubic meters',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A90E2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Meter Photo',
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
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(
                color: _selectedPhoto != null
                    ? const Color(0xFF2ECC71)
                    : const Color(0xFFE5E7EB),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
              color: _selectedPhoto != null ? null : const Color(0xFFF9FAFB),
            ),
            child: _selectedPhoto != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(_selectedPhoto!, fit: BoxFit.cover),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        color: Color(0xFF6B7280),
                        size: 48,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap to add meter photo',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
