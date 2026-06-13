import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'company_subscription_screen.dart';
import 'post_job_screen.dart';
import 'manage_applications_screen.dart';
import 'employer_profile_screen.dart';
import 'employer_dashboard_page.dart';

class EmployerHomeScreen extends StatefulWidget {
  const EmployerHomeScreen({super.key, this.token});

  /// Bearer token from OTP login (use for future API calls).
  final String? token;

  @override
  State<EmployerHomeScreen> createState() => _EmployerHomeScreenState();
}

class _EmployerHomeScreenState extends State<EmployerHomeScreen> {
  int _currentIndex = 0;

  final GlobalKey<EmployerDashboardPageState> _dashboardKey =
      GlobalKey<EmployerDashboardPageState>();

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      EmployerDashboardPage(key: _dashboardKey),
      const ManageApplicationsScreen(),
      const CompanySubscriptionScreen(),
      const EmployerProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.people_alt_rounded,
                  label: 'Applicants',
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.card_membership_rounded,
                  label: 'Subscriptions',
                  index: 2,
                ),
                _buildNavItem(
                  icon: Icons.business_rounded,
                  label: 'Company',
                  index: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                final dashboard = _dashboardKey.currentState;
                // Block posting for unverified companies.
                if (dashboard == null || !dashboard.isVerified) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Your company is not verified yet. You can post jobs only after admin approval.',
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                // First job is free; subsequent jobs require payment (₹399).
                final hasJobs = dashboard.hasAnyJob;
                if (hasJobs) {
                  if (!mounted) return;
                  final proceed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Post new job for ₹399?'),
                      content: const Text(
                        'Your first job posting was free. Additional job postings cost ₹399 each.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Continue'),
                        ),
                      ],
                    ),
                  );
                  if (proceed != true) return;
                }

                final posted = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const PostJobScreen()),
                );
                if (posted == true && mounted) {
                  _dashboardKey.currentState?.load();
                }
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Post Job',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textHint,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}