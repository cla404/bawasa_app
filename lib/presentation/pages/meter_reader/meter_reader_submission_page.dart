import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../../domain/entities/consumer.dart';
import '../../../services/camera_service.dart';
import 'dart:io';

class MeterReaderSubmissionPage extends StatefulWidget {
  const MeterReaderSubmissionPage({super.key});

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
  List<Consumer> _consumers = [];

  @override
  void initState() {
    super.initState();
    _loadConsumers();
  }

  @override
  void dispose() {
    _previousReadingController.dispose();
    _presentReadingController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadConsumers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement actual consumer loading from repository
      // For now, using mock data
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _consumers = [
          Consumer(
            id: '1',
            waterMeterNo: 'WM001',
            fullName: 'John Doe',
            fullAddress: '123 Main St, City',
            phone: '09123456789',
            email: 'john@example.com',
            previousReading: 1000.0,
            currentReading: 1050.0,
            consumptionCubicMeters: 50.0,
            amountCurrentBilling: 500.0,
            billingMonth: 'January 2024',
            meterReadingDate: '2024-01-15',
            dueDate: '2024-02-15',
            status: 'Pending',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Consumer(
            id: '2',
            waterMeterNo: 'WM002',
            fullName: 'Jane Smith',
            fullAddress: '456 Oak Ave, City',
            phone: '09987654321',
            email: 'jane@example.com',
            previousReading: 2000.0,
            currentReading: 2100.0,
            consumptionCubicMeters: 100.0,
            amountCurrentBilling: 1000.0,
            billingMonth: 'January 2024',
            meterReadingDate: '2024-01-15',
            dueDate: '2024-02-15',
            status: 'Pending',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
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

  void _selectConsumer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
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
              Expanded(
                child: ListView.builder(
                  itemCount: _consumers.length,
                  itemBuilder: (context, index) {
                    final consumer = _consumers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF2ECC71),
                          child: Text(
                            consumer.waterMeterNo.substring(2),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          consumer.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A3A5C),
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Meter: ${consumer.waterMeterNo}'),
                            Text('Address: ${consumer.fullAddress}'),
                            Text(
                              'Current Reading: ${consumer.currentReading.toStringAsFixed(0)}',
                            ),
                          ],
                        ),
                        onTap: () {
                          setState(() {
                            _selectedConsumer = consumer;
                            _previousReadingController.text = consumer
                                .currentReading
                                .toStringAsFixed(0);
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
  }

  void _submitReading() {
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

    // TODO: Implement actual submission using repository
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
              onTap: _selectConsumer,
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
                      CircleAvatar(
                        backgroundColor: const Color(0xFF2ECC71),
                        child: Text(
                          _selectedConsumer!.waterMeterNo.substring(2),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
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
                        onPressed: _selectConsumer,
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitReading,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2ECC71),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Submit Meter Reading',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
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
