import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RiceMealTracker extends StatefulWidget {
  const RiceMealTracker({super.key});

  @override
  State<RiceMealTracker> createState() => _RiceMealTrackerState();
}

class _RiceMealTrackerState extends State<RiceMealTracker> {
  List<String> profiles = [];
  String? selectedProfile;

  int month = DateTime.now().month;
  int year = DateTime.now().year;

  Map<String, Set<int>> selectedDays = {
    "Morning": {},
    "Lunch": {},
    "Dinner": {},
  };

  Map<String, Map<int, int>> extraMeals = {
    "Morning": {},
    "Lunch": {},
    "Dinner": {},
  };

  @override
  void initState() {
    super.initState();
    loadProfiles();
  }

  // -------------------- Profiles --------------------
  Future<void> loadProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      profiles = prefs.getStringList("meal_profiles") ?? [];
    });
  }

  Future<void> saveProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList("meal_profiles", profiles);
  }

  void addProfileDialog() {
    TextEditingController controller = TextEditingController();
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Add Profile"),
          content: TextField(
              controller: controller,
              decoration:
              const InputDecoration(hintText: "Enter profile name")),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
                onPressed: () {
                  String newName = controller.text.trim();
                  if (newName.isEmpty) return;

                  if (profiles.contains(newName)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "Profile already exists, try a new name")),
                    );
                    return;
                  }

                  setState(() {
                    profiles.add(newName);
                  });
                  saveProfiles();
                  Navigator.pop(context);
                },
                child: const Text("Add"))
          ],
        ));
  }

  // -------------------- Load/Save Days --------------------
  Future<void> loadDays() async {
    if (selectedProfile == null) return;
    final prefs = await SharedPreferences.getInstance();
    for (var meal in ["Morning", "Lunch", "Dinner"]) {
      final normalKey = "${selectedProfile}_$meal$month$year";
      final extraKey = "${selectedProfile}_extra_$meal$month$year";

      final normalList = prefs.getStringList(normalKey) ?? [];
      final extraList = prefs.getStringList(extraKey) ?? [];

      setState(() {
        selectedDays[meal] = normalList.map(int.parse).toSet();
        extraMeals[meal] = {
          for (var e in extraList)
            int.parse(e.split(":")[0]): int.parse(e.split(":")[1])
        };
      });
    }
  }

  Future<void> saveDays() async {
    if (selectedProfile == null) return;
    final prefs = await SharedPreferences.getInstance();
    for (var meal in ["Morning", "Lunch", "Dinner"]) {
      final normalKey = "${selectedProfile}_$meal$month$year";
      final extraKey = "${selectedProfile}_extra_$meal$month$year";

      await prefs.setStringList(
          normalKey, selectedDays[meal]!.map((e) => e.toString()).toList());
      await prefs.setStringList(extraKey,
          extraMeals[meal]!.entries.map((e) => "${e.key}:${e.value}").toList());
    }
  }

  // -------------------- Delete Profile --------------------
  Future<void> deleteProfile(String profileName) async {
    bool confirm = false;
    await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Delete Profile"),
          content: Text(
              "Are you sure you want to delete profile '$profileName'? All data will be lost."),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Cancel")),
            ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  confirm = true;
                  Navigator.pop(context);
                },
                child: const Text("Delete")),
          ],
        ));

    if (confirm) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        profiles.remove(profileName);
        if (selectedProfile == profileName) {
          selectedProfile = null;
          for (var meal in ["Morning", "Lunch", "Dinner"]) {
            selectedDays[meal]!.clear();
            extraMeals[meal]!.clear();
          }
        }
      });

      await prefs.setStringList("meal_profiles", profiles);

      for (var meal in ["Morning", "Lunch", "Dinner"]) {
        await prefs.remove("${profileName}_$meal$month$year");
        await prefs.remove("${profileName}_extra_$meal$month$year");
      }

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profile '$profileName' deleted")));
    }
  }

  // -------------------- UI --------------------
  @override
  Widget build(BuildContext context) {
    int totalAllMeals = 0;
    for (var meal in ["Morning", "Lunch", "Dinner"]) {
      totalAllMeals +=
          selectedDays[meal]!.length + extraMeals[meal]!.values.fold(0, (a, b) => a + b);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Per Day Rice Count"),
        backgroundColor: Colors.teal,
        elevation: 6,

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

      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: DropdownButton<String>(
                  hint: const Text("Select Profile"),
                  value: selectedProfile,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: profiles
                      .map((p) => DropdownMenuItem(
                    value: p,
                    child: GestureDetector(
                        onLongPress: () => deleteProfile(p),
                        child: Text(p)),
                  ))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedProfile = v;
                      for (var meal in ["Morning", "Lunch", "Dinner"]) {
                        selectedDays[meal]!.clear();
                        extraMeals[meal]!.clear();
                      }
                    });
                    loadDays();
                  },
                ),
              ),
            ),

            const SizedBox(height: 8),

            Row(
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
                    loadDays();
                  },
                ),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: year,
                  items: List.generate(
                      6,
                          (i) => DropdownMenuItem(
                          value: DateTime.now().year - 2 + i,
                          child: Text("${DateTime.now().year - 2 + i}"))),
                  onChanged: (v) {
                    setState(() => year = v!);
                    loadDays();
                  },
                ),
              ],
            ),

            const Divider(thickness: 1.2),

            if (selectedProfile != null)
              Expanded(
                child: DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(12)),
                        child: const TabBar(
                          labelColor: Colors.teal,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: Colors.teal,
                          tabs: [
                            Tab(text: "Morning"),
                            Tab(text: "Lunch"),
                            Tab(text: "Dinner"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: TabBarView(
                          children: ["Morning", "Lunch", "Dinner"].map((meal) {
                            int totalMeal = selectedDays[meal]!.length +
                                extraMeals[meal]!.values.fold(0, (a, b) => a + b);
                            return Column(
                              children: [
                                Expanded(
                                  child: GridView.builder(
                                    padding: const EdgeInsets.all(8),
                                    gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 7,
                                      childAspectRatio: 1,
                                      crossAxisSpacing: 4,
                                      mainAxisSpacing: 4,
                                    ),
                                    itemCount: 31,
                                    itemBuilder: (context, index) {
                                      int day = index + 1;
                                      bool normal = selectedDays[meal]!.contains(day);
                                      int extra = extraMeals[meal]![day] ?? 0;

                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            normal
                                                ? selectedDays[meal]!.remove(day)
                                                : selectedDays[meal]!.add(day);
                                          });
                                          saveDays(); // 🔥 AUTO SAVE
                                        },
                                        onLongPress: () {
                                          TextEditingController extraController =
                                          TextEditingController(
                                              text: extraMeals[meal]![day]?.toString() ?? "");
                                          showDialog(
                                              context: context,
                                              builder: (_) => AlertDialog(
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                    BorderRadius.circular(12)),
                                                title: Text("$meal Extra (Day $day)"),
                                                content: TextField(
                                                  controller: extraController,
                                                  keyboardType:
                                                  TextInputType.number,
                                                  decoration: const InputDecoration(
                                                      hintText: "Enter extra count"),
                                                ),
                                                actions: [
                                                  TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(context),
                                                      child: const Text("Cancel")),
                                                  ElevatedButton(
                                                      onPressed: () {
                                                        int val = int.tryParse(
                                                            extraController.text) ?? 0;
                                                        setState(() {
                                                          if (val > 0) {
                                                            extraMeals[meal]![day] = val;
                                                          } else {
                                                            extraMeals[meal]!.remove(day);
                                                          }
                                                        });
                                                        saveDays(); // 🔥 AUTO SAVE
                                                        Navigator.pop(context);
                                                      },
                                                      child: const Text("OK"))
                                                ],
                                              ));
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          decoration: BoxDecoration(
                                            gradient: normal
                                                ? const LinearGradient(
                                                colors: [Colors.green, Colors.lightGreen])
                                                : const LinearGradient(
                                                colors: [Colors.grey, Colors.black26]),
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 4,
                                                offset: const Offset(1, 2),
                                              )
                                            ],
                                          ),
                                          alignment: Alignment.center,
                                          child: Stack(
                                            children: [
                                              Center(
                                                child: Text(day.toString(),
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold)),
                                              ),
                                              if (extra > 0)
                                                Positioned(
                                                  top: 4,
                                                  right: 4,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                        color: Colors.orange,
                                                        borderRadius: BorderRadius.circular(8)),
                                                    child: Text(extra.toString(),
                                                        style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 12,
                                                            fontWeight:
                                                            FontWeight.bold)),
                                                  ),
                                                )
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Card(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  elevation: 3,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("$meal Total: $totalMeal",
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold, fontSize: 16)),
                                        const Icon(Icons.restaurant_menu, color: Colors.teal),
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            );
                          }).toList(),
                        ),
                      )
                    ],
                  ),
                ),
              ),

            if (selectedProfile != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  color: Colors.teal.shade100,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Total All Rice: $totalAllMeals",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const Icon(Icons.star, color: Colors.orange),
                      ],
                    ),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}