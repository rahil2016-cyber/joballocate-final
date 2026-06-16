import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../constants/industry_types.dart';
import '../../main.dart' show RoleSelectionScreen;
import '../../features/resume/adapters/draft_resume_parse.dart';
import '../../features/resume/models/resume_model.dart';
import '../../services/app_session.dart';
import '../../services/job_seeker_api_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/media_url.dart';
import '../../utils/resume_draft_utils.dart';
import './package_purchase_history_screen.dart';
import './packages_screen.dart';
import './resume_templates_screen.dart';
import 'seeker_resume_studio_screen.dart';
import '../../widgets/seeker_html_template_swatch.dart';
import '../common/pdf_view_screen.dart';
import 'job_seeker_profile_edit_sheet.dart';
import 'my_resumes_screen.dart';
import 'settings_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../common/refer_and_earn_screen.dart';

int _profileCompletenessPercent(Map<String, dynamic> p) {
  int s = 0;
  bool ne(dynamic v) => v != null && v.toString().trim().isNotEmpty;

  if (ne(p['headline'])) s += 14;
  if (ne(p['bio'])) s += 14;
  final skills = p['skills'];
  if (skills is List && skills.isNotEmpty) s += 20;
  if (ne(p['city'])) s += 14;
  if (ne(p['country'])) s += 14;
  if (p['experience_years'] != null) s += 12;
  if (p['expected_salary_min'] != null || p['expected_salary_max'] != null) {
    s += 12;
  }
  final photoUrl = p['profile_photo_url']?.toString().trim() ?? '';
  final photoRaw = p['profile_photo']?.toString().trim() ?? '';
  if (photoUrl.isNotEmpty || photoRaw.isNotEmpty) {
    s += 10;
  }
  return s.clamp(0, 100);
}

String _initials(String name) {
  final p = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
  if (p.isEmpty) return '?';
  if (p.length == 1) return p.first.substring(0, 1).toUpperCase();
  return (p.first[0] + p.last[0]).toUpperCase();
}

String _formatResumeDraftDate(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  final d = DateTime.tryParse(iso)?.toLocal();
  if (d == null) return iso;
  return DateFormat('MMM d, y').format(d);
}

class JobSeekerProfileScreen extends StatefulWidget {
  const JobSeekerProfileScreen({super.key});

  @override
  State<JobSeekerProfileScreen> createState() => _JobSeekerProfileScreenState();
}

class _JobSeekerProfileScreenState extends State<JobSeekerProfileScreen> {
  Map<String, dynamic>? _profile;
  /// Primary / “active” resume draft (used when applying), from [JobSeekerApiService.getResumeDrafts].
  Map<String, dynamic>? _activeResumeDraft;
  bool _loading = true;
  String? _error;
  bool _uploadingPhoto = false;

