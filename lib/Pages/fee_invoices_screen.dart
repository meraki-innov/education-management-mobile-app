import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

// Fees > My Fee Invoices (student). FRONTEND ONLY for now: the invoices below
// are mock data. When the API is ready, replace _mockInvoices with a provider
// and keep the widgets exactly as they are.

enum InvoiceStatus { unpaid, partial, paid, overdue, waived }

extension on InvoiceStatus {
  String get label => switch (this) {
    InvoiceStatus.unpaid => 'Unpaid',
    InvoiceStatus.partial => 'Partial',
    InvoiceStatus.paid => 'Paid',
    InvoiceStatus.overdue => 'Overdue',
    InvoiceStatus.waived => 'Waived',
  };

  Color color(BuildContext c) => switch (this) {
    InvoiceStatus.unpaid => c.warningColor,
    InvoiceStatus.partial => c.warningColor,
    InvoiceStatus.paid => c.successColor,
    InvoiceStatus.overdue => c.dangerColor,
    InvoiceStatus.waived => c.mutedText,
  };

  // Counts toward "Total Due".
  bool get isOwing =>
      this == InvoiceStatus.unpaid ||
      this == InvoiceStatus.partial ||
      this == InvoiceStatus.overdue;
}

class _Invoice {
  const _Invoice({
    required this.number,
    required this.title,
    required this.fees,
    required this.netPayable,
    required this.due,
    required this.dueDate,
    required this.status,
  });
  final String number;
  final String title;
  final String fees;
  final double netPayable;
  final double due;
  final String dueDate;
  final InvoiceStatus status;
}

const _mockInvoices = <_Invoice>[
  _Invoice(
    number: 'INV-20261027-Um7e4Z8P',
    title: 'New Fee config',
    fees: 'New Fees',
    netPayable: 200,
    due: 200,
    dueDate: '31 Oct 2026',
    status: InvoiceStatus.unpaid,
  ),
  _Invoice(
    number: 'INV-20260915-Kq2x9L1A',
    title: 'Monthly tuition',
    fees: 'Tuition Fee',
    netPayable: 1500,
    due: 0,
    dueDate: '30 Sep 2026',
    status: InvoiceStatus.paid,
  ),
  _Invoice(
    number: 'INV-20260810-Zr5t3B7C',
    title: 'Exam fee',
    fees: 'Exam Fee',
    netPayable: 600,
    due: 250,
    dueDate: '25 Aug 2026',
    status: InvoiceStatus.partial,
  ),
];

String _money(double v) =>
    'BDT ${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2)}';

class FeeInvoicesScreen extends StatefulWidget {
  const FeeInvoicesScreen({super.key});

  @override
  State<FeeInvoicesScreen> createState() => _FeeInvoicesScreenState();
}

class _FeeInvoicesScreenState extends State<FeeInvoicesScreen> {
  String _query = '';
  InvoiceStatus? _status; // null = All Status

