String achievementEmoji(String icon) {
  return switch (icon) {
    'rocket' => '🚀',
    'star' => '⭐',
    'target' => '🎯',
    'bolt' => '⚡',
    'compass' => '🧭',
    'calendar' => '📅',
    'crown' => '👑',
    'flame' => '🔥',
    'pencil' => '✏️',
    'sparkle' => '✨',
    _ => '🎖️',
  };
}
