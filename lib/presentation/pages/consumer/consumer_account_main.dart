import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/recent_activity_bloc.dart';
import '../../bloc/consumption_bloc.dart';
import '../../widgets/consumption_chart.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/entities/recent_activity.dart';
import 'meter_reading_page.dart';
import 'billing_page.dart';
import 'issues_page.dart';
import 'profile_page.dart';
import '../sign_in.dart';

class ConsumerAccountMain extends StatefulWidget {
  const ConsumerAccountMain({super.key});

  @override
  State<ConsumerAccountMain> createState() => _ConsumerAccountMainState();
}

class _ConsumerAccountMainState extends State<ConsumerAccountMain> {
  int _selectedIndex = 0;

  void _signOut() {
    context.read<AuthBloc>().add(SignOutRequested());
  }

  @override
  Widget build(BuildContext context) {
    print('ConsumerAccountMain: Building main page');
    print('ConsumerAccountMain: Build timestamp: ${DateTime.now()}');

    // Check authentication state and handle accordingly
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        print('ConsumerAccountMain: Building with state ${state.runtimeType}');

        if (state is! AuthAuthenticated) {
          print('ConsumerAccountMain: User not authenticated, showing loading');
          // Force navigation back to sign in if user is not authenticated
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              print('ConsumerAccountMain: Forcing navigation to sign in');
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

        print('ConsumerAccountMain: User authenticated, building main content');
        return MultiBlocProvider(
          providers: [
            BlocProvider<RecentActivityBloc>(
              create: (context) {
                final bloc = RecentActivityBloc(
                  getRecentActivitiesUseCase: GetIt.instance(),
                );
                // Add event asynchronously to avoid race conditions
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (bloc.isClosed == false) {
                    bloc.add(const LoadRecentActivities());
                  }
                });
                return bloc;
              },
            ),
            BlocProvider<ConsumptionBloc>(
              create: (context) {
                final consumptionBloc = GetIt.instance<ConsumptionBloc>();
                // Add event asynchronously to avoid race conditions
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (consumptionBloc.isClosed == false) {
                    consumptionBloc.add(const LoadConsumptionData());
                  }
                });
                return consumptionBloc;
              },
            ),
          ],
          child: BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              print(
                'ConsumerAccountMain: Auth state changed to ${state.runtimeType}',
              );
              if (state is AuthError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Scaffold(
              backgroundColor: const Color(0xFFF5F7FA),
              body: _getCurrentPage(),
              bottomNavigationBar: _buildBottomNavigationBar(),
            ),
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
        return MeterReadingPage(
          onBackToHome: () {
            setState(() {
              _selectedIndex = 0;
            });
          },
        );
      case 2:
        return BillingPage(
          onBackToHome: () {
            setState(() {
              _selectedIndex = 0;
            });
          },
        );
      case 3:
        return IssuesPage(
          onBackToHome: () {
            setState(() {
              _selectedIndex = 0;
            });
          },
        );
      case 4:
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
            SizedBox(height: isTablet ? 24 : 20),

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

            // Consumption Chart Section
            BlocBuilder<ConsumptionBloc, ConsumptionState>(
              builder: (context, state) {
                return _buildConsumptionChartSection(isTablet);
              },
            ),
            SizedBox(height: isTablet ? 32 : 24),

            // Quick Actions Section
            _buildQuickActionsSection(isTablet, screenWidth),
            SizedBox(height: isTablet ? 32 : 24),

            // Recent Activity Section
            _buildRecentActivitySection(),
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
          'Welcome Back!',
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
    final displayName = user?.fullName ?? 'User';
    final email = user?.email ?? 'No email';

    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
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
      child: Row(
        children: [
          Container(
            width: isTablet ? 60 : 50,
            height: isTablet ? 60 : 50,
            decoration: BoxDecoration(
              color: const Color(0xFF4A90E2),
              borderRadius: BorderRadius.circular(isTablet ? 30 : 25),
            ),
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: isTablet ? 28 : 24,
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

  Widget _buildConsumptionChartSection(bool isTablet) {
    return BlocBuilder<ConsumptionBloc, ConsumptionState>(
      builder: (context, state) {
        if (state is ConsumptionLoading) {
          return Container(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
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
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading consumption data...',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is ConsumptionError) {
          return Container(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
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
                const SizedBox(height: 8),
                const Text(
                  'Failed to load consumption data',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3A5C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    context.read<ConsumptionBloc>().add(
                      const RefreshConsumptionData(),
                    );
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is ConsumptionLoaded) {
          return ConsumptionChart(meterReadings: state.meterReadings);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildQuickActionsSection(bool isTablet, double screenWidth) {
    final crossAxisCount = isTablet ? 3 : 2;
    final padding = isTablet ? 20.0 : 16.0;

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
        SizedBox(height: isTablet ? 20 : 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: isTablet ? 16 : 12,
          mainAxisSpacing: isTablet ? 16 : 12,
          childAspectRatio: isTablet ? 1.1 : 0.95,
          padding: EdgeInsets.all(padding),
          children: [
            _buildQuickActionCard(
              icon: Icons.speed,
              iconColor: Colors.green,
              title: 'Meter Readings',
              subtitle: 'Record meter reading',
              isTablet: isTablet,
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
              },
            ),
            _buildQuickActionCard(
              icon: Icons.receipt_long,
              iconColor: Colors.orange,
              title: 'View Bills',
              subtitle: 'Check billing history',
              isTablet: isTablet,
              onTap: () {
                setState(() {
                  _selectedIndex = 2;
                });
              },
            ),
            _buildQuickActionCard(
              icon: Icons.warning,
              iconColor: Colors.red,
              title: 'Report Issue',
              subtitle: 'Report problems',
              isTablet: isTablet,
              onTap: () {
                setState(() {
                  _selectedIndex = 3;
                });
              },
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
    required bool isTablet,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isTablet ? 56 : 48,
              height: isTablet ? 56 : 48,
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(isTablet ? 28 : 24),
              ),
              child: Icon(icon, color: Colors.white, size: isTablet ? 26 : 22),
            ),
            SizedBox(height: isTablet ? 10 : 8),
            Text(
              title,
              style: TextStyle(
                fontSize: isTablet ? 15 : 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A3A5C),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: isTablet ? 4 : 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: isTablet ? 13 : 11,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: isTablet ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A3A5C),
              ),
            ),
            TextButton(
              onPressed: () {
                context.read<RecentActivityBloc>().add(
                  const RefreshRecentActivities(),
                );
              },
              child: Text(
                'Refresh',
                style: TextStyle(
                  color: const Color(0xFF4A90E2),
                  fontSize: isTablet ? 16 : 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        BlocBuilder<RecentActivityBloc, RecentActivityState>(
          builder: (context, state) {
            if (state is RecentActivityLoading) {
              final isTablet = MediaQuery.of(context).size.width > 600;
              return Container(
                padding: EdgeInsets.all(isTablet ? 20 : 16),
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

            if (state is RecentActivityError) {
              final isTablet = MediaQuery.of(context).size.width > 600;
              return Container(
                padding: EdgeInsets.all(isTablet ? 20 : 16),
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
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Failed to load activities',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3A5C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.message,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        context.read<RecentActivityBloc>().add(
                          const LoadRecentActivities(),
                        );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is RecentActivityLoaded) {
              if (state.activities.isEmpty) {
                final isTablet = MediaQuery.of(context).size.width > 600;
                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isTablet ? 20 : 16),
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
                      const Icon(
                        Icons.history,
                        color: Color(0xFF6B7280),
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'No recent activity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A3A5C),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Your recent activities will appear here',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              final isTablet = MediaQuery.of(context).size.width > 600;
              return Container(
                padding: EdgeInsets.all(isTablet ? 20 : 16),
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
                    ...state.activities.asMap().entries.map((entry) {
                      final index = entry.key;
                      final activity = entry.value;
                      return Column(
                        children: [
                          _buildActivityItem(
                            icon: _getActivityIcon(activity.iconName),
                            iconColor: _getActivityColor(activity.type),
                            title: activity.title,
                            subtitle: activity.subtitle,
                            time: activity.timeAgo,
                            isTablet: screenWidth > 600,
                          ),
                          if (index < state.activities.length - 1)
                            const Divider(height: 24),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              );
            }

            final isTablet = MediaQuery.of(context).size.width > 600;
            return Container(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
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
          },
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
          width: isTablet ? 50 : 40,
          height: isTablet ? 50 : 40,
          decoration: BoxDecoration(
            color: iconColor,
            borderRadius: BorderRadius.circular(isTablet ? 25 : 20),
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

  IconData _getActivityIcon(String? iconName) {
    switch (iconName) {
      case 'speed':
        return Icons.speed;
      case 'receipt_long':
        return Icons.receipt_long;
      case 'warning':
        return Icons.warning;
      case 'email':
        return Icons.email;
      case 'check_circle':
        return Icons.check_circle;
      default:
        return Icons.history;
    }
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.meterReading:
        return Colors.green;
      case ActivityType.billGenerated:
        return Colors.orange;
      case ActivityType.billPaid:
        return Colors.blue;
      case ActivityType.issueReported:
        return Colors.red;
      case ActivityType.issueResolved:
        return Colors.purple;
    }
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
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF4A90E2),
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
            icon: Icon(Icons.receipt_long, size: isTablet ? 28 : 24),
            label: 'Billing',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning, size: isTablet ? 28 : 24),
            label: 'Issues',
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
