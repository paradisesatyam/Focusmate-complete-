class QuoteBank {
  static const _quotes = [
    {"quote": "Discipline is choosing between what you want now and what you want most.", "author": "Abraham Lincoln"},
    {"quote": "You don't have to be extreme, just consistent.", "author": "Unknown"},
    {"quote": "Small daily improvements are the key to staggering long-term results.", "author": "Unknown"},
    {"quote": "Motivation gets you going, but discipline keeps you growing.", "author": "John C. Maxwell"},
    {"quote": "The pain of discipline weighs ounces; the pain of regret weighs tons.", "author": "Jim Rohn"},
    {"quote": "Focus on being productive instead of busy.", "author": "Tim Ferriss"},
    {"quote": "Success is the sum of small efforts repeated day in and day out.", "author": "Robert Collier"},
    {"quote": "Do something today that your future self will thank you for.", "author": "Unknown"},
    {"quote": "It always seems impossible until it's done.", "author": "Nelson Mandela"},
    {"quote": "Push yourself, because no one else is going to do it for you.", "author": "Unknown"},
    {"quote": "Great things never come from comfort zones.", "author": "Unknown"},
    {"quote": "Dream it. Wish it. Do it.", "author": "Unknown"},
  ];

  static Map<String, String> get today {
    final day = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return Map<String, String>.from(_quotes[day % _quotes.length]);
  }
}
