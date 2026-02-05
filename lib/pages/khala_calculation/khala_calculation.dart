import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';

// -------------------- MODEL --------------------
class KhalaProfile {
  String name;
  double deposit;
  double pcBill;

  KhalaProfile({
    required this.name,
    required this.deposit,
    required this.pcBill,
  });
}

// -------------------- MAIN PAGE --------------------
class KhalaBillPage extends StatefulWidget {
  const KhalaBillPage({super.key});

  @override
  State<KhalaBillPage> createState() => _KhalaBillPageState();
}

class _KhalaBillPageState extends State<KhalaBillPage> {
  final List<KhalaProfile> profiles = [];
  final TextEditingController khalaBillController = TextEditingController();
  final TextEditingController currentBillController = TextEditingController();
  final TextEditingController guraBillController = TextEditingController();
  final TextEditingController extraCostController = TextEditingController();
  final TextEditingController wifiBillController = TextEditingController();
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

  // -------------------- ADD / EDIT PROFILE --------------------
  Future<void> _showProfileForm({KhalaProfile? existing, int? index}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final depositController =
    TextEditingController(text: existing?.deposit.toStringAsFixed(2) ?? '');
    final pcBillController =
    TextEditingController(text: existing?.pcBill.toStringAsFixed(2) ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey.shade100,
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
                existing == null
                    ? "➕ Add Khala Bill Profile"
                    : "✏ Edit Khala Bill Profile",
                style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade800),
              ),
              const SizedBox(height: 16),
              _buildTextField(nameController, "Full Name", Icons.person),
              const SizedBox(height: 12),
              _buildTextField(depositController, "Deposit (Tk)", Icons.monetization_on,
                  isNumber: true),
              const SizedBox(height: 12),
              _buildTextField(pcBillController, "PC Bill (Tk, optional)", Icons.computer,
                  isNumber: true),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  final name = nameController.text.trim();
                  final deposit =
                      double.tryParse(depositController.text.trim()) ?? -1;
                  final pcBill =
                      double.tryParse(pcBillController.text.trim()) ?? 0;

