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
import '../../../domain/usecases/billing_usecases.dart';
import '../../../domain/entities/billing.dart';
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

  @override
  void initState() {
    super.initState();
    // Refresh user status on page load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthBloc>().add(RefreshUserStatusRequested());
      }
    });
  }

  void _signOut() {
    context.read<AuthBloc>().add(SignOutRequested());
  }

  bool _isSuspended() {
    final authBloc = context.read<AuthBloc>();
    final customUser = authBloc.getCurrentCustomUser();
    return customUser != null &&
        customUser.userType == 'consumer' &&
        customUser.status?.toLowerCase() == 'suspended';
  }

  Widget _buildSuspendedBanner(bool isTablet) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final authBloc = context.read<AuthBloc>();
        final customUser = authBloc.getCurrentCustomUser();
        final isSuspended =
            customUser != null &&
            customUser.userType == 'consumer' &&
            customUser.status?.toLowerCase() == 'suspended';

        if (!isSuspended) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade300, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red.shade700,
                size: isTablet ? 28 : 24,
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: Text(
                  'Your account has been suspended. Please contact the administrator for assistance.',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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

            // Suspended Status Banner
            _buildSuspendedBanner(isTablet),
            if (_isSuspended()) SizedBox(height: isTablet ? 24 : 20),

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

            // Current Unpaid Bill Section
            _buildCurrentUnpaidBillSection(isTablet),
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

  Widget _buildCurrentUnpaidBillSection(bool isTablet) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const SizedBox.shrink();
        }

        final customUser = context.read<AuthBloc>().getCurrentCustomUser();
        final waterMeterNo = customUser?.waterMeterNo;

        if (waterMeterNo == null || waterMeterNo.isEmpty) {
          return const SizedBox.shrink();
        }

        return FutureBuilder<Billing?>(
          future: GetIt.instance<GetCurrentBill>().call(waterMeterNo),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
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

            if (snapshot.hasError) {
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
                    Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: isTablet ? 24 : 20,
                    ),
                    SizedBox(width: isTablet ? 12 : 8),
                    Expanded(
                      child: Text(
                        'Failed to load current bill',
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final currentBill = snapshot.data;

            if (currentBill == null) {
              // No unpaid bill
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
                      width: isTablet ? 48 : 40,
                      height: isTablet ? 48 : 40,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: isTablet ? 24 : 20,
                      ),
                    ),
                    SizedBox(width: isTablet ? 16 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'All Paid',
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A3A5C),
                            ),
                          ),
                          SizedBox(height: isTablet ? 4 : 2),
                          Text(
                            'You have no unpaid bills',
                            style: TextStyle(
                              fontSize: isTablet ? 14 : 12,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            // Display current unpaid bill
            final isOverdue = currentBill.isOverdue;
            final statusColor = isOverdue ? Colors.red : Colors.orange;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = 2; // Navigate to billing page
                });
              },
              child: Container(
                padding: EdgeInsets.all(isTablet ? 20 : 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: statusColor.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.1),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: isTablet ? 48 : 40,
                              height: isTablet ? 48 : 40,
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(
                                  isTablet ? 24 : 20,
                                ),
                              ),
                              child: Icon(
                                Icons.receipt_long,
                                color: statusColor,
                                size: isTablet ? 24 : 20,
                              ),
                            ),
                            SizedBox(width: isTablet ? 16 : 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Bill',
                                  style: TextStyle(
                                    fontSize: isTablet ? 18 : 16,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1A3A5C),
                                  ),
                                ),
                                SizedBox(height: isTablet ? 4 : 2),
                                Text(
                                  currentBill.billingMonth,
                                  style: TextStyle(
                                    fontSize: isTablet ? 14 : 12,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 12 : 10,
                            vertical: isTablet ? 6 : 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isOverdue
                                ? 'OVERDUE'
                                : currentBill.paymentStatus.toUpperCase(),
                            style: TextStyle(
                              fontSize: isTablet ? 12 : 10,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isTablet ? 16 : 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Amount Due',
                              style: TextStyle(
                                fontSize: isTablet ? 14 : 12,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            SizedBox(height: isTablet ? 4 : 2),
                            Text(
                              currentBill.formattedAmount,
                              style: TextStyle(
                                fontSize: isTablet ? 24 : 20,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Due Date',
                              style: TextStyle(
                                fontSize: isTablet ? 14 : 12,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            SizedBox(height: isTablet ? 4 : 2),
                            Text(
                              currentBill.formattedDueDate,
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 14,
                                fontWeight: FontWeight.w600,
                                color: isOverdue
                                    ? Colors.red
                                    : const Color(0xFF1A3A5C),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (currentBill.isPartiallyPaid) ...[
                      SizedBox(height: isTablet ? 12 : 8),
                      Container(
                        padding: EdgeInsets.all(isTablet ? 12 : 10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue,
                              size: isTablet ? 20 : 18,
                            ),
                            SizedBox(width: isTablet ? 8 : 6),
                            Expanded(
                              child: Text(
                                'Partially paid: ₱${currentBill.amountPaid.toStringAsFixed(2)} of ${currentBill.formattedAmount}',
                                style: TextStyle(
                                  fontSize: isTablet ? 13 : 11,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: isTablet ? 12 : 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            color: const Color(0xFF4A90E2),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: isTablet ? 4 : 2),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: isTablet ? 14 : 12,
                          color: const Color(0xFF4A90E2),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
              final maxHeight = isTablet ? 400.0 : 300.0;

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
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxHeight),
                  child: SingleChildScrollView(
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
                  ),
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
          // Refresh user status when navigating between tabs
          context.read<AuthBloc>().add(RefreshUserStatusRequested());
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
