import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallpaper_app/core/widgets/neon_button.dart';
import 'package:wallpaper_app/core/widgets/liquid_glass_container.dart';
import 'package:wallpaper_app/core/theme/dark_neon_theme.dart';
import 'package:wallpaper_app/data/models/wallpaper_model.dart';
import 'package:wallpaper_app/presentation/providers/wallpaper_providers.dart';

void main() {
  testWidgets('NeonButton renders with correct label and handles tap', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: DarkNeonTheme.themeData,
        home: Scaffold(
          body: Center(
            child: NeonButton(
              text: 'EXPLORE NEON',
              neonColor: DarkNeonTheme.primaryNeon,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('EXPLORE NEON'), findsOneWidget);
    await tester.tap(find.text('EXPLORE NEON'));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });

  testWidgets('LiquidGlassContainer renders children with glowing border', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: LiquidGlassContainer(
              child: Text('LIQUID GLASS TEST'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('LIQUID GLASS TEST'), findsOneWidget);
  });

  testWidgets('Wallpaper providers handle mock in-memory data cleanly', (WidgetTester tester) async {
    final mockWallpapers = [
      WallpaperModel(
        id: 'test_wall_1',
        uploaderId: 'test_user',
        uploaderName: 'Test Artist',
        type: WallpaperType.STATIC,
        categoryId: 'cyberpunk',
        title: 'TEST CYBER WALLPAPER',
        tags: ['test', 'neon'],
        imageUrl: 'https://example.com/test.jpg',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        averageRating: 5.0,
        ratingCount: 1,
        uploadedAt: DateTime.now(),
        source: 'TEST',
      ),
    ];

    final container = ProviderContainer(
      overrides: [
        wallpapersListProvider.overrideWith((ref) async => mockWallpapers),
      ],
    );

    final result = await container.read(wallpapersListProvider.future);
    expect(result.length, equals(1));
    expect(result.first.title, equals('TEST CYBER WALLPAPER'));
  });
}
