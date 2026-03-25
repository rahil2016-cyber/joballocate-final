import 'package:flutter/material.dart';
import 'package:joballocate/models/resume_template.dart';
import 'package:joballocate/models/seeker_profile.dart';
import 'package:joballocate/services/app_session.dart';
import 'package:joballocate/services/job_seeker_api_service.dart';
import 'package:joballocate/services/resume_service.dart';
import 'resume_builder_screen.dart';

class ResumeTemplatesScreen extends StatefulWidget {
  final String userId;
  final String token;
  const ResumeTemplatesScreen({
    Key? key,
    this.userId = 'demo-user',
    this.token = 'demo-token',
  }) : super(key: key);

  @override
  State<ResumeTemplatesScreen> createState() => _ResumeTemplatesScreenState();
}

class _ResumeTemplatesScreenState extends State<ResumeTemplatesScreen> {
  final ResumeService _resumeService = ResumeService();
  List<ResumeTemplate> templates = [];
  bool isLoading = true;
  String selectedCategory = 'all';
  SeekerProfileSummary? _profileSummary;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final tok = AppSession.token ?? widget.token;
    if (tok.isEmpty) return;
    try {
      final raw = await JobSeekerApiService.instance.getSeekerProfile();
      if (!mounted) return;
      setState(() => _profileSummary = SeekerProfileSummary.fromJson(raw));
    } catch (_) {}
  }

  Future<void> _loadTemplates() async {
    setState(() => isLoading = true);
    try {
      final loadedTemplates = await _resumeService.getTemplates();
      setState(() {
        templates = loadedTemplates;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading templates: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  List<ResumeTemplate> _getFilteredTemplates() {
    if (selectedCategory == 'all') {
      return templates;
    }
    return templates.where((t) => t.category == selectedCategory).toList();
  }

  /// Mini layout preview matching PDF [ResumeTemplate.designVariant] (4 styles).
  /// Uses [FittedBox] so content never overflows fixed preview height.
  Widget _buildDesignPreview(ResumeTemplate t, {double height = 110}) {
    final v = t.designVariant % 4;
    const name = 'Your name';
    const phone = '+91 · · · · · · · · · ·';
    const dob = 'DOB · · · · · · ·';

    Widget inner;
    switch (v) {
      case 0:
        inner = Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border.all(color: Colors.blue.shade800, width: 1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: Colors.blue.shade900,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      phone,
                      style: TextStyle(fontSize: 8, color: Colors.grey.shade700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    dob,
                    style: TextStyle(fontSize: 8, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ],
          ),
        );
        break;
      case 1:
        inner = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 3, height: 36, color: Colors.teal.shade700),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: Colors.teal.shade900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$phone · $dob',
                    style: TextStyle(fontSize: 7, color: Colors.grey.shade700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        );
        break;
      case 2:
        inner = Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Divider(color: Colors.grey.shade400, height: 6),
            Text(phone, style: TextStyle(fontSize: 7, color: Colors.grey.shade700)),
            Text(dob, style: TextStyle(fontSize: 7, color: Colors.grey.shade700)),
          ],
        );
        break;
      default:
        inner = Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade600),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PHONE',
                      style: TextStyle(
                        fontSize: 6,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(phone, style: const TextStyle(fontSize: 8)),
                  ],
                ),
              ),
              Container(width: 1, height: 32, color: Colors.grey.shade400),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROFILE',
                      style: TextStyle(
                        fontSize: 6,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(name, style: const TextStyle(fontSize: 8)),
                    Text(dob, style: TextStyle(fontSize: 7, color: Colors.grey.shade700)),
                  ],
                ),
              ),
            ],
          ),
        );
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        child: ColoredBox(
          color: Colors.grey.shade100,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                    child: inner,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Templates'),
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
      ),
      body: Column(
        children: [
          // Curated layouts (2 provider-style options; same PDF header variants 0 & 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose a layout',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Two styles for now — more can be added later (or via API).',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 138,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: resumeFeaturedTemplates.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final t = resumeFeaturedTemplates[i];
                      return SizedBox(
                        width: 168,
                        child: Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () => _selectTemplate(t),
                            borderRadius: BorderRadius.circular(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildDesignPreview(t, height: 96),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      8, 6, 8, 8),
                                  child: Text(
                                    t.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'More templates',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ),
          // Category filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: selectedCategory == 'all',
                  onSelected: (selected) {
                    setState(() => selectedCategory = 'all');
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Professional'),
                  selected: selectedCategory == 'professional',
                  onSelected: (selected) {
                    setState(() => selectedCategory = 'professional');
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Modern'),
                  selected: selectedCategory == 'modern',
                  onSelected: (selected) {
                    setState(() => selectedCategory = 'modern');
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Creative'),
                  selected: selectedCategory == 'creative',
                  onSelected: (selected) {
                    setState(() => selectedCategory = 'creative');
                  },
                ),
              ],
            ),
          ),
          // Templates grid
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : templates.isEmpty
                    ? const Center(child: Text('No templates found.'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _getFilteredTemplates().length,
                        itemBuilder: (context, index) {
                          final template = _getFilteredTemplates()[index];
                          return _buildTemplateCard(template);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(ResumeTemplate template) {
    return GestureDetector(
      onTap: () => _selectTemplate(template),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail / preview (matches PDF header style)
            Expanded(
              flex: 3,
              child: _buildDesignPreview(template),
            ),
            // Template info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          template.description,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            template.category,
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectTemplate(ResumeTemplate template) {
    final hasResumePlan = _profileSummary?.canBuildResume ?? false;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(template.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Header style preview (name, phone & DOB on PDF export)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: _buildDesignPreview(template, height: 120),
              ),
              const SizedBox(height: 16),
              Text(
                template.description,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sections included:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: template.sections
                    .map(
                      (section) => Chip(
                        label: Text(section.replaceAll('_', ' ')),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _continueAfterTemplateChoice(template);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _continueAfterTemplateChoice(ResumeTemplate template) async {
    final uid = AppSession.userId ?? widget.userId;
    final tok = AppSession.token ?? widget.token;
    if (tok.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to use resumes.')),
      );
      return;
    }
    _openBuilder(template, uid, tok);
  }

  void _openBuilder(ResumeTemplate template, String uid, String tok) {
    if (!mounted) return;
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ResumeBuilderScreen(
          template: template,
          userId: uid,
          token: tok,
        ),
      ),
    );
  }
}
