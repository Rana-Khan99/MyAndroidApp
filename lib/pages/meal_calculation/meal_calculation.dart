import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';

class Profile {
  String name;
  int mealCount;
  double deposit;

  Profile({
    required this.name,
    required this.mealCount,
    required this.deposit,
  });
}

class MealCalculationScreen extends StatefulWidget {
  const MealCalculationScreen({super.key});

  @override
  State<MealCalculationScreen> createState() => _MealCalculationScreenState();
}

class _MealCalculationScreenState extends State<MealCalculationScreen> {
  final List<Profile> profiles = [];
  final TextEditingController bazarCostController = TextEditingController();
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

  // ---------- Profile Form ----------
  Future<void> _showProfileForm({Profile? existing, int? index}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final mealController =
    TextEditingController(text: existing?.mealCount.toString() ?? '');
    final depositController =
    TextEditingController(text: existing?.deposit.toStringAsFixed(2) ?? '');

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.9),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  height: 5,
                  width: 50,
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12)),
                ),
                const SizedBox(height: 16),
                Text(
                  existing == null ? "➕ Add Profile" : "✏ Edit Profile",
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.tealAccent,
                  ),
                ),
                const SizedBox(height: 18),
                _glassField(nameController, "Full Name", Icons.person),
                const SizedBox(height: 12),
                _glassField(mealController, "Meal Count", Icons.fastfood,
                    isNumber: true),
                const SizedBox(height: 12),
                _glassField(depositController, "Deposit (Tk)",
                    Icons.account_balance_wallet,
                    isDecimal: true),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final meal = int.tryParse(mealController.text.trim()) ?? -1;
                    final deposit =
                        double.tryParse(depositController.text.trim()) ??
                            double.nan;

                    if (name.isEmpty || meal < 0 || deposit.isNaN) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("⚠ Please enter valid data"),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }

                    setState(() {
                      if (existing != null && index != null) {
                        profiles[index] = Profile(
                            name: name, mealCount: meal, deposit: deposit);
                      } else {
                        profiles.add(Profile(
                            name: name, mealCount: meal, deposit: deposit));
                        Future.delayed(const Duration(milliseconds: 250), () {
                          if (_scrollController.hasClients) {
                            _scrollController.animateTo(
                              _scrollController.position.maxScrollExtent,
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOut,
                            );
                          }
                        });
                      }
                    });
                    Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.check, color: Colors.black),
                  label: Text(
                    existing == null ? "Add Profile" : "Save",
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _glassField(TextEditingController controller, String label,
      IconData icon,
      {bool isNumber = false, bool isDecimal = false}) {
    return TextField(
      controller: controller,
      keyboardType: isDecimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : (isNumber ? TextInputType.number : TextInputType.text),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.tealAccent),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.tealAccent, width: 1.5),
        ),
      ),
    );
  }

  // ---------- Delete Single ----------
  Future<void> _confirmDelete(int index) async {
    final removed = profiles[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('🗑 Delete Profile',
            style: GoogleFonts.poppins(
                color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${removed.name}"?',
            style: GoogleFonts.poppins(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => profiles.removeAt(index));
    }
  }

  // ---------- 🗑 Delete All Profiles ----------
  Future<void> _confirmDeleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '🗑 Delete All Profiles',
          style: GoogleFonts.poppins(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete ALL profiles? This action cannot be undone!',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
            const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => profiles.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🗑 All profiles deleted'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ---------- PDF Generate ----------
  Future<void> _generatePdfReport() async {
    try {
      if (profiles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('⚠ Please add profiles first!'),
          backgroundColor: Colors.redAccent,
        ));
        return;
      }

      final pdf = pw.Document();
      final totalBazar = double.tryParse(bazarCostController.text.trim()) ?? 0;
      final totalMeal = profiles.fold(0, (sum, p) => sum + p.mealCount);
      final mealRate = totalMeal == 0 ? 0 : totalBazar / totalMeal;

      final now = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd').format(now);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (context) => [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Meal Report',
                        style: pw.TextStyle(
                            fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('Date: $formattedDate',
                        style: pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    borderRadius:
                    const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(width: 1),
                  ),
                  child: pw.Text(
                    'Total Meal: $totalMeal\nTotal Bazar: ${totalBazar.toStringAsFixed(2)} Tk',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Divider(),
            pw.SizedBox(height: 12),
            pw.Text('Summary',
                style: pw.TextStyle(
                    fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text('Meal Rate: ${mealRate.toStringAsFixed(2)} Tk per meal'),
            pw.SizedBox(height: 12),
            pw.Table.fromTextArray(
              headers: [
                'Name',
                'Meal',
                'Deposit (Tk)',
                'Cost (Tk)',
                'Manager Gets (Tk)',
                'Border Gets (Tk)'
              ],
              data: profiles.map((p) {
                final cost = p.mealCount * mealRate;
                final diff = p.deposit - cost;
                final managerGets = diff < 0 ? (-diff) : 0;
                final borderGets = diff > 0 ? diff : 0;
                return [
                  p.name,
                  p.mealCount.toString(),
                  p.deposit.toStringAsFixed(2),
                  cost.toStringAsFixed(2),
                  managerGets > 0 ? managerGets.toStringAsFixed(2) : '-',
                  borderGets > 0 ? borderGets.toStringAsFixed(2) : '-',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration:
              const pw.BoxDecoration(color: PdfColors.grey300),
            ),
            pw.SizedBox(height: 18),
            pw.Divider(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('Generated by Mr.R-Group',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
            ),
          ],
        ),
      );

      Directory dir;
      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      final file = File("${dir.path}/meal_report_$formattedDate.pdf");
      await file.writeAsBytes(await pdf.save());

      final result = await OpenFilex.open(file.path);
      if (result.type == ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ PDF saved: ${file.path}'),
          backgroundColor: Colors.green,
        ));
      }
      else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('⚠ PDF saved but not opened: ${file.path}'),
          backgroundColor: Colors.orange,
        ));
      }
    }
    catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('❌ Failed to generate PDF: $e'),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalMeals = profiles.fold(0, (sum, p) => sum + p.mealCount);
    final totalDeposit = profiles.fold(0.0, (sum, p) => sum + p.deposit);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text("Meal Calculation",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: Colors.tealAccent)),
        centerTitle: true,
        backgroundColor: Colors.black54,
        elevation: 10,
        shadowColor: Colors.tealAccent.withOpacity(0.5),
        actions: [
          if (profiles.isNotEmpty)
            IconButton(
              icon:
              const Icon(Icons.delete_forever, color: Colors.redAccent),
              tooltip: "Delete All Profiles",
              onPressed: _confirmDeleteAll,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProfileForm(),
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text("Add Profile", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.tealAccent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              // ---------- Stats Section ----------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statCard("Profiles", profiles.length.toString(),
                      Icons.group, Colors.blueAccent),
                  _statCard("Total Meals", totalMeals.toString(),
                      Icons.fastfood, Colors.orangeAccent),
                  _statCard(
                      "Total Deposit",
                      "${totalDeposit.toStringAsFixed(0)} Tk",
                      Icons.account_balance_wallet,
                      Colors.greenAccent),
                ],
              ),
              const SizedBox(height: 16),
              // ---------- Bazar Cost ----------
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.tealAccent.withOpacity(0.2),
                      Colors.purpleAccent.withOpacity(0.15)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.tealAccent.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: bazarCostController,
                        keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Total Bazar Cost (Tk)",
                          labelStyle:
                          GoogleFonts.poppins(color: Colors.white70),
                          prefixIcon: const Icon(Icons.shopping_cart,
                              color: Colors.tealAccent),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _generatePdfReport,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text("PDF"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.tealAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // ---------- Profile List ----------
              Expanded(
                child: profiles.isEmpty
                    ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.group,
                            size: 90, color: Colors.white24),
                        const SizedBox(height: 14),
                        Text("No profiles yet",
                            style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                color: Colors.white70)),
                      ],
                    ))
                    : ListView.separated(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: profiles.length,
                  separatorBuilder: (ctx, idx) =>
                  const SizedBox(height: 10),
                  itemBuilder: (ctx, idx) {
                    final p = profiles[idx];
                    return Card(
                      color: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                          side: BorderSide(
                              color: Colors.tealAccent.withOpacity(0.2),
                              width: 1)),
                      elevation: 6,
                      shadowColor:
                      Colors.tealAccent.withOpacity(0.3),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        leading: CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.tealAccent,
                          child: Text(p.name[0].toUpperCase(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Colors.black)),
                        ),
                        title: Text(p.name,
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.white)),
                        subtitle: Text(
                            "Meal: ${p.mealCount} | Deposit: ${p.deposit.toStringAsFixed(2)} Tk",
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w400,
                                color: Colors.white70)),
                        trailing: PopupMenuButton<String>(
                          color: Colors.grey.shade900,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(14)),
                          onSelected: (val) {
                            if (val == "edit") {
                              _showProfileForm(existing: p, index: idx);
                            }
                            if (val == "delete") {
                              _confirmDelete(idx);
                            }
                          },
                          icon: const Icon(Icons.more_vert,
                              color: Colors.white70),
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                                value: "edit",
                                child: Row(children: [
                                  const Icon(Icons.edit,
                                      color: Colors.tealAccent),
                                  const SizedBox(width: 6),
                                  Text("Edit",
                                      style: GoogleFonts.poppins(
                                          color: Colors.white))
                                ])),
                            PopupMenuItem(
                                value: "delete",
                                child: Row(children: [
                                  const Icon(Icons.delete,
                                      color: Colors.redAccent),
                                  const SizedBox(width: 6),
                                  Text("Delete",
                                      style: GoogleFonts.poppins(
                                          color: Colors.redAccent))
                                ])),
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

  Widget _statCard(
      String title, String value, IconData icon, Color accentColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accentColor.withOpacity(0.2), Colors.black87],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accentColor.withOpacity(0.4), width: 1),
          boxShadow: [
            BoxShadow(
                color: accentColor.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: accentColor, size: 28),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 4),
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
