import 'package:flutter/material.dart';
import 'package:joballocate/features/resume/models/resume_model.dart';

import 'resume_model_blocks.dart';
import 'resume_typography.dart';

/// Minimal single-column résumé — black & white ATS layout (fixed structure; content-only edits).
class MinimalAtsLayout extends StatelessWidget {
  const MinimalAtsLayout({super.key, required this.model, required this.typography});

  final ResumeModel model;
  final ResumeTypography typography;

  static const Color _ink = Color(0xFF111111);
  static const Color _muted = Color(0xFF424242);

  String _pd(String label) {
    final want = label.trim().toLowerCase();
    for (final r in model.personalDetails) {
      if (r.label.trim().toLowerCase() == want) return r.value.trim();
    }
    return '';
  }

  TextStyle _capsStyle() =>
      typography.sectionCaps().copyWith(color: _ink, letterSpacing: 1.0, fontWeight: FontWeight.w800);

  TextStyle _body(double size) => typography.body(size).copyWith(color: _ink, height: 1.35);

  TextStyle _small() => typography.caption(9.5).copyWith(color: _muted);

  Widget _sectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title.trim().toUpperCase(), style: _capsStyle()),
        const SizedBox(height: 6),
        Container(height: 1, color: _ink),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _headerDivider() {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: Container(height: 1, color: _ink),
    );
  }

  Widget _contactBar() {
    final linkedIn = _pd('LinkedIn');
    final location = _pd('Current Location');
    final chips = <Widget>[];

    void push(IconData icon, String text) {
      if (text.isEmpty) return;
      if (chips.isNotEmpty) {
        chips.add(Text('  |  ', style: _small()));
      }
      chips.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: _muted),
            const SizedBox(width: 4),
            Flexible(
              child: Text(text, style: typography.caption(10).copyWith(color: _ink), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );
    }

    push(Icons.phone_outlined, model.contact.mobile.trim());
    push(Icons.mail_outline, model.contact.email.trim());
    push(Icons.link, linkedIn);
    push(Icons.place_outlined, location);

    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 6,
      children: chips,
    );
  }

  bool _schoolingHasData() {
    final s12 = model.education.schooling.class12;
    final s10 = model.education.schooling.class10;
    return [s12.boardName, s12.medium, s12.yearOfPassing, s12.score, s10.boardName, s10.medium, s10.yearOfPassing, s10.score]
        .any((s) => s.trim().isNotEmpty);
  }

  Iterable<PersonalDetailRow> _extraPersonalRows() {
    const skip = {'linkedin', 'current location'};
    return model.personalDetails.where((r) {
      final k = r.label.trim().toLowerCase();
      return !skip.contains(k) && (r.label.trim().isNotEmpty || r.value.trim().isNotEmpty);
    });
  }

  @override
  Widget build(BuildContext context) {
    final v = model.sectionVisible;
    final name = model.fullName.trim().isEmpty ? '\u00A0' : model.fullName.trim().toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(name, style: typography.nameLarge().copyWith(fontSize: 22, color: _ink, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
        if (model.professionalTitle.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              model.professionalTitle.trim().toUpperCase(),
              style: typography.titleLine().copyWith(color: _muted, fontSize: 11, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
        if (v[ResumeSectionKeys.sidebar] ?? true) ...[
          const SizedBox(height: 12),
          _contactBar(),
        ],
        _headerDivider(),
        if (v[ResumeSectionKeys.summary] ?? true) ...[
          _sectionTitle('Summary'),
          Text(model.summary, style: _body(11)),
          const SizedBox(height: 16),
        ],
        if (v[ResumeSectionKeys.work] ?? true) ...[
          _sectionTitle('Experience'),
          for (var i = 0; i < model.workExperience.length; i++) ...[
            _MinimalAtsJobTile(item: model.workExperience[i], bodyStyle: _body(10), mutedStyle: _small()),
            if (i < model.workExperience.length - 1) const Divider(height: 20, thickness: 0.6, color: Color(0xFFE0E0E0)),
          ],
          const SizedBox(height: 16),
        ],
        if ((v[ResumeSectionKeys.internships] ?? true) && model.internships.isNotEmpty) ...[
          _sectionTitle('Internships'),
          for (final e in model.internships) _MinimalAtsJobTile(item: e, bodyStyle: _body(10), mutedStyle: _small()),
          const SizedBox(height: 16),
        ],
        if (v[ResumeSectionKeys.education] ?? true) ...[
          _sectionTitle('Education'),
          _MinimalAtsGradRow(model: model, ink: _ink, muted: _muted, typography: typography),
          if (_schoolingHasData()) ...[
            const SizedBox(height: 10),
            ResumeEducationStandard(model: model, typography: typography),
          ],
          const SizedBox(height: 16),
        ],
        if (v[ResumeSectionKeys.skills] ?? true) ...[
          _sectionTitle('Skills'),
          LayoutBuilder(
            builder: (context, cons) {
              final list = model.skills.where((s) => s.trim().isNotEmpty).toList();
              if (list.isEmpty) return const SizedBox.shrink();
              final w = cons.maxWidth.isFinite ? cons.maxWidth : 700.0;
              final col = ((w - 32) / 5).clamp(96.0, 200.0);
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: list
                    .map(
                      (s) => SizedBox(
                        width: col,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• ', style: _body(10)),
                            Expanded(child: Text(s.trim(), style: _body(10))),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
        if (((v[ResumeSectionKeys.languages] ?? true) || (v[ResumeSectionKeys.certifications] ?? true)) &&
            (model.languages.any((s) => s.trim().isNotEmpty) || model.certifications.any((s) => s.trim().isNotEmpty))) ...[
          _sectionTitle('Languages & certifications'),
          ResumeLanguagesCerts(
            languages: model.languages,
            certifications: model.certifications,
            typography: typography,
          ),
          const SizedBox(height: 16),
        ],
        if ((v[ResumeSectionKeys.personal] ?? true) && _extraPersonalRows().isNotEmpty) ...[
          _sectionTitle('Personal details'),
          ResumePersonalGrid(rows: _extraPersonalRows().toList(), typography: typography),
          const SizedBox(height: 16),
        ],
        if ((v[ResumeSectionKeys.projects] ?? true) && model.projects.isNotEmpty) ...[
          _sectionTitle('Projects'),
          for (final e in model.projects)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _MinimalAtsJobTile(item: e, bodyStyle: _body(10), mutedStyle: _small()),
            ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _MinimalAtsGradRow extends StatelessWidget {
  const _MinimalAtsGradRow({required this.model, required this.ink, required this.muted, required this.typography});

  final ResumeModel model;
  final Color ink;
  final Color muted;
  final ResumeTypography typography;

  @override
  Widget build(BuildContext context) {
    final g = model.education.graduation;
    final left = '${g.course.trim()}${g.course.trim().isNotEmpty && g.college.trim().isNotEmpty ? ' | ' : ''}${g.college.trim()}';
    final date = g.score.trim();
    if (left.isEmpty && date.isEmpty) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            left.isEmpty ? '\u00A0' : left,
            style: typography.accentText(11, FontWeight.w800).copyWith(color: ink),
          ),
        ),
        if (date.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(date, style: typography.caption(10).copyWith(color: muted, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}

class _MinimalAtsJobTile extends StatelessWidget {
  const _MinimalAtsJobTile({required this.item, required this.bodyStyle, required this.mutedStyle});

  final ExperienceItem item;
  final TextStyle bodyStyle;
  final TextStyle mutedStyle;

  @override
  Widget build(BuildContext context) {
    final company = item.companyName.trim();
    final dates = item.dateRange.trim();
    final bullets = item.bullets.where((b) => b.trim().isNotEmpty).toList();
    if (company.isEmpty && dates.isEmpty && bullets.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  company.isEmpty ? '\u00A0' : company,
                  style: bodyStyle.copyWith(fontWeight: FontWeight.w800, fontSize: 11),
                ),
              ),
              if (dates.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(dates, style: mutedStyle.copyWith(fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (final line in bullets)
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: bodyStyle),
                  Expanded(child: Text(line.trim(), style: bodyStyle)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Accent band header + airy single-column body.
class ModernProfessionalLayout extends StatelessWidget {
  const ModernProfessionalLayout({super.key, required this.model, required this.typography});

  final ResumeModel model;
  final ResumeTypography typography;

  @override
  Widget build(BuildContext context) {
    final v = model.sectionVisible;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          decoration: BoxDecoration(
            color: typography.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border(left: BorderSide(color: typography.accent, width: 5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                model.fullName.trim().isEmpty ? '\u00A0' : model.fullName,
                style: typography.nameLarge(),
              ),
              if (model.professionalTitle.trim().isNotEmpty)
                Text(model.professionalTitle, style: typography.titleLine()),
              if (v[ResumeSectionKeys.sidebar] ?? true) ...[
                const SizedBox(height: 8),
                ResumeContactLine(mobile: model.contact.mobile, email: model.contact.email, typography: typography),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (v[ResumeSectionKeys.summary] ?? true) ...[
          ResumeSectionCaps(title: 'Professional summary', typography: typography),
          Text(model.summary, style: typography.body()),
          const SizedBox(height: 14),
        ],
        if (v[ResumeSectionKeys.skills] ?? true) ...[
          ResumeSectionCaps(title: 'Core skills', typography: typography),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: model.skills
                .where((s) => s.trim().isNotEmpty)
                .map(
                  (s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: typography.accent.withValues(alpha: 0.35)),
                      color: typography.secondary.withValues(alpha: 0.06),
                    ),
                    child: Text(s, style: typography.caption(10)),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
        ],
        if (v[ResumeSectionKeys.personal] ?? true) ...[
          ResumeSectionCaps(title: 'Personal details', typography: typography),
          ResumePersonalGrid(rows: model.personalDetails, typography: typography),
          const SizedBox(height: 14),
        ],
        if (v[ResumeSectionKeys.education] ?? true) ...[
          ResumeSectionCaps(title: 'Education', typography: typography),
          ResumeEducationStandard(model: model, typography: typography),
          const SizedBox(height: 14),
        ],
        if (v[ResumeSectionKeys.work] ?? true) ...[
          ResumeSectionCaps(title: 'Experience', typography: typography),
          for (final e in model.workExperience) ResumeExperienceTile(item: e, typography: typography),
        ],
        if (v[ResumeSectionKeys.internships] ?? true) ...[
          ResumeSectionCaps(title: 'Internships', typography: typography),
          for (final e in model.internships) ResumeExperienceTile(item: e, typography: typography),
        ],
        if (v[ResumeSectionKeys.projects] ?? true) ...[
          ResumeSectionCaps(title: 'Projects', typography: typography),
          for (final e in model.projects) ResumeExperienceTile(item: e, typography: typography),
        ],
        if ((v[ResumeSectionKeys.languages] ?? true) || (v[ResumeSectionKeys.certifications] ?? true)) ...[
          ResumeSectionCaps(title: 'Languages & certifications', typography: typography),
          ResumeLanguagesCerts(
            languages: model.languages,
            certifications: model.certifications,
            typography: typography,
          ),
        ],
      ],
    );
  }
}

/// Formal headers with navy accent rules (structured corporate rhythm).
class CorporateBlueLayout extends StatelessWidget {
  const CorporateBlueLayout({super.key, required this.model, required this.typography});

  final ResumeModel model;
  final ResumeTypography typography;

  @override
  Widget build(BuildContext context) {
    final v = model.sectionVisible;
    Widget corporateSection(String title, List<Widget> body) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: typography.accent, width: 2)),
              ),
              child: Text(title.toUpperCase(), style: typography.sectionCaps()),
            ),
            const SizedBox(height: 10),
            ...body,
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResumeAvatar(model: model, diameter: 72, accent: typography.accent, typography: typography),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(model.fullName.trim().isEmpty ? '\u00A0' : model.fullName, style: typography.nameLarge()),
                  if (model.professionalTitle.trim().isNotEmpty)
                    Text(model.professionalTitle, style: typography.titleLine()),
                  if (v[ResumeSectionKeys.sidebar] ?? true) ...[
                    const SizedBox(height: 6),
                    ResumeContactLine(mobile: model.contact.mobile, email: model.contact.email, typography: typography),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (v[ResumeSectionKeys.summary] ?? true)
          corporateSection('Executive summary', [Text(model.summary, style: typography.body())]),
        if (v[ResumeSectionKeys.skills] ?? true)
          corporateSection('Skills', [ResumeSkillsBlock(skills: model.skills, typography: typography)]),
        if (v[ResumeSectionKeys.personal] ?? true)
          corporateSection('Personal details', [ResumePersonalGrid(rows: model.personalDetails, typography: typography)]),
        if (v[ResumeSectionKeys.education] ?? true)
          corporateSection('Education', [ResumeEducationStandard(model: model, typography: typography)]),
        if (v[ResumeSectionKeys.work] ?? true)
          corporateSection(
            'Professional experience',
            [
              for (final e in model.workExperience) ResumeExperienceTile(item: e, typography: typography),
            ],
          ),
        if (v[ResumeSectionKeys.internships] ?? true)
          corporateSection(
            'Internships',
            [for (final e in model.internships) ResumeExperienceTile(item: e, typography: typography)],
          ),
        if (v[ResumeSectionKeys.projects] ?? true)
          corporateSection(
            'Projects',
            [for (final e in model.projects) ResumeExperienceTile(item: e, typography: typography)],
          ),
        if ((v[ResumeSectionKeys.languages] ?? true) || (v[ResumeSectionKeys.certifications] ?? true))
          corporateSection(
            'Languages & certifications',
            [
              ResumeLanguagesCerts(
                languages: model.languages,
                certifications: model.certifications,
                typography: typography,
              ),
            ],
          ),
      ],
    );
  }
}

/// Vertical accent rail — subtle creative signal without graphics-heavy ATS risk.
class CreativeCleanLayout extends StatelessWidget {
  const CreativeCleanLayout({super.key, required this.model, required this.typography});

  final ResumeModel model;
  final ResumeTypography typography;

  @override
  Widget build(BuildContext context) {
    final v = model.sectionVisible;
    final inner = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(model.fullName.trim().isEmpty ? '\u00A0' : model.fullName, style: typography.nameLarge()),
        if (model.professionalTitle.trim().isNotEmpty)
          Text(model.professionalTitle, style: typography.titleLine()),
        const SizedBox(height: 10),
        if (v[ResumeSectionKeys.sidebar] ?? true)
          ResumeContactLine(mobile: model.contact.mobile, email: model.contact.email, typography: typography),
        const SizedBox(height: 14),
        if (v[ResumeSectionKeys.summary] ?? true) ...[
          ResumeSectionCaps(title: 'Profile', typography: typography),
          Text(model.summary, style: typography.body()),
          const SizedBox(height: 14),
        ],
        if (v[ResumeSectionKeys.skills] ?? true) ...[
          ResumeSectionCaps(title: 'Expertise', typography: typography),
          ResumeSkillsBlock(skills: model.skills, typography: typography),
          const SizedBox(height: 14),
        ],
        if (v[ResumeSectionKeys.personal] ?? true) ...[
          ResumeSectionCaps(title: 'Personal', typography: typography),
          ResumePersonalGrid(rows: model.personalDetails, typography: typography),
          const SizedBox(height: 14),
        ],
        if (v[ResumeSectionKeys.education] ?? true) ...[
          ResumeSectionCaps(title: 'Education', typography: typography),
          ResumeEducationStandard(model: model, typography: typography),
          const SizedBox(height: 14),
        ],
        if (v[ResumeSectionKeys.work] ?? true) ...[
          ResumeSectionCaps(title: 'Experience', typography: typography),
          for (final e in model.workExperience) ResumeExperienceTile(item: e, typography: typography),
        ],
        if (v[ResumeSectionKeys.internships] ?? true) ...[
          ResumeSectionCaps(title: 'Internships', typography: typography),
          for (final e in model.internships) ResumeExperienceTile(item: e, typography: typography),
        ],
        if (v[ResumeSectionKeys.projects] ?? true) ...[
          ResumeSectionCaps(title: 'Projects', typography: typography),
          for (final e in model.projects) ResumeExperienceTile(item: e, typography: typography),
        ],
        if ((v[ResumeSectionKeys.languages] ?? true) || (v[ResumeSectionKeys.certifications] ?? true)) ...[
          ResumeSectionCaps(title: 'Languages & certifications', typography: typography),
          ResumeLanguagesCerts(
            languages: model.languages,
            certifications: model.certifications,
            typography: typography,
          ),
        ],
      ],
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 7, decoration: BoxDecoration(color: typography.accent, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 16),
          Expanded(child: inner),
        ],
      ),
    );
  }
}

/// Name/title left, contact stack right — leadership-forward hierarchy.
class ExecutiveResumeLayout extends StatelessWidget {
  const ExecutiveResumeLayout({super.key, required this.model, required this.typography});

  final ResumeModel model;
  final ResumeTypography typography;

  @override
  Widget build(BuildContext context) {
    final v = model.sectionVisible;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(model.fullName.trim().isEmpty ? '\u00A0' : model.fullName,
                      style: typography.nameLarge().copyWith(fontSize: 32)),
                  if (model.professionalTitle.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(model.professionalTitle, style: typography.titleLine()),
                    ),
                ],
              ),
            ),
            if (v[ResumeSectionKeys.sidebar] ?? true)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (model.contact.mobile.trim().isNotEmpty)
                    Text(model.contact.mobile, style: typography.caption(11)),
                  if (model.contact.email.trim().isNotEmpty)
                    Text(model.contact.email, style: typography.caption(11)),
                ],
              ),
          ],
        ),
        const SizedBox(height: 8),
        Divider(color: typography.accent.withValues(alpha: 0.35), thickness: 1.2),
        const SizedBox(height: 12),
        if (v[ResumeSectionKeys.summary] ?? true) ...[
          ResumeSectionCaps(title: 'Board-ready summary', typography: typography),
          Text(model.summary, style: typography.body()),
          const SizedBox(height: 14),
        ],
        if (v[ResumeSectionKeys.work] ?? true) ...[
          ResumeSectionCaps(title: 'Leadership experience', typography: typography),
          for (final e in model.workExperience) ResumeExperienceTile(item: e, typography: typography),
          const SizedBox(height: 12),
        ],
        if (v[ResumeSectionKeys.education] ?? true) ...[
          ResumeSectionCaps(title: 'Education', typography: typography),
          ResumeEducationStandard(model: model, typography: typography),
          const SizedBox(height: 12),
        ],
        if (v[ResumeSectionKeys.projects] ?? true) ...[
          ResumeSectionCaps(title: 'Strategic projects', typography: typography),
          for (final e in model.projects) ResumeExperienceTile(item: e, typography: typography),
        ],
        if (v[ResumeSectionKeys.internships] ?? true) ...[
          ResumeSectionCaps(title: 'Internships', typography: typography),
          for (final e in model.internships) ResumeExperienceTile(item: e, typography: typography),
        ],
        if (v[ResumeSectionKeys.skills] ?? true) ...[
          ResumeSectionCaps(title: 'Skills', typography: typography),
          ResumeSkillsBlock(skills: model.skills, typography: typography),
          const SizedBox(height: 12),
        ],
        if (v[ResumeSectionKeys.personal] ?? true) ...[
          ResumeSectionCaps(title: 'Personal details', typography: typography),
          ResumePersonalGrid(rows: model.personalDetails, typography: typography),
        ],
        if ((v[ResumeSectionKeys.languages] ?? true) || (v[ResumeSectionKeys.certifications] ?? true)) ...[
          const SizedBox(height: 12),
          ResumeSectionCaps(title: 'Languages & certifications', typography: typography),
          ResumeLanguagesCerts(
            languages: model.languages,
            certifications: model.certifications,
            typography: typography,
          ),
        ],
      ],
    );
  }
}

