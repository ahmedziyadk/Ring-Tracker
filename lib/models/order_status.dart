class OrderStatus {
  static const pending = 'pending';
  static const withMaker = 'with_maker';
  static const ready = 'ready';
  static const rework = 'rework';

  static const activeStatuses = [pending, withMaker, ready, rework];

  static bool isReady(String status) => status == ready || status == 'completed';

  static bool isWithMaker(String status) =>
      status == withMaker || status == 'in_progress';

  static bool isRework(String status) => status == rework;

  static String label(String status) {
    if (isWithMaker(status)) return 'With Maker';
    if (isReady(status)) return 'Ready';
    if (isRework(status)) return 'Rework';
    return 'Pending';
  }
}
