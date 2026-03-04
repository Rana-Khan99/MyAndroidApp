import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NodeSheet extends StatefulWidget {
  const NodeSheet({super.key});

  @override
  State<NodeSheet> createState() => _NodeSheetState();
}

class _NodeSheetState extends State<NodeSheet> {
  List<String> profiles = [];
  String? selectedProfile;

  int month = DateTime.now().month;
  int year = DateTime.now().year;

  Set<int> selectedDays = {};        // Normal meal
  Map<int, int> extraMeals = {};     // Extra meal (day : count)

  @override
  void initState() {
    super.initState();
    loadProfiles();
  }

  // ================= LOAD & SAVE =================

  Future<void> loadProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      profiles = prefs.getStringList("profiles") ?? [];
    });
  }

  Future<void> saveProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList("profiles", profiles);
  }

  Future<void> loadDays() async {
    if (selectedProfile == null) return;

    final prefs = await SharedPreferences.getInstance();
    final normalKey = "${selectedProfile}_$month$year";
    final extraKey = "${selectedProfile}_extra_$month$year";

    final normalList = prefs.getStringList(normalKey) ?? [];
    final extraList = prefs.getStringList(extraKey) ?? [];

    setState(() {
      selectedDays = normalList.map(int.parse).toSet();
      extraMeals = {
        for (var e in extraList)
          int.parse(e.split(":")[0]): int.parse(e.split(":")[1])
      };
    });
  }

  Future<void> saveDays() async {
    if (selectedProfile == null) return;

    final prefs = await SharedPreferences.getInstance();
    final normalKey = "${selectedProfile}_$month$year";
    final extraKey = "${selectedProfile}_extra_$month$year";

    await prefs.setStringList(
      normalKey,
      selectedDays.map((e) => e.toString()).toList(),
    );

    await prefs.setStringList(
      extraKey,
      extraMeals.entries.map((e) => "${e.key}:${e.value}").toList(),
    );

  }

  // ================= ADD PROFILE =================

  void addProfileDialog() {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Add Profile"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Enter profile name",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              String newName = controller.text.trim();
              if (newName.isEmpty) return;

              if (profiles.contains(newName)) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Duplicate Profile"),
                    content: const Text(
                        "Profile with this name already exists.\nPlease use a different name."),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("OK"))
                    ],
                  ),
                );
              } else {
                setState(() {
                  profiles.add(newName);
                });
                saveProfiles();
                Navigator.pop(context);
              }
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    int totalMeals =
        selectedDays.length + extraMeals.values.fold(0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Per Day Meal Count"),
        backgroundColor: Colors.teal,
        elevation: 4,
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.save),
        //     tooltip: "Save Data",
        //     onPressed: saveDays,
        //   )
        // ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 0, right: 0),
        child: FloatingActionButton.extended(
          onPressed: () => addProfileDialog(),
          backgroundColor: Colors.teal,
          icon: const Icon(Icons.person),
          label: const Text("Add Profile"),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      body: Column(
        children: [

          // ---------- PROFILE ----------
          Padding(
            padding: const EdgeInsets.all(8),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: DropdownButton<String>(
                  hint: const Text("Select Profile"),
                  value: selectedProfile,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: profiles.map((p) => DropdownMenuItem(
                    value: p,
                    child: GestureDetector(
                      onLongPress: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Delete Profile"),
                            content: Text("Are you sure you want to delete profile '$p'? This will remove all saved data for this profile."),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Cancel"),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  setState(() {
                                    profiles.remove(p);
                                    if (selectedProfile == p) {
                                      selectedProfile = null;
                                      selectedDays.clear();
                                      extraMeals.clear();
                                    }
                                  });

                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setStringList("profiles", profiles);

                                  final normalKey = "${p}_$month$year";
                                  final extraKey = "${p}_extra_$month$year";
                                  await prefs.remove(normalKey);
                                  await prefs.remove(extraKey);

                                  Navigator.pop(context);
                                },
                                child: const Text("Delete"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                              )
                            ],
                          ),
                        );
                      },
                      child: Text(p),
                    ),
                  )).toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedProfile = v;
                      selectedDays.clear();
                      extraMeals.clear();
                    });
                    loadDays();
                  },
                ),
              ),
            ),
          ),

          const Divider(),

          // ---------- MONTH / YEAR ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DropdownButton<int>(
                      value: month,
                      items: List.generate(12, (i) {
                        return DropdownMenuItem(
                          value: i + 1,
                          child: Text("Month ${i + 1}"),
                        );
                      }),
                      onChanged: (v) {
                        setState(() => month = v!);
                        loadDays();
                      },
                    ),
                    const SizedBox(width: 20),
                    DropdownButton<int>(
                      value: year,
                      items: List.generate(6, (i) {
                        int y = DateTime.now().year - 2 + i;
                        return DropdownMenuItem(
                          value: y,
                          child: Text(y.toString()),
                        );
                      }),
                      onChanged: (v) {
                        setState(() => year = v!);
                        loadDays();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ---------- DAYS GRID ----------
          Expanded(
            child: selectedProfile == null
                ? const Center(child: Text("Please select profile"))
                : GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: 31,
              itemBuilder: (context, index) {
                int day = index + 1;
                bool normal = selectedDays.contains(day);
                int extraCount = extraMeals[day] ?? 0;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      normal
                          ? selectedDays.remove(day)
                          : selectedDays.add(day);
                    });
                    saveDays(); // ✅ AUTO SAVE ADDED
                  },
                  onLongPress: () {
                    TextEditingController extraController =
                    TextEditingController(
                        text: extraMeals[day]?.toString() ?? "");

                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        title: Text("Extra Meal (Day $day)"),
                        content: TextField(
                          controller: extraController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: "Enter extra meal count",
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              int value =
                                  int.tryParse(extraController.text) ?? 0;

                              setState(() {
                                if (value > 0) {
                                  extraMeals[day] = value;
                                } else {
                                  extraMeals.remove(day);
                                }
                              });

                              saveDays(); // ✅ AUTO SAVE ADDED
                              Navigator.pop(context);
                            },
                            child: const Text("OK"),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: normal ? Colors.green : Colors.grey.shade500,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 3,
                              offset: const Offset(1, 2),
                            )
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          day.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (extraCount > 0)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              extraCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ---------- TOTAL SUMMARY ----------
          if (selectedProfile != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Card(
                margin: const EdgeInsets.all(10),
                elevation: 10,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedProfile!,
                        style: const TextStyle(
                          color: Colors.teal,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Extra Meals: ${extraMeals.values.fold(0, (a, b) => a + b)}",
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Total Meals: $totalMeals",
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}