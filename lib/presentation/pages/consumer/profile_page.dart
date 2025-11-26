import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../../domain/entities/user.dart';
import '../../../core/config/supabase_config.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback? onBackToHome;
  
  const ProfilePage({super.key, this.onBackToHome});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _isLoading = false;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _lastFetchedUserId;
  String? _originalName;
  String? _originalPhone;

  @override
  void initState() {
    super.initState();
    // Refresh user status when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(RefreshUserStatusRequested());
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }


  Future<void> _fetchAccountData(
    String userId, {
    bool forceRefresh = false,
  }) async {
    // Avoid fetching if already loading or if we've already fetched for this user (unless forcing refresh)
    if (_isLoading || (!forceRefresh && _lastFetchedUserId == userId)) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final accountResponse = await SupabaseConfig.client
          .from('accounts')
          .select('full_name, full_address, mobile_no, email')
          .eq('id', userId)
          .maybeSingle();

      if (accountResponse != null && mounted) {
        setState(() {
            _nameController.text = accountResponse['full_name'] ?? '';
            _emailController.text = accountResponse['email'] ?? '';
            _phoneController.text =
                accountResponse['mobile_no']?.toString() ?? '';
            _addressController.text = accountResponse['full_address'] ?? '';
          _lastFetchedUserId = userId;
          // Store original values for cancel functionality
          _originalName = accountResponse['full_name'] ?? '';
          _originalPhone = accountResponse['mobile_no']?.toString() ?? '';
        });
      }
    } catch (e) {
      print('❌ [ProfilePage] Error fetching account data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  void _signOut() {
    context.read<AuthBloc>().add(SignOutRequested());
  }

  bool _isSuspended() {
    final authBloc = context.read<AuthBloc>();
    final customUser = authBloc.getCurrentCustomUser();
    return customUser != null && 
        (customUser.userType == 'meter_reader' || customUser.userType == 'consumer') && 
        customUser.status?.toLowerCase() == 'suspended';
  }

  void _handleEdit() {
    if (_isSuspended()) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Your account has been suspended. You cannot edit your profile.'),
          backgroundColor: Colors.red,
      ),
    );
      return;
    }
    setState(() {
      _isEditing = true;
    });
  }

  void _handleCancel() {
    setState(() {
      _isEditing = false;
      // Restore original values
      if (_originalName != null) {
        _nameController.text = _originalName!;
      }
      if (_originalPhone != null) {
        _phoneController.text = _originalPhone!;
  }
    });
  }

  Future<void> _handleSave() async {
    // Check if consumer is suspended
    if (_isSuspended()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your account has been suspended. You cannot edit your profile.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authBloc = context.read<AuthBloc>();
    final authState = authBloc.state;
    String? userId;

    if (authState is AuthAuthenticated) {
      userId = authState.user.id;
    } else {
      final customUser = authBloc.getCurrentCustomUser();
      userId = customUser?.id;
    }

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to identify user. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Update only full_name and mobile_no
      final updates = <String, dynamic>{
        'full_name': _nameController.text.trim().isEmpty 
            ? null 
            : _nameController.text.trim(),
      };

      // Parse mobile_no as integer if not empty
      if (_phoneController.text.trim().isNotEmpty) {
        final phoneInt = int.tryParse(_phoneController.text.trim());
        if (phoneInt != null) {
          updates['mobile_no'] = phoneInt;
        } else {
          throw Exception('Invalid phone number format');
        }
      } else {
        updates['mobile_no'] = null;
      }

      final response = await SupabaseConfig.client
          .from('accounts')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      if (mounted) {
        // Update original values
        setState(() {
          _originalName = response['full_name'] ?? '';
          _originalPhone = response['mobile_no']?.toString() ?? '';
          _isEditing = false;
        });

        // Refresh user data
        await _fetchAccountData(userId, forceRefresh: true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ [ProfilePage] Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
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
          'Profile',
          style: TextStyle(
            color: Color(0xFF1A3A5C),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A3A5C)),
        actions: [
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final isSuspended = _isSuspended();
              
              if (_isEditing) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSaving)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else ...[
                      TextButton(
                        onPressed: _handleCancel,
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Color(0xFF1A3A5C)),
                        ),
                      ),
                      TextButton(
                        onPressed: _handleSave,
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            color: Color(0xFF4A90E2),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              }

              return IconButton(
                icon: Icon(
                  Icons.edit,
                  color: isSuspended ? Colors.grey : const Color(0xFF1A3A5C),
                ),
                onPressed: isSuspended ? null : _handleEdit,
                tooltip: isSuspended 
                    ? 'Cannot edit: Account suspended' 
                    : 'Edit Profile',
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Profile Header
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  User? user;
                  if (state is AuthAuthenticated) {
                    user = state.user;
                    // Fetch account data when user is authenticated
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (user != null) {
                        _fetchAccountData(user.id);
                      }
                    });
                  }
                  return _buildProfileHeader(user);
                },
              ),
              const SizedBox(height: 20),

              // Suspended Status Banner (for meter readers and consumers)
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final authBloc = context.read<AuthBloc>();
                  final customUser = authBloc.getCurrentCustomUser();
                  final isSuspended = customUser != null && 
                      (customUser.userType == 'meter_reader' || customUser.userType == 'consumer') && 
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
                          Icon(Icons.warning_amber_rounded, 
                            color: Colors.red.shade700, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your account has been suspended. Please contact the administrator for assistance.',
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

              // Profile Information
              _buildProfileInfoSection(),
              const SizedBox(height: 20),

              // App Settings
              _buildAppSettingsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(User? user) {
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
          // Profile Picture
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF4A90E2),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 16),

          // User Name
          Text(
            user?.fullName ?? 'User',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A3A5C),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // User Email
          Text(
            user?.email ?? 'No email',
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Member Since
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF4A90E2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Member since ${user?.createdAt?.year ?? DateTime.now().year}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A90E2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoSection() {
    final isSuspended = _isSuspended();
    
    // For all users (consumers and meter readers), name and phone can be edited when in edit mode
    // Suspended meter readers cannot edit
    final canEditName = _isEditing && !isSuspended;
    final canEditPhone = _isEditing && !isSuspended;

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
              const Icon(
                Icons.person_outline,
                color: Color(0xFF4A90E2),
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3A5C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Name Field
          _buildInfoField(
            label: 'Full Name',
            controller: _nameController,
            icon: Icons.person,
            enabled: canEditName,
          ),
          const SizedBox(height: 16),

          // Email Field
          _buildInfoField(
            label: 'Email',
            controller: _emailController,
            icon: Icons.email,
            enabled: false,
          ),
          const SizedBox(height: 16),

          // Phone Field
          _buildInfoField(
            label: 'Phone Number',
            controller: _phoneController,
            icon: Icons.phone,
            enabled: canEditPhone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),

          // Address Field
          _buildInfoField(
            label: 'Address',
            controller: _addressController,
            icon: Icons.location_on,
            enabled: false,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool enabled,
    TextInputType? keyboardType,
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
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 20),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
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
            filled: !enabled,
            fillColor: enabled ? null : Colors.grey.withOpacity(0.1),
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildAppSettingsSection() {
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
              const Icon(
                Icons.info_outline,
                color: Color(0xFF4A90E2),
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text(
                'App Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3A5C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildSettingItem(
            icon: Icons.info,
            title: 'About',
            subtitle: 'App version and information',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('About BAWASA'),
                  content: const Text(
                    'BAWASA Management System\nVersion 1.0.0\n\nBuilt with Flutter',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(height: 24),

          _buildSettingItem(
            icon: Icons.logout,
            title: 'Sign Out',
            subtitle: 'Sign out of your account',
            onTap: _signOut,
            textColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: textColor ?? const Color(0xFF6B7280), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor ?? const Color(0xFF1A3A5C),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: textColor ?? const Color(0xFF6B7280),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
