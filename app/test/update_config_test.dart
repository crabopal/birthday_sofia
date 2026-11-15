import 'package:flutter_test/flutter_test.dart';
import 'package:sonya_birthday/config/update_config.dart';

void main() {
  test('manifest URL encodes slash in branch name', () {
    expect(UpdateConfig.encodedRef, 'cursor%2Fsonya-birthday-game-apk-922d');
    expect(
      UpdateConfig.manifestUrl,
      'https://raw.githubusercontent.com/crabopal/birthday_sofia/'
      'cursor%2Fsonya-birthday-game-apk-922d/dist/version.json',
    );
  });
}
