import 'package:flutter/material.dart';

import '../models/resume_demo_view_profile.dart';
import '../services/resume_demo_profiles_cache.dart';

/// Filled résumé thumbnail using Laravel `ResumeHtmlDemoData` (via `/resume/demo-profiles`).
class SeekerHtmlTemplateFilledPreview extends StatefulWidget {
  const SeekerHtmlTemplateFilledPreview({
    super.key,
    required this.templateKey,
    this.demoVariant = 0,
  });

  final String templateKey;
  final int demoVariant;

  @override
  State<SeekerHtmlTemplateFilledPreview> createState() => _SeekerHtmlTemplateFilledPreviewState();
}

class _SeekerHtmlTemplateFilledPreviewState extends State<SeekerHtmlTemplateFilledPreview> {
  ResumeDemoViewProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void didUpdateWidget(SeekerHtmlTemplateFilledPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.demoVariant != widget.demoVariant) {
      _applyProfile(ResumeDemoProfilesCache.instance.profileForVariant(widget.demoVariant));
    }
  }

  Future<void> _loadProfile() async {
    _applyProfile(ResumeDemoProfilesCache.instance.profileForVariant(widget.demoVariant));
    final profiles = await ResumeDemoProfilesCache.instance.ensureLoaded();
    if (!mounted) return;
    final v = widget.demoVariant % profiles.length;
    _applyProfile(profiles[v]);
  }

  void _applyProfile(ResumeDemoViewProfile p) {
    if (_profile?.variant == p.variant && _profile?.fullName == p.fullName) return;
    setState(() => _profile = p);
  }

  ResumeDemoViewProfile get _p =>
      _profile ?? ResumeDemoProfilesCache.instance.profileForVariant(widget.demoVariant);

  String get _name => _p.fullName;
  String get _title => _p.professionalTitle;
  String get _mobile => _p.mobile;
  String get _email => _p.email;
  List<String> get _skills => _p.skills;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 200,
            height: 280,
            child: ClipRect(
              child: _layoutForKey(widget.templateKey),
            ),
          ),
        );
      },
    );
  }

  Widget _layoutForKey(String key) {
    switch (key) {
      case 't1_teal_sidebar':
        return _twoColumn(
          sideColor: const Color(0xFF0D7377),
          sideText: Colors.white,
          mainBg: Colors.white,
          accent: const Color(0xFF0D7377),
        );
      case 't2_minimal':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF334155)],
                ),
              ),
              child: _headerBlock(Colors.white, Colors.white70, showPhoto: true),
            ),
            Expanded(
              child: ColoredBox(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: _mainBlock(const Color(0xFF0F172A), Colors.black87),
                ),
              ),
            ),
          ],
        );
      case 't3_bold_navy':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 6, color: const Color(0xFF1E3A5F)),
            Expanded(
              child: ColoredBox(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _headerBlock(const Color(0xFF1E3A5F), const Color(0xFF3B82F6)),
                      const SizedBox(height: 6),
                      Expanded(child: _mainBlock(const Color(0xFF1E3A5F), Colors.black87)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      case 't4_classic_serif':
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 62,
              child: ColoredBox(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _headerBlock(const Color(0xFF0C0A09), const Color(0xFF78716C)),
                      const SizedBox(height: 6),
                      Expanded(child: _mainBlock(const Color(0xFF9F1239), Colors.black87)),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 38,
              child: ColoredBox(
                color: const Color(0xFFFFF7ED),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _avatar(16, border: const Color(0xFF9F1239)),
                      const SizedBox(height: 6),
                      Expanded(child: _sideSkills(const Color(0xFF9F1239))),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      case 't5_modern_split':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
              ),
              child: _headerBlock(Colors.white, Colors.white70),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 72,
                    color: const Color(0xFF334155),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _avatar(18, border: const Color(0xFFC7D2FE)),
                        const SizedBox(height: 6),
                        _contactBlock(const Color(0xFFC7D2FE), onDark: true),
                        const SizedBox(height: 6),
                        Expanded(child: _sideSkills(const Color(0xFFC7D2FE), onDark: true)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ColoredBox(
                      color: const Color(0xFF1E293B),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: _mainBlock(const Color(0xFFC7D2FE), Colors.white70, onDark: true),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case 't6_navy_two_column':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: const Color(0xFF152238),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  _avatar(22, border: Colors.white38),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_name, style: _t(11, Colors.white, FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(_title, style: _t(8, Colors.white70, FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 56, color: const Color(0xFFF1F5F9), child: _sideSkills(const Color(0xFF152238))),
                  Expanded(child: _mainBlock(const Color(0xFF152238), Colors.black87)),
                ],
              ),
            ),
          ],
        );
      case 't7_geometric_modern':
        return _twoColumn(
          sideColor: const Color(0xFFF0FDFA),
          sideText: const Color(0xFF0F172A),
          mainBg: Colors.white,
          accent: const Color(0xFF06B6D4),
          sideBorder: const Color(0xFF06B6D4),
        );
      case 't8_typewriter_retro':
        return ColoredBox(
          color: const Color(0xFFF4E8D0),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Text(_name.toUpperCase(), style: _t(12, const Color(0xFF78350F), FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis)),
                const SizedBox(height: 4),
                Center(child: Text(_title, style: _t(9, const Color(0xFF78350F), FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis)),
                const Divider(color: Color(0xFF78350F)),
                Expanded(child: _mainBlock(const Color(0xFF78350F), const Color(0xFF292524))),
              ],
            ),
          ),
        );
      case 't9_vintage_folio':
        return Padding(
          padding: const EdgeInsets.all(6),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFA8A29E)),
              color: const Color(0xFFFAF7F2),
            ),
            child: _twoColumn(
              sideColor: const Color(0xFFE7E5E4),
              sideText: const Color(0xFF44403C),
              mainBg: Colors.white,
              accent: const Color(0xFF78716C),
            ),
          ),
        );
      case 't10_creative_sunset':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFFF97316), Color(0xFFEC4899), Color(0xFF8B5CF6)]),
              ),
              child: _headerBlock(Colors.white, Colors.white70),
            ),
            Expanded(
              child: _twoColumn(
                sideColor: const Color(0xFFFFF7ED),
                sideText: const Color(0xFF9A3412),
                mainBg: Colors.white,
                accent: const Color(0xFFEA580C),
              ),
            ),
          ],
        );
      case 't11_mono_swiss':
        return Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_name, style: _t(14, Colors.black, FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis),
              Container(height: 2, margin: const EdgeInsets.only(top: 6, bottom: 8), color: Colors.black),
              Text(_title, style: _t(9, Colors.black54, FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Expanded(child: _mainBlock(Colors.black, Colors.black87)),
            ],
          ),
        );
      case 't12_royal_gold':
        return Padding(
          padding: const EdgeInsets.all(5),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFC9A227)),
              color: const Color(0xFF0C1929),
            ),
            child: _twoColumn(
              sideColor: const Color(0xFF132337),
              sideText: const Color(0xFFC9A227),
              mainBg: const Color(0xFF0C1929),
              accent: const Color(0xFFC9A227),
              onDark: true,
            ),
          ),
        );
      default:
        return _twoColumn(
          sideColor: const Color(0xFF0D7377),
          sideText: Colors.white,
          mainBg: Colors.white,
          accent: const Color(0xFF0D7377),
        );
    }
  }

  Widget _twoColumn({
    required Color sideColor,
    required Color sideText,
    required Color mainBg,
    required Color accent,
    Color? sideBorder,
    bool onDark = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 72,
          decoration: BoxDecoration(
            color: sideColor,
            border: sideBorder != null ? Border(right: BorderSide(color: sideBorder, width: 3)) : null,
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _avatar(16, border: sideText.withValues(alpha: 0.4)),
              const SizedBox(height: 4),
              _contactBlock(sideText, onDark: onDark),
              const SizedBox(height: 4),
              Text('SKILLS', style: _t(6.5, sideText.withValues(alpha: 0.85), FontWeight.w800)),
              const SizedBox(height: 4),
              ..._skills.take(4).map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '• $s',
                        style: _t(7, sideText, FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
            ],
          ),
        ),
        Expanded(
          child: ColoredBox(
            color: mainBg,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _name,
                    style: _t(12, onDark ? Colors.white : accent, FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _title,
                    style: _t(8, onDark ? Colors.white70 : Colors.black54, FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Expanded(child: _mainBlock(onDark ? Colors.white : accent, onDark ? Colors.white70 : Colors.black87, onDark: onDark)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _headerBlock(Color titleColor, Color subColor, {bool showPhoto = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_name, style: _t(12, titleColor, FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(_title, style: _t(8, subColor, FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        if (showPhoto) ...[
          const SizedBox(width: 4),
          _avatar(14, border: titleColor.withValues(alpha: 0.5)),
        ],
      ],
    );
  }

  Widget _mainBlock(Color accent, Color lineColor, {bool onDark = false}) {
    final summary = _p.summarySnippet;
    final workLine = _p.primaryWorkLine;
    final workBody = _p.primaryWorkBody;
    final projectLine = _p.primaryProjectLine;
    final internLine = _p.primaryInternshipLine;
    final eduLine = _p.primaryEducationLine;
    final certLine = _p.primaryCertLine;
    final bodyStyle = _t(5.5, lineColor.withValues(alpha: onDark ? 0.92 : 0.88), FontWeight.w500);

    return ListView(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Text('SUMMARY', style: _t(6.5, accent, FontWeight.w800)),
        const SizedBox(height: 2),
        Text(
          summary.isNotEmpty ? summary : 'Experienced professional with a strong track record.',
          style: bodyStyle,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        if (workLine != null) ...[
          const SizedBox(height: 5),
          Text('EXPERIENCE', style: _t(6.5, accent, FontWeight.w800)),
          const SizedBox(height: 2),
          Text(workLine, style: _t(5.5, lineColor, FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
          if (workBody != null)
            Text(workBody, style: bodyStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
        if (projectLine != null) ...[
          const SizedBox(height: 5),
          Text('PROJECTS', style: _t(6.5, accent, FontWeight.w800)),
          const SizedBox(height: 2),
          Text(projectLine, style: bodyStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
        if (internLine != null) ...[
          const SizedBox(height: 5),
          Text('INTERNSHIPS', style: _t(6.5, accent, FontWeight.w800)),
          const SizedBox(height: 2),
          Text(internLine, style: bodyStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
        if (eduLine != null) ...[
          const SizedBox(height: 5),
          Text('EDUCATION', style: _t(6.5, accent, FontWeight.w800)),
          const SizedBox(height: 2),
          Text(eduLine, style: bodyStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
        if (certLine != null) ...[
          const SizedBox(height: 5),
          Text('CERTIFICATIONS', style: _t(6.5, accent, FontWeight.w800)),
          const SizedBox(height: 2),
          Text(certLine, style: bodyStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ],
    );
  }

  Widget _contactBlock(Color color, {bool onDark = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CONTACT', style: _t(6, color.withValues(alpha: 0.85), FontWeight.w800)),
        const SizedBox(height: 2),
        Text(_mobile, style: _t(6, onDark ? Colors.white70 : color, FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(_email, style: _t(5.5, onDark ? Colors.white60 : color.withValues(alpha: 0.9), FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _sideSkills(Color accent, {bool onDark = false}) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Skills', style: _t(8, accent, FontWeight.w800)),
          const SizedBox(height: 6),
          ..._skills.take(6).map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    '• $s',
                    style: _t(7, onDark ? Colors.white70 : Colors.black87, FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _avatar(double r, {required Color border}) {
    final url = _p.photoUrl?.trim();
    final size = r * 2;
    Widget child;
    if (url != null && url.isNotEmpty) {
      child = ClipOval(
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Icon(Icons.person_rounded, size: r, color: border.withValues(alpha: 0.9)),
        ),
      );
    } else {
      child = Icon(Icons.person_rounded, size: r, color: border.withValues(alpha: 0.9));
    }
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: border.withValues(alpha: 0.2),
          border: Border.all(color: border, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }

  TextStyle _t(double size, Color color, FontWeight weight) =>
      TextStyle(fontSize: size, color: color, fontWeight: weight, height: 1.15);
}
