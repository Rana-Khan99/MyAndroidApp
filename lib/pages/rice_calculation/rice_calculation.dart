import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';

class RiceProfile {
  String name;
  double cost;
  double deposit;

  RiceProfile({
    required this.name,
    required this.cost,
    required this.deposit,
  });
}

class RiceCalculationPage extends StatefulWidget {
  const RiceCalculationPage({super.key});

  @override
  State<RiceCalculationPage> createState() => _RiceCalculationPageState();
}

class _RiceCalculationPageState extends State<RiceCalculationPage> {
  final List<RiceProfile> profiles = [];
  final TextEditingController extraRiceController = TextEditingController();
  final TextEditingController managerRiceController = TextEditingController();
  final TextEditingController prevImprovementController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _requestStoragePermission();
  }

  Future<void> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isDenied) {
        await Permission.manageExternalStorage.request();
      }
      if (await Permission.storage.isDenied) {
        await Permission.storage.request();
      }
    }
  }

  // 🧾 Add/Edit Profile
  Future<void> _showProfileForm({RiceProfile? existing, int? index}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final costController = TextEditingController(text: existing?.cost.toString() ?? '');
    final depositController = TextEditingController(text: existing?.deposit.toString() ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey.shade50,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                existing == null ? "➕ Add Rice Profile" : "✏ Edit Rice Profile",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade800,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(nameController, "Full Name", Icons.person),
              const SizedBox(height: 12),
              _buildTextField(costController, "Cost (Rice Pot)", Icons.rice_bowl, isNumber: true),
              const SizedBox(height: 12),
              _buildTextField(depositController, "Deposit (Rice Pot)", Icons.monetization_on, isNumber: true),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  final name = nameController.text.trim();
                  final cost = double.tryParse(costController.text.trim()) ?? -1;
                  final deposit = double.tryParse(depositController.text.trim()) ?? double.nan;

                  if (name.isEmpty || cost < 0 || deposit.isNaN) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("⚠ Please enter valid information.")),
                    );
                    return;
                  }

                  setState(() {
                    if (existing != null && index != null) {
                      profiles[index] = RiceProfile(name: name, cost: cost, deposit: deposit);
                    } else {
                      profiles.add(RiceProfile(name: name, cost: cost, deposit: deposit));
                      Future.delayed(const Duration(milliseconds: 200), () {
                        if (_scrollController.hasClients) {
                          _scrollController.animateTo(
                            _scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
                      });
                    }
                  });
                  Navigator.pop(ctx);
                },
                icon: const Icon(Icons.check, color: Colors.white),
                label: Text(existing == null ? "Add Profile" : "Save Changes"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.teal.shade700),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ❌ Delete single profile
  Future<void> _confirmDelete(int index) async {
    final removed = profiles[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Profile"),
        content: Text('Are you sure you want to delete "${removed.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => profiles.removeAt(index));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile "${removed.name}" deleted.')),
      );
    }
  }

  // 🗑️ Delete All
  Future<void> _confirmDeleteAll() async {
    if (profiles.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete All Profiles"),
        content: const Text("Are you sure you want to delete all profiles?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => profiles.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All profiles deleted.')),
      );
    }
  }

  // 🧹 Clear all input fields
  void _resetAllInputs() {
    extraRiceController.clear();
    managerRiceController.clear();
    prevImprovementController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All input fields cleared.')),
    );
  }
          //genarate pdf
  Future<void> _generatePdfReport() async {
    if (profiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠ Please add profiles first!')),
      );
      return;
    }

    final pdf = pw.Document();

    final totalExtraRice =
        double.tryParse(extraRiceController.text.trim()) ?? 0;
    final prevImprovement =
        double.tryParse(prevImprovementController.text.trim()) ?? 0;
    final currentManagerRice =
        double.tryParse(managerRiceController.text.trim()) ?? 0;

    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd – hh:mm a').format(now);

    // ---------- Logic ----------
    final totalProfiles = profiles.length;
    final dividedExtra = totalProfiles > 0 ? totalExtraRice / totalProfiles : 0;

    double totalDeposit = 0;
    double totalCost = 0;
    double totalManagerGets = 0;
    double totalBorderGets = 0;

    final tableData = profiles.map((p) {
      // ✅ সব হিসাব float এ থাকবে
      final cost = p.cost + dividedExtra;
      final deposit = p.deposit;

      final diff = deposit - cost;

      final managerGets = diff < 0 ? (-diff) : 0;
      final borderGets = diff > 0 ? diff : 0;

      totalDeposit += deposit;
      totalCost += cost;
      totalManagerGets += managerGets;
      totalBorderGets += borderGets;

      return [
        p.name,
        p.cost.toStringAsFixed(2),
        deposit.toStringAsFixed(2),
        cost.toStringAsFixed(2),
        managerGets > 0 ? managerGets.toStringAsFixed(2) : '-',
        borderGets > 0 ? borderGets.toStringAsFixed(2) : '-',
      ];
    }).toList();

    final managerFinalRice = (totalManagerGets + currentManagerRice) -
        totalBorderGets -
        prevImprovement;

    // ---------- PDF Layout ----------
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Rice Report',
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.Text(formattedDate, style: pw.TextStyle(fontSize: 10)),
            ],
          ),
          pw.SizedBox(height: 16),

          // 🔹 Summary Section
          pw.Text('Summary',
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('Total Profiles: $totalProfiles'),
          pw.SizedBox(height: 3),
          pw.Text('Total Deposit: ${totalDeposit.toStringAsFixed(2)} pot'),
          pw.SizedBox(height: 3),
          pw.Text('Total Cost: ${totalCost.toStringAsFixed(2)} pot'),
          pw.SizedBox(height: 3),
          pw.Text('Extra Cost (Total): ${totalExtraRice.toStringAsFixed(2)} pot'),
          pw.SizedBox(height: 3),
          pw.Text('Extra per Person: ${dividedExtra.toStringAsFixed(2)} pot'),
          pw.SizedBox(height: 3),
          pw.Text('Manager Current Rice: ${currentManagerRice.toStringAsFixed(2)} pot'),
          pw.SizedBox(height: 3),
          pw.Text('Manager Final Balance: ${managerFinalRice.toStringAsFixed(2)} pot'),

          pw.SizedBox(height: 20),

          // 🔹 Profiles Breakdown Table
          pw.Text('Profiles Breakdown',
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headers: [
              'Name',
              'Cost',
              'Deposit',
              'Final Cost',
              'Manager Gets',
              'Border Gets'
            ],
            data: tableData,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            headerStyle:
            pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.center,
            columnWidths: {
              0: const pw.FlexColumnWidth(2.5),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(1.5),
              5: const pw.FlexColumnWidth(1.5),
            },
            cellHeight: 22,
          ),

          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 8),

          // 🔹 Manager Balance Formula
          pw.Text("Manager Rice Calculation:",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(
            "(${totalManagerGets.toStringAsFixed(2)} + $currentManagerRice current) "
                "- ${totalBorderGets.toStringAsFixed(2)} border gets "
                "- $prevImprovement improvement",
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text("= ${managerFinalRice.toStringAsFixed(2)} pot",
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),

          pw.SizedBox(height: 20),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text('Generated by Mr.R-Group',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          ),
        ],
      ),
    );

    // ---------- Save & Open ----------
    Directory dir;
    if (Platform.isAndroid) {
      dir = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

    final file = File("${dir.path}/rice_report_$formattedDate.pdf");
    await file.writeAsBytes(await pdf.save());
    await OpenFilex.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("🍚 Rice Calculation"),
        centerTitle: true,
        backgroundColor: Colors.teal.shade700,
        elevation: 6,
        actions: [
          if (profiles.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.white),
              tooltip: "Delete All Profiles",
              onPressed: _confirmDeleteAll,
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: "Clear All Inputs",
            onPressed: _resetAllInputs,
          ),
        ],
      ),
      floatingActionButton: GestureDetector(
        onLongPress: _confirmDeleteAll,
        child: FloatingActionButton.extended(
          onPressed: () => _showProfileForm(),
          icon: const Icon(Icons.add),
          label: const Text("Add Profile"),
          backgroundColor: Colors.teal.shade700,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _buildTextField(extraRiceController, "Extra Rice (pot)", Icons.add_circle, isNumber: true),
                      const SizedBox(height: 12),
                      _buildTextField(managerRiceController, "Current Manager Rice", Icons.rice_bowl_sharp, isNumber: true),
                      const SizedBox(height: 12),
                      _buildTextField(prevImprovementController, "Previous Improvement", Icons.trending_down, isNumber: true),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: _generatePdfReport,
                        icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                        label: const Text("Generate PDF"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade600,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          minimumSize: const Size.fromHeight(50),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: profiles.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.group, size: 80, color: Colors.grey),
                      const SizedBox(height: 10),
                      Text("No profiles yet", style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54)),
                    ],
                  ),
                )
                    : ListView.builder(
                  controller: _scrollController,
                  itemCount: profiles.length,
                  itemBuilder: (ctx, idx) {
                    final p = profiles[idx];
                    return Card(
                      color: Colors.white,
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.shade600,
                          child: Text(p.name[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(p.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        subtitle: Text("Cost: ${p.cost} | Deposit: ${p.deposit}",
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54)),
                        trailing: PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == "edit") _showProfileForm(existing: p, index: idx);
                            if (val == "delete") _confirmDelete(idx);
                          },
                          itemBuilder: (ctx) => const [
                            PopupMenuItem(value: "edit", child: Text("Edit")),
                            PopupMenuItem(value: "delete", child: Text("Delete")),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
