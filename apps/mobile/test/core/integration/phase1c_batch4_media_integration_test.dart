import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/constants/asset_paths.dart';
import 'package:mobile/core/widgets/armsphere_image.dart';
import 'package:mobile/features/community/screens/community_feed_screen.dart';
import 'package:mobile/features/community/screens/post_comments_screen.dart';
import 'package:mobile/features/community/screens/create_post_screen.dart';
import 'package:mobile/core/providers/community_provider.dart';
import 'package:mobile/core/providers/state_providers.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCommunityFeedNotifier extends AutoDisposeAsyncNotifier<List<Map<String, dynamic>>>
    implements CommunityFeedNotifier {
  final List<Map<String, dynamic>> _data;
  _FakeCommunityFeedNotifier(this._data);

  @override
  Future<List<Map<String, dynamic>>> build() async => _data;
}

class _FakePostCommentsNotifier extends AutoDisposeFamilyAsyncNotifier<List<Map<String, dynamic>>, String>
    implements PostCommentsNotifier {
  final List<Map<String, dynamic>> _data;
  _FakePostCommentsNotifier(this._data);

  @override
  Future<List<Map<String, dynamic>>> build(String arg) async => _data;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 1C Batch 4: Community / Social Identity Media Integration Tests', () {
    testWidgets('CommunityFeedScreen renders federation seal, athlete avatar, and video thumbnail via ArmSphereImage',
        (WidgetTester tester) async {
      final mockFeedData = [
        {
          'id': 'post_test_1',
          'externalUrl': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          'platform': 'YOUTUBE',
          'category': 'TECHNIQUE',
          'caption': 'Mastering the high hook against top-roll specialists.',
          'createdAt': '2026-09-28T12:00:00Z',
          'likeCount': 42,
          'commentCount': 8,
          'likedByViewer': false,
          'athlete': {
            'id': 'ath_101',
            'displayName': 'Tariq "Iron Grip" Malik',
            'profilePhoto': 'https://storage.armsphere.com/avatars/tariq.jpg',
            'country': 'PAK',
          },
        },
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(
                  AuthState(
                    status: AuthStatus.authenticated,
                    userProfile: {'id': 'ath_101', 'role': 'ATHLETE'},
                  ),
                )),
            communityFeedProvider.overrideWith(() => _FakeCommunityFeedNotifier(mockFeedData)),
          ],
          child: const MaterialApp(
            home: CommunityFeedScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Verify AppBar Federation Seal
      final appBarSealFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ArmSphereImage &&
            widget.assetPath == ArmSphereAssets.sealFed &&
            widget.width == 18 &&
            widget.height == 18 &&
            widget.semanticLabel == 'Official Federation Community Arena',
      );
      expect(appBarSealFinder, findsOneWidget);
      expect(find.text('COMMUNITY ARENA'), findsOneWidget);

      // 2. Verify Athlete Avatar via ArmSphereImage.avatar
      final avatarFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ArmSphereImage &&
            widget.imageUrl == 'https://storage.armsphere.com/avatars/tariq.jpg' &&
            widget.fallbackAsset == ArmSphereAssets.defaultAvatar &&
            widget.semanticLabel == 'Profile photo for Tariq "Iron Grip" Malik',
      );
      expect(avatarFinder, findsOneWidget);

      // 3. Verify Video Thumbnail via ArmSphereImage with dynamic YouTube thumb
      final thumbnailFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ArmSphereImage &&
            widget.imageUrl == 'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg' &&
            widget.fallbackAsset == ArmSphereAssets.heroGrip &&
            widget.fit == BoxFit.cover,
      );
      expect(thumbnailFinder, findsOneWidget);

      // 4. Verify post content preservation
      expect(find.text('Tariq "Iron Grip" Malik'), findsOneWidget);
      expect(find.text('Mastering the high hook against top-roll specialists.'), findsOneWidget);
      expect(find.text('TECHNIQUE'), findsWidgets);

      // Clean teardown
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('PostCommentsScreen renders federation seal and commenter avatar via ArmSphereImage',
        (WidgetTester tester) async {
      const postId = 'post_comm_1';
      final mockComments = [
        {
          'id': 'comm_1',
          'body': 'Incredible wrist flexion angle on the setup!',
          'createdAt': '2026-09-28T14:30:00Z',
          'athlete': {
            'id': 'ath_202',
            'displayName': 'Hamza "The Hammer" Khan',
            'profilePhoto': 'https://storage.armsphere.com/avatars/hamza.jpg',
          },
        },
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(
                  AuthState(status: AuthStatus.authenticated),
                )),
            postCommentsProvider(postId).overrideWith(() => _FakePostCommentsNotifier(mockComments)),
          ],
          child: const MaterialApp(
            home: PostCommentsScreen(postId: postId),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Verify AppBar Federation Seal
      final commentsSealFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ArmSphereImage &&
            widget.assetPath == ArmSphereAssets.sealFed &&
            widget.width == 18 &&
            widget.height == 18 &&
            widget.semanticLabel == 'Official Federation Seal',
      );
      expect(commentsSealFinder, findsOneWidget);
      expect(find.text('Community Discussion'), findsOneWidget);

      // 2. Verify Commenter Avatar via ArmSphereImage.avatar
      final commenterAvatarFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ArmSphereImage &&
            widget.imageUrl == 'https://storage.armsphere.com/avatars/hamza.jpg' &&
            widget.fallbackAsset == ArmSphereAssets.defaultAvatar &&
            widget.semanticLabel == 'Profile photo for Hamza "The Hammer" Khan',
      );
      expect(commenterAvatarFinder, findsOneWidget);

      // 3. Verify comment text and author preservation
      expect(find.text('Hamza "The Hammer" Khan'), findsOneWidget);
      expect(find.text('Incredible wrist flexion angle on the setup!'), findsOneWidget);

      // Clean teardown
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('CreatePostScreen renders federation seal and dynamic YouTube video preview',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier(
                  AuthState(status: AuthStatus.authenticated),
                )),
          ],
          child: const MaterialApp(
            home: CreatePostScreen(),
          ),
        ),
      );

      await tester.pump();

      // 1. Verify AppBar and Header Federation Seals
      final headerSealsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ArmSphereImage &&
            widget.assetPath == ArmSphereAssets.sealFed &&
            (widget.semanticLabel == 'Official Federation Seal' ||
                widget.semanticLabel == 'Federation Submission Seal'),
      );
      expect(headerSealsFinder, findsNWidgets(2));

      // 2. Enter a YouTube URL and verify dynamic preview renders
      final urlField = find.byType(TextFormField).first;
      await tester.enterText(urlField, 'https://www.youtube.com/watch?v=dQw4w9WgXcQ');
      await tester.pump();

      // Verify dynamic preview thumbnail rendered via ArmSphereImage
      final previewThumbnailFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ArmSphereImage &&
            widget.imageUrl == 'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg' &&
            widget.fallbackAsset == ArmSphereAssets.heroGrip &&
            widget.semanticLabel == 'Video Preview Thumbnail',
      );
      expect(previewThumbnailFinder, findsOneWidget);
      expect(find.text('Federation Preview Verified'), findsOneWidget);

      // Clean teardown
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  });
}
