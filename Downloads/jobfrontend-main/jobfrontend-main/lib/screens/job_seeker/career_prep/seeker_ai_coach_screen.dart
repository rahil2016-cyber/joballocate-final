import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/app_session.dart';
import '../../../services/job_seeker_api_service.dart';
import '../../../utils/app_colors.dart';

/// One block of AI output (markdown-style heading or numbered section).
class _CoachSection {
  const _CoachSection({required this.title, required this.body});

  final String title;
  final String body;
}

/// Calls `POST /job-seeker/career/ai-coach` with [kind] `career_path` or `interview_prep`.
/// Generated text is stored locally per user + [kind] until the user taps Regenerate.
class SeekerAiCoachScreen extends StatefulWidget {
  const SeekerAiCoachScreen({
    super.key,
    required this.kind,
  });

  final String kind;

  @override
  State<SeekerAiCoachScreen> createState() => _SeekerAiCoachScreenState();
}

class _SeekerAiCoachScreenState extends State<SeekerAiCoachScreen> {
  final _focusCtrl = TextEditingController();
  String? _text;
  String? _error;
  bool _loading = false;
  bool _restoring = true;

  static const _prefsPrefix = 'seeker_ai_coach_v1_';

  @override
  void initState() {
    super.initState();
    _restoreFromDisk();
  }

  @override
  void dispose() {
    _focusCtrl.dispose();
    super.dispose();
  }

  bool get _isCareer => widget.kind == 'career_path';

  String get _title =>
      _isCareer ? 'AI career path' : 'AI interview prep';

  String get _storageKey {
    final uid = AppSession.userId ?? 'anon';
    return '$_prefsPrefix${widget.kind}_$uid';
  }

  Future<void> _restoreFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = AppSession.userId;
      if (uid == null || uid.isEmpty) {
        if (mounted) setState(() => _restoring = false);
        return;
      }
      final v = prefs.getString(_storageKey);
      if (mounted) {
        setState(() {
          if (v != null && v.trim().isNotEmpty) {
            _text = v;
          }
          _restoring = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _restoring = false);
    }
  }

