import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus/features/auth/models/user_model.dart';

void main() {
  group('Avatar & Profile Update Flow Tests', () {
    test('UserModel copyWith preserves new avatarUrl', () {
      final initialUser = UserModel(
        id: 1,
        studentId: '23103023',
        fullName: 'Nguyễn Văn A',
        avatarUrl: 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
        role: 'sinh_vien',
      );

      const newAvatar = 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde';
      final updated = initialUser.copyWith(avatarUrl: newAvatar);

      expect(updated.avatarUrl, equals(newAvatar));
      expect(updated.fullName, equals('Nguyễn Văn A'));
      expect(updated.studentId, equals('23103023'));
    });

    test('UserModel.guest() supports updating and serializing avatar', () {
      final guest = UserModel.guest();
      expect(guest.isGuest, isTrue);
      expect(guest.avatarUrl, isNull);

      const guestAvatar = 'https://cdn-icons-png.flaticon.com/512/3135/3135789.png';
      final updatedGuest = guest.copyWith(avatarUrl: guestAvatar);

      expect(updatedGuest.avatarUrl, equals(guestAvatar));

      // Test JSON Serialization & Deserialization
      final jsonStr = jsonEncode(updatedGuest.toJson());
      final Map<String, dynamic> decoded = jsonDecode(jsonStr);
      final restored = UserModel.fromJson(decoded);

      expect(restored.avatarUrl, equals(guestAvatar));
      expect(restored.isGuest, isTrue);
    });

    test('UserModel.fromJson parses multiple avatar field aliases', () {
      final json1 = {'id': 1, 'mssv': '123', 'full_name': 'Test', 'avatar': 'https://img.com/1.png'};
      final json2 = {'id': 2, 'mssv': '124', 'full_name': 'Test', 'avatar_url': 'https://img.com/2.png'};
      final json3 = {'id': 3, 'mssv': '125', 'full_name': 'Test', 'avatarUrl': 'https://img.com/3.png'};

      expect(UserModel.fromJson(json1).avatarUrl, equals('https://img.com/1.png'));
      expect(UserModel.fromJson(json2).avatarUrl, equals('https://img.com/2.png'));
      expect(UserModel.fromJson(json3).avatarUrl, equals('https://img.com/3.png'));
    });
  });
}
