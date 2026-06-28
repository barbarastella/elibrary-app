enum BookStatus {
  toRead,
  reading,
  read,
  abandoned;

  static BookStatus fromString(String status) {
    switch(status) {
      case 'reading': return BookStatus.reading;
      case 'read': return BookStatus.read;
      case 'abandoned': return BookStatus.abandoned;
      case 'to_read':
      default: return BookStatus.toRead;
    }
  }

  String toShortString() {
    switch(this) {
      case BookStatus.toRead: return 'to_read';
      case BookStatus.reading: return 'reading';
      case BookStatus.read: return 'read';
      case BookStatus.abandoned: return 'abandoned';
    }
  }
}