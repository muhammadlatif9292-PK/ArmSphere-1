import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/glass_card.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  final List<Map<String, dynamic>> _posts = [
    {
      'id': 'p-1',
      'author': 'Haider Khan',
      'text': 'Hitting a new rising lift PR of 32kg! Strap training is finally paying off. Matches in Lahore are going to be hot this autumn!',
      'likes': 14,
      'comments': 3,
    },
    {
      'id': 'p-2',
      'author': 'Zain Shah',
      'text': 'Official Referee Seminar registrations are now open. We have slots for 15 new referee certifications. WAF certified.',
      'likes': 8,
      'comments': 1,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: () => context.push('/community/post/create'),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _posts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final p = _posts[index];
          return GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                      child: Text(p['author'][0]),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      p['author'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  p['text'],
                  style: const TextStyle(height: 1.4),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.favorite_border),
                          onPressed: () {
                            setState(() {
                              p['likes'] = p['likes'] + 1;
                            });
                          },
                        ),
                        Text('${p['likes']} likes'),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline),
                          onPressed: () => context.push('/community/post/${p['id']}/comments'),
                        ),
                        Text('${p['comments']} comments'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
