import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:moodiaryhealthtracker_new/services/ai_service.dart';

void main() {
  test('AIService should attempt to use Gemini provider when key is set', () async {
    final service = AIService.instance;
    
    // Initial state
    service.clearApiKeys();
    
    // Set Gemini key
    service.setGeminiApiKey('dummy_key');
    service.setProvider('gemini'); // Force provider
    
    await service.generateTherapistResponse('Hello', []);
    
    // Since the service catches errors and falls back to rule-based, 
    // we should check if lastApiError is set.
    debugPrint('Last API Error: ${service.lastApiError}');
    
    expect(service.lastApiError, isNotNull);
    expect(service.lastApiError, contains('API key'));
  });
}
