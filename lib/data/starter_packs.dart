class StarterPacks {
  StarterPacks._();

  static const eat = ['Pizza', 'Sushi', 'Burger', 'Salad', 'Ramen', 'Tacos'];
  static const watch = ['Movie', 'Series', 'YouTube', 'Anime', 'Doc'];
  static const start = ['Inbox', 'Workout', 'Deep work', 'Break', 'Walk'];
  static const coin = ['Heads', 'Tails'];
  static const yesNo = ['Yes', 'No'];
  static const team = ['A', 'B', 'C', 'D'];
  static const mood = ['Out', 'Home', 'Gym', 'Call a friend'];
  static const weekend = ['Trip', 'Clean', 'Sleep', 'Party', 'Hobby'];
  static const people = ['Alex', 'Sam', 'Jamie', 'Riley'];

  static const library = <(String, String, List<String>)>[
    ('Eat', 'Food when you cannot choose', eat),
    ('Watch', 'What to put on the screen', watch),
    ('Start', 'First move of the day', start),
    ('Coin', 'Simple two-way flip', coin),
    ('Yes / No', 'A clean binary', yesNo),
    ('Team', 'Assign people or sides', team),
    ('Mood', 'How the evening goes', mood),
    ('Weekend', 'Saturday plan', weekend),
  ];

  static List<String> forDailyPrompt(String prompt) {
    final p = prompt.toLowerCase();
    if (p.contains('eat')) return eat;
    if (p.contains('watch')) return watch;
    if (p.contains('text') || p.contains('who')) return people;
    if (p.contains('go') || p.contains('where')) return weekend;
    if (p.contains('hour') || p.contains('first') || p.contains('habit')) {
      return start;
    }
    return yesNo;
  }
}

class HomeTabs {
  HomeTabs._();

  static const drop = 0;
  static const sets = 1;
  static const history = 2;
  static const daily = 3;
  static const presets = 4;
  static const duel = 5;
  static const stats = 6;
  static const favorites = 7;
  static const guide = 8;
  static const lab = 9;
  static const about = 10;
  static const settings = 11;
  static const count = 12;
}
