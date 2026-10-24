import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/contributor.dart';
import '../../data/providers/app_state.dart';
import 'contributor_history_screen.dart';

class ContributorsScreen extends StatefulWidget {
  final AppState state;

  const ContributorsScreen({super.key, required this.state});

  @override
  State<ContributorsScreen> createState() => _ContributorsScreenState();
}

class _ContributorsScreenState extends State<ContributorsScreen> {
  final _searchController = TextEditingController();
  String _statusFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    widget.state.loadContributors(
      searchQuery: _searchController.text.trim(),
      statusFilter: _statusFilter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final contributors = widget.state.contributors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المساهمون'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: 'إضافة مساهم',
              onPressed: () => _showAddContributorDialog(context),
            ),
          ],
        ),
        body: Column(
          children: [
            // Search and Filters
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'البحث بالاسم أو رقم الهاتف...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _onFilterChanged();
                              },
                            )
                          : null,
                    ),
                    onChanged: (val) => _onFilterChanged(),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('الكل', 'all'),
                        const SizedBox(width: 8),
                        _buildFilterChip('نشط', 'active'),
                        const SizedBox(width: 8),
                        _buildFilterChip('متوقف مؤقتاً', 'paused'),
                        const SizedBox(width: 8),
                        _buildFilterChip('مؤرشف', 'archived'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: contributors.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'لا يوجد مساهمين مطابقين للبحث',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: contributors.length,
                      itemBuilder: (ctx, i) => _buildContributorCard(context, contributors[i]),
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddContributorDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('مساهم جديد'),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.primaryGreen,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (val) {
        setState(() => _statusFilter = value);
        _onFilterChanged();
      },
    );
  }

  Widget _buildContributorCard(BuildContext context, Contributor c) {
    Color statusColor;
    switch (c.status) {
      case 'active':
        statusColor = AppTheme.targetReachedColor;
        break;
      case 'paused':
        statusColor = AppTheme.secondaryGold;
        break;
      case 'archived':
      default:
        statusColor = Colors.grey;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryGreen.withOpacity(0.12),
                  child: Text(
                    c.name.isNotEmpty ? c.name[0] : '؟',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              c.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              c.statusArabicName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${c.typeArabicName} ${c.phone != null && c.phone!.isNotEmpty ? '• ${c.phone}' : ''}',
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (val) => _handleAction(context, c, val),
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('تعديل البيانات'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'rate',
                      child: Row(
                        children: [
                          Icon(Icons.price_change, size: 18),
                          SizedBox(width: 8),
                          Text('تعديل الالتزام الشهري'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'history',
                      child: Row(
                        children: [
                          Icon(Icons.history, size: 18),
                          SizedBox(width: 8),
                          Text('سجل المساهمات'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'status',
                      child: Row(
                        children: [
                          Icon(Icons.toggle_on, size: 18),
                          const SizedBox(width: 8),
                          Text(c.status == 'active' ? 'إيقاف / أرشفة' : 'تفعيل المساهم'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('الالتزام الشهري الحالي', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(
                      c.currentRateAmount != null
                          ? CurrencyFormatter.formatIqd(c.currentRateAmount!)
                          : 'غير محدد',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('تاريخ بدء المساهمة', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(
                      c.startsOn,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, Contributor c, String action) {
    switch (action) {
      case 'edit':
        _showEditContributorDialog(context, c);
        break;
      case 'rate':
        _showUpdateRateDialog(context, c);
        break;
      case 'history':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ContributorHistoryScreen(contributor: c),
          ),
        );
        break;
      case 'status':
        _showChangeStatusDialog(context, c);
        break;
    }
  }

  void _showAddContributorDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final rateCtrl = TextEditingController(text: '25000');
    final notesCtrl = TextEditingController();
    String type = 'person';
    DateTime startsOn = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text('إضافة مساهم جديد'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'اسم المساهم *',
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: type,
                        decoration: const InputDecoration(
                          labelText: 'نوع المساهم *',
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'person', child: Text('فرد')),
                          DropdownMenuItem(value: 'department', child: Text('قسم')),
                          DropdownMenuItem(value: 'group', child: Text('مجموعة')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => type = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'رقم الهاتف (اختياري)',
                          prefixIcon: Icon(Icons.phone),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: rateCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'الالتزام الشهري المتوقع (د.ع) *',
                          prefixIcon: Icon(Icons.attach_money),
                          suffixText: 'د.ع',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'ملاحظات (اختياري)',
                          prefixIcon: Icon(Icons.note),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      final rate = CurrencyFormatter.parseIqd(rateCtrl.text) ?? 0;
                      final startsOnStr =
                          '${startsOn.year}-${startsOn.month.toString().padLeft(2, '0')}-${startsOn.day.toString().padLeft(2, '0')}';

                      Navigator.of(ctx).pop();
                      await widget.state.addContributor(
                        name: nameCtrl.text.trim(),
                        contributorType: type,
                        phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                        startsOn: startsOnStr,
                        initialRateIqd: rate,
                        notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                      );
                    },
                    child: const Text('إضافة'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditContributorDialog(BuildContext context, Contributor c) {
    final nameCtrl = TextEditingController(text: c.name);
    final phoneCtrl = TextEditingController(text: c.phone ?? '');
    final notesCtrl = TextEditingController(text: c.notes ?? '');
    String type = c.contributorType;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text('تعديل بيانات المساهم'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'اسم المساهم *'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: type,
                        decoration: const InputDecoration(labelText: 'النوع *'),
                        items: const [
                          DropdownMenuItem(value: 'person', child: Text('فرد')),
                          DropdownMenuItem(value: 'department', child: Text('قسم')),
                          DropdownMenuItem(value: 'group', child: Text('مجموعة')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => type = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneCtrl,
                        decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notesCtrl,
                        decoration: const InputDecoration(labelText: 'ملاحظات'),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      Navigator.of(ctx).pop();
                      await widget.state.updateContributor(
                        id: c.id,
                        name: nameCtrl.text.trim(),
                        contributorType: type,
                        phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                        startsOn: c.startsOn,
                        endsOn: c.endsOn,
                        notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                      );
                    },
                    child: const Text('حفظ التعديل'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showUpdateRateDialog(BuildContext context, Contributor c) {
    final rateCtrl = TextEditingController(
      text: c.currentRateAmount != null ? c.currentRateAmount.toString() : '25000',
    );
    DateTime effectiveDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: Text('تعديل التزام: ${c.name}'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'وفق متطلب FR-03: تغيير قيمة الالتزام يسري من تاريخ النفاذ المختار ولا يغير الأشهر السابقة.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: rateCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'القيمة الشهرية الجديدة (د.ع) *',
                        suffixText: 'د.ع',
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: effectiveDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setDialogState(() => effectiveDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'تاريخ النفاذ: ${effectiveDate.year}-${effectiveDate.month.toString().padLeft(2, '0')}-${effectiveDate.day.toString().padLeft(2, '0')}',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final newRate = CurrencyFormatter.parseIqd(rateCtrl.text);
                      if (newRate != null && newRate >= 0) {
                        final effStr =
                            '${effectiveDate.year}-${effectiveDate.month.toString().padLeft(2, '0')}-${effectiveDate.day.toString().padLeft(2, '0')}';
                        Navigator.of(ctx).pop();
                        try {
                          await widget.state.updateContributorRate(
                            contributorId: c.id,
                            newAmountIqd: newRate,
                            effectiveFrom: effStr,
                          );
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(backgroundColor: Colors.red, content: Text('خطأ: $e')),
                            );
                          }
                        }
                      }
                    },
                    child: const Text('حفظ'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showChangeStatusDialog(BuildContext context, Contributor c) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('تغيير حالة: ${c.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('نشط'),
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  selected: c.status == 'active',
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await widget.state.setContributorStatus(c.id, 'active');
                  },
                ),
                ListTile(
                  title: const Text('متوقف مؤقتاً'),
                  leading: const Icon(Icons.pause_circle_filled, color: Colors.amber),
                  selected: c.status == 'paused',
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await widget.state.setContributorStatus(c.id, 'paused');
                  },
                ),
                ListTile(
                  title: const Text('مؤرشف'),
                  leading: const Icon(Icons.archive, color: Colors.grey),
                  selected: c.status == 'archived',
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await widget.state.setContributorStatus(c.id, 'archived');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
