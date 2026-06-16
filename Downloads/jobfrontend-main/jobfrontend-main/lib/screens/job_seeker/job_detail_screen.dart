import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/job.dart';
import '../../services/app_session.dart';
import '../../services/job_seeker_api_service.dart';
import '../../services/job_share_service.dart';
import '../../widgets/apply_job_sheet.dart';
import '../../utils/app_colors.dart';
import '../../constants/industry_types.dart';
import 'similar_jobs_screen.dart';

class JobDetailScreen extends StatefulWidget {
  final Job job;
  final String userId;
  final String token;
  /// From feed when applications list is already loaded.
  final bool hasApplied;
  final bool isBookmarked;

  const JobDetailScreen({
    super.key,
    required this.job,
    this.userId = 'demo-user',
    this.token = 'demo-token',
    this.hasApplied = false,
    this.isBookmarked = false,
  });

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _isBookmarked = false;
  late Job _job;
  bool _refreshing = false;
  late bool _hasApplied;

  @override
  void initState() {
    super.initState();
    _job = widget.job;
    _hasApplied = widget.hasApplied;
    _isBookmarked = widget.isBookmarked;
    _refreshJob();
    _syncAppliedFromApi();
    _syncSavedStatusFromApi();
  }

  Future<void> _syncSavedStatusFromApi() async {
    if (!AppSession.isLoggedIn) return;
    try {
      final saved = await JobSeekerApiService.instance.listSavedJobs(perPage: 100);
      final hit = saved.any((j) => j.id == _job.id);
      if (mounted) setState(() => _isBookmarked = hit);
    } catch (_) {}
  }

  Future<void> _syncAppliedFromApi() async {
    if (!AppSession.isLoggedIn) return;
    try {
      final apps =
          await JobSeekerApiService.instance.listMyApplications(perPage: 100);
      final hit = apps.any((a) => a.jobId == _job.id);
      if (mounted) setState(() => _hasApplied = hit);
    } catch (_) {}
  }

