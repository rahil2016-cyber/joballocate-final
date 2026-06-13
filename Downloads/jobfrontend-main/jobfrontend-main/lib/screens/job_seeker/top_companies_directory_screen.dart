import 'package:flutter/material.dart';
import '../../models/top_company.dart';
import '../../services/job_seeker_api_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/media_url.dart';
import 'company_jobs_screen.dart';

/// Full list from `GET /companies/top?limit=…`.
class TopCompaniesDirectoryScreen extends StatefulWidget {
  final String userId;
  final String token;

  const TopCompaniesDirectoryScreen({
    super.key,
    required this.userId,
    required this.token,
  });

  @override
  State<TopCompaniesDirectoryScreen> createState() =>
      _TopCompaniesDirectoryScreenState();
}

class _TopCompaniesDirectoryScreenState
    extends State<TopCompaniesDirectoryScreen> {
  List<TopCompany> _list = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await JobSeekerApiService.instance.getTopCompanies(limit: 40);
      if (mounted) {
        setState(() {
          _list = rows;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Top companies hiring'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ],
      );
    }
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(_error!),
          TextButton(onPressed: _load, child: const Text('Retry')),
        ],
      );
    }
    if (_list.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 80),
          Text(
            'No verified companies with open jobs yet.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final c = _list[i];
        final resolvedLogo = MediaUrl.resolve(c.logoUrl);
        return ListTile(
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFF1F5F9)),
          ),
          leading: CircleAvatar(
            backgroundColor: AppColors.primaryLight,
            backgroundImage: resolvedLogo != null
                ? NetworkImage(resolvedLogo)
                : null,
            child: resolvedLogo == null
                ? Text(
                    c.name.isNotEmpty ? c.name[0].toUpperCase() : 'C',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : null,
          ),
          title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('${c.openJobsCount} open role${c.openJobsCount == 1 ? '' : 's'}'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CompanyJobsScreen(
                  companyId: c.id,
                  companyName: c.name,
                  userId: widget.userId,
                  token: widget.token,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
