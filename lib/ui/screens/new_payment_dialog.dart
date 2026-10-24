import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/contributor.dart';
import '../../data/models/contributor_payment_status.dart';
import '../../data/providers/app_state.dart';

class NewPaymentDialog extends StatefulWidget {
  final AppState state;
  final String? preselectedContributorId;

  const NewPaymentDialog({
    super.key,
    required this.state,
    this.preselectedContributorId,
  });

  @override
  State<NewPaymentDialog> createState() => _NewPaymentDialogState();
}

class _NewPaymentDialogState extends State<NewPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedContributorId;
  String _selectedMethod = 'electronic'; // 'cash' or 'electronic'
  DateTime _paymentDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedContributorId = widget.preselectedContributorId;
    if (_selectedContributorId != null) {
      _applySuggestedAmount(_selectedContributorId!);
    }
  }

  void _applySuggestedAmount(String contributorId) {
    final status = widget.state.paymentStatuses.cast<ContributorPaymentStatus?>().firstWhere(
          (s) => s?.contributorId == contributorId,
          orElse: () => null,
        );

    if (status != null && status.remainingIqd > 0) {
      _amountController.text = CurrencyFormatter.formatForInput(status.remainingIqd);
    } else {
      final contributor = widget.state.contributors.cast<Contributor?>().firstWhere(
            (c) => c?.id == contributorId,
            orElse: () => null,
          );
      if (contributor?.currentRateAmount != null && contributor!.currentRateAmount! > 0) {
        _amountController.text = CurrencyFormatter.formatForInput(contributor.currentRateAmount);
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (widget.state.selectedPeriod?.isLocked == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.burntSienna,
          content: Text('هذا الشهر مقفل وتم دفع كفالته مسبقاً، ولا يمكن تسجيل دفعات جديدة إليه'),
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_selectedContributorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار المساهم أولاً')),
      );
      return;
    }

    final amount = CurrencyFormatter.parseIqd(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال مبلغ صحيح أكبر من صفر')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.state.recordPayment(
        contributorId: _selectedContributorId!,
        amountIqd: amount,
        method: _selectedMethod,
        paidAt: _paymentDate.toIso8601String(),
        referenceNumber: _referenceController.text.trim().isNotEmpty
            ? _referenceController.text.trim()
            : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.targetReachedColor,
            content: Text(
              'تم تسجيل دفعة قدرها ${CurrencyFormatter.formatIqd(amount)} بنجاح',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('خطأ: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final period = widget.state.selectedPeriod;
    final periodTitle = period?.arabicMonthName ?? '';

    // Find currently selected status to display expected / remaining info
    final status = widget.state.paymentStatuses.cast<ContributorPaymentStatus?>().firstWhere(
          (s) => s?.contributorId == _selectedContributorId,
          orElse: () => null,
        );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'تسجيل دفعة لشهر $periodTitle',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                if (period?.isLocked == true) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF0EC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF8C8B8)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_rounded, color: AppTheme.burntSienna, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'هذا الشهر مقفل وتم دفع كفالته مسبقاً، ولا يمكن إضافة تسديدات جديدة إليه.',
                            style: TextStyle(
                              color: Color(0xFF8A301E),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Contributor Selector
                DropdownButtonFormField<String>(
                  value: _selectedContributorId,
                  decoration: const InputDecoration(
                    labelText: 'المساهم *',
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: widget.state.contributors.map((c) {
                    return DropdownMenuItem(
                      value: c.id,
                      child: Text('${c.name} (${c.typeArabicName})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedContributorId = val;
                      if (val != null) _applySuggestedAmount(val);
                    });
                  },
                  validator: (val) => val == null ? 'مطلوب' : null,
                ),

                if (status != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('الالتزام الشهري', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(
                              CurrencyFormatter.formatIqd(status.expectedAmountIqd),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('المسدد حتى الآن', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(
                              CurrencyFormatter.formatIqd(status.paidIqd),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: status.paidIqd > 0 ? AppTheme.targetReachedColor : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('المتبقي', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(
                              CurrencyFormatter.formatIqd(status.remainingIqd),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: status.remainingIqd > 0 ? Colors.red : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Amount
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'مبلغ الدفعة (د.ع) *',
                    prefixIcon: const Icon(Icons.attach_money),
                    suffixText: 'د.ع',
                    helperText: 'أدخل المبلغ بالدينار العراقي كعدد صحيح',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'يرجى إدخال المبلغ';
                    final parsed = CurrencyFormatter.parseIqd(val);
                    if (parsed == null || parsed <= 0) return 'المبلغ يجب أن يكون رقماً أكبر من صفر';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Payment Method Selector (PRD: Cash or Electronic)
                const Text(
                  'طريقة الدفع *',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedMethod = 'electronic'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedMethod == 'electronic'
                                ? AppTheme.electronicColor.withValues(alpha: 0.12)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedMethod == 'electronic'
                                  ? AppTheme.electronicColor
                                  : Colors.grey.shade300,
                              width: _selectedMethod == 'electronic' ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.phone_android,
                                color: _selectedMethod == 'electronic'
                                    ? AppTheme.electronicColor
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'إلكتروني',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _selectedMethod == 'electronic'
                                      ? AppTheme.electronicColor
                                      : Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedMethod = 'cash'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedMethod == 'cash'
                                ? AppTheme.cashColor.withValues(alpha: 0.12)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedMethod == 'cash'
                                  ? AppTheme.cashColor
                                  : Colors.grey.shade300,
                              width: _selectedMethod == 'cash' ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.payments_outlined,
                                color: _selectedMethod == 'cash'
                                    ? AppTheme.cashColor
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'نقدي',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _selectedMethod == 'cash'
                                      ? AppTheme.cashColor
                                      : Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Payment Date
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _paymentDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setState(() => _paymentDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.grey),
                        const SizedBox(width: 12),
                        Text(
                          'تاريخ الدفع: ${_paymentDate.year}-${_paymentDate.month.toString().padLeft(2, '0')}-${_paymentDate.day.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Reference number (optional)
                TextFormField(
                  controller: _referenceController,
                  decoration: const InputDecoration(
                    labelText: 'رقم المرجع / الحوالة (اختياري)',
                    prefixIcon: Icon(Icons.tag),
                  ),
                ),

                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات (اختياري)',
                    prefixIcon: Icon(Icons.note_alt_outlined),
                  ),
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('حفظ الدفعة'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