  static const int _maxPhotoBytes = 2 * 1024 * 1024;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!AppSession.isLoggedIn) {
      setState(() {
        _loading = false;
        _error = 'Not logged in';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await JobSeekerApiService.instance.getSeekerProfile();
      Map<String, dynamic>? activeDraft;
      try {
        final draftsRaw = await JobSeekerApiService.instance.getResumeDrafts();
        activeDraft = pickPrimaryResumeDraft(draftsRaw);
      } catch (_) {
        activeDraft = null;
      }
      if (!mounted) return;
      _mergeProfileResponseIntoSession(data);
      setState(() {
        _profile = data;
        _activeResumeDraft = activeDraft;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _activeResumeDraft = null;
        _loading = false;
      });
    }
  }

  Map<String, dynamic>? get _user => AppSession.user;

  String get _displayName =>
      _user?['name']?.toString().trim().isNotEmpty == true
      ? _user!['name'].toString()
      : 'Job seeker';

  /// Profile API exposes real email; `users.email` may be a phone-only placeholder.
  String get _email {
    final pe = _profile?['email']?.toString().trim() ?? '';
    if (pe.isNotEmpty) return pe;
    final ue = _user?['email']?.toString() ?? '';
    if (ue.contains('@internal.joballocate')) return '—';
    if (ue.isEmpty) return '—';
    return ue;
  }

  String get _phone {
    final pp = _profile?['phone']?.toString().trim() ?? '';
    if (pp.isNotEmpty) return pp;
    return _user?['phone']?.toString() ?? '—';
  }

  void _mergeProfileResponseIntoSession(Map<String, dynamic> data) {
    final u = AppSession.user;
    if (u == null) return;
    final merged = Map<String, dynamic>.from(u);
    final e = data['email']?.toString().trim();
    final ph = data['phone']?.toString().trim();
    if (e != null && e.isNotEmpty) merged['email'] = e;
    if (ph != null && ph.isNotEmpty) merged['phone'] = ph;
    final url = data['profile_photo_url']?.toString().trim();
    if (url != null && url.isNotEmpty) merged['profile_photo_url'] = url;
    AppSession.updateUser(merged);
  }

  Future<void> _pickAndUploadProfilePhoto() async {
    if (!AppSession.isLoggedIn || _profile == null) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (picked == null || !mounted) return;

      final bytes = await picked.readAsBytes();
      if (bytes.lengthInBytes > _maxPhotoBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo too large (max ~2MB). Try another image.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      setState(() => _uploadingPhoto = true);
      final data = await JobSeekerApiService.instance.updateSeekerProfile({
        'profile_photo': base64Encode(bytes),
      });
      if (!mounted) return;
      setState(() {
        _profile = data;
        _uploadingPhoto = false;
      });
      _mergeProfileResponseIntoSession(data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile photo updated'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _openActiveResumeDraft(Map<String, dynamic> d) async {
    final idRaw = d['id'];
    final id = idRaw is int
        ? idRaw
        : int.tryParse(idRaw?.toString() ?? '') ?? 0;
    final templateStr = d['template_id']?.toString() ?? '';

    final parsed = resumeDraftParseForBuilder(d['content']);

    final apiTitle = d['title']?.toString().trim() ?? '';
    final ResumeModel baseModel = parsed.model ??
        (parsed.legacy != null
            ? ResumeModel.fromLegacyJsonResume(parsed.legacy!)
            : ResumeModel.empty());
    final ResumeModel initial =
        apiTitle.isNotEmpty ? baseModel.copyWith(draftTitle: apiTitle) : baseModel;

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SeekerResumeStudioScreen(
          resumeDraftId: id > 0 ? id : null,
          initialModel: initial,
          templateIdForSave: templateStr.isNotEmpty ? templateStr : '1',
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _openMyResumesAndRefresh() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => MyResumesScreen(
          userId: AppSession.userId ?? 'demo-user',
          token: AppSession.token ?? 'demo-token',
        ),
      ),
    );
    if (mounted) await _load();
  }

  void _openEdit() {
    final p = _profile;
    if (p == null) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => JobSeekerProfileEditSheet(
        initial: Map<String, dynamic>.from(p),
        onSaved: () async {
          await _load();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile saved'),
              backgroundColor: AppColors.success,
            ),
          );
        },
      ),
    );
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You will need to sign in again to use JobAllocate.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await AppSession.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final p = _profile;

    final rawPhoto = p?['profile_photo_url']?.toString() ??
        p?['profile_photo']?.toString();
    final profilePhotoUrl = MediaUrl.resolve(rawPhoto);

    final horizontalMargin =
        (MediaQuery.of(context).size.width * 0.12).clamp(16.0, 60.0);

    final backendComplete = p?['profile_completion_percent'];
    final complete = backendComplete is int
        ? backendComplete
        : int.tryParse(backendComplete?.toString() ?? '') ??
              (p != null ? _profileCompletenessPercent(p) : 0);

    final city = p?['city']?.toString() ?? '';
    final country = p?['country']?.toString() ?? '';
    final location = [city, country].where((e) => e.isNotEmpty).join(', ');
    final headline = p?['headline']?.toString() ?? '';
    final bio = p?['bio']?.toString() ?? '';
    final skills = p?['skills'] is List
        ? (p!['skills'] as List).map((e) => e.toString()).toList()
        : <String>[];
    final expYears = p?['experience_years'];
    final smin = p?['expected_salary_min'];
    final smax = p?['expected_salary_max'];

    final uid = AppSession.userId ?? '';
    final tok = AppSession.token ?? '';

    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_error != null && p == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: AppColors.primary,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.6),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.18),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: _uploadingPhoto
                                    ? const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(20),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      )
                                    : profilePhotoUrl != null
                                        ? Image.network(
                                            profilePhotoUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Center(
                                              child: Text(
                                                _initials(_displayName),
                                                style: const TextStyle(
                                                  fontSize: 32,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                          )
                                        : Center(
                                            child: Text(
                                              _initials(_displayName),
                                              style: const TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                              ),
                            ),
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Material(
                                color: Colors.white,
                                shape: const CircleBorder(),
                                elevation: 3,
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: _uploadingPhoto
                                      ? null
                                      : _pickAndUploadProfilePhoto,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.camera_alt_rounded,
                                      size: 20,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          location.isEmpty
                              ? 'Add location in Edit profile'
                              : location,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.18),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Profile Completeness',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '$complete%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: complete / 100,
                                  backgroundColor: Colors.white.withOpacity(0.25),
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickAction(
                            icon: Icons.edit_document,
                            label: 'Edit Profile',
                            bgColor: const Color(0xFFEEF2FF),
                            iconColor: const Color(0xFF4F46E5),
                            onTap: _openEdit,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickAction(
                            icon: Icons.description_rounded,
                            label: 'My Resume',
                            bgColor: const Color(0xFFECFDF5),
                            iconColor: const Color(0xFF059669),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ResumeTemplatesScreen(
                                  userId: uid.isEmpty ? 'demo-user' : uid,
                                  token: tok.isEmpty ? 'demo-token' : tok,
                                  seekerProfile: _profile,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickAction(
                            icon: Icons.shopping_bag_rounded,
                            label: 'Plans & Packages',
                            bgColor: const Color(0xFFFFFBEB),
                            iconColor: const Color(0xFFD97706),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const JobSeekerPackagesScreen(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickAction(
                            icon: Icons.receipt_long_rounded,
                            label: 'Purchase History',
                            bgColor: const Color(0xFFFFF1F2),
                            iconColor: const Color(0xFFE11D48),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const PackagePurchaseHistoryScreen(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickAction(
                            icon: Icons.settings_rounded,
                            label: 'Settings',
                            bgColor: const Color(0xFFF1F5F9),
                            iconColor: const Color(0xFF475569),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SettingsScreen(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickAction(
                            icon: Icons.card_giftcard_rounded,
                            label: 'Refer & Earn',
                            bgColor: const Color(0xFFFAF5FF),
                            iconColor: const Color(0xFF7C3AED),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ReferAndEarnScreen(audience: 'job_seeker'),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    if (headline.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          headline,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    _buildSectionCard(
                      title: 'About Me',
                      icon: Icons.person_outline_rounded,
                      child: Text(
                        bio.isEmpty
                            ? 'Tell employers about yourself — tap Edit Profile.'
                            : bio,
                        style: textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                          fontStyle: bio.isEmpty
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPersonalDetailsCard(p, textTheme),
                    _buildSectionCard(
                      title: 'Contact Information',
                      icon: Icons.contact_mail_outlined,
                      child: Column(
                        children: [
                          _buildContactRow(Icons.email_outlined, _email),
                          const SizedBox(height: 12),
                          _buildContactRow(Icons.phone_outlined, _phone),
                          const SizedBox(height: 12),
                          _buildContactRow(
                            Icons.location_on_outlined,
                            location.isEmpty ? '—' : location,
                          ),
                          if ((p?['portfolio_url']?.toString().trim() ?? '').isNotEmpty) ...[
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () {
                                final url = p!['portfolio_url'].toString().trim();
                                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                              },
                              child: Row(
                                children: [
                                  Icon(Icons.link_rounded, size: 18, color: AppColors.primary),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      p!['portfolio_url'].toString().trim(),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'Active resume (for applications)',
                      icon: Icons.verified_outlined,
                      child: _buildActiveResumeSection(textTheme),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'Resume (PDF)',
                      icon: Icons.picture_as_pdf_rounded,
                      child: Builder(
                        builder: (context) {
                          final url = p?['resume_url']?.toString().trim() ?? '';
                          if (url.isEmpty) {
                            return Text(
                              'No resume uploaded yet. Tap Edit Profile to upload a PDF.',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textHint,
                                fontStyle: FontStyle.italic,
                              ),
                            );
                          }
                          final fileName =
                              Uri.tryParse(url)?.pathSegments.isNotEmpty == true
                              ? Uri.parse(url).pathSegments.last
                              : 'resume.pdf';
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.picture_as_pdf_rounded,
                                    color: Colors.red.shade700,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Resume uploaded',
                                        style: textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        fileName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: textTheme.bodySmall?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed: () async {
                                    if (!context.mounted) return;
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => PdfViewScreen(
                                          title: 'Resume (PDF)',
                                          url: url,
                                        ),
                                      ),
                                    );
                                  },
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Open'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (p != null &&
                        (p['industry_type']?.toString().trim().isNotEmpty ??
                            false))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildSectionCard(
                          title: 'Industry / role type',
                          icon: Icons.business_center_outlined,
                          child: Text(
                            industryTypeLabel(p['industry_type']?.toString()),
                            style: textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    _buildEducationCard(p, textTheme),
                    const SizedBox(height: 16),
                    _buildWorkExperienceCard(p, textTheme),
                    _buildInternshipsCard(p, textTheme),
                    _buildProjectsCard(p, textTheme),
                    _buildSectionCard(
                      title: 'Skills',
                      icon: Icons.code_rounded,
                      child: skills.isEmpty
                          ? Text(
                              'No skills yet — add them in Edit Profile.',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textHint,
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          : Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: skills.map((skill) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.primary.withOpacity(0.12),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    skill,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                    const SizedBox(height: 16),
                    _buildCertificationsCard(p, textTheme),
                    _buildLanguagesCard(p, textTheme),
                    _buildAcademicAchievementsCard(p, textTheme),
                    _buildAwardsCard(p, textTheme),
                    _buildExamResultsCard(p, textTheme),
                    _buildAchievementsCard(p, textTheme),
                    _buildSectionCard(
                      title: 'Career preferences',
                      icon: Icons.work_outline_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expYears != null
                                ? 'Experience: $expYears years'
                                : 'Experience: not set',
                            style: textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            smin != null || smax != null
                                ? 'Expected salary: ₹${smin ?? '—'} – ₹${smax ?? '—'} / year'
                                : 'Expected salary: not set',
                            style: textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        icon: Icon(
                          Icons.logout_rounded,
                          color: Colors.red.shade700,
                          size: 20,
                        ),
                        label: Text(
                          'Log Out',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: 0.2,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.shade200, width: 1.5),
                          backgroundColor: Colors.red.shade50.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: iconColor.withOpacity(0.12),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: iconColor.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveResumeSection(TextTheme textTheme) {
    final d = _activeResumeDraft;
    if (d == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No primary resume is set yet. Choose which saved resume employers see when you apply.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _openMyResumesAndRefresh,
            icon: const Icon(Icons.description_outlined, size: 20),
            label: const Text('Open My Resumes'),
          ),
        ],
      );
    }

    final title = d['title']?.toString() ?? 'Untitled resume';
    final templateIdStr = d['template_id']?.toString() ?? '—';
    final updated =
        d['updated_at']?.toString() ?? d['created_at']?.toString();

    final htmlKey = seekerHtmlTemplateKeyForStudioTemplateId(templateIdStr);

    const previewH = 72.0;
    const previewW = 52.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: previewW,
                  height: previewH,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SeekerHtmlTemplateSwatch(templateKey: htmlKey),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Updated ${_formatResumeDraftDate(updated)}',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => _openActiveResumeDraft(d),
                        child: Text(
                          'Tap to edit resume',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: TextButton.icon(
              onPressed: _openMyResumesAndRefresh,
              icon: const Icon(Icons.list_alt_rounded, size: 18),
              label: const Text(
                'Manage in My Resumes',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildEducationCard(Map<String, dynamic>? p, TextTheme textTheme) {
    final raw = p?['education'];
    final rows = <Map<String, dynamic>>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          rows.add(Map<String, dynamic>.from(e));
        }
      }
    }
    final hasContent = rows.any(
      (m) =>
          (m['title']?.toString().trim().isNotEmpty == true) ||
          (m['institution']?.toString().trim().isNotEmpty == true),
    );

    return _buildSectionCard(
      title: 'Education',
      icon: Icons.school_outlined,
      child: !hasContent
          ? Text(
              'Add Class 10, 12, diploma or degree — tap Edit Profile.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textHint,
                fontStyle: FontStyle.italic,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final m in rows)
                  if ((m['title']?.toString().trim().isNotEmpty == true) ||
                      (m['institution']?.toString().trim().isNotEmpty == true))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m['title']?.toString().trim().isNotEmpty == true
                                ? m['title'].toString()
                                : m['institution'].toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          if (m['title']?.toString().trim().isNotEmpty ==
                                  true &&
                              m['institution']?.toString().trim().isNotEmpty ==
                                  true)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                m['institution'].toString(),
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          if (m['board_or_stream']
                                  ?.toString()
                                  .trim()
                                  .isNotEmpty ==
                              true)
                            Text(
                              m['board_or_stream'].toString(),
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.textHint,
                              ),
                            ),
                          if (m['marks_or_grade']
                                      ?.toString()
                                      .trim()
                                      .isNotEmpty ==
                                  true ||
                              m['year_completed']
                                      ?.toString()
                                      .trim()
                                      .isNotEmpty ==
                                  true)
                            Text(
                              [
                                if (m['marks_or_grade']
                                        ?.toString()
                                        .trim()
                                        .isNotEmpty ==
                                    true)
                                  m['marks_or_grade'].toString(),
                                if (m['year_completed']
                                        ?.toString()
                                        .trim()
                                        .isNotEmpty ==
                                    true)
                                  m['year_completed'].toString(),
                              ].join(' · '),
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
              ],
            ),
    );
  }

  Widget _buildPersonalDetailsCard(Map<String, dynamic>? p, TextTheme textTheme) {
    final dob = p?['dob']?.toString().trim() ?? '';
    final gender = p?['gender']?.toString().trim() ?? '';
    final hasContent = dob.isNotEmpty || gender.isNotEmpty;

    if (!hasContent) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _buildSectionCard(
        title: 'Personal Details',
        icon: Icons.person_outline_rounded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (dob.isNotEmpty) ...[
              Row(
                children: [
                  const Text(
                    'Date of birth: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    dob,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
            if (dob.isNotEmpty && gender.isNotEmpty) const SizedBox(height: 8),
            if (gender.isNotEmpty) ...[
              Row(
                children: [
                  const Text(
                    'Gender: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    gender[0].toUpperCase() + gender.substring(1).toLowerCase(),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWorkExperienceCard(Map<String, dynamic>? p, TextTheme textTheme) {
    final raw = p?['work_experience'];
    final rows = <Map<String, dynamic>>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          rows.add(Map<String, dynamic>.from(e));
        }
      }
    }
    final validRows = rows.where((m) =>
      (m['company_name']?.toString().trim().isNotEmpty == true) ||
      (m['date_range']?.toString().trim().isNotEmpty == true)
    ).toList();

    if (validRows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _buildSectionCard(
        title: 'Work experience',
        icon: Icons.history_rounded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < validRows.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    validRows[i]['company_name']?.toString().trim() ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  if (validRows[i]['date_range']?.toString().trim().isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 6),
                      child: Text(
                        validRows[i]['date_range'].toString().trim(),
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  if (validRows[i]['bullets'] is List) ...[
                    for (final bullet in (validRows[i]['bullets'] as List))
                      if (bullet.toString().trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Text(
                                  bullet.toString().trim(),
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInternshipsCard(Map<String, dynamic>? p, TextTheme textTheme) {
    final raw = p?['internships'];
    final rows = <Map<String, dynamic>>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          rows.add(Map<String, dynamic>.from(e));
        }
      }
    }
    final validRows = rows.where((m) =>
      (m['organization']?.toString().trim().isNotEmpty == true) ||
      (m['role']?.toString().trim().isNotEmpty == true)
    ).toList();

    if (validRows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _buildSectionCard(
        title: 'Internships',
        icon: Icons.badge_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < validRows.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    validRows[i]['role']?.toString().trim().isNotEmpty == true
                        ? '${validRows[i]['role']} at ${validRows[i]['organization']}'
                        : validRows[i]['organization']?.toString().trim() ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  if (validRows[i]['duration']?.toString().trim().isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 6),
                      child: Text(
                        validRows[i]['duration'].toString().trim(),
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  if (validRows[i]['description']?.toString().trim().isNotEmpty == true)
                    Text(
                      validRows[i]['description'].toString().trim(),
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProjectsCard(Map<String, dynamic>? p, TextTheme textTheme) {
    final raw = p?['projects'];
    final rows = <Map<String, dynamic>>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          rows.add(Map<String, dynamic>.from(e));
        }
      }
    }
    final validRows = rows.where((m) =>
      (m['title']?.toString().trim().isNotEmpty == true)
    ).toList();

    if (validRows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _buildSectionCard(
        title: 'Projects',
        icon: Icons.folder_open_rounded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < validRows.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          validRows[i]['title']?.toString().trim() ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (validRows[i]['link']?.toString().trim().isNotEmpty == true) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.primary),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            final url = validRows[i]['link'].toString().trim();
                            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                          },
                        ),
                      ],
                    ],
                  ),
                  if (validRows[i]['description']?.toString().trim().isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        validRows[i]['description'].toString().trim(),
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCertificationsCard(Map<String, dynamic>? p, TextTheme textTheme) {
    final raw = p?['certifications_structured'];
    final rows = <Map<String, dynamic>>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          rows.add(Map<String, dynamic>.from(e));
        }
      }
    }
    final validRows = rows.where((m) =>
      (m['name']?.toString().trim().isNotEmpty == true)
    ).toList();

    if (validRows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _buildSectionCard(
        title: 'Certifications',
        icon: Icons.card_membership_rounded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < validRows.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.workspace_premium_outlined, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          validRows[i]['name']?.toString().trim() ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (validRows[i]['date']?.toString().trim().isNotEmpty == true)
                          Text(
                            validRows[i]['date'].toString().trim(),
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLanguagesCard(Map<String, dynamic>? p, TextTheme textTheme) {
    final raw = p?['languages_known'];
    final rows = <Map<String, dynamic>>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          rows.add(Map<String, dynamic>.from(e));
        }
      }
    }
    final validRows = rows.where((m) =>
      (m['language']?.toString().trim().isNotEmpty == true)
    ).toList();

    if (validRows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _buildSectionCard(
        title: 'Languages known',
        icon: Icons.language_rounded,
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: validRows.map((m) {
            final lang = m['language'].toString().trim();
            final prof = m['proficiency']?.toString().trim() ?? '';
            final label = prof.isNotEmpty ? '$lang ($prof)' : lang;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.12),
                  width: 1,
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAcademicAchievementsCard(Map<String, dynamic>? p, TextTheme textTheme) {
    final raw = p?['academic_achievements'];
    final rows = <Map<String, dynamic>>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          rows.add(Map<String, dynamic>.from(e));
        }
      }
    }
    final validRows = rows.where((m) =>
      (m['title']?.toString().trim().isNotEmpty == true)
    ).toList();

    if (validRows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _buildSectionCard(
        title: 'Academic achievements',
        icon: Icons.star_border_purple500_rounded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < validRows.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    validRows[i]['title']?.toString().trim() ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (validRows[i]['detail']?.toString().trim().isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        validRows[i]['detail'].toString().trim(),
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAwardsCard(Map<String, dynamic>? p, TextTheme textTheme) {
    final raw = p?['awards_honors'];
    final rows = <Map<String, dynamic>>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          rows.add(Map<String, dynamic>.from(e));
        }
      }
    }
    final validRows = rows.where((m) =>
      (m['title']?.toString().trim().isNotEmpty == true)
    ).toList();

    if (validRows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _buildSectionCard(
        title: 'Awards & honors',
        icon: Icons.emoji_events_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < validRows.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    validRows[i]['title']?.toString().trim() ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (validRows[i]['detail']?.toString().trim().isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        validRows[i]['detail'].toString().trim(),
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExamResultsCard(Map<String, dynamic>? p, TextTheme textTheme) {
    final raw = p?['competitive_exam_results'];
    final rows = <Map<String, dynamic>>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          rows.add(Map<String, dynamic>.from(e));
        }
      }
    }
    final validRows = rows.where((m) =>
      (m['exam']?.toString().trim().isNotEmpty == true)
    ).toList();

    if (validRows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _buildSectionCard(
        title: 'Competitive exam results',
        icon: Icons.assignment_turned_in_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < validRows.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      validRows[i]['exam']?.toString().trim() ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    validRows[i]['result']?.toString().trim() ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsCard(Map<String, dynamic>? p, TextTheme textTheme) {
    final raw = p?['achievements'];
    final rows = <String>[];
    if (raw is List) {
      for (final e in raw) {
        if (e != null && e.toString().trim().isNotEmpty) {
          rows.add(e.toString().trim());
        }
      }
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _buildSectionCard(
        title: 'Achievements',
        icon: Icons.workspace_premium_rounded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final achievement in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        achievement,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
