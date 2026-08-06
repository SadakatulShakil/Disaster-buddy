import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bipod_bondhu/presentation/widgets/safe_asset_image.dart';

void main() {
  testWidgets('renders a placeholder instead of crashing on a missing asset', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SafeAssetImage(assetName: 'does_not_exist.png', width: 48, height: 48),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
  });
}
