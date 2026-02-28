import '../colleagues/colleague_model.dart';
import 'ledger_entry_model.dart';

class ColleagueLedgerResponse {
  final Colleague colleague;
  final double outstanding;
  final List<LedgerEntryModel> ledger;

  ColleagueLedgerResponse({
    required this.colleague,
    required this.outstanding,
    required this.ledger,
  });

  factory ColleagueLedgerResponse.fromJson(Map<String, dynamic> json) {
    final data = Map<String, dynamic>.from(json['data'] as Map);

    final outstandingRaw = data['outstanding'];
    final outstanding = (outstandingRaw is num)
        ? outstandingRaw.toDouble()
        : double.tryParse((outstandingRaw ?? '0').toString()) ?? 0.0;

    final ledgerRaw = (data['ledger'] as List? ?? []);
    final ledger = ledgerRaw
        .map((e) => LedgerEntryModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return ColleagueLedgerResponse(
      colleague: Colleague.fromJson(Map<String, dynamic>.from(data['colleague'] as Map)),
      outstanding: outstanding,
      ledger: ledger,
    );
  }
}
