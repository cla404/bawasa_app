import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../../domain/entities/user.dart';
import '../consumer/profile_page.dart';
import '../sign_in.dart';
import 'meter_reader_submission_page.dart';

class MeterReaderAccountMain extends StatefulWidget {
  const MeterReaderAccountMain({super.key});

  @override
  State<MeterReaderAccountMain> createState() => _MeterReaderAccountMainState();
}

class _MeterReaderAccountMainState extends State<MeterReaderAccountMain> {
  int _selectedIndex = 0;

  void _signOut() {
    context.read<AuthBloc>().add(SignOutRequested());
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
        return const MeterReaderSubmissionPage();
      case 2:
        return const ProfilePage();
      default:
        return _buildHomePage();
    }
  }

  Widget _buildHomePage() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeader(),
            const SizedBox(height: 20),

            // User Info Card
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                User? user;
                if (state is AuthAuthenticated) {
                  user = state.user;
                }
                return _buildUserInfoCard(user);
              },
            ),
            const SizedBox(height: 24),

            // Quick Actions Section
            _buildQuickActionsSection(),
            const SizedBox(height: 24),

            // Recent Activity Section
            _buildRecentActivitySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Meter Reader Dashboard',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A3A5C),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.notifications_outlined,
            color: Color(0xFF1A3A5C),
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfoCard(User? user) {
    final displayName = user?.fullName ?? 'Meter Reader';
    final email = user?.email ?? 'No email';

    return Container(
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
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF2ECC71), // Green color for meter readers
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(Icons.speed, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3A5C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ECC71).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Meter Reader',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2ECC71),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout, color: Color(0xFF6B7280)),
            tooltip: 'Sign Out',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A3A5C),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
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
            ),
            _buildQuickActionCard(
              icon: Icons.history,
              iconColor: Colors.blue,
              title: 'Reading History',
              subtitle: 'View past readings',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reading history feature coming soon!'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
            _buildQuickActionCard(
              icon: Icons.assignment,
              iconColor: Colors.orange,
              title: 'Daily Tasks',
              subtitle: 'View assigned routes',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Daily tasks feature coming soon!'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
            _buildQuickActionCard(
              icon: Icons.report,
              iconColor: Colors.red,
              title: 'Reports',
              subtitle: 'Generate reports',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reports feature coming soon!'),
                    backgroundColor: Colors.blue,
                  ),
                );
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
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A3A5C),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 20,
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
          child: Column(
            children: [
              _buildActivityItem(
                icon: Icons.speed,
                iconColor: const Color(0xFF2ECC71),
                title: 'Meter Reading Submitted',
                subtitle: 'Reading: 1,250 cubic meters',
                time: '2 hours ago',
              ),
              const Divider(height: 24),
              _buildActivityItem(
                icon: Icons.location_on,
                iconColor: Colors.blue,
                title: 'Route Completed',
                subtitle: '15 meters read today',
                time: '4 hours ago',
              ),
              const Divider(height: 24),
              _buildActivityItem(
                icon: Icons.check_circle,
                iconColor: Colors.green,
                title: 'Task Completed',
                subtitle: 'All assigned readings done',
                time: '1 day ago',
              ),
            ],
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
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
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
                subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
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
        selectedItemColor: const Color(0xFF2ECC71), // Green for meter readers
        unselectedItemColor: const Color(0xFF6B7280),
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.speed), label: 'Meter'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
