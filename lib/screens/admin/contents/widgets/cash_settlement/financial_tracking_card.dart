import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sidrive/models/financial_tracking_model.dart';
import 'package:sidrive/core/utils/currency_formatter.dart';
import 'package:intl/intl.dart';

class FinancialTrackingCard extends StatefulWidget {
  final FinancialTrackingModel data;

  const FinancialTrackingCard({super.key, required this.data});

  @override
  State<FinancialTrackingCard> createState() => _FinancialTrackingCardState();
}

class _FinancialTrackingCardState extends State<FinancialTrackingCard> {
  bool _expanded = false;
  bool _copied = false;

  Color get _statusColor {
    switch (widget.data.financialStatus.toLowerCase()) {
      case 'ok': return const Color(0xFF3B82F6);
      case 'selesai': return const Color(0xFF10B981);
      case 'pending': return const Color(0xFFF59E0B);
      case 'bermasalah': return const Color(0xFFEF4444);
      default: return const Color(0xFF6B7280);
    }
  }

  Color get _statusBgColor {
    switch (widget.data.financialStatus.toLowerCase()) {
      case 'ok': return const Color(0xFFDBEAFE);
      case 'selesai': return const Color(0xFFD1FAE5);
      case 'pending': return const Color(0xFFFEF3C7);
      case 'bermasalah': return const Color(0xFFFEE2E2);
      default: return const Color(0xFFF3F4F6);
    }
  }

  IconData get _jenisIcon {
    switch (widget.data.jenisPesanan.toLowerCase()) {
      case 'ojek': return Icons.motorcycle_outlined;
      case 'umkm': return Icons.shopping_bag_outlined;
      default: return Icons.receipt_long_outlined;
    }
  }

  Future<void> _copyId() async {
    await Clipboard.setData(ClipboardData(text: widget.data.idPesanan));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Main row (compact) ──────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Jenis icon
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _statusBgColor,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(_jenisIcon, color: _statusColor, size: 14),
                  ),
                  const SizedBox(width: 10),

                  // ── Tengah: ID + copy TEPAT sebelah + customer/date ──────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ID + tombol copy TEPAT di sebelah kanan teks ID
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                d.idPesanan,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111827),
                                  fontFamily: 'monospace',
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            // ← TOMBOL COPY TEPAT DI SINI, langsung setelah ID
                            GestureDetector(
                              onTap: _copyId,
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 5),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: _copied
                                      ? const Icon(
                                          Icons.check_rounded,
                                          key: ValueKey('check'),
                                          size: 13,
                                          color: Color(0xFF10B981),
                                        )
                                      : const Icon(
                                          Icons.copy_rounded,
                                          key: ValueKey('copy'),
                                          size: 13,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${d.customerNama} · ${DateFormat('dd MMM yy').format(d.tanggalPesanan)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // ── Kanan: Amount + status ────────────────────────────────
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        CurrencyFormatter.format(d.totalHarga),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _statusBgColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          d.financialStatus.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: _statusColor,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 6),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: const Color(0xFF9CA3AF),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded detail ─────────────────────────────────────────────
          if (_expanded) ...[
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                children: [
                  // Participants
                  if (d.driverNama != null || d.umkmNama != null)
                    Row(
                      children: [
                        if (d.driverNama != null)
                          Expanded(
                            child: _DetailChip(
                              icon: Icons.motorcycle_outlined,
                              label: 'Driver',
                              value: d.driverNama!,
                            ),
                          ),
                        if (d.driverNama != null && d.umkmNama != null)
                          const SizedBox(width: 8),
                        if (d.umkmNama != null)
                          Expanded(
                            child: _DetailChip(
                              icon: Icons.store_outlined,
                              label: 'UMKM',
                              value: d.umkmNama!,
                            ),
                          ),
                      ],
                    ),

                  if (d.driverNama != null || d.umkmNama != null)
                    const SizedBox(height: 8),

                  // Payment method & payout
                  Row(
                    children: [
                      Expanded(
                        child: _DetailChip(
                          icon: Icons.payment_outlined,
                          label: 'Metode',
                          value: d.metodePembayaran.toUpperCase(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DetailChip(
                          icon: d.isPaidOut
                              ? Icons.check_circle_outline_rounded
                              : Icons.hourglass_bottom_outlined,
                          label: 'Payout',
                          value: d.isPaidOut ? 'Sudah' : 'Belum',
                          valueColor: d.isPaidOut
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Breakdown
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      children: [
                        if (d.adminFee > 0)
                          _BreakRow(
                            label: 'Admin Fee',
                            value: CurrencyFormatter.format(d.adminFee),
                            color: const Color(0xFFEF4444),
                          ),
                        if (d.driverEarnings > 0) ...[
                          if (d.adminFee > 0) const SizedBox(height: 5),
                          _BreakRow(
                            label: 'Driver Earnings',
                            value: CurrencyFormatter.format(d.driverEarnings),
                            color: const Color(0xFF3B82F6),
                          ),
                        ],
                        if (d.umkmEarnings > 0) ...[
                          const SizedBox(height: 5),
                          _BreakRow(
                            label: 'UMKM Earnings',
                            value: CurrencyFormatter.format(d.umkmEarnings),
                            color: const Color(0xFF10B981),
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (d.notes != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFCD34D)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline,
                              size: 14, color: Color(0xFF92400E)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              d.notes!,
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF92400E)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailChip({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF9CA3AF)),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF9CA3AF))),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? const Color(0xFF111827),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BreakRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        Text(value,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}