class Endpoints {
  static const colleagues = '/api/colleagues';
  static const items = '/api/items';
  static String item(int id) => '/api/items/$id';
  static String deactivateItem(int id) => '/api/items/$id/deactivate';
  static const orderBatches = '/api/order-batches';
  static String orderBatch(int id) => '/api/order-batches/$id';
  static String orderBatchItems(int id) => '/api/order-batches/$id/items';
  static String finalizeOrderBatch(int id) => '/api/order-batches/$id/finalize';
  static String colleagueAliases(int id) => '/api/colleagues/$id/aliases';
  static String colleagueLedger(int id) => '/api/colleagues/$id/ledger';
  static String colleagueDeactivate(int id) => '/api/colleagues/$id/deactivate';
  static const ledgerManualCredit = '/api/ledger/manual-credit';
  static const String notificationsUnmatched = '/api/notifications/unmatched';
  static const String notificationsIngest = '/api/notifications/ingest';

  static String notificationAssign(int id) => '/api/notifications/$id/assign';
  static String notificationIgnore(int id) => '/api/notifications/$id/ignore';
  static String notificationApply(int id) => '/api/notifications/$id/apply';

}
