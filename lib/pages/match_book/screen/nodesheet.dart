import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'count/mealcount.dart';
import 'count/ricecount.dart';
import 'count/bazarlist.dart';
import '../screen/profile_screen.dart';

import 'drawer/nodepad.dart';
import 'drawer/extracost.dart';
import 'drawer/totaldepositmany.dart';

class HomeTabPage extends StatefulWidget {
  const HomeTabPage({super.key});

  @override
  State<HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<HomeTabPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currentUser = FirebaseAuth.instance.currentUser!;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _launchURL(String url) async {
    if (url.isEmpty) return;

    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget buildDrawer() {
    return Drawer(
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData =
          snapshot.data!.data() as Map<String, dynamic>?;

          return ListView(
            padding: EdgeInsets.zero,
            children: [

              /// HEADER
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal, Colors.green],
                  ),
                ),
                accountName: Text(
                  userData?['name'] ?? "No Name",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                accountEmail:
                Text(currentUser.email ?? "No Email"),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage:
                  userData?['profilePicture'] != null
                      ? NetworkImage(
                      userData!['profilePicture'])
                      : null,
                  child: userData?['profilePicture'] == null
                      ? Text(
                    userData?['name'] != null &&
                        userData!['name'].isNotEmpty
                        ? userData!['name'][0]
                        .toUpperCase()
                        : "U",
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal),
                  )
                      : null,
                ),
              ),

              /// PROFILE
              ListTile(
                leading: const Icon(Icons.person,
                    color: Colors.teal),
                title: const Text("My Profile"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                        const ProfileScreen()),
                  );
                },
              ),

              const Divider(),

              /// NOTE PAD
              ListTile(
                leading: const Icon(Icons.book,
                    color: Colors.blueGrey),
                title: const Text("Note Pad"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                        const NoteListPage()),
                  );
                },
              ),

              /// EXTRA COST
              ListTile(
                leading: const Icon(
                    Icons.monetization_on,
                    color: Colors.orange),
                title:
                const Text("Extra Cost Money"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                        const ExtraCostPage()),
                  );
                },
              ),

              /// DEPOSIT
              ListTile(
                leading: const Icon(Icons.add_card,
                    color: Colors.green),
                title:
                const Text("Total Deposit Money"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                        const TotalDepositPage()),
                  );
                },
              ),

              const Divider(),

              /// SUPPORT SECTION TITLE
              const Padding(
                padding: EdgeInsets.only(
                    left: 16, top: 10, bottom: 5),
                child: Text(
                  "Support & Contact",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),

              /// SOCIAL LINKS STREAM
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('social_links')
                    .doc('support')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox();
                  }

                  final data = snapshot.data!.data()
                  as Map<String, dynamic>?;

                  if (data == null)
                    return const SizedBox();

                  return Column(
                    children: [

                      if (data['facebook'] != null &&
                          data['facebook'] != "")
                        ListTile(
                          leading: const Icon(
                              Icons.facebook,
                              color: Colors.blue),
                          title:
                          const Text("Facebook"),
                          onTap: () => _launchURL(
                              data['facebook']),
                        ),

                      if (data['whatsapp'] != null &&
                          data['whatsapp'] != "")
                        ListTile(
                          leading: const Icon(
                              Icons.chat,
                              color: Colors.green),
                          title:
                          const Text("WhatsApp"),
                          onTap: () => _launchURL(
                              data['whatsapp']),
                        ),

                      if (data['instagram'] != null &&
                          data['instagram'] != "")
                        ListTile(
                          leading: const Icon(
                              Icons.camera_alt,
                              color: Colors.purple),
                          title:
                          const Text("Instagram"),
                          onTap: () => _launchURL(
                              data['instagram']),
                        ),

                      if (data['linkedin'] != null &&
                          data['linkedin'] != "")
                        ListTile(
                          leading: const Icon(
                            Icons.interpreter_mode_sharp,
                              color: Colors.blueGrey),
                          title:
                          const Text("LinkedIn"),
                          onTap: () => _launchURL(
                              data['linkedin']),
                        ),


                    ],
                  );
                },
              ),

              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      drawer: buildDrawer(),

      appBar: AppBar(
        title: const Text(
          'Meal Tracker',
          style: TextStyle(
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Meals Count"),
            Tab(text: "Rice Count"),
            Tab(text: "Bazar List"),
          ],
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: const [
          NodeSheet(),
          RiceMealTracker(),
          BazarList(),
        ],
      ),
    );
  }
}