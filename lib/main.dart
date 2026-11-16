import 'dart:ui';

import 'package:flutter/material.dart';

const bool kScreenshotMode = bool.fromEnvironment('SCREENSHOT_MODE');
const String kAppName = 'LAFORET SYLVIE FRANCOISE';
const String kDeveloperEmail = 'support@laforetsylviefrancoise.fr';
const Color kInk = Color(0xFF061824);
const Color kTeal = Color(0xFF0F6973);
const Color kDeepTeal = Color(0xFF0A3B45);
const Color kGold = Color(0xFFB8872E);
const Color kPaper = Color(0xFFF4F7F6);

void main() {
  runApp(
    LaforetOperationsApp(
      initialRoute: PlatformDispatcher.instance.defaultRouteName,
    ),
  );
}

class LaforetOperationsApp extends StatelessWidget {
  const LaforetOperationsApp({
    super.key,
    this.screenshotMode = kScreenshotMode,
    this.initialRoute = '/',
  });

  final bool screenshotMode;
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: kTeal,
          brightness: Brightness.light,
        ).copyWith(
          primary: kTeal,
          onPrimary: Colors.white,
          secondary: kGold,
          onSecondary: kInk,
          tertiary: kDeepTeal,
          surface: Colors.white,
          onSurface: kInk,
        );

    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: kPaper,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Colors.transparent,
          foregroundColor: kInk,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: kTeal.withValues(alpha: 0.12),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              color: states.contains(WidgetState.selected) ? kTeal : kInk,
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ),
      ),
      home: OperationsHome(
        screenshotMode: screenshotMode,
        initialRoute: initialRoute,
      ),
    );
  }
}

class OperationsHome extends StatefulWidget {
  const OperationsHome({
    super.key,
    required this.screenshotMode,
    this.initialRoute = '/',
  });

  final bool screenshotMode;
  final String initialRoute;

  @override
  State<OperationsHome> createState() => _OperationsHomeState();
}

class _OperationsHomeState extends State<OperationsHome> {
  int _tabIndex = 0;
  List<OperationRecord> _records = const [];
  String _siteName = 'Main facility';
  String _coordinator = 'Operations desk';

