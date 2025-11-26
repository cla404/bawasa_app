import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/meter_reading_repository.dart';
import '../consumer/profile_page.dart';
import '../sign_in.dart';
import 'meter_reader_submission_page.dart';
import 'meter_reader_history_page.dart';

class MeterReaderAccountMain extends StatefulWidget {
  const MeterReaderAccountMain({super.key});

  @override
  State<MeterReaderAccountMain> createState() => _MeterReaderAccountMainState();
}

class _MeterReaderAccountMainState extends State<MeterReaderAccountMain> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _recentActivities = [];
  bool _isLoadingActivities = false;
  int _pendingReadingsCount = 0;
  bool _isLoadingPendingCount = false;

  @override
  void initState() {
    super.initState();
    _loadRecentActivities();
    _loadPendingReadingsCount();
    // Refresh user status when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(RefreshUserStatusRequested());
    });
  }

  void _signOut() {
    context.read<AuthBloc>().add(SignOutRequested());
  }

  Future<void> _loadRecentActivities() async {
    setState(() {
      _isLoadingActivities = true;
    });

    try {
      final repository = GetIt.instance<MeterReadingRepository>();
      final completedReadings = await repository.getCompletedMeterReadings();

      // Limit to most recent 5 activities
      final recentReadings = (completedReadings.length > 5
          ? completedReadings.take(5).toList()
          : completedReadings);

      setState(() {
        _recentActivities = recentReadings;
        _isLoadingActivities = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingActivities = false;
      });
      print('Error loading recent activities: $e');
    }
  }

  Future<void> _loadPendingReadingsCount() async {
    setState(() {
      _isLoadingPendingCount = true;
    });

    try {
      final repository = GetIt.instance<MeterReadingRepository>();
      final pendingConsumers = await repository.getConsumersForMeterReader();

      setState(() {
        _pendingReadingsCount = pendingConsumers.length;
        _isLoadingPendingCount = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPendingCount = false;
      });
      print('Error loading pending readings count: $e');
    }
  }

  String _getTimeAgo(DateTime date) {
    // Show actual date and time instead of relative time
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final hour = date.hour;
    final minute = date.minute;
    final isPM = hour >= 12;
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    final minuteStr = minute.toString().padLeft(2, '0');

    return '${months[date.month - 1]} ${date.day}, ${date.year} ${displayHour}:${minuteStr} ${isPM ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    print('MeterReaderAccountMain: Building main page');
    print('MeterReaderAccountMain: Build timestamp: ${DateTime.now()}');

    // Check authentication state and handle accordingly
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        print(
          'MeterReaderAccountMain: Building with state ${state.runtimeType}',
        );

        if (state is! AuthAuthenticated) {
          print(
            'MeterReaderAccountMain: User not authenticated, showing loading',
          );
          // Force navigation back to sign in if user is not authenticated
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              print('MeterReaderAccountMain: Forcing navigation to sign in');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SignIn()),
              );
            }
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        print(
          'MeterReaderAccountMain: User authenticated, building main content',
        );

        return BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            print(
              'MeterReaderAccountMain: Auth state changed to ${state.runtimeType}',
            );
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is AuthAuthenticated) {
              // Check if status changed and show message
              final customUser = context
                  .read<AuthBloc>()
                  .getCurrentCustomUser();
              if (customUser != null && customUser.userType == 'meter_reader') {
                // Status will be checked in UI components, no need to show message here
                // as it might be annoying to show on every refresh
              }
            }
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFF5F7FA),
            body: _getCurrentPage(),
            bottomNavigationBar: _buildBottomNavigationBar(),
          ),
        );
      },
    );
  }

  Widget _getCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        return MeterReaderSubmissionPage(
          onBackToHome: () {
            setState(() {
              _selectedIndex = 0;
            });
          },
        );
      case 2:
        return MeterReaderHistoryPage(
          onBackToHome: () {
            setState(() {
              _selectedIndex = 0;
            });
          },
        );
      case 3:
        return ProfilePage(
          onBackToHome: () {
            setState(() {
              _selectedIndex = 0;
            });
          },
        );
      default:
        return _buildHomePage();
    }
  }

  Widget _buildHomePage() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeader(isTablet),
            SizedBox(height: isTablet ? 32 : 20),

            // User Info Card
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                User? user;
                if (state is AuthAuthenticated) {
                  user = state.user;
                }
                return _buildUserInfoCard(user, isTablet);
              },
            ),
            SizedBox(height: isTablet ? 32 : 24),

            // Pending Readings Count Card
            _buildPendingReadingsCard(isTablet),
            SizedBox(height: isTablet ? 32 : 24),

            // Quick Actions Section
            _buildQuickActionsSection(isTablet),
            SizedBox(height: isTablet ? 32 : 24),

            // Recent Activity Section
            _buildRecentActivitySection(isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isTablet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Meter Reader Dashboard',
          style: TextStyle(
            fontSize: isTablet ? 28 : 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A3A5C),
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfoCard(User? user, bool isTablet) {
    final displayName = user?.fullName ?? 'Meter Reader';
    final email = user?.email ?? 'No email';

    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isTablet ? 60 : 50,
            height: isTablet ? 60 : 50,
            decoration: BoxDecoration(
              color: const Color(0xFF2ECC71), // Green color for meter readers
              borderRadius: BorderRadius.circular(isTablet ? 30 : 25),
            ),
            child: Icon(
              Icons.speed,
              color: Colors.white,
              size: isTablet ? 30 : 24,
            ),
          ),
          SizedBox(width: isTablet ? 20 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: isTablet ? 22 : 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A3A5C),
                  ),
                ),
                SizedBox(height: isTablet ? 6 : 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                SizedBox(height: isTablet ? 6 : 4),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 12 : 8,
                    vertical: isTablet ? 4 : 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ECC71).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Meter Reader',
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      color: const Color(0xFF2ECC71),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _signOut,
            icon: Icon(
              Icons.logout,
              color: const Color(0xFF6B7280),
              size: isTablet ? 28 : 24,
            ),
            tooltip: 'Sign Out',
          ),
        ],
      ),
    );
  }

  Widget _buildPendingReadingsCard(bool isTablet) {
    return GestureDetector(
      onTap: () {
        // Navigate to submission page when tapped
        setState(() {
          _selectedIndex = 1;
        });
      },
      child: Container(
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF2ECC71).withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2ECC71).withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: isTablet ? 64 : 56,
              height: isTablet ? 64 : 56,
              decoration: BoxDecoration(
                color: const Color(0xFF2ECC71).withOpacity(0.1),
                borderRadius: BorderRadius.circular(isTablet ? 32 : 28),
              ),
              child: Icon(
                Icons.assignment,
                color: const Color(0xFF2ECC71),
                size: isTablet ? 32 : 28,
              ),
            ),
            SizedBox(width: isTablet ? 20 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Readings Needed',
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  SizedBox(height: isTablet ? 8 : 6),
                  _isLoadingPendingCount
                      ? Row(
                          children: [
                            SizedBox(
                              width: isTablet ? 16 : 14,
                              height: isTablet ? 16 : 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  const Color(0xFF2ECC71),
                                ),
                              ),
                            ),
                            SizedBox(width: isTablet ? 8 : 6),
                            Text(
                              'Loading...',
                              style: TextStyle(
                                fontSize: isTablet ? 14 : 12,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$_pendingReadingsCount',
                              style: TextStyle(
                                fontSize: isTablet ? 36 : 32,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2ECC71),
                              ),
                            ),
                            SizedBox(width: isTablet ? 8 : 6),
                            Text(
                              _pendingReadingsCount == 1
                                  ? 'reading'
                                  : 'readings',
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 14,
                                color: const Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                  SizedBox(height: isTablet ? 8 : 6),
                  Row(
                    children: [
                      Text(
                        'Tap to submit readings',
                        style: TextStyle(
                          fontSize: isTablet ? 14 : 12,
                          color: const Color(0xFF2ECC71),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: isTablet ? 4 : 2),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: isTablet ? 14 : 12,
                        color: const Color(0xFF2ECC71),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: isTablet ? 24 : 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A3A5C),
          ),
        ),
        SizedBox(height: isTablet ? 24 : 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isTablet ? 3 : 2,
          crossAxisSpacing: isTablet ? 16 : 12,
          mainAxisSpacing: isTablet ? 16 : 12,
          childAspectRatio: 1.2,
          children: [
            _buildQuickActionCard(
              icon: Icons.speed,
              iconColor: const Color(0xFF2ECC71),
              title: 'Submit Reading',
              subtitle: 'Record meter reading',
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
              },
              isTablet: isTablet,
            ),
            _buildQuickActionCard(
              icon: Icons.history,
              iconColor: Colors.blue,
              title: 'Reading History',
              subtitle: 'View past readings',
              onTap: () {
                setState(() {
                  _selectedIndex = 2;
                });
              },
              isTablet: isTablet,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isTablet,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isTablet ? 60 : 50,
              height: isTablet ? 60 : 50,
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(isTablet ? 30 : 25),
              ),
              child: Icon(icon, color: Colors.white, size: isTablet ? 30 : 24),
            ),
            SizedBox(height: isTablet ? 16 : 12),
            Text(
              title,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A3A5C),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: isTablet ? 14 : 12,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: isTablet ? 24 : 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A3A5C),
          ),
        ),
        SizedBox(height: isTablet ? 24 : 16),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isTablet ? 24 : 16),
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
          child: _isLoadingActivities
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(isTablet ? 32.0 : 20.0),
                    child: CircularProgressIndicator(
                      strokeWidth: isTablet ? 3 : 2.5,
                    ),
                  ),
                )
              : _recentActivities.isEmpty
              ? Padding(
                  padding: EdgeInsets.all(isTablet ? 32.0 : 20.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.history,
                        size: isTablet ? 64 : 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: isTablet ? 16 : 12),
                      Text(
                        'No recent activity',
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your completed readings will appear here',
                        style: TextStyle(
                          fontSize: isTablet ? 14 : 12,
                          color: const Color(0xFF6B7280),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: _recentActivities.asMap().entries.map((entry) {
                    final index = entry.key;
                    final activity = entry.value;
                    final consumer =
                        activity['consumers'] as Map<String, dynamic>;
                    final account =
                        consumer['accounts'] as Map<String, dynamic>?;
                    final meterReadings =
                        activity['bawasa_meter_readings'] as List;

                    if (meterReadings.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final latestReading =
                        meterReadings[0] as Map<String, dynamic>;
                    final readingDate = DateTime.parse(
                      latestReading['created_at'],
                    );

                    return Column(
                      children: [
                        _buildActivityItem(
                          icon: Icons.speed,
                          iconColor: const Color(0xFF2ECC71),
                          title: 'Meter Reading Submitted',
                          subtitle:
                              '${account?['full_name'] ?? 'Unknown'} - ${latestReading['present_reading']?.toStringAsFixed(0) ?? '0'} m³',
                          time: _getTimeAgo(readingDate),
                          isTablet: isTablet,
                        ),
                        if (index < _recentActivities.length - 1)
                          const Divider(height: 24),
                      ],
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
    required bool isTablet,
  }) {
    return Row(
      children: [
        Container(
          width: isTablet ? 48 : 40,
          height: isTablet ? 48 : 40,
          decoration: BoxDecoration(
            color: iconColor,
            borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
          ),
          child: Icon(icon, color: Colors.white, size: isTablet ? 24 : 20),
        ),
        SizedBox(width: isTablet ? 16 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A3A5C),
                ),
              ),
              SizedBox(height: isTablet ? 4 : 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isTablet ? 14 : 12,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: isTablet ? 14 : 12,
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          // Refresh user status when navigating between tabs
          context.read<AuthBloc>().add(RefreshUserStatusRequested());
          // Refresh pending readings count when returning to home
          if (index == 0) {
            _loadPendingReadingsCount();
            _loadRecentActivities();
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF2ECC71), // Green for meter readers
        unselectedItemColor: const Color(0xFF6B7280),
        selectedLabelStyle: TextStyle(
          fontSize: isTablet ? 14 : 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: isTablet ? 14 : 12,
          fontWeight: FontWeight.normal,
        ),
        iconSize: isTablet ? 28 : 24,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: isTablet ? 28 : 24),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.speed, size: isTablet ? 28 : 24),
            label: 'Meter',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history, size: isTablet ? 28 : 24),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, size: isTablet ? 28 : 24),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
