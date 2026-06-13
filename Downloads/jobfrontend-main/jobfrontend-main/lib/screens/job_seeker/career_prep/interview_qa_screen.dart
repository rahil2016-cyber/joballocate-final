import 'package:flutter/material.dart';
import '../../../services/job_seeker_api_service.dart';
import '../../../utils/app_colors.dart';

class InterviewQaScreen extends StatefulWidget {
  const InterviewQaScreen({super.key});

  @override
  State<InterviewQaScreen> createState() => _InterviewQaScreenState();
}

class _InterviewQaScreenState extends State<InterviewQaScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _categories = [];
  String _selectedCategory = '';

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
      final data = await JobSeekerApiService.instance.getCareerContents('interview_qa');
      if (!mounted) return;
      final raw = data['categories'];
      final list = raw is List
          ? raw.map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : <Map<String, dynamic>>[];
      final firstCat = list.isNotEmpty ? (list.first['category']?.toString() ?? '') : '';
      setState(() {
        _categories = list;
        if (_selectedCategory.isEmpty || !list.any((c) => c['category'] == _selectedCategory)) {
          _selectedCategory = firstCat;
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  int? _parseId(dynamic id) {
    if (id is int) return id;
    if (id is num) return id.toInt();
    return int.tryParse('$id');
  }

  Future<void> _toggleHelpful(Map<String, dynamic> item) async {
    final id = _parseId(item['id']);
    if (id == null) return;
    final currently = item['user_marked_helpful'] == true;
    try {
      final res = await JobSeekerApiService.instance.setCareerContentHelpful(
        id,
        helpful: !currently,
      );
      if (!mounted) return;
      setState(() {
        item['user_marked_helpful'] = res['user_marked_helpful'] == true;
        item['helpful_count'] = res['helpful_count'] ?? item['helpful_count'];
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    List<dynamic> questions = [];
    for (final c in _categories) {
      if (c['category']?.toString() == _selectedCategory) {
        final items = c['items'];
        questions = items is List ? items : [];
        break;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Interview Q/A Pro',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            FilledButton(onPressed: _load, child: const Text('Retry')),
                          ],
                        ),
                      ),
                    ],
                  )
                : _categories.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 80),
                          Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'No interview questions yet. Admins add Q&A from the web console — check back soon.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Container(
                            height: 60,
                            color: Colors.white,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              children: _categories.map((category) {
                                final name = category['category']?.toString() ?? '';
                                final isSelected = _selectedCategory == name;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(name.isEmpty ? 'General' : name),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() => _selectedCategory = name);
                                    },
                                    backgroundColor: Colors.grey.shade100,
                                    selectedColor: AppColors.primary.withOpacity(0.12),
                                    checkmarkColor: AppColors.primary,
                                    labelStyle: TextStyle(
                                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: questions.length,
                              itemBuilder: (context, index) {
                                final raw = questions[index];
                                final item = raw is Map<String, dynamic>
                                    ? raw
                                    : Map<String, dynamic>.from(raw as Map);
                                return _QuestionCard(
                                  question: item['question']?.toString() ?? '',
                                  answer: item['answer']?.toString() ?? '',
                                  index: index + 1,
                                  helpfulCount: item['helpful_count'],
                                  markedHelpful: item['user_marked_helpful'] == true,
                                  onHelpful: () => _toggleHelpful(item),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }
}

class _QuestionCard extends StatefulWidget {
  final String question;
  final String answer;
  final int index;
  final dynamic helpfulCount;
  final bool markedHelpful;
  final VoidCallback onHelpful;

  const _QuestionCard({
    required this.question,
    required this.answer,
    required this.index,
    required this.helpfulCount,
    required this.markedHelpful,
    required this.onHelpful,
  });

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final helpful = widget.helpfulCount is int
        ? widget.helpfulCount as int
        : int.tryParse('${widget.helpfulCount}') ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                'Q${widget.index}',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900),
              ),
            ),
            title: Text(
              widget.question,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            trailing: Icon(
              _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              color: AppColors.primary,
            ),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    'EXPERT ANSWER:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.answer,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: widget.onHelpful,
                      icon: Icon(
                        widget.markedHelpful ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                        size: 18,
                        color: widget.markedHelpful ? AppColors.primary : null,
                      ),
                      label: Text('Helpful ($helpful)'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