  @override
  void initState() {
    super.initState();
    if (widget.screenshotMode) {
      _records = OperationRecord.screenshotRecords();
      _siteName = 'Campus Nord';
      _coordinator = 'Sylvie desk';
    } else {
      _records = OperationRecord.starterRecords();
    }
    _tabIndex = _tabIndexFromRoute(widget.initialRoute);
    if (widget.initialRoute == '/detail') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _records.isEmpty) {
          return;
        }
        _openRecord(_records.first);
      });
    }
  }

  int _tabIndexFromRoute(String route) {
    return switch (route) {
      '/work' => 1,
      '/bookings' => 2,
      '/inventory' => 3,
      '/settings' => 4,
      '/detail' => 1,
      _ => 0,
    };
  }

  Future<void> _showRecordForm(List<RecordType> allowedTypes) async {
    final record = await showModalBottomSheet<OperationRecord>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => RecordFormSheet(
        allowedTypes: allowedTypes,
        defaultSite: _siteName,
        defaultOwner: _coordinator,
      ),
    );
    if (record == null) {
      return;
    }
    setState(() {
      _records = [record, ..._records];
    });
  }

  Future<void> _advanceStatus(OperationRecord record) async {
    setState(() {
      _records = _records
          .map((item) => item.id == record.id ? item.nextStatus() : item)
          .toList();
    });
  }

  Future<void> _deleteRecord(OperationRecord record) async {
    setState(() {
      _records = _records.where((item) => item.id != record.id).toList();
    });
  }

  Future<void> _saveSettings(String siteName, String coordinator) async {
    setState(() {
      _siteName = siteName.trim().isEmpty ? 'Main facility' : siteName.trim();
      _coordinator = coordinator.trim().isEmpty
          ? 'Operations desk'
          : coordinator.trim();
    });
  }

  void _openRecord(OperationRecord record) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecordDetailPage(
          record: record,
          onAdvanceStatus: () => _advanceStatus(record),
          onDelete: () async {
            await _deleteRecord(record);
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(
        records: _records,
        siteName: _siteName,
        coordinator: _coordinator,
        onCreate: () => _showRecordForm(RecordType.values),
        onOpen: _openRecord,
      ),
      RecordsListPage(
        title: 'LAFORET SYLVIE FRANCOISE',
        emptyText: 'No maintenance requests or tasks yet.',
        records: _records
            .where((record) => record.type.isWorkItem)
            .toList(growable: false),
        allowedTypes: const [RecordType.maintenance, RecordType.task],
        onCreate: _showRecordForm,
        onOpen: _openRecord,
        onAdvanceStatus: _advanceStatus,
      ),
      RecordsListPage(
        title: 'Bookings',
        emptyText: 'No facility bookings yet.',
        records: _records
            .where((record) => record.type == RecordType.booking)
            .toList(growable: false),
        allowedTypes: const [RecordType.booking],
        onCreate: _showRecordForm,
        onOpen: _openRecord,
        onAdvanceStatus: _advanceStatus,
      ),
      RecordsListPage(
        title: 'Inventory',
        emptyText: 'No tracked inventory items yet.',
        records: _records
            .where((record) => record.type == RecordType.inventory)
            .toList(growable: false),
        allowedTypes: const [RecordType.inventory],
        onCreate: _showRecordForm,
        onOpen: _openRecord,
        onAdvanceStatus: _advanceStatus,
      ),
      SettingsPage(
        siteName: _siteName,
        coordinator: _coordinator,
        onSave: _saveSettings,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LAFORET Ops',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            Text(
              _siteName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.black.withValues(alpha: 0.58),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Add record',
            onPressed: () => _showRecordForm(RecordType.values),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: SafeArea(child: pages[_tabIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) => setState(() => _tabIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Work',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_available_outlined),
            selectedIcon: Icon(Icons.event_available),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Stock',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.records,
    required this.siteName,
    required this.coordinator,
    required this.onCreate,
    required this.onOpen,
  });

  final List<OperationRecord> records;
  final String siteName;
  final String coordinator;
  final VoidCallback onCreate;
  final ValueChanged<OperationRecord> onOpen;

  @override
  Widget build(BuildContext context) {
    final openCount = records.where((record) => !record.isClosed).length;
    final bookings = records
        .where((record) => record.type == RecordType.booking)
        .length;
    final lowStock = records
        .where(
          (record) =>
              record.type == RecordType.inventory &&
              record.quantity <= record.threshold,
        )
        .length;
    final nextRecords = records.take(4).toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 7,
                child: Image.asset(
                  'docs/featured.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        kInk.withValues(alpha: 0.88),
                        kInk.withValues(alpha: 0.34),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      siteName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Daily operations coordinated by $coordinator',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            MetricTile(label: 'Open items', value: '$openCount'),
            MetricTile(label: 'Bookings', value: '$bookings'),
            MetricTile(label: 'Low stock', value: '$lowStock'),
          ],
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          key: const Key('dashboard-new-record'),
          onPressed: onCreate,
          icon: const Icon(Icons.add),
          label: const Text('New operations record'),
        ),
        const SizedBox(height: 20),
        SectionHeader(
          title: 'Today focus',
          actionLabel: 'Add',
          onAction: onCreate,
        ),
        const SizedBox(height: 10),
        if (nextRecords.isEmpty)
          const EmptyState(
            icon: Icons.assignment_outlined,
            text: 'Create the first request, booking, task, or stock item.',
          )
        else
          ...nextRecords.map(
            (record) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: RecordCard(
                record: record,
                onTap: () => onOpen(record),
                compact: true,
              ),
            ),
          ),
      ],
    );
  }
}

class RecordsListPage extends StatelessWidget {
  const RecordsListPage({
    super.key,
    required this.title,
    required this.emptyText,
    required this.records,
    required this.allowedTypes,
    required this.onCreate,
    required this.onOpen,
    required this.onAdvanceStatus,
  });