/// Education-first ordering tuned for early-career profiles.
class FresherResumeLayout extends StatelessWidget {
  const FresherResumeLayout({super.key, required this.model, required this.typography});

  final ResumeModel model;
  final ResumeTypography typography;

  @override
  Widget build(BuildContext context) {
    final v = model.sectionVisible;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            ResumeAvatar(model: model, diameter: 68, accent: typography.accent, typography: typography),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(model.fullName.trim().isEmpty ? '\u00A0' : model.fullName, style: typography.nameLarge()),
                  if (model.professionalTitle.trim().isNotEmpty)
                    Text(model.professionalTitle, style: typography.titleLine()),
                  if (v[ResumeSectionKeys.sidebar] ?? true)
                    ResumeContactLine(mobile: model.contact.mobile, email: model.contact.email, typography: typography),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (v[ResumeSectionKeys.summary] ?? true) ...[
          ResumeSectionCaps(title: 'Objective', typography: typography),
          Text(model.summary, style: typography.body()),
          const SizedBox(height: 14),
        ],
        if (v[ResumeSectionKeys.education] ?? true) ...[
          ResumeSectionCaps(title: 'Education', typography: typography),
          ResumeEducationStandard(model: model, typography: typography),
          const SizedBox(height: 14),
        ],
        if (v[ResumeSectionKeys.projects] ?? true) ...[
          ResumeSectionCaps(title: 'Academic projects', typography: typography),
          for (final e in model.projects) ResumeExperienceTile(item: e, typography: typography),
          const SizedBox(height: 14),
        ],
        if (v[ResumeSectionKeys.internships] ?? true) ...[
          ResumeSectionCaps(title: 'Internships', typography: typography),
          for (final e in model.internships) ResumeExperienceTile(item: e, typography: typography),
          const SizedBox(height: 14),
        ],
        if (v[ResumeSectionKeys.skills] ?? true) ...[
          ResumeSectionCaps(title: 'Technical skills', typography: typography),
          ResumeSkillsBlock(skills: model.skills, typography: typography, compact: true),
          const SizedBox(height: 14),
        ],
        if (v[ResumeSectionKeys.work] ?? true) ...[
          ResumeSectionCaps(title: 'Experience', typography: typography),
          for (final e in model.workExperience) ResumeExperienceTile(item: e, typography: typography),
        ],
        if (v[ResumeSectionKeys.personal] ?? true) ...[
          const SizedBox(height: 12),
          ResumeSectionCaps(title: 'Personal details', typography: typography),
          ResumePersonalGrid(rows: model.personalDetails, typography: typography),
        ],
        if ((v[ResumeSectionKeys.languages] ?? true) || (v[ResumeSectionKeys.certifications] ?? true)) ...[
          const SizedBox(height: 12),
          ResumeSectionCaps(title: 'Languages & certifications', typography: typography),
          ResumeLanguagesCerts(
            languages: model.languages,
            certifications: model.certifications,
            typography: typography,
          ),
        ],
      ],
    );
  }
}

