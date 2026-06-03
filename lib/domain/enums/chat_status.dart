enum ChatStatus {
  active,
  closed,
}

extension ChatStatusExtension on ChatStatus {
  String get value {
    switch (this) {
      case ChatStatus.active:
        return 'ACTIVE';
      case ChatStatus.closed:
        return 'CLOSED';
    }
  }

  static ChatStatus fromString(String value) {
    switch (value) {
      case 'ACTIVE':
        return ChatStatus.active;
      case 'CLOSED':
        return ChatStatus.closed;
      default:
        return ChatStatus.active;
    }
  }
}