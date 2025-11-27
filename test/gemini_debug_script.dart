import 'package:moodiaryhealthtracker_new/services/ai_service.dart';
import 'package:flutter/material.dart';

void main() async {
  debugPrint('Starting debug script...');
  
  final service = AIService.instance;
  
  // Initial state
  service.clearApiKeys();
  
  // Set Gemini key
  debugPrint('Setting Gemini key...');
  service.setGeminiApiKey('dummy_key');
  service.setProvider('gemini');
  
  debugPrint('Calling generateTherapistResponse...');
  final response = await service.generateTherapistResponse('Hello', []);
  
  debugPrint('Response received: $response');
  debugPrint('Last API Error: ${service.lastApiError}');
  
  if (service.lastApiError != null && service.lastApiError!.contains('API key')) {
    debugPrint('SUCCESS: Caught expected API key error.');
  } else {
    debugPrint('FAILURE: Did not catch expected API key error.');
  }
}