                  if (name.isEmpty || deposit < 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("⚠ Please enter valid data")),
                    );
                    return;
                  }

                  setState(() {
                    if (existing != null && index != null) {
                      profiles[index] =
                          KhalaProfile(name: name, deposit: deposit, pcBill: pcBill);
                    } else {
                      profiles.add(
                          KhalaProfile(name: name, deposit: deposit, pcBill: pcBill));
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
                label: Text(existing == null ? "Add Profile" : "Save"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
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
      keyboardType:
      isNumber ? const TextInputType.numberWithOptions(decimal: true) : null,
      style: TextStyle(color: Colors.grey.shade800),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.teal.shade700),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // -------------------- DELETE ONE --------------------
  Future<void> _confirmDelete(int index) async {
    final removed = profiles[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Profile',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: Colors.red.shade400)),
        content: Text('Are you sure you want to delete "${removed.name}"?',
            style: GoogleFonts.poppins()),
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
    }
  }

  // -------------------- DELETE ALL --------------------
  Future<void> _confirmDeleteAll() async {
    if (profiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠ No profiles to delete!")),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete All Profiles',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: Colors.red.shade400)),
        content: Text(
          'Are you sure you want to delete all ${profiles.length} profiles?',
          style: GoogleFonts.poppins(),
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("✅ All profiles deleted successfully!"),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  // -------------------- RESET INPUTS --------------------
  void _resetInputs() {
    khalaBillController.clear();
    currentBillController.clear();
    guraBillController.clear();
    extraCostController.clear();
    wifiBillController.clear();

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("✅ All input fields cleared!"),
      backgroundColor: Colors.orange,
    ));
  }

  // -------------------- GENERATE PDF --------------------
  Future<void> _generatePdfReport() async {
    if (profiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠ Please add profiles first!')),
      );
      return;
    }

    final pdf = pw.Document();

    final khalaBill = double.tryParse(khalaBillController.text.trim()) ?? 0;
    final currentBill = double.tryParse(currentBillController.text.trim()) ?? 0;
    final guraBill = double.tryParse(guraBillController.text.trim()) ?? 0;
    final extraCost = double.tryParse(extraCostController.text.trim()) ?? 0;
    final wifiBill = double.tryParse(wifiBillController.text.trim()) ?? 0;

    final totalProfiles = profiles.length;
    final totalDeposit = profiles.fold(0.0, (sum, p) => sum + p.deposit);
    final totalPcBill = profiles.fold(0.0, (sum, p) => sum + p.pcBill);

    // ✅ নতুন লজিক অনুযায়ী হিসাব
    final totalCost = (currentBill - totalPcBill) + wifiBill + guraBill + extraCost;
    final perProfileCost = totalProfiles == 0 ? 0 : totalCost / totalProfiles;

    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd – hh:mm a').format(now);

    double managerTotal = 0;
    double borderTotal = 0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          // 🧾 Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Khala Bill Report",
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.Text("Date: $formattedDate", style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Divider(),
          pw.SizedBox(height: 12),

          // 📊 Summary Section
          pw.Text("Summary",
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.teal700)),
          pw.SizedBox(height: 6),
          pw.Text("Total Profiles: $totalProfiles"),
          pw.Text("Total Deposit: ${totalDeposit.toStringAsFixed(2)} Tk"),
          pw.Text("Total PC Bill: ${totalPcBill.toStringAsFixed(2)} Tk"),
          pw.Text("Current Bill: ${currentBill.toStringAsFixed(2)} Tk"),
          pw.Text("Wifi Bill: ${wifiBill.toStringAsFixed(2)} Tk"),
          pw.Text("Gura Bill: ${guraBill.toStringAsFixed(2)} Tk"),
          pw.Text("Extra Cost: ${extraCost.toStringAsFixed(2)} Tk"),
          pw.Text("Khala Bill: ${khalaBill.toStringAsFixed(2)} Tk"),
          pw.SizedBox(height: 6),
          pw.Text("Total Cost (Calculated): ${totalCost.toStringAsFixed(2)} Tk",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text("⚖ Profile Per Cost: ${perProfileCost.toStringAsFixed(2)} Tk",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),

          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 10),

          // 👥 Profile Breakdown
          pw.Text("👥 Profile Breakdown",
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),

          pw.Table.fromTextArray(
            headers: [
              'Name',
              'Deposit',
              'PC Bill',
              'Basic Cost',
              'Total Cost',
              'Manager Gets',
              'Border Gets'
            ],
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.center,
            columnWidths: {
              0: const pw.FlexColumnWidth(2.2),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(1),
              5: const pw.FlexColumnWidth(1.2),
              6: const pw.FlexColumnWidth(1.2),
            },
            data: profiles.map((p) {
              // ✅ নতুন লজিক
              final basicCost = perProfileCost;
              final totalCostPerUser = p.pcBill > 0
                  ? basicCost + p.pcBill + khalaBill
                  : basicCost + khalaBill;

              final diff = p.deposit - totalCostPerUser;
              final managerGets = diff < 0 ? (-diff) : 0;
              final borderGets = diff > 0 ? diff : 0;

              managerTotal += managerGets;
              borderTotal += borderGets;

              return [
                p.name,
                p.deposit.toStringAsFixed(2),
                p.pcBill.toStringAsFixed(2),
                basicCost.toStringAsFixed(2),
                totalCostPerUser.toStringAsFixed(2),
                managerGets > 0 ? managerGets.toStringAsFixed(2) : "-",
                borderGets > 0 ? borderGets.toStringAsFixed(2) : "-",
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 18),
          pw.Divider(),
          pw.SizedBox(height: 8),

          // 📦 Totals
          pw.Text("Manager Total Gets: ${managerTotal.toStringAsFixed(2)} Tk",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text("Border Total Gets: ${borderTotal.toStringAsFixed(2)} Tk",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),

          pw.SizedBox(height: 20),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Generated by Mr. R-Group',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ),
        ],
      ),
    );

    // 💾 Save & Open
    Directory dir;
    if (Platform.isAndroid) {
      dir = Directory('/storage/emulated/0/Download');
      if (!dir.existsSync()) dir = await getApplicationDocumentsDirectory();
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

    final file =
    File("${dir.path}/khala_report_${DateFormat('yyyyMMdd_HHmmss').format(now)}.pdf");
    await file.writeAsBytes(await pdf.save());
    await OpenFilex.open(file.path);
  }

  // -------------------- BUILD UI --------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("Khala Bill Calculation",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.teal.shade700,
        elevation: 6,
        actions: [
          IconButton(
              onPressed: _resetInputs,
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: "Reset All Inputs"),
          if (profiles.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.white),
              tooltip: "Delete All Profiles",
              onPressed: _confirmDeleteAll,
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
                shadowColor: Colors.teal.withOpacity(0.2),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _buildInputField(controller: khalaBillController, label: "Khala Bill (Tk)", icon: Icons.attach_money),
                      const SizedBox(height: 10),
                      _buildInputField(controller: currentBillController, label: "Current Bill (Tk)", icon: Icons.lightbulb),
                      const SizedBox(height: 10),
                      _buildInputField(controller: guraBillController, label: "Gura Bill (Tk)", icon: Icons.bolt),
                      const SizedBox(height: 10),
                      _buildInputField(controller: extraCostController, label: "Extra Cost", icon: Icons.add_card),
                      const SizedBox(height: 10),
                      _buildInputField(controller: wifiBillController, label: "WiFi Bill", icon: Icons.wifi),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _generatePdfReport,
                        icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                        label: const Text("Generate PDF"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
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
                      const SizedBox(height: 12),
                      Text("No profiles yet",
                          style: GoogleFonts.poppins(
                              fontSize: 16, color: Colors.grey.shade700)),
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
                      shadowColor: Colors.teal.withOpacity(0.2),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.shade100,
                          child: Text(p.name[0].toUpperCase(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                        title: Text(p.name,
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                        subtitle: Text(
                            "Deposit: ${p.deposit.toStringAsFixed(2)} Tk | PC Bill: ${p.pcBill.toStringAsFixed(2)} Tk",
                            style: GoogleFonts.poppins(fontSize: 13)),
                        trailing: PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == "edit") {
                              _showProfileForm(existing: p, index: idx);
                            } else if (val == "delete") {
                              _confirmDelete(idx);
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(value: "edit", child: Text("Edit")),
                            const PopupMenuItem(value: "delete", child: Text("Delete")),
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(color: Colors.grey.shade800),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.teal.shade700),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