/// Dark surface variant — relies on [ResumeTypography] inverse-friendly colors.
class DarkProfessionalLayout extends StatelessWidget {
  const DarkProfessionalLayout({super.key, required this.model, required this.typography});

  final ResumeModel model;
  final ResumeTypography typography;

  @override
  Widget build(BuildContext context) {
    final v = model.sectionVisible;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: typography.accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: typography.accent.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              ResumeAvatar(model: model, diameter: 74, accent: typography.accent, typography: typography),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(model.fullName.trim().isEmpty ? '\u00A0' : model.fullName, style: typography.nameLarge()),
                    if (model.professionalTitle.trim().isNotEmpty)
                      Text(model.professionalTitle, style: typography.titleLine()),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (v[ResumeSectionKeys.sidebar] ?? true)
          ResumeContactLine(mobile: model.contact.mobile, email: model.contact.email, typography: typography),
        const SizedBox(height: 12),
        if (v[ResumeSectionKeys.summary] ?? true) ...[
          ResumeSectionCaps(title: 'Summary', typography: typography),
          Text(model.summary, style: typography.body()),
          const SizedBox(height: 14),
        ],
        if (v[ResumeSectionKeys.skills] ?? true) ...[
          ResumeSectionCaps(title: 'Skills', typography: typography),
          ResumeSkillsBlock(skills: model.skills, typography: typography),
          const SizedBox(height: 14),
        ],
        if (v[ResumeSectionKeys.work] ?? true) ...[
          ResumeSectionCaps(title: 'Experience', typography: typography),
          for (final e in model.workExperience) ResumeExperienceTile(item: e, typography: typography),
        ],
        if (v[ResumeSectionKeys.education] ?? true) ...[
          const SizedBox(height: 12),
          ResumeSectionCaps(title: 'Education', typography: typography),
          ResumeEducationStandard(model: model, typography: typography),
        ],
        if (v[ResumeSectionKeys.internships] ?? true) ...[
          ResumeSectionCaps(title: 'Internships', typography: typography),
          for (final e in model.internships) ResumeExperienceTile(item: e, typography: typography),
        ],
        if (v[ResumeSectionKeys.projects] ?? true) ...[
          ResumeSectionCaps(title: 'Projects', typography: typography),
          for (final e in model.projects) ResumeExperienceTile(item: e, typography: typography),
        ],
        if (v[ResumeSectionKeys.personal] ?? true) ...[
          ResumeSectionCaps(title: 'Personal details', typography: typography),
          ResumePersonalGrid(rows: model.personalDetails, typography: typography),
        ],
        if ((v[ResumeSectionKeys.languages] ?? true) || (v[ResumeSectionKeys.certifications] ?? true)) ...[
          ResumeSectionCaps(title: 'Languages & certifications', typography: typography),
          ResumeLanguagesCerts(
            languages: model.languages,
            certifications: model.certifications,
            typography: typography,
          ),
        ],
      ],
    );
  }
}

