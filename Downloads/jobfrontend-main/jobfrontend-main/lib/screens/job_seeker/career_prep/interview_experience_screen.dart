import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';

class InterviewExperienceScreen extends StatelessWidget {
  const InterviewExperienceScreen({super.key});

  final List<Map<String, dynamic>> _experiences = const [
    {
      'company': 'Google — Software Engineer',
      'experience': 'The process was extremely structured. It started with a recruiter call, followed by a technical screening (LeetCode Hard level). Then were 4 onsite rounds. Focus was on algorithms, data structures, and the "Googliness" factor. PRO TIP: Communicate your thoughts clearly during the coding rounds.',
      'rating': 4.5,
      'date': 'Jan 2024',
      'source': 'Quora Expert (FAANG)',
      'avatar': 'G',
      'color': Colors.red,
    },
    {
      'company': 'Amazon — SDE-II',
      'experience': 'Amazon is BIG on leadership principles. 50% of the interview is technical, but the other 50% is about how you align with their 16 principles like Customer Obsession and Bias for Action. Be ready with STAR method stories for every principle. Tech rounds were deep on system design.',
      'rating': 4.0,
      'date': 'Feb 2024',
      'source': 'Quora Alumnus',
      'avatar': 'A',
      'color': Colors.orange,
    },
    {
      'company': 'Cred — Backend Developer',
      'experience': 'Startups are all about agility. The interview was very practical. I had to build a small feature in an hour, followed by a deep-dive into concurrency and database optimization. They want people who can build things end-to-end. Focus on your projects and solving real problems.',
      'rating': 4.8,
      'date': 'Dec 2023',
      'source': 'Quora Startup Specialist',
      'avatar': 'C',
      'color': Colors.black,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          'Interview Experiences',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _experiences.length,
        itemBuilder: (context, index) {
          final exp = _experiences[index];
          return _ExperienceCard(exp: exp);
        },
      ),
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  final Map<String, dynamic> exp;

  const _ExperienceCard({required this.exp});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: exp['color'].withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      exp['avatar'],
                      style: TextStyle(
                        color: exp['color'],
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exp['company'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${exp['source']} • ${exp['date']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'INTERVIEW STORY:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  exp['experience'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      exp['rating'].toString(),
                      style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.share_rounded, size: 16),
                      label: const Text('Read More'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