  @override
  Widget build(BuildContext context) {
    final totalDue = _mockInvoices
        .where((i) => i.status.isOwing)
        .fold<double>(0, (s, i) => s + i.due);
    final owingCount = _mockInvoices
        .where((i) => i.status.isOwing && i.due > 0)
        .length;

    final q = _query.trim().toLowerCase();
    final shown = _mockInvoices.where((i) {
      if (_status != null && i.status != _status) return false;
      if (q.isEmpty) return true;
      return i.number.toLowerCase().contains(q) ||
          i.title.toLowerCase().contains(q) ||
          i.fees.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Fee Invoices',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _TotalDueCard(
              total: totalDue,
              owingCount: owingCount,
              onPay: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Online payment is not built yet'),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                border: Border.all(color: context.borderColor),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search + status filter. On narrow phones they stack.
                  LayoutBuilder(
                    builder: (context, c) {
                      final search = _SearchField(
                        onChanged: (v) => setState(() => _query = v),
                      );
                      final status = _StatusDropdown(
                        value: _status,
                        onChanged: (v) => setState(() => _status = v),
                      );
                      if (c.maxWidth < 420) {
                        return Column(
                          children: [
                            search,
                            const SizedBox(height: 10),
                            SizedBox(width: double.infinity, child: status),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: search),
                          const SizedBox(width: 10),
                          status,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  if (shown.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Center(
                        child: Text(
                          'No invoices found.',
                          style: TextStyle(color: context.mutedText),
                        ),
                      ),
                    )
                  else
                    for (var i = 0; i < shown.length; i++) ...[
                      _InvoiceCard(index: i + 1, invoice: shown[i]),
                      if (i != shown.length - 1) const SizedBox(height: 10),
                    ],
                  const SizedBox(height: 14),
                  Text(
                    'Showing ${shown.isEmpty ? 0 : 1} to ${shown.length} of ${shown.length} entries',
                    style: TextStyle(fontSize: 12, color: context.mutedText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalDueCard extends StatelessWidget {
  const _TotalDueCard({
    required this.total,
    required this.owingCount,
    required this.onPay,
  });
  final double total;
  final int owingCount;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL DUE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _money(total),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  owingCount == 1
                      ? '1 unpaid invoice'
                      : '$owingCount unpaid invoices',
                  style: TextStyle(fontSize: 13, color: context.mutedText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: onPay,
            icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
            label: const Text('Pay Fees'),
            style: FilledButton.styleFrom(
              backgroundColor: context.isDark
                  ? AppColors.darkButton
                  : AppColors.primary700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search',
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: context.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: context.brandColor),
        ),
      ),
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({required this.value, required this.onChanged});
  final InvoiceStatus? value;
  final ValueChanged<InvoiceStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<InvoiceStatus?>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(10),
          items: [
            const DropdownMenuItem<InvoiceStatus?>(
              value: null,
              child: Text('All Status'),
            ),
            for (final s in InvoiceStatus.values)
              DropdownMenuItem<InvoiceStatus?>(value: s, child: Text(s.label)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);
  final InvoiceStatus status;

  @override
  Widget build(BuildContext context) {
    final c = status.color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c),
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.index, required this.invoice});
  final int index;
  final _Invoice invoice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.iconBoxColor,
        border: Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                index.toString().padLeft(2, '0'),
                style: TextStyle(fontSize: 12, color: context.mutedText),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.number,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      invoice.title,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: context.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(invoice.status),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_vert_rounded, size: 20),
                onSelected: (_) => _showInvoice(context, invoice),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('View'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: context.borderColor),
          const SizedBox(height: 10),
          Row(
            children: [
              _Cell(label: 'FEES', value: invoice.fees),
              _Cell(
                label: 'NET PAYABLE',
                value: _money(invoice.netPayable),
                bold: true,
              ),
              _Cell(label: 'DUE', value: _money(invoice.due), bold: true),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.event_outlined, size: 15, color: context.mutedText),
              const SizedBox(width: 6),
              Text(
                'Due ${invoice.dueDate}',
                style: TextStyle(fontSize: 12.5, color: context.mutedText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.label, required this.value, this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: context.mutedText,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// "View" action: invoice details in a bottom sheet.
void _showInvoice(BuildContext context, _Invoice inv) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.surfaceColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (sheetContext) {
      Widget row(String k, Widget v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                k,
                style: TextStyle(fontSize: 13, color: context.mutedText),
              ),
            ),
            v,
          ],
        ),
      );
      const bold = TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Invoice Details',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Text(
                inv.number,
                style: TextStyle(fontSize: 13, color: context.mutedText),
              ),
              const SizedBox(height: 10),
              Divider(color: context.borderColor),
              row('Description', Text(inv.title, style: bold)),
              row('Fees', Text(inv.fees, style: bold)),
              row('Net Payable', Text(_money(inv.netPayable), style: bold)),
              row('Paid', Text(_money(inv.netPayable - inv.due), style: bold)),
              row('Due', Text(_money(inv.due), style: bold)),
              row('Due Date', Text(inv.dueDate, style: bold)),
              row('Status', _StatusBadge(inv.status)),
            ],
          ),
        ),
      );
    },
  );
}
