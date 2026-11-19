import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_rush/app/services/narration_service.dart';

void main() {
  group('NarrationText', () {
    test('reads equations as questions and joins choices naturally', () {
      final text = NarrationText.question(
        text: '3 + 2 = ?',
        options: const ['2', '3', '4'],
      );

      expect(text, '3 plus 2 equals what? The choices are 2, 3, or 4.');
    });

    test('keeps question intonation instead of stripping punctuation', () {
      final text = NarrationText.question(
        text: 'Which shape has 3 sides?',
        options: const ['triangle', 'circle', 'square'],
      );

      expect(text, startsWith('Which shape has 3 sides?'));
    });

    test('reads fractions, decimals, money and thousands naturally', () {
      final fraction = NarrationText.question(
        text: 'What is 1/2 of 8?',
        options: const ['4', '5', '6'],
      );
      expect(fraction, contains('1 over 2'));
      expect(fraction, contains('?'));

      final decimals = NarrationText.question(
        text: '2.5 + 1.75 = ?',
        options: const ['4.25', '3.25', '4.75'],
      );
      expect(decimals, contains('2.5 plus 1.75 equals what?'));

      final money = NarrationText.question(
        text: r'How much is $3.50?',
        options: const [r'$3.50', r'$4.50'],
      );
      expect(money, contains('3.50 dollars'));
      expect(money, isNot(contains(r'$')));

      final big = NarrationText.question(
        text: 'How many grams are in 1,000 kilograms?',
        options: const ['1000', '10000'],
      );
      expect(big, contains('1000 kilograms'));
    });

    test('feedback sounds warm and keeps the explanation', () {
      final correct = NarrationText.feedback(
        correct: true,
        correctAnswer: '3',
        explanation: 'One plus two is three.',
      );
      expect(correct, startsWith('Yes! 3 is right.'));

      final wrong = NarrationText.feedback(
        correct: false,
        correctAnswer: '3',
        explanation: 'Count one, two, three.',
      );
      expect(wrong, contains('Let’s look together.'));
    });
  });
}
