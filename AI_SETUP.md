# AI Chatbot Setup Guide

## Current Status
The AI chatbot now uses **enhanced rule-based responses** by default, which are more intelligent and context-aware. These responses analyze your recent emotions and provide personalized support.

## To Use Real AI (Optional)

If you want to use real AI APIs (Claude or OpenAI), follow these steps:

### Option 1: Using Claude API (Anthropic)

1. Get your API key from: https://console.anthropic.com/
2. In your app initialization code (e.g., `main.dart`), add:

```dart
import 'services/ai_service.dart';

void main() {
  // Set your Claude API key
  AIService.instance.setClaudeApiKey('your-claude-api-key-here');
  // Or set the provider explicitly
  AIService.instance.setProvider('claude');
  
  runApp(const MyApp());
}
```

### Option 2: Using OpenAI API

1. Get your API key from: https://platform.openai.com/api-keys
2. In your app initialization code, add:

```dart
import 'services/ai_service.dart';

void main() {
  // Set your OpenAI API key
  AIService.instance.setOpenAiApiKey('your-openai-api-key-here');
  AIService.instance.setProvider('openai');
  
  runApp(const MyApp());
}
```

### Option 3: Keep Using Enhanced Local AI (Default)

The enhanced rule-based system is now much smarter and provides contextual responses based on:
- Your message content
- Your recent emotion history
- Emotional patterns

No setup required! It works out of the box.

## Security Note

⚠️ **Important**: Never commit API keys to version control. Consider using:
- Environment variables
- Secure storage packages like `flutter_secure_storage`
- Configuration files that are git-ignored

## Features

- ✅ Enhanced rule-based responses (works without API keys)
- ✅ Context-aware responses based on emotion history
- ✅ Support for Claude API
- ✅ Support for OpenAI API
- ✅ Automatic fallback to rule-based if API fails
- ✅ Error handling to prevent infinite loading

