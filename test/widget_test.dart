// Kullanıcı adı -> e-posta dönüşümünün doğruluğunu test eder.
// (Firebase başlatma gerektirmeyen saf birim testi.)

import 'package:flutter_test/flutter_test.dart';
import 'package:treadom/services/auth_service.dart';

void main() {
  group('AuthService.usernameToEmail', () {
    test('kullanıcı adını küçük harfe çevirip alan adını ekler', () {
      expect(AuthService.usernameToEmail('Salim'), 'salim@treadom.app');
    });

    test('baştaki/sondaki boşlukları temizler', () {
      expect(AuthService.usernameToEmail('  Ahmet_42  '), 'ahmet_42@treadom.app');
    });
  });
}