  Future<void> _persist(String text) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = AppSession.userId;
      if (uid == null || uid.isEmpty) return;
      await prefs.setString(_storageKey, text);
    } catch (_) {}
  }

  Future<void> _run() async {
    if (!AppSession.isLoggedIn) {
      setState(() => _error = 'Please sign in again.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await JobSeekerApiService.instance.postCareerAiCoach(
        kind: widget.kind,
        focus: _focusCtrl.text,
      );
      if (!mounted) return;
      final newText = data['text']?.toString();
      setState(() {
        _text = newText;
        _loading = false;
      });
      if (newText != null && newText.trim().isNotEmpty) {
        await _persist(newText.trim());
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// Split AI output into titled sections using `##` / `###` or `1. Title` line starts.
  List<_CoachSection> _parseIntoSections(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return [];

    final splitter = RegExp(
      r'(?=^(?:#{1,3}\s|\d+\.\s).+$)',
      multiLine: true,
    );
    final chunks =
        text.split(splitter).map((c) => c.trim()).where((c) => c.isNotEmpty).toList();

    if (chunks.isEmpty) {
      return [_CoachSection(title: _isCareer ? 'Your career plan' : 'Your prep guide', body: text)];
    }

    final out = <_CoachSection>[];
    for (final chunk in chunks) {
      final lines = chunk.split('\n');
      if (lines.isEmpty) continue;
      final head = lines.first.trim();
      final hash = RegExp(r'^#{1,3}\s+(.+)$').firstMatch(head);
      final numbered = RegExp(r'^\d+\.\s+(.+)$').firstMatch(head);

      String sectionTitle;
      String body;
      if (hash != null) {
        sectionTitle = hash.group(1)!.trim();
        body = lines.skip(1).join('\n').trim();
      } else if (numbered != null) {
        sectionTitle = numbered.group(1)!.trim();
        body = lines.skip(1).join('\n').trim();
      } else {
        sectionTitle = _isCareer ? 'Overview' : 'Tips';
        body = chunk.trim();
      }

      if (sectionTitle.isEmpty && body.isEmpty) continue;
      out.add(_CoachSection(
        title: sectionTitle.isEmpty ? 'Details' : sectionTitle,
        body: body,
      ));
    }

    if (out.isEmpty) {
      return [_CoachSection(title: _isCareer ? 'Your career plan' : 'Your prep guide', body: text)];
    }
    return out;
  }

  Widget _buildBodyContent(String body, TextTheme tt) {
    final lines = body.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      final t = line.trimRight();
      if (t.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }
      final bullet = RegExp(r'^[-•*]\s+(.+)$').firstMatch(t);
      final numBullet = RegExp(r'^(\d+)\.\s+(.+)$').firstMatch(t);
      if (bullet != null) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SelectableText(
                    bullet.group(1)!,
                    style: tt.bodyMedium?.copyWith(height: 1.45, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (numBullet != null && numBullet.group(1) != null) {
        // Sub-numbered line inside body (not used as section header)
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '${numBullet.group(1)}.',
                    style: tt.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: SelectableText(
                    numBullet.group(2) ?? '',
                    style: tt.bodyMedium?.copyWith(height: 1.45),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: SelectableText(
              t,
              style: tt.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
        );
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }

  Widget _buildSectionCards(String fullText, TextTheme tt) {
    final sections = _parseIntoSections(fullText);
    return Column(
      children: List.generate(sections.length, (i) {
        final s = sections[i];
        return Padding(
          padding: EdgeInsets.only(bottom: i < sections.length - 1 ? 14 : 0),
          child: Material(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.title,
                              style: tt.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: Colors.grey.shade100),
                  const SizedBox(height: 14),
                  if (s.body.trim().isEmpty)
                    Text(
                      '—',
                      style: tt.bodySmall?.copyWith(
                        color: AppColors.textPrimary.withValues(alpha: 0.4),
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    _buildBodyContent(s.body, tt),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    if (_restoring) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(_title),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final hasPlan = _text != null && _text!.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          if (hasPlan)
            IconButton(
              tooltip: 'Copy entire plan',
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _text!));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Full plan copied')),
                  );
                }
              },
              icon: const Icon(Icons.copy_rounded),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            _isCareer
                ? 'Get a personalized career roadmap based on your profile (role, skills, location).'
                : 'Practice-oriented tips and question themes tailored to your profile. Add a target role or company below (optional).',
            style: tt.bodyMedium?.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.75),
              height: 1.4,
            ),
          ),
          if (!_isCareer) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _focusCtrl,
              maxLines: 3,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: 'Focus (optional)',
                hintText: 'e.g. Software engineer at product companies',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loading ? null : _run,
            icon: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(hasPlan ? Icons.refresh_rounded : Icons.auto_awesome_rounded),
            label: Text(
              _loading
                  ? 'Generating…'
                  : hasPlan
                      ? 'Regenerate'
                      : 'Generate',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          if (hasPlan) ...[
            const SizedBox(height: 10),
            Material(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.bookmark_outline_rounded, size: 22, color: AppColors.primary.withValues(alpha: 0.9)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This plan stays on your device until you tap Regenerate.',
                        style: tt.bodySmall?.copyWith(
                          color: AppColors.textPrimary.withValues(alpha: 0.85),
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Material(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline_rounded, color: Colors.red.shade800, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: tt.bodySmall?.copyWith(color: Colors.red.shade900, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (hasPlan) ...[
            const SizedBox(height: 22),
            Row(
              children: [
                Text(
                  _isCareer ? 'Your roadmap' : 'Your guide',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                Text(
                  '${_parseIntoSections(_text!).length} sections',
                  style: tt.labelMedium?.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildSectionCards(_text!, tt),
          ],
        ],
      ),
    );
  }
}
