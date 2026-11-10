import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus/features/auth/models/user_model.dart';
import 'package:smart_campus/features/profile/widgets/avatar_picker_modal.dart';

void main() {
  testWidgets('AvatarPickerModal displays only Camera and Gallery options', (tester) async {
    const testUser = UserModel(
      id: 1,
      studentId: '23103023',
      fullName: 'Nguyễn Huy Hoàng',
      avatarUrl: 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
      role: 'sinh_vien',
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AvatarPickerModal(currentUser: testUser),
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify Title
    expect(find.text('Chọn ảnh đại diện'), findsOneWidget);

    // Verify 2 options are present
    expect(find.text('Chụp ảnh mới'), findsOneWidget);
    expect(find.text('Chọn từ thư viện'), findsOneWidget);

    // Verify old preset avatar and URL input options are GONE
    expect(find.text('Hình đại diện có sẵn'), findsNothing);
    expect(find.text('Hoặc nhập liên kết ảnh (URL)'), findsNothing);
    expect(find.text('Áp dụng'), findsNothing);
  });
}

