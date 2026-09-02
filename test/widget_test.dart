import 'package:flutter_test/flutter_test.dart';
import 'package:vortixadropgame/data/app_store.dart';
import 'package:vortixadropgame/data/models.dart';

void main() {
  test('quick choice picks exactly one existing option', () {
    final options = [
      ChoiceOption(id: 'a', label: 'Coffee', colorIndex: 0),
      ChoiceOption(id: 'b', label: 'Tea', colorIndex: 1),
    ];
    final session = DropSession.quick(setName: 'Drinks', options: options);
    expect(session.winners, hasLength(1));
    expect(options.map((o) => o.id), contains(session.winners.first.id));
  });

  test('multi select never repeats a winner', () {
    final options = List.generate(
      6,
      (i) => ChoiceOption(id: '$i', label: 'O$i', colorIndex: i),
    );
    final session = DropSession.multi(
      setName: 'Mix',
      options: options,
      pickCount: 3,
    );
    expect(session.winners, hasLength(3));
    expect(session.winners.map((o) => o.id).toSet(), hasLength(3));
  });

  test('skip last winner uses another option when possible', () {
    final options = [
      ChoiceOption(id: 'a', label: 'Coffee', colorIndex: 0),
      ChoiceOption(id: 'b', label: 'Tea', colorIndex: 1),
      ChoiceOption(id: 'c', label: 'Water', colorIndex: 2),
    ];
    for (var i = 0; i < 20; i++) {
      final session = DropSession.quick(
        setName: 'Drinks',
        options: options,
        excludeId: 'a',
      );
      expect(session.winners.single.id, isNot('a'));
    }
  });

  test('multi needs at least 3 options', () {
    final store = AppStore()
      ..mode = DropMode.multi
      ..workingOptions = [
        ChoiceOption(id: 'a', label: 'A', colorIndex: 0),
        ChoiceOption(id: 'b', label: 'B', colorIndex: 1),
      ];
    expect(store.validateDrop(), contains('3'));
    store.workingOptions.add(ChoiceOption(id: 'c', label: 'C', colorIndex: 2));
    expect(store.validateDrop(), isNull);
  });

  test('split groups differ by at most one item', () {
    final options = List.generate(
      10,
      (i) => ChoiceOption(id: '$i', label: 'O$i', colorIndex: i % 8),
    );
    final session = DropSession.split(
      setName: 'Teams',
      options: options,
      groupCount: 3,
    );
    final sizes = session.groups.map((g) => g.length).toList()..sort();
    expect(sizes.last - sizes.first, lessThanOrEqualTo(1));
    expect(session.groups.expand((g) => g).length, 10);
  });
}
