import 'dart:io';
import 'package:flutter/material.dart';
import '../../../services/camera_service.dart';
import '../../../services/photo_upload_service.dart';
import '../../../core/injection/injection_container.dart';
import '../../../domain/entities/issue_report.dart';
import '../../../domain/usecases/submit_issue_report.dart';
import '../../../domain/usecases/get_issue_reports_by_consumer_id.dart';
import '../../../domain/repositories/consumer_repository.dart';
import '../../../domain/repositories/auth_repository.dart';

class IssuesPage extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const IssuesPage({super.key, this.onBackToHome});

  @override
  State<IssuesPage> createState() => _IssuesPageState();
}

class _IssuesPageState extends State<IssuesPage> {
  final TextEditingController _issueController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedIssueType = 'Water Leak';
  String _selectedPriority = 'Medium';

  // Image upload state
  final List<File> _selectedImages = [];
  final CameraService _cameraService = CameraService();
  final PhotoUploadService _photoUploadService = PhotoUploadService();
  bool _isSubmitting = false;
  int _uploadProgress = 0;
  int _totalImages = 0;

  // Repository and use case
  late final SubmitIssueReport _submitIssueReportUseCase;
  late final GetIssueReportsByConsumerIdUseCase
  _getIssueReportsByConsumerIdUseCase;

  // Recent issues state
  List<IssueReport> _recentIssues = [];
  bool _isLoadingRecentIssues = false;
  String? _recentIssuesError;

  final List<String> _issueTypes = [
    'Water Leak',
    'Low Water Pressure',
    'Water Quality Issue',
    'Billing Dispute',
    'Meter Problem',
    'Service Interruption',
    'Other',
  ];

  final List<String> _priorities = ['Low', 'Medium', 'High', 'Urgent'];

  @override
  void initState() {
    super.initState();
    _submitIssueReportUseCase = sl<SubmitIssueReport>();
    _getIssueReportsByConsumerIdUseCase =
        sl<GetIssueReportsByConsumerIdUseCase>();
    _loadRecentIssues();
  }