  Future<void> _refreshJob() async {
    final id = _job.id;
    setState(() => _refreshing = true);
    try {
      final j = await JobSeekerApiService.instance.getJob(id);
      if (mounted) setState(() => _job = j);
    } catch (_) {
      // keep passed-in job
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _shareJob() async {
    try {
      await JobShareService.instance.shareJob(
        jobId: _job.id,
        title: _job.title,
        companyName: _job.companyName,
        location: _job.location,
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _contactHR() async {
    final pref = _job.contactPreference ?? 'phone_call';
    if (pref == 'whatsapp') {
      final phone = _job.contactPhone ?? '';
      if (phone.isEmpty) {
        _showError('No HR contact phone number provided');
        return;
      }
      final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
      final whatsappUrl = "https://wa.me/$cleanPhone?text=Hi, I am interested in your job post: ${_job.title}";
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showError('Could not launch WhatsApp');
      }
    } else if (pref == 'email') {
      final email = _job.contactEmail ?? '';
      if (email.isEmpty) {
        _showError('No HR contact email provided');
        return;
      }
      final emailUrl = Uri(
        scheme: 'mailto',
        path: email,
        queryParameters: {
          'subject': 'Job Application for ${_job.title}',
          'body': 'Hi, I would like to apply for the ${_job.title} position.',
        },
      );
      if (await canLaunchUrl(emailUrl)) {
        await launchUrl(emailUrl);
      } else {
        _showError('Could not open email app');
      }
    } else {
      final phone = _job.contactPhone ?? '';
      if (phone.isEmpty) {
        _showError('No HR contact phone number provided');
        return;
      }
      final phoneUrl = Uri(scheme: 'tel', path: phone);
      if (await canLaunchUrl(phoneUrl)) {
        await launchUrl(phoneUrl);
      } else {
        _showError('Could not start phone call');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DefaultTabController(
      length: 2, // Job Details, Company Details
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                SliverAppBar(
                  pinned: false,
                  floating: false,
                  backgroundColor: Colors.white,
                  elevation: 0.5,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    'Job Details',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  centerTitle: true,
                  actions: [
                    IconButton(
                      icon: Icon(
                        _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        color: _isBookmarked ? AppColors.primary : AppColors.textPrimary,
                        size: 24,
                      ),
                      onPressed: () async {
                        if (!AppSession.isLoggedIn) {
                          _showError('Please log in to save jobs');
                          return;
                        }

                        try {
                          final jobId = _job.id;

                          if (_isBookmarked) {
                            await JobSeekerApiService.instance.unsaveJob(jobId);
                          } else {
                            await JobSeekerApiService.instance.saveJob(jobId);
                          }

                          if (mounted) {
                            setState(() => _isBookmarked = !_isBookmarked);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  _isBookmarked ? 'Job saved!' : 'Job removed from saved',
                                ),
                                backgroundColor: AppColors.primary,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            _showError('Error: $e');
                          }
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_rounded, color: AppColors.textPrimary, size: 24),
                      onPressed: () => _shareJob(),
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: _buildHeader(textTheme),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textHint,
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      tabs: const [
                        Tab(text: 'Job Details'),
                        Tab(text: 'Company Details'),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              children: [
                _buildJobDetailsTab(textTheme),
                _buildCompanyDetailsTab(textTheme),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomBar(textTheme),
      ),
    );
  }

  Widget _buildHeader(TextTheme textTheme) {
    final experienceText = _job.experienceLevel.toLowerCase() == 'fresher' 
        ? 'Fresher' 
        : '${_job.experienceLevel.replaceAll('_', ' ').toUpperCase()} in ${_job.department ?? _job.roleCategory ?? "Field Sales"}';
        
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Center(
                  child: _job.companyLogoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: _job.companyLogoUrl!,
                            fit: BoxFit.cover,
                            width: 64,
                            height: 64,
                            errorWidget: (context, url, error) => Center(
                              child: Text(
                                _job.companyName.isNotEmpty ? _job.companyName[0].toUpperCase() : 'C',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Text(
                          _job.companyName.isNotEmpty ? _job.companyName[0].toUpperCase() : 'C',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _job.title,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _job.companyName,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.primary),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildHeaderInfoRow(Icons.location_on_rounded, Colors.indigo.shade600, '${_job.location.isEmpty ? "Remote" : _job.location}'),
          const SizedBox(height: 8),
          _buildHeaderInfoRow(Icons.access_time_filled_rounded, Colors.indigo.shade600, experienceText),
          const SizedBox(height: 8),
          _buildHeaderSalaryInfoRow(Icons.wallet_rounded, Colors.indigo.shade600),
          const SizedBox(height: 16),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Fixed Salary: ',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      _job.salaryRange,
                      style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (_job.incentiveDetail != null && _job.incentiveDetail!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Incentive: ',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Expanded(
                        child: Text(
                          _job.incentiveDetail!,
                          style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
                if (_job.salaryInsights != null && _job.salaryInsights!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Salary Insights: ',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Expanded(
                        child: Text(
                          _job.salaryInsights!,
                          style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Posted ${_job.postedAgoLabel}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              _buildHeaderBadge(Icons.stars_rounded, 'New'),
              const SizedBox(width: 8),
              _buildHeaderBadge(Icons.work_rounded, '${_job.applicationsCount}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfoRow(IconData icon, Color iconColor, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderSalaryInfoRow(IconData icon, Color iconColor) {
    final hasIncentive = _job.incentiveDetail != null && _job.incentiveDetail!.isNotEmpty;
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            children: [
              const TextSpan(text: 'Fixed Salary'),
              if (hasIncentive)
                const TextSpan(
                  text: ' + Incentive',
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildJobDetailsTab(TextTheme textTheme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _job.securityDeposit ? Icons.warning_rounded : Icons.verified_user_rounded,
                    color: _job.securityDeposit ? Colors.red.shade700 : Colors.indigo,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _job.securityDeposit ? 'Security Deposit Charged' : 'No Payment Involved',
                    style: TextStyle(
                      color: _job.securityDeposit ? Colors.red.shade700 : Colors.indigo,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _job.securityDeposit ? Colors.amber.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _job.securityDeposit ? Icons.info_outline_rounded : Icons.warning_rounded,
                      color: _job.securityDeposit ? Colors.amber.shade900 : Colors.red.shade800,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _job.securityDeposit
                            ? 'Warning: Candidates are asked for a security deposit (e.g. kit/uniform/bike).'
                            : 'Report job if money is demanded',
                        style: TextStyle(
                          color: _job.securityDeposit ? Colors.amber.shade900 : Colors.red.shade900,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _buildJobHighlightsCard(textTheme),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.description_rounded, color: Colors.indigo, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Job Description',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _job.description,
                style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _buildCandidateRequirementCard(textTheme),
        const SizedBox(height: 16),

        _buildAdditionalInformationCard(textTheme),
        const SizedBox(height: 16),
        _buildInterviewDetailsCard(textTheme),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildJobHighlightsCard(TextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.orange, width: 4),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.flash_on_rounded, color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Job Highlights',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_job.assetsRequired != null && _job.assetsRequired!.isNotEmpty)
                  _buildHighlightDetailRow('Assets', _job.assetsRequired!),
                _buildHighlightDetailRow('Languages', _job.languages ?? 'Tamil, English'),
                _buildHighlightDetailRow('Industry Experience', _job.experienceDisplay),
                if (_job.skills.isNotEmpty)
                  _buildHighlightDetailRow('Skills Required', _job.skills.join(', ')),
                if (_job.incentiveDetail != null && _job.incentiveDetail!.isNotEmpty)
                  _buildHighlightDetailRow('Incentives', _job.incentiveDetail!),
                _buildHighlightDetailRow('Job Timings', _job.jobTimings ?? '9:30 AM - 6:30 PM'),
                if (_job.department != null && _job.department!.isNotEmpty)
                  _buildHighlightDetailRow('Department', _job.department!),
                if (_job.roleCategory != null && _job.roleCategory!.isNotEmpty)
                  _buildHighlightDetailRow('Role Category', _job.roleCategory!),
                if (_job.functionalArea != null && _job.functionalArea!.isNotEmpty)
                  _buildHighlightDetailRow('Functional Area', _job.functionalArea!),
                _buildHighlightDetailRow('Role', _job.role ?? _job.title),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCandidateRequirementCard(TextTheme textTheme) {
    final ageText = (_job.ageMin != null && _job.ageMax != null)
        ? '${_job.ageMin} - ${_job.ageMax} Years'
        : '18 - 45 Years';
    final genderPref = _job.genderPreference == 'male_only' 
        ? 'Male Only' 
        : _job.genderPreference == 'female_only' 
            ? 'Female Only' 
            : 'Any Gender';
    final qualification = [
      _job.education ?? '12th Pass',
      genderPref
    ].where((e) => e.isNotEmpty).join(' / ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_rounded, color: Colors.indigo, size: 18),
              SizedBox(width: 8),
              Text(
                'Candidate Requirement',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRequirementChipRow('Age', ageText),
          const SizedBox(height: 12),
          _buildRequirementChipRow('Qualification', qualification),
          const SizedBox(height: 12),
          if (_job.skills.isNotEmpty) ...[
            _buildRequirementChipRow('Skills required', _job.skills.join(', ')),
            const SizedBox(height: 12),
          ],
          _buildRequirementChipRow('Language Preference', _job.languages ?? 'Tamil, English'),
          if (_job.requirements.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Detailed Requirements',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              _job.requirements,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequirementChipRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInformationCard(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.indigo, size: 18),
              SizedBox(width: 8),
              Text(
                'Additional Information',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoItem('Job Timings', _job.jobTimings ?? '9:30 AM - 6:30 PM'),
          _buildInfoItem('Job Type', '${_job.jobType.replaceAll('_', ' ').toUpperCase()} | ${_job.workingDays ?? "Monday to Saturday"}'),
          if (_job.department != null && _job.department!.isNotEmpty)
            _buildInfoItem('Department', _job.department!),
          if (_job.roleCategory != null && _job.roleCategory!.isNotEmpty)
            _buildInfoItem('Role Category', _job.roleCategory!),
          if (_job.functionalArea != null && _job.functionalArea!.isNotEmpty)
            _buildInfoItem('Functional Area', _job.functionalArea!),
          _buildInfoItem('Role', _job.role ?? _job.title),
          _buildInfoItem('Industry Experience', _job.experienceDisplay),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterviewDetailsCard(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.business_center_rounded, color: Colors.indigo, size: 18),
              SizedBox(width: 8),
              Text(
                'Interview / Contact Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
              ),
            ],
          ),
          if (_job.interviewTimings != null && _job.interviewTimings!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Interview Timings:',
              style: TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                _job.interviewTimings!,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Contact Person:',
            style: TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              _job.contactPerson ?? 'HR Manager',
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            ),
          ),
          if (_job.contactPhone != null && _job.contactPhone!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _job.contactPreference == 'whatsapp' ? 'WhatsApp Number:' : 'HR Phone Number:',
              style: const TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _contactHR,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.indigo.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      _job.contactPreference == 'whatsapp'
                          ? Icons.chat_rounded
                          : Icons.phone_enabled_rounded,
                      size: 16,
                      color: Colors.indigo,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _job.contactPhone!,
                      style: const TextStyle(fontSize: 13, color: Colors.indigo, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      _job.contactPreference == 'whatsapp' ? 'Chat on WhatsApp' : 'Call HR',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.indigo,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_job.contactEmail != null && _job.contactEmail!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'HR Email Address:',
              style: TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _contactHR,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.indigo.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.email_rounded,
                      size: 16,
                      color: Colors.indigo,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _job.contactEmail!,
                      style: const TextStyle(fontSize: 13, color: Colors.indigo, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    const Text(
                      'Email HR',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.indigo,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompanyDetailsTab(TextTheme textTheme) {
    final perks = _job.benefits ?? '';
    final website = _job.company?['website']?.toString() ?? '';
    final about = _job.aboutCompany ?? _job.company?['description']?.toString() ?? '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCompanyDetailCard('Industry Type', industryTypeLabel(_job.industryType)),
        const SizedBox(height: 16),

        if (perks.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.star_rounded, color: Colors.orange, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Perks and Benefits',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildBulletList(perks, textTheme),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (website.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Company Website',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () async {
                    final uri = Uri.tryParse(website);
                    if (uri != null) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            website,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (about.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About ${_job.companyName}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                Text(
                  about,
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        _buildInterviewDetailsCard(textTheme),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                icon: Icons.share_rounded,
                label: 'Share',
                bgColor: const Color(0xFFDCF8C6),
                textColor: const Color(0xFF075E54),
                onTap: _shareJob,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionTile(
                icon: Icons.warning_amber_rounded,
                label: 'Report',
                bgColor: const Color(0xFFFFEBEE),
                textColor: const Color(0xFFC62828),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Job reported. Admin will review.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionTile(
                icon: Icons.lightbulb_outline_rounded,
                label: 'Tips',
                bgColor: const Color(0xFFE8EAF6),
                textColor: const Color(0xFF283593),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tip: Prepare your resume before calling the recruiter.'),
                      backgroundColor: Colors.indigo,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildCompanyDetailCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletList(String text, TextTheme textTheme) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    final lines = text
        .split(RegExp(r'\n|,'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (lines.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  line,
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.hub_outlined, color: AppColors.primary, size: 20),
                label: const Text(
                  'Similar Jobs',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SimilarJobsScreen(
                        job: _job,
                        userId: widget.userId,
                        token: widget.token,
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 5,
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _hasApplied || _refreshing
                      ? null
                      : () async {
                          final ok = await showApplyJobSheet(context, _job);
                          if (!ok || !context.mounted) return;
                          if (mounted) setState(() => _hasApplied = true);
                          await _refreshJob();
                        },
                  icon: Icon(
                    _hasApplied ? Icons.check_circle_rounded : Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: Text(
                    _hasApplied ? 'Applied' : 'Apply',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasApplied ? Colors.grey.shade400 : AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade400,
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
