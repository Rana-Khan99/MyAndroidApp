import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class TotalDepositPage extends StatefulWidget {
  const TotalDepositPage({super.key});

  @override
  State<TotalDepositPage> createState() => _TotalDepositPageState();
}

class _TotalDepositPageState extends State<TotalDepositPage> {
  List<Map<String, dynamic>> deposits = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  double get totalAmount {
    return deposits.fold(0, (sum, item) => sum + item['amount']);
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('deposits');
    if (data != null) {
      setState(() {
        deposits = List<Map<String, dynamic>>.from(jsonDecode(data));
      });
    }
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('deposits', jsonEncode(deposits));
  }

  void deleteDeposit(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text("Delete Deposit?"),
        content:
        const Text("Are you sure you want to delete this deposit?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                deposits.removeAt(index);
              });
              saveData();
              Navigator.pop(context);
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void openDepositDialog({Map<String, dynamic>? item, int? index}) {
    final dateController =
    TextEditingController(text: item?['date'] ?? "");
    final nameController =
    TextEditingController(text: item?['name'] ?? "");
    final amountController =
    TextEditingController(text: item?['amount']?.toString() ?? "");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          item == null ? "Add Deposit" : "Edit Deposit",
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
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Profile Name",
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Deposit Amount",
                  prefixIcon: const Icon(Icons.account_balance_wallet),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount != null &&
                  dateController.text.isNotEmpty &&
                  nameController.text.isNotEmpty) {
                setState(() {
                  if (index == null) {
                    deposits.add({
                      'date': dateController.text,
                      'name': nameController.text,
                      'amount': amount,
                    });
                  } else {
                    deposits[index] = {
                      'date': dateController.text,
                      'name': nameController.text,
                      'amount': amount,
                    };
                  }
                });
                saveData();
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fa),
      appBar: AppBar(
        title: const Text("Total Deposit Money"),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Colors.teal],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: deposits.isEmpty
                ? const Center(
              child: Text(
                "No Deposits Yet 💰",
                style:
                TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: deposits.length,
              itemBuilder: (context, index) {
                final item = deposits[index];
                return GestureDetector(
                  onTap: () => openDepositDialog(
                      item: item, index: index),
                  onLongPress: () => deleteDeposit(index),
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
                              item['name'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight:
                                FontWeight.w600,
                              ),
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
                            color: Colors.green,
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
                colors: [Colors.green, Colors.teal],
              ),
            ),
            width: double.infinity,
            child: Text(
              "Total Deposit: ৳ ${totalAmount.toStringAsFixed(2)}",
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
          label: const Text("Add Diposit Profile"),
          onPressed: () => openDepositDialog(),
        ),
      ),
    );
  }
}
