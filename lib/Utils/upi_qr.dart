/// Data extracted from a scanned UPI QR code.
class UpiQrData {
  final String vpa;
  final String? name;
  final double? amount;
  final String? note;
  final String? txnRef;
  final String? txnId;

  const UpiQrData({
    required this.vpa,
    this.name,
    this.amount,
    this.note,
    this.txnRef,
    this.txnId,
  });

  /// Sentinel returned when the user chooses to type the UPI ID manually
  /// instead of scanning — [vpa] is empty.
  static const manual = UpiQrData(vpa: '');

  bool get isManual => vpa.isEmpty;
}

final _vpaRegex = RegExp(r'[A-Za-z0-9][A-Za-z0-9._-]*@[A-Za-z0-9]+');

/// Parses a scanned QR payload into [UpiQrData], or returns `null` when it is
/// not a UPI QR code.
///
/// Supported formats:
/// - Standard: `upi://pay?pa=name@upi&pn=Name&am=100.00&tn=Note&tr=ref&tid=id`
/// - Legacy: `upi://pay?payeeVpa=name@upi`
/// - Bare VPA string: `name@upi`
UpiQrData? parseUpiQr(String raw) {
  final input = raw.trim();
  if (input.isEmpty) return null;

  final lower = input.toLowerCase();
  if (lower.startsWith('upi://')) {
    final uri = Uri.parse(input);
    final params = <String, String>{};
    for (final e in uri.queryParameters.entries) {
      params[e.key.toLowerCase()] = e.value;
    }

    final vpa = (params['pa'] ?? params['payeevpa'] ?? '').trim();
    if (vpa.isEmpty) return null;

    final amStr = (params['am'] ?? '').trim().replaceAll(',', '');
    final amount = amStr.isEmpty ? null : double.tryParse(amStr);

    return UpiQrData(
      vpa: vpa,
      name: params['pn']?.trim(),
      amount: amount,
      note: params['tn']?.trim(),
      txnRef: params['tr']?.trim(),
      txnId: params['tid']?.trim(),
    );
  }

  // Don't attempt a bare-VPA match inside web links.
  if (lower.startsWith('http')) return null;

  final vpaMatch = _vpaRegex.firstMatch(input);
  if (vpaMatch != null) {
    return UpiQrData(vpa: vpaMatch.group(0)!);
  }

  return null;
}