  @override
  void dispose() {
    _issueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Image picker methods
  Future<void> _pickImageFromGallery() async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already selected 5 images'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final File? image = await _cameraService.pickPhotoFromGallery();
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      String errorMessage = 'Error picking image';
      if (e.toString().contains('permission') ||
          e.toString().contains('denied')) {
        errorMessage =
            'Photo library permission denied. Please enable photo library access in Settings.';
      } else {
        errorMessage = 'Error picking image: ${e.toString()}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already selected 5 images'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final File? image = await _cameraService.pickPhotoFromCamera();
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      String errorMessage = 'Error taking photo';
      if (e.toString().contains('permission') ||
          e.toString().contains('denied')) {
        errorMessage =
            'Camera permission denied. Please enable camera access in Settings.';
      } else if (e.toString().contains('not available')) {
        errorMessage = 'Camera is not available on this device.';
      } else {
        errorMessage = 'Error taking photo: ${e.toString()}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Load recent issues for the current consumer
  Future<void> _loadRecentIssues() async {
    setState(() {
      _isLoadingRecentIssues = true;
      _recentIssuesError = null;
    });

    try {
      // Get current consumer
      final consumerRepository = sl<ConsumerRepository>();
      final authRepository = sl<AuthRepository>();
      final currentUser = authRepository.getCurrentUser();

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final consumer = await consumerRepository.getConsumerByUserId(
        currentUser.id,
      );
      if (consumer == null) {
        throw Exception('Consumer profile not found');
      }

      // Fetch recent issues
      final issues = await _getIssueReportsByConsumerIdUseCase(consumer.id);

      if (mounted) {
        setState(() {
          _recentIssues = issues;
          _isLoadingRecentIssues = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _recentIssuesError = e.toString();
          _isLoadingRecentIssues = false;
        });
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitIssue() async {
    if (_issueController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedImages.length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please attach exactly 5 images. Currently attached: ${_selectedImages.length}',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _uploadProgress = 0;
      _totalImages = _selectedImages.length;
    });

    try {
      // Get consumer ID once to avoid repeated database calls
      final consumerRepository = sl<ConsumerRepository>();
      final authRepository = sl<AuthRepository>();
      final currentUser = authRepository.getCurrentUser();

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final consumer = await consumerRepository.getConsumerByUserId(
        currentUser.id,
      );
      if (consumer == null) {
        throw Exception('Consumer profile not found');
      }

      // Upload images in parallel for much faster performance
      List<String> uploadedImageUrls = [];
      if (_selectedImages.isNotEmpty) {
        // Create futures for parallel uploads
        final uploadFutures = _selectedImages.map((image) async {
          final imageUrl = await _photoUploadService
              .uploadIssuePhotoWithConsumerId(image, consumer.id);

          // Update progress
          setState(() {
            _uploadProgress++;
          });

          return imageUrl;
        }).toList();

        // Wait for all uploads to complete
        uploadedImageUrls = await Future.wait(uploadFutures);
      }

      // Create issue report entity
      final issueReport = IssueReport(
        issueType: _selectedIssueType,
        priority: _selectedPriority,
        issueTitle: _issueController.text,
        description: _descriptionController.text,
        issueImages: uploadedImageUrls,
      );

      // Submit issue report to database
      final submittedIssue = await _submitIssueReportUseCase(issueReport);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Issue reported successfully! ${uploadedImageUrls.length} image(s) uploaded. Issue ID: ${submittedIssue.id}. We will contact you soon.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      // Clear form
      _issueController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedIssueType = 'Water Leak';
        _selectedPriority = 'Medium';
        _selectedImages.clear();
      });

      // Refresh recent issues to show the newly submitted issue
      await _loadRecentIssues();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting issue: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _uploadProgress = 0;
          _totalImages = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Report Issues',
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
              // Emergency Contact Card

              // Report Issue Form
              _buildReportIssueForm(),
              const SizedBox(height: 24),

              // Recent Issues
              _buildRecentIssuesSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportIssueForm() {
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
            'Report New Issue',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A3A5C),
            ),
          ),
          const SizedBox(height: 20),

          // Issue Type Dropdown
          const Text(
            'Issue Type',
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
                value: _selectedIssueType,
                isExpanded: true,
                items: _issueTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedIssueType = newValue;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Priority Dropdown
          const Text(
            'Priority',
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
                value: _selectedPriority,
                isExpanded: true,
                items: _priorities.map((String priority) {
                  return DropdownMenuItem<String>(
                    value: priority,
                    child: Text(priority),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedPriority = newValue;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Issue Title Input
          const Text(
            'Issue Title',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A3A5C),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _issueController,
            decoration: InputDecoration(
              hintText: 'Brief description of the issue',
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

          // Description Input
          const Text(
            'Detailed Description',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A3A5C),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText:
                  'Please provide detailed information about the issue...',
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

          // Image Upload Section
          _buildImageUploadSection(),
          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_isSubmitting || _selectedImages.length != 5)
                  ? null
                  : _submitIssue,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Submitting Issue Report...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        if (_totalImages > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Uploading images: $_uploadProgress/$_totalImages',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: _totalImages > 0
                                ? _uploadProgress / _totalImages
                                : 0,
                            backgroundColor: Colors.white30,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ],
                      ],
                    )
                  : Text(
                      _selectedImages.length == 5
                          ? 'Submit Issue Report'
                          : 'Submit Issue Report (${_selectedImages.length}/5 images)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _selectedImages.length == 5
                            ? Colors.white
                            : Colors.white70,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attach Images (Required)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A3A5C),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add exactly 5 images to help describe the issue',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),

        // Add Image Button
        if (_selectedImages.length < 5)
          GestureDetector(
            onTap: _showImageSourceDialog,
            child: Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF4A90E2),
                  style: BorderStyle.solid,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF4A90E2).withOpacity(0.05),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    color: Color(0xFF4A90E2),
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Add Image',
                    style: TextStyle(
                      color: Color(0xFF4A90E2),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 12),

        // Selected Images Grid
        if (_selectedImages.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _selectedImages[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

        const SizedBox(height: 12),

        // Progress indicator
        Row(
          children: [
            Text(
              'Images: ${_selectedImages.length}/5',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _selectedImages.length == 5
                    ? Colors.green
                    : Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: LinearProgressIndicator(
                value: _selectedImages.length / 5,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _selectedImages.length == 5 ? Colors.green : Colors.orange,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentIssuesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Issues',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A3A5C),
              ),
            ),
            if (_recentIssuesError != null || _recentIssues.isNotEmpty)
              IconButton(
                onPressed: _loadRecentIssues,
                icon: const Icon(Icons.refresh, color: Color(0xFF4A90E2)),
                tooltip: 'Refresh',
              ),
          ],
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
          child: _buildRecentIssuesContent(),
        ),
      ],
    );
  }

  Widget _buildRecentIssuesContent() {
    if (_isLoadingRecentIssues) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            children: [
              CircularProgressIndicator(color: Color(0xFF4A90E2)),
              SizedBox(height: 12),
              Text(
                'Loading recent issues...',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      );
    }

    if (_recentIssuesError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(
                'Failed to load recent issues',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A3A5C),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _recentIssuesError!,
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadRecentIssues,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_recentIssues.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Icon(
                Icons.inbox_outlined,
                color: Color(0xFF6B7280),
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text(
                'No issues reported yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A3A5C),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your reported issues will appear here',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < _recentIssues.length; i++) ...[
          _buildIssueItemFromData(_recentIssues[i]),
          if (i < _recentIssues.length - 1) const Divider(height: 24),
        ],
      ],
    );
  }

  Widget _buildIssueItemFromData(IssueReport issue) {
    // Determine status and color based on issue data
    // Since the IssueReport entity doesn't have a status field, we'll use a default
    String status = 'Pending'; // Default status
    Color statusColor = Colors.orange; // Default color for pending

    // Format the date
    String formattedDate = 'Unknown date';
    if (issue.createdAt != null) {
      formattedDate = _formatDate(issue.createdAt!);
    }

    return _buildIssueItem(
      title: issue.issueTitle ?? 'Untitled Issue',
      date: formattedDate,
      status: status,
      statusColor: statusColor,
      priority: issue.priority ?? 'Unknown',
      issueType: issue.issueType ?? 'Unknown',
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildIssueItem({
    required String title,
    required String date,
    required String status,
    required Color statusColor,
    required String priority,
    String? issueType,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.warning, color: Colors.red, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3A5C),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Reported: $date',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 2),
              Text(
                'Priority: $priority',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              if (issueType != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Type: $issueType',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
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