  final String title;
  final String emptyText;
  final List<OperationRecord> records;
  final List<RecordType> allowedTypes;
  final ValueChanged<List<RecordType>> onCreate;
  final ValueChanged<OperationRecord> onOpen;
  final ValueChanged<OperationRecord> onAdvanceStatus;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: [
        SectionHeader(
          title: title,
          actionLabel: 'New',
          onAction: () => onCreate(allowedTypes),
        ),
        const SizedBox(height: 10),
        if (records.isEmpty)
          EmptyState(icon: allowedTypes.first.icon, text: emptyText)
        else
          ...records.map(
            (record) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: RecordCard(
                record: record,
                onTap: () => onOpen(record),
                onAdvanceStatus: () => onAdvanceStatus(record),
              ),
            ),
          ),
      ],
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.siteName,
    required this.coordinator,
    required this.onSave,
  });

  final String siteName;
  final String coordinator;
  final Future<void> Function(String siteName, String coordinator) onSave;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _siteController;
  late final TextEditingController _coordinatorController;

  @override
  void initState() {
    super.initState();
    _siteController = TextEditingController(text: widget.siteName);
    _coordinatorController = TextEditingController(text: widget.coordinator);
  }

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.siteName != widget.siteName) {
      _siteController.text = widget.siteName;
    }
    if (oldWidget.coordinator != widget.coordinator) {
      _coordinatorController.text = widget.coordinator;
    }
  }

  @override
  void dispose() {
    _siteController.dispose();
    _coordinatorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: [
        const SectionHeader(title: 'Settings'),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Workspace',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _siteController,
                  decoration: const InputDecoration(
                    labelText: 'Default facility',
                    prefixIcon: Icon(Icons.apartment_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _coordinatorController,
                  decoration: const InputDecoration(
                    labelText: 'Coordinator',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () => widget.onSave(
                      _siteController.text,
                      _coordinatorController.text,
                    ),
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save settings'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const InfoPanel(
          icon: Icons.lock_outline,
          title: 'On-device session',
          body:
              'Records and workspace preferences are handled inside the app on this device. There is no account, cloud sync, analytics, advertising ID, or network service.',
        ),
        const SizedBox(height: 12),
        const InfoPanel(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy contact',
          body: '$kAppName\n$kDeveloperEmail',
        ),
      ],
    );
  }
}

class RecordDetailPage extends StatelessWidget {
  const RecordDetailPage({
    super.key,
    required this.record,
    required this.onAdvanceStatus,
    required this.onDelete,
  });

  final OperationRecord record;
  final VoidCallback onAdvanceStatus;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(record.type.singular)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        TypeBadge(type: record.type),
                        const SizedBox(width: 8),
                        StatusPill(status: record.status),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      record.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      record.notes,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 18),
                    DetailRow(
                      icon: Icons.place_outlined,
                      label: record.type == RecordType.inventory
                          ? 'Storage area'
                          : 'Location',
                      value: record.location,
                    ),
                    DetailRow(
                      icon: Icons.person_outline,
                      label: 'Owner',
                      value: record.owner,
                    ),
                    DetailRow(
                      icon: Icons.schedule_outlined,
                      label: record.type == RecordType.inventory
                          ? 'Review cadence'
                          : 'Due',
                      value: record.dueLabel,
                    ),
                    if (record.type == RecordType.inventory)
                      DetailRow(
                        icon: Icons.inventory_2_outlined,
                        label: 'Stock level',
                        value:
                            '${record.quantity} units, reorder at ${record.threshold}',
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onAdvanceStatus,
              icon: const Icon(Icons.update),
              label: const Text('Advance status'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete record'),
            ),
          ],
        ),
      ),
    );
  }
}

class RecordFormSheet extends StatefulWidget {
  const RecordFormSheet({
    super.key,
    required this.allowedTypes,
    required this.defaultSite,
    required this.defaultOwner,
  });

  final List<RecordType> allowedTypes;
  final String defaultSite;
  final String defaultOwner;

  @override
  State<RecordFormSheet> createState() => _RecordFormSheetState();
}