/// Sidebar + main column — classic ATS parsing-friendly split.
class TwoColumnResumeLayout extends StatelessWidget {
  const TwoColumnResumeLayout({super.key, required this.model, required this.typography});

  final ResumeModel model;
  final ResumeTypography typography;

  static const double _side = 214;

  @override
  Widget build(BuildContext context) {
    final v = model.sectionVisible;
    final main = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(model.fullName.trim().isEmpty ? '\u00A0' : model.fullName, style: typography.nameLarge()),
          if (model.professionalTitle.trim().isNotEmpty)
            Text(model.professionalTitle, style: typography.titleLine()),
          const SizedBox(height: 12),
          if (v[ResumeSectionKeys.summary] ?? true) ...[
            ResumeSectionCaps(title: 'Summary', typography: typography),
            Text(model.summary, style: typography.body()),
            const SizedBox(height: 12),
          ],
          if (v[ResumeSectionKeys.personal] ?? true) ...[
            ResumeSectionCaps(title: 'Personal details', typography: typography),
            ResumePersonalGrid(rows: model.personalDetails, typography: typography),
            const SizedBox(height: 12),
          ],
          if (v[ResumeSectionKeys.education] ?? true) ...[
            ResumeSectionCaps(title: 'Education', typography: typography),
            ResumeEducationStandard(model: model, typography: typography),
            const SizedBox(height: 12),
          ],
          if (v[ResumeSectionKeys.work] ?? true) ...[
            ResumeSectionCaps(title: 'Experience', typography: typography),
            for (final e in model.workExperience) ResumeExperienceTile(item: e, typography: typography),
          ],
          if (v[ResumeSectionKeys.internships] ?? true) ...[
            ResumeSectionCaps(title: 'Internships', typography: typography),
            for (final e in model.internships) ResumeExperienceTile(item: e, typography: typography),
          ],
          if (v[ResumeSectionKeys.projects] ?? true) ...[
            ResumeSectionCaps(title: 'Projects', typography: typography),
            for (final e in model.projects) ResumeExperienceTile(item: e, typography: typography),
          ],
        ],
      ),
    );

    final sidebar = SizedBox(
      width: _side,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: typography.secondary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ResumeAvatar(model: model, diameter: 78, accent: typography.accent, typography: typography),
            const SizedBox(height: 12),
            if (v[ResumeSectionKeys.sidebar] ?? true) ...[
              ResumeSectionCaps(title: 'Contact', typography: typography),
              Align(
                alignment: Alignment.centerLeft,
                child: ResumeContactLine(mobile: model.contact.mobile, email: model.contact.email, typography: typography),
              ),
              const SizedBox(height: 10),
            ],
            if (v[ResumeSectionKeys.skills] ?? true) ...[
              ResumeSectionCaps(title: 'Skills', typography: typography),
              Align(
                alignment: Alignment.centerLeft,
                child: ResumeSkillsBlock(skills: model.skills, typography: typography),
              ),
              const SizedBox(height: 10),
            ],
            if (v[ResumeSectionKeys.languages] ?? true) ...[
              ResumeSectionCaps(title: 'Languages', typography: typography),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  model.languages.where((s) => s.trim().isNotEmpty).join(', '),
                  style: typography.caption(10),
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (v[ResumeSectionKeys.certifications] ?? true) ...[
              ResumeSectionCaps(title: 'Certifications', typography: typography),
              Align(
                alignment: Alignment.centerLeft,
                child: ResumeBulletStrings(
                  lines: model.certifications.where((s) => s.trim().isNotEmpty).toList(),
                  typography: typography,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sidebar,
        const SizedBox(width: 14),
        main,
      ],
    );
  }
}

/// Dense single-column résumé — fits more lines per page while staying textual.
class CompactAtsLayout extends StatelessWidget {
  const CompactAtsLayout({super.key, required this.model, required this.typography});

  final ResumeModel model;
  final ResumeTypography typography;

  @override
  Widget build(BuildContext context) {
    final compactTypo = ResumeTypography(
      accent: typography.accent,
      primary: typography.primary,
      secondary: typography.secondary,
      headingFamily: typography.headingFamily,
      bodyFamily: typography.bodyFamily,
      scale: typography.scale * 0.88,
    );
    return MinimalAtsLayout(model: model, typography: compactTypo);
  }
}

/// Generous vertical rhythm — pairs well with serif headings from studio settings.
class ElegantModernLayout extends StatelessWidget {
  const ElegantModernLayout({super.key, required this.model, required this.typography});

  final ResumeModel model;
  final ResumeTypography typography;

  @override
  Widget build(BuildContext context) {
    final v = model.sectionVisible;
    Widget gap([double h = 18]) => SizedBox(height: h);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResumeAvatar(model: model, diameter: 78, accent: typography.accent, typography: typography),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(model.fullName.trim().isEmpty ? '\u00A0' : model.fullName, style: typography.nameLarge()),
                  if (model.professionalTitle.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(model.professionalTitle, style: typography.titleLine()),
                    ),
                ],
              ),
            ),
          ],
        ),
        gap(16),
        if (v[ResumeSectionKeys.sidebar] ?? true)
          ResumeContactLine(mobile: model.contact.mobile, email: model.contact.email, typography: typography),
        gap(18),
        if (v[ResumeSectionKeys.summary] ?? true) ...[
          ResumeSectionCaps(title: 'Profile narrative', typography: typography),
          Text(model.summary, style: typography.body(12)),
          gap(18),
        ],
        if (v[ResumeSectionKeys.skills] ?? true) ...[
          ResumeSectionCaps(title: 'Expertise clusters', typography: typography),
          Text(
            model.skills.where((s) => s.trim().isNotEmpty).join(' · '),
            style: typography.body(11),
          ),
          gap(18),
        ],
        if (v[ResumeSectionKeys.personal] ?? true) ...[
          ResumeSectionCaps(title: 'Personal details', typography: typography),
          ResumePersonalGrid(rows: model.personalDetails, typography: typography),
          gap(18),
        ],
        if (v[ResumeSectionKeys.education] ?? true) ...[
          ResumeSectionCaps(title: 'Education', typography: typography),
          ResumeEducationStandard(model: model, typography: typography),
          gap(18),
        ],
        if (v[ResumeSectionKeys.work] ?? true) ...[
          ResumeSectionCaps(title: 'Professional journey', typography: typography),
          for (final e in model.workExperience) ResumeExperienceTile(item: e, typography: typography),
          gap(14),
        ],
        if (v[ResumeSectionKeys.internships] ?? true) ...[
          ResumeSectionCaps(title: 'Internships', typography: typography),
          for (final e in model.internships) ResumeExperienceTile(item: e, typography: typography),
          gap(14),
        ],
        if (v[ResumeSectionKeys.projects] ?? true) ...[
          ResumeSectionCaps(title: 'Highlighted projects', typography: typography),
          for (final e in model.projects) ResumeExperienceTile(item: e, typography: typography),
          gap(14),
        ],
        if ((v[ResumeSectionKeys.languages] ?? true) || (v[ResumeSectionKeys.certifications] ?? true)) ...[
          ResumeSectionCaps(title: 'Languages & certifications', typography: typography),
          ResumeLanguagesCerts(
            languages: model.languages,
            certifications: model.certifications,
            typography: typography,
          ),
        ],
      ],
    );
  }
}

