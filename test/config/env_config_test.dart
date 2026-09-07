import 'package:flutter_test/flutter_test.dart';
import 'package:mineintel_ai/config/env_config.dart';

void main() {
  group('EnvConfig Tests', () {
    tearDown(() {
      EnvConfig.resetToProduction();
    });

    test('default environment points to production Vercel API', () {
      expect(EnvConfig.baseUrl, 'https://mini-intel-ai-sih.vercel.app/api/v1');
      expect(EnvConfig.activeEnvironment, AppEnvironment.production);
    });

    test('setting custom URL overrides base URL immediately', () {
      EnvConfig.setCustomUrl('http://192.168.1.100:5000/api/v1');
      expect(EnvConfig.baseUrl, 'http://192.168.1.100:5000/api/v1');
      expect(EnvConfig.activeEnvironment, AppEnvironment.custom);
    });

    test('resetToProduction restores production Vercel URL', () {
      EnvConfig.setCustomUrl('http://localhost:5000/api/v1');
      EnvConfig.resetToProduction();
      expect(EnvConfig.baseUrl, 'https://mini-intel-ai-sih.vercel.app/api/v1');
      expect(EnvConfig.activeEnvironment, AppEnvironment.production);
    });
  });
}
