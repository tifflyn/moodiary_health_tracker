class AvatarData {
  static final List<Avatar> avatars = [
    Avatar(id: 'avatar1', name: 'Happy Panda', emoji: '🐼'),
    Avatar(id: 'avatar2', name: 'Smiling Cat', emoji: '😺'),
    Avatar(id: 'avatar3', name: 'Wise Owl', emoji: '🦉'),
    Avatar(id: 'avatar4', name: 'Playful Dog', emoji: '🐶'),
    Avatar(id: 'avatar5', name: 'Curious Fox', emoji: '🦊'),
    Avatar(id: 'avatar6', name: 'Gentle Bear', emoji: '🐻'),
    Avatar(id: 'avatar7', name: 'Magic Unicorn', emoji: '🦄'),
    Avatar(id: 'avatar8', name: 'Brave Lion', emoji: '🦁'),
    Avatar(id: 'avatar9', name: 'Clever Rabbit', emoji: '🐰'),
    Avatar(id: 'avatar10', name: 'Peaceful Turtle', emoji: '🐢'),
  ];
}

class Avatar {
  final String id;
  final String name;
  final String emoji;

  Avatar({required this.id, required this.name, required this.emoji});
}
