import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('BasicUserApp renders User Registration header and form fields', (WidgetTester tester) async {
    // Build the BasicUserApp widget tree
    await tester.pumpWidget(const BasicUserApp());

    // Allow any initial async frames to settle
    await tester.pump();

    // Verify AppBar header title is displayed
    expect(find.text('User Registration'), findsOneWidget);

    // Verify registration input fields exist
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Phone Number'), findsOneWidget);

    // Verify action button exists
    expect(find.text('Register User'), findsOneWidget);
  });
}
