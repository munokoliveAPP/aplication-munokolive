import 'package:flutter_test/flutter_test.dart';
import 'package:munokolive_music/models/user_profile.dart';

void main() {
  group('UserProfile Model Test', () {
    test('fromJson creates a valid UserProfile', () {
      final json = {
        'id': '123',
        'first_name': 'John',
        'last_name': 'Doe',
        'email': 'john.doe@example.com',
        'role': 'user',
        'status': 'active',
        'points': 100,
        'category': 'Musician',
        'is_validated': true,
        'is_available': false,
      };

      final user = UserProfile.fromJson(json);

      expect(user.id, '123');
      expect(user.firstName, 'John');
      expect(user.lastName, 'Doe');
      expect(user.email, 'john.doe@example.com');
      expect(user.role, 'user');
      expect(user.status, 'active');
      expect(user.points, 100);
      expect(user.category, 'Musician');
      expect(user.isValidated, true);
      expect(user.isAvailable, false);
    });

    test('fromJson handles null values with defaults', () {
      final json = {
        'id': '456',
        'first_name': 'Jane',
        'last_name': 'Doe',
      };

      final user = UserProfile.fromJson(json);

      expect(user.id, '456');
      expect(user.firstName, 'Jane');
      expect(user.points, 0); // Default value
      expect(user.isValidated, false); // Default value
      expect(user.isAvailable, true); // Default value
      expect(user.status, 'pending'); // Default value
    });
  });
}
