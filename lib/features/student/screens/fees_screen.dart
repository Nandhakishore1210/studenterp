import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/student_provider.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/fee_model.dart';

class FeesScreen extends ConsumerWidget {
  const FeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feesAsync = ref.watch(studentFeesProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        title: Text('Fee Details', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      body: feesAsync.when(
        loading: () => const ShimmerList(count: 3, itemHeight: 100),
        error: (e, _) => Center(child: Text(e.toString(),
            style: GoogleFonts.inter(color: AppColors.textSecondary))),
        data: (fees) {
          if (fees.isEmpty) {
            return Center(child: Text('No fee records found',
                style: GoogleFonts.inter(color: AppColors.textSecondary)));
          }

          final total   = fees.fold<double>(0, (s, f) => s + f.amount);
          final paid    = fees.fold<double>(0, (s, f) => s + f.paidAmount);
          final balance = total - paid;
          final paidPct = total > 0 ? paid / total : 0.0;

          return ListView(children: [
            // ── Summary banner ──
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF047857), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: const Color(0xFF059669).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))],
              ),
              child: Column(children: [
                Row(children: [
                  _SummaryCol('Total Fee', total, Colors.white70),
                  _Vline(),
                  _SummaryCol('Paid', paid, const Color(0xFFA7F3D0)),
                  _Vline(),
                  _SummaryCol('Balance', balance, balance > 0 ? const Color(0xFFFCA5A5) : const Color(0xFFA7F3D0)),
                ]),
                const SizedBox(height: 16),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Payment Progress', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                    Text('${(paidPct * 100).toStringAsFixed(0)}% paid',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: paidPct,
                      minHeight: 8,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation(Color(0xFFA7F3D0)),
                    ),
                  ),
                ]),
              ]),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Text('Breakdown', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1C1C1E))),
            ),

            ...fees.map((f) => _FeeCard(fee: f)),
            const SizedBox(height: 28),
          ]);
        },
      ),
    );
  }
}

class _SummaryCol extends StatelessWidget {
  final String label;
  final double amount;
  final Color textColor;
  const _SummaryCol(this.label, this.amount, this.textColor);

  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
    const SizedBox(height: 4),
    Text('₹${NumberFormat('#,##0').format(amount)}',
        style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
  ]));
}

class _Vline extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 36, width: 1, color: Colors.white24,
    margin: const EdgeInsets.symmetric(horizontal: 4));
}

class _FeeCard extends StatelessWidget {
  final FeeModel fee;
  const _FeeCard({required this.fee});

  @override
  Widget build(BuildContext context) {
    final f = fee;
    final paid    = f.status == 'paid';
    final partial = f.status == 'partial';
    final color   = paid ? const Color(0xFF22C55E) : partial ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);
    final bg      = paid ? const Color(0xFFF0FDF4) : partial ? const Color(0xFFFFFBEB) : const Color(0xFFFEF2F2);
    final label   = paid ? 'Paid' : partial ? 'Partial' : 'Pending';
    final paidPct = f.amount > 0 ? f.paidAmount / f.amount : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.receipt_long_outlined, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(f.feeType, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF1C1C1E))),
            if (f.dueDate != null)
              Text('Due: ${DateFormat('dd MMM yyyy').format(f.dueDate!)}',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
            child: Text(label, style: GoogleFonts.inter(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          _AmtCol('Amount', f.amount),
          _AmtCol('Paid', f.paidAmount, color: const Color(0xFF22C55E)),
          _AmtCol('Balance', f.balance, color: f.balance > 0 ? const Color(0xFFEF4444) : const Color(0xFF22C55E)),
        ]),
        if (!paid) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: paidPct,
              minHeight: 5,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ]),
    );
  }
}

class _AmtCol extends StatelessWidget {
  final String label;
  final double amount;
  final Color? color;
  const _AmtCol(this.label, this.amount, {this.color});

  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
    const SizedBox(height: 3),
    Text('₹${NumberFormat('#,##0').format(amount)}',
        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700,
            color: color ?? const Color(0xFF1C1C1E))),
  ]));
}