class _RecordFormSheetState extends State<RecordFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late RecordType _type;
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _ownerController;
  late final TextEditingController _dueController;
  late final TextEditingController _notesController;
  late final TextEditingController _quantityController;
  late final TextEditingController _thresholdController;

  @override
  void initState() {
    super.initState();
    _type = widget.allowedTypes.first;
    _titleController = TextEditingController();
    _locationController = TextEditingController(text: widget.defaultSite);
    _ownerController = TextEditingController(text: widget.defaultOwner);
    _dueController = TextEditingController(text: _type.defaultDue);
    _notesController = TextEditingController();
    _quantityController = TextEditingController(text: '12');
    _thresholdController = TextEditingController(text: '6');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _ownerController.dispose();
    _dueController.dispose();
    _notesController.dispose();
    _quantityController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(
      OperationRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        type: _type,
        title: _titleController.text.trim(),
        location: _locationController.text.trim(),
        owner: _ownerController.text.trim(),
        dueLabel: _dueController.text.trim(),
        status: _type.defaultStatus,
        notes: _notesController.text.trim().isEmpty
            ? _type.defaultNotes
            : _notesController.text.trim(),
        quantity: int.tryParse(_quantityController.text.trim()) ?? 0,
        threshold: int.tryParse(_thresholdController.text.trim()) ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'New operations record',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<RecordType>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Record type',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: widget.allowedTypes
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.singular),
                      ),
                    )
                    .toList(),
                onChanged: widget.allowedTypes.length == 1
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _type = value;
                          _dueController.text = value.defaultDue;
                        });
                      },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('create-record-title'),
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: _type.titleLabel,
                  prefixIcon: Icon(_type.icon),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: _type == RecordType.inventory
                      ? 'Storage area'
                      : 'Location',
                  prefixIcon: const Icon(Icons.place_outlined),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ownerController,
                decoration: const InputDecoration(
                  labelText: 'Owner',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dueController,
                decoration: InputDecoration(
                  labelText: _type == RecordType.inventory
                      ? 'Review cadence'
                      : 'Due or scheduled time',
                  prefixIcon: const Icon(Icons.schedule_outlined),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              if (_type == RecordType.inventory) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          prefixIcon: Icon(Icons.numbers),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _thresholdController,
                        decoration: const InputDecoration(
                          labelText: 'Reorder at',
                          prefixIcon: Icon(Icons.warning_amber_outlined),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('save-record'),
                  onPressed: _save,
                  icon: const Icon(Icons.check),
                  label: const Text('Save record'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RecordCard extends StatelessWidget {
  const RecordCard({
    super.key,
    required this.record,
    required this.onTap,
    this.onAdvanceStatus,
    this.compact = false,
  });

  final OperationRecord record;
  final VoidCallback onTap;
  final VoidCallback? onAdvanceStatus;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TypeBadge(type: record.type),
                  const SizedBox(width: 8),
                  Expanded(child: StatusPill(status: record.status)),
                  if (onAdvanceStatus != null)
                    IconButton(
                      tooltip: 'Advance status',
                      visualDensity: VisualDensity.compact,
                      onPressed: onAdvanceStatus,
                      icon: const Icon(Icons.update, size: 20),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                record.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.place_outlined,
                    size: 16,
                    color: Colors.black.withValues(alpha: 0.54),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${record.location} | ${record.dueLabel}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              if (!compact) ...[
                const SizedBox(height: 8),
                Text(
                  record.notes,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 52) / 3,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: kDeepTeal,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black.withValues(alpha: 0.62),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add, size: 18),
            label: Text(actionLabel!),
          ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(icon, color: kTeal, size: 34),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class InfoPanel extends StatelessWidget {
  const InfoPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: kGold.withValues(alpha: 0.18),
              foregroundColor: kDeepTeal,
              child: Icon(icon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(body, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TypeBadge extends StatelessWidget {
  const TypeBadge({super.key, required this.type});

  final RecordType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: type.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, size: 15, color: type.color),
          const SizedBox(width: 5),
          Text(
            type.label,
            style: TextStyle(
              color: type.color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Complete' => const Color(0xFF247048),
      'Scheduled' => const Color(0xFF915F00),
      'Low stock' => const Color(0xFF9A3D28),
      'In progress' => kTeal,
      _ => const Color(0xFF42505A),
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          status,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: kTeal),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.black.withValues(alpha: 0.58),
                  ),
                ),
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum RecordType { maintenance, task, booking, inventory }

extension RecordTypeDetails on RecordType {
  String get label => switch (this) {
    RecordType.maintenance => 'Request',
    RecordType.task => 'Task',
    RecordType.booking => 'Booking',
    RecordType.inventory => 'Stock',
  };

  String get singular => switch (this) {
    RecordType.maintenance => 'Maintenance request',
    RecordType.task => 'Task',
    RecordType.booking => 'Facility booking',
    RecordType.inventory => 'Inventory item',
  };

  IconData get icon => switch (this) {
    RecordType.maintenance => Icons.handyman_outlined,
    RecordType.task => Icons.checklist_outlined,
    RecordType.booking => Icons.event_available_outlined,
    RecordType.inventory => Icons.inventory_2_outlined,
  };

  Color get color => switch (this) {
    RecordType.maintenance => kTeal,
    RecordType.task => const Color(0xFF526D1F),
    RecordType.booking => const Color(0xFF806018),
    RecordType.inventory => const Color(0xFF8A4428),
  };

  bool get isWorkItem =>
      this == RecordType.maintenance || this == RecordType.task;

  String get storageValue => name;

  String get defaultStatus => switch (this) {
    RecordType.booking => 'Scheduled',
    RecordType.inventory => 'In stock',
    _ => 'Open',
  };

  String get defaultDue => switch (this) {
    RecordType.booking => 'Tomorrow, 09:00',
    RecordType.inventory => 'Weekly review',
    _ => 'Today',
  };

  String get titleLabel => switch (this) {
    RecordType.maintenance => 'Request title',
    RecordType.task => 'Task title',
    RecordType.booking => 'Booking title',
    RecordType.inventory => 'Item name',
  };

  String get defaultNotes => switch (this) {
    RecordType.maintenance => 'Describe the issue, priority, and access notes.',
    RecordType.task => 'Describe the work required and expected outcome.',
    RecordType.booking => 'Add setup needs, attendee count, and room notes.',
    RecordType.inventory => 'Add supplier, storage, or reorder notes.',
  };

  static RecordType parse(String value) {
    return RecordType.values.firstWhere(
      (type) => type.storageValue == value,
      orElse: () => RecordType.task,
    );
  }
}

class OperationRecord {
  const OperationRecord({
    required this.id,
    required this.type,
    required this.title,
    required this.location,
    required this.owner,
    required this.dueLabel,
    required this.status,
    required this.notes,
    this.quantity = 0,
    this.threshold = 0,
  });

  final String id;
  final RecordType type;
  final String title;
  final String location;
  final String owner;
  final String dueLabel;
  final String status;
  final String notes;
  final int quantity;
  final int threshold;

  bool get isClosed => status == 'Complete';

  OperationRecord nextStatus() {
    final next = switch (status) {
      'Open' => 'Scheduled',
      'Scheduled' => 'In progress',
      'In progress' => 'Complete',
      'In stock' when quantity <= threshold => 'Low stock',
      'In stock' => 'Complete',
      'Low stock' => 'In stock',
      _ => 'Open',
    };
    return copyWith(status: next);
  }

  OperationRecord copyWith({String? status}) {
    return OperationRecord(
      id: id,
      type: type,
      title: title,
      location: location,
      owner: owner,
      dueLabel: dueLabel,
      status: status ?? this.status,
      notes: notes,
      quantity: quantity,
      threshold: threshold,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.storageValue,
      'title': title,
      'location': location,
      'owner': owner,
      'dueLabel': dueLabel,
      'status': status,
      'notes': notes,
      'quantity': quantity,
      'threshold': threshold,
    };
  }

  factory OperationRecord.fromJson(Map<String, dynamic> json) {
    return OperationRecord(
      id: json['id'] as String? ?? DateTime.now().toIso8601String(),
      type: RecordTypeDetails.parse(json['type'] as String? ?? 'task'),
      title: json['title'] as String? ?? 'Untitled record',
      location: json['location'] as String? ?? 'Main facility',
      owner: json['owner'] as String? ?? 'Operations desk',
      dueLabel: json['dueLabel'] as String? ?? 'Today',
      status: json['status'] as String? ?? 'Open',
      notes: json['notes'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      threshold: json['threshold'] as int? ?? 0,
    );
  }

  static List<OperationRecord> starterRecords() {
    return const [
      OperationRecord(
        id: 'starter-maintenance',
        type: RecordType.maintenance,
        title: 'Inspect reception lighting',
        location: 'Main facility',
        owner: 'Operations desk',
        dueLabel: 'Today',
        status: 'Open',
        notes: 'Track the request, assign ownership, and update the status.',
      ),
    ];
  }

  static List<OperationRecord> screenshotRecords() {
    return const [
      OperationRecord(
        id: 'shot-01',
        type: RecordType.maintenance,
        title: 'Repair corridor access reader',
        location: 'Building A, level 2',
        owner: 'Sylvie desk',
        dueLabel: 'Today, 15:00',
        status: 'In progress',
        notes:
            'Technician assigned. Confirm badge reader wiring and update front desk when access is restored.',
      ),
      OperationRecord(
        id: 'shot-02',
        type: RecordType.task,
        title: 'Prepare weekly service review',
        location: 'Operations office',
        owner: 'Facilities lead',
        dueLabel: 'Friday',
        status: 'Open',
        notes:
            'Collect completed requests, open risks, booking usage, and low stock actions.',
      ),
      OperationRecord(
        id: 'shot-03',
        type: RecordType.booking,
        title: 'Boardroom booking for vendor visit',
        location: 'Boardroom 3',
        owner: 'Reception',
        dueLabel: 'Tomorrow, 09:00',
        status: 'Scheduled',
        notes:
            'Set twelve seats, check projector, and keep visitor badges ready.',
      ),
      OperationRecord(
        id: 'shot-04',
        type: RecordType.inventory,
        title: 'HVAC filters',
        location: 'Technical storage',
        owner: 'Maintenance',
        dueLabel: 'Weekly review',
        status: 'Low stock',
        notes: 'Reorder before the monthly preventive maintenance window.',
        quantity: 4,
        threshold: 8,
      ),
      OperationRecord(
        id: 'shot-05',
        type: RecordType.inventory,
        title: 'Cleaning supply kits',
        location: 'Service closet',
        owner: 'Facilities team',
        dueLabel: 'Monthly review',
        status: 'In stock',
        notes: 'Keep minimum stock available for after-hours requests.',
        quantity: 18,
        threshold: 10,
      ),
    ];
  }
}
