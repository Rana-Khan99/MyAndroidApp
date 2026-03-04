import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BazarList extends StatefulWidget {
  const BazarList({super.key});

  @override
  State<BazarList> createState() => _BazarListState();
}

class _BazarListState extends State<BazarList> {
  List<Map<String, dynamic>> bazarItems = [];
  int month = DateTime.now().month;
  int year = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    loadBazarItems();
  }

  // ================== LOAD & SAVE ==================
  Future<void> loadBazarItems() async {
    final prefs = await SharedPreferences.getInstance();
    final key = "bazar_${month}_$year";
    final savedList = prefs.getStringList(key) ?? [];

    setState(() {
      bazarItems = savedList.map((e) {
        final parts = e.split(":");
        final dateParts = parts[0].split("/"); // "dd/mm/yyyy"
        return {
          "day": int.parse(dateParts[0]),
          "month": int.parse(dateParts[1]),
          "year": int.parse(dateParts[2]),
          "amount": double.parse(parts[1]),
        };
      }).toList();
    });
  }

  Future<void> saveBazarItems() async {
    final prefs = await SharedPreferences.getInstance();
    final key = "bazar_${month}_$year";
    final saveList = bazarItems.map((e) =>
    "${e['day'].toString().padLeft(2,'0')}/${e['month'].toString().padLeft(2,'0')}/${e['year']}:${e['amount']}").toList();
    await prefs.setStringList(key, saveList);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Bazar List Saved Successfully")),
    );
  }

  // ================== ADD / EDIT ITEM ==================
  void addOrEditItem({int? index}) {
    DateTime selectedDate = index != null
        ? DateTime(bazarItems[index]['year'], bazarItems[index]['month'], bazarItems[index]['day'])
        : DateTime.now();
    final dateController = TextEditingController(
        text: "${selectedDate.day.toString().padLeft(2,'0')}/"
            "${selectedDate.month.toString().padLeft(2,'0')}/"
            "${selectedDate.year}");
    final amountController = TextEditingController(
        text: index != null ? bazarItems[index]['amount'].toString() : "");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(index == null ? "Add Bazar Item" : "Edit Bazar Item"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dateController,
              readOnly: true,
              decoration: const InputDecoration(hintText: "Pick a date"),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  selectedDate = picked;
                  dateController.text =
                  "${picked.day.toString().padLeft(2,'0')}/"
                      "${picked.month.toString().padLeft(2,'0')}/"
                      "${picked.year}";
                }
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: "Amount"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final double amount = double.tryParse(amountController.text) ?? 0;

              if (amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Enter valid amount")),
                );
                return;
              }

              setState(() {
                final item = {
                  "day": selectedDate.day,
                  "month": selectedDate.month,
                  "year": selectedDate.year,
                  "amount": amount,
                };
                if (index != null) {
                  bazarItems[index] = item;
                } else {
                  bazarItems.add(item);
                }
              });

              saveBazarItems();
              Navigator.pop(context);
            },
            child: Text(index == null ? "Add" : "Update"),
          ),
        ],
      ),
    );
  }

  // ================== DELETE ITEM ==================
  void deleteItem(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Bazar Item"),
        content: Text(
          "Are you sure you want to delete Bazar item of date "
              "${bazarItems[index]['day'].toString().padLeft(2,'0')}/"
              "${bazarItems[index]['month'].toString().padLeft(2,'0')}/"
              "${bazarItems[index]['year']}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                bazarItems.removeAt(index);
              });

              saveBazarItems();

              // ✅ DELETE SUCCESS SNACKBAR
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Bazar item deleted successfully"),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );

              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // ================== TOTAL AMOUNT ==================
  double get totalAmount => bazarItems.fold(0, (sum, item) => sum + item['amount']);

  // ================== UI ==================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bazar List"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
              icon: const Icon(Icons.save),
              tooltip: "Save Bazar List",
              onPressed: saveBazarItems),
        ],
      ),
      floatingActionButton: Padding(
      padding: const EdgeInsets.only(bottom: 70.0, right: 0),
      child: FloatingActionButton.extended(
        onPressed: () => addOrEditItem(),
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add),
        label: const Text("Add Bazar List"),
      ),
    ),


      body: Column(
        children: [
          // Month / Year selector
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DropdownButton<int>(
                  value: month,
                  items: List.generate(
                      12,
                          (i) =>
                          DropdownMenuItem(value: i + 1, child: Text("Month ${i + 1}"))),
                  onChanged: (v) {
                    setState(() => month = v!);
                    loadBazarItems();
                  },
                ),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: year,
                  items: List.generate(6, (i) {
                    int y = DateTime.now().year - 2 + i;
                    return DropdownMenuItem(value: y, child: Text("$y"));
                  }),
                  onChanged: (v) {
                    setState(() => year = v!);
                    loadBazarItems();
                  },
                ),
              ],
            ),
          ),

          const Divider(),

          // Bazar Items List
          Expanded(
            child: bazarItems.isEmpty
                ? const Center(child: Text("No Bazar Items Added"))
                : ListView.builder(
              itemCount: bazarItems.length,
              itemBuilder: (context, index) {
                final item = bazarItems[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListTile(
                    title: Text(
                        "Date: ${item['day'].toString().padLeft(2,'0')}/"
                            "${item['month'].toString().padLeft(2,'0')}/"
                            "${item['year']}"),
                    subtitle: Text("Amount: ${item['amount']} tk"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.teal),
                          onPressed: () => addOrEditItem(index: index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteItem(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Total Amount
          Card(
            margin: const EdgeInsets.all(20),
            color: Colors.teal.shade100,
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Bazar Amount:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("$totalAmount tk",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
