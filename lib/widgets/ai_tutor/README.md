# Controlled AI Tutor - Implementation Guide

## Overview
The AI Tutor is now strictly controlled to only respond to app content. It cannot be used for general chat or off-topic questions.

## Key Features

### 1. Context-Only Responses
- AI will ONLY answer when viewing lessons, vocabulary, or grammar content
- No context = No response
- Automatic rejection of off-topic questions

### 2. Rate Limiting
- 10 requests per minute
- 50 requests per hour  
- 100 requests per day
- Prevents abuse and controls costs

### 3. Content Validation
- Blocks keywords: weather, news, sports, politics, gaming, etc.
- Minimum/maximum message length checks
- Topic detection

### 4. Strict System Prompt
- Only 3 sentence maximum responses
- Must stay focused on provided content
- Cannot engage in general conversation

## Usage Examples

### 1. In Vocabulary Screen
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    // ... vocabulary content ...
    floatingActionButton: AITutorFloatingButton(
      vocabularyId: widget.vocabulary.id,
      content: {
        'word': widget.vocabulary.word,
        'translation': widget.vocabulary.translation,
        'example': widget.vocabulary.exampleSentences.first,
      },
      languageCode: 'es', // Spanish
    ),
  );
}
```

### 2. In Grammar Lesson Screen
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    // ... grammar content ...
    floatingActionButton: AITutorFloatingButton(
      grammarRuleId: widget.grammarRule.id,
      content: {
        'rule': widget.grammarRule.title,
        'explanation': widget.grammarRule.explanation,
      },
      languageCode: 'es',
    ),
  );
}
```

### 3. In Regular Lesson Screen
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    // ... lesson content ...
    floatingActionButton: AITutorFloatingButton(
      lessonId: widget.lesson.id,
      content: {
        'lesson_title': widget.lesson.title,
        'lesson_content': widget.lesson.content,
      },
      languageCode: 'es',
    ),
  );
}
```

### 4. Using Provider Directly (Advanced)
```dart
final aiProvider = Provider.of<AITutorProvider>(context, listen: false);

// Set context
aiProvider.setLearningContext(
  vocabularyId: 'vocab_123',
  content: {'word': 'hola', 'translation': 'hello'},
);

// Ask specific question
await aiProvider.explainVocabulary(
  'vocab_123',
  'hola',
  'hello',
  'es',
  exampleSentence: '¡Hola! ¿Cómo estás?',
);

// Or ask custom question (still validated)
await aiProvider.askQuestion(
  'Why is this word used here?',
  userProficiencyLevel: 'beginner',
);
```

## Security Measures

### 1. Blocked Topics
The AI will NOT respond to questions about:
- Weather
- News
- Sports
- Politics
- Gaming
- Movies/Music
- Recipes
- Programming
- Math/Science
- Personal advice
- Work/Money
- Religion

### 2. Context Requirements
- Must have lessonId, vocabularyId, OR grammarRuleId
- Context content must be provided
- AI tracks which content user is viewing

### 3. Response Restrictions
- Max 3 sentences
- Must relate to provided content
- Cannot provide external information
- Cannot engage in conversation

## Error Messages

### No Context
```
"AI Tutor is available only when viewing lessons, vocabulary, or grammar content. 
Please open a learning activity first."
```

### Off-Topic
```
"I can only help with the language content you're currently studying. 
Please ask about the lesson, vocabulary word, or grammar rule on your screen."
```

### Rate Limit
```
"You've reached the daily limit for AI questions. Please try again tomorrow."
```

### Invalid Context Type
```
"AI Tutor can only help with lesson content, vocabulary, and grammar explanations."
```

## Best Practices

1. **Always provide context** - The floating button requires context IDs
2. **Use context-specific methods** - They automatically set and validate context
3. **Check rate limits** - Display remaining requests to users
4. **Handle errors gracefully** - Show user-friendly error messages
5. **Clear context on navigation** - Call `clearLearningContext()` when leaving screen

## Implementation Checklist

- [x] AI service with content validation
- [x] Rate limiting (10/min, 50/hr, 100/day)
- [x] Context requirement enforcement
- [x] Off-topic detection
- [x] Strict system prompts
- [x] Usage tracking
- [x] Floating button widget
- [x] Chat interface
- [ ] Add to vocabulary screen
- [ ] Add to grammar screen
- [ ] Add to lesson screen
- [ ] Test rate limiting
- [ ] Test content validation

## Testing

### Test 1: No Context
```dart
// Don't set context
final response = await aiService.askQuestion(
  AITutorRequest(message: 'Hello'),
);
// Expected: Error about needing context
```

### Test 2: Off-Topic
```dart
aiService.setLearningContext(vocabularyId: '123', content: {...});
final response = await aiService.askQuestion(
  AITutorRequest(message: 'What is the weather today?'),
);
// Expected: Blocked, returns error message
```

### Test 3: Rate Limit
```dart
// Send 11 requests quickly
for (var i = 0; i < 11; i++) {
  await aiService.askQuestion(...);
}
// 11th request should be blocked
```

### Test 4: Valid Question
```dart
aiService.setLearningContext(
  vocabularyId: '123',
  content: {'word': 'hola', 'translation': 'hello'},
);
final response = await aiService.askQuestion(
  AITutorRequest(message: 'How do I use this word?'),
);
// Expected: Valid response about the vocabulary
```

## Notes

- All AI interactions are logged to database
- Usage stats can be retrieved for analytics
- Rate limits are per user
- Context is cleared when app restarts
- AI key is hardcoded but should be moved to environment variables in production
