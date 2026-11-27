import 'package:flutter_test/flutter_test.dart';
import 'package:lifepilot/features/goals/models/goal.dart';

void main() {
  test('goal JSON preserves backend description and milestones', () {
    final goal = Goal.fromJson({
      'id': 'goal-1',
      'title': 'Learn',
      'category': 'Personal',
      'description': 'Study consistently',
      'milestones': ['Finish lesson one', 'Complete project'],
      'progress': 0.25,
      'targetDate': '2026-12-01',
    });

    expect(goal.description, 'Study consistently');
    expect(goal.milestones, ['Finish lesson one', 'Complete project']);
    expect(goal.toJson()['description'], 'Study consistently');
    expect(goal.toJson()['milestones'], [
      'Finish lesson one',
      'Complete project',
    ]);
  });
}
