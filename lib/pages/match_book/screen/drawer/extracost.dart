import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ExtraCostPage extends StatefulWidget {
  const ExtraCostPage({super.key});

  @override
  State<ExtraCostPage> createState() => _ExtraCostPageState();
}

class _ExtraCostPageState extends State<ExtraCostPage> {
  List<Map<String, dynamic>> expenses = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  double get totalAmount {
    return expenses.fold(0, (sum, item) => sum + item['amount']);
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('expenses');
    if (data != null) {
      setState(() {
        expenses = List<Map<String, dynamic>>.from(jsonDecode(data));
      });
    }
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('expenses', jsonEncode(expenses));
  }

  void deleteExpense(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text("Delete Expense?"),
        content: const Text("Are you sure you want to delete this item?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                expenses.removeAt(index);
              });
              saveData();
              Navigator.pop(context);
            },
            child: const Text("Delete",
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void openExpenseDialog({Map<String, dynamic>? expense, int? index}) {
    final dateController =
    TextEditingController(text: expense?['date'] ?? "");
    final noteController =
    TextEditingController(text: expense?['note'] ?? "");
    final amountController =
    TextEditingController(text: expense?['amount']?.toString() ?? "");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          expense == null ? "Add Expense" : "Edit Expense",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: dateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Date",
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    dateController.text =
                        DateFormat('MM/dd/yyyy').format(picked);
                  }
                },
              ),
              const SizedBox(height: 15),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: "Description",
                  prefixIcon: const Icon(Icons.note),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Amount",
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount != null &&
                  dateController.text.isNotEmpty) {
                setState(() {
                  if (index == null) {
                    expenses.add({
                      'date': dateController.text,
                      'note': noteController.text,
                      'amount': amount,
                    });
                  } else {
                    expenses[index] = {
                      'date': dateController.text,
                      'note': noteController.text,
                      'amount': amount,
                    };
                  }
                });
                saveData();
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fa),
      appBar: AppBar(
        title: const Text("Extra Cost Money"),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.green],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: expenses.isEmpty
                ? const Center(
              child: Text(
                "No Expenses Yet 💸",
                style:
                TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final item = expenses[index];
                return GestureDetector(
                  onTap: () => openExpenseDialog(
                      expense: item, index: index),
                  onLongPress: () => deleteExpense(index),
                  child: Container(
                    margin:
                    const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                      BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withOpacity(0.05),
                          blurRadius: 10,
                          offset:
                          const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['note'],
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                  FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['date'],
                              style: const TextStyle(
                                  color: Colors.grey),
                            ),
                          ],
                        ),
                        Text(
                          "৳ ${item['amount']}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight:
                            FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal, Colors.green],
              ),
            ),
            width: double.infinity,
            child: Text(
              "Total: ৳ ${totalAmount.toStringAsFixed(2)}",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          )
        ],
      ),
      floatingActionButton:
      Padding(
        padding: const EdgeInsets.only(bottom: 40.0, right: 0.0),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.green,
          icon: const Icon(Icons.add),
          label: const Text("Add Extra Cost"),
          onPressed: () => openExpenseDialog(),
        ),
      ),

    );
  }
}
