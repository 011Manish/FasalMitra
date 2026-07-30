import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/farm_profile.dart';
import '../../services/farm_service.dart';
import '../widgets/farm_card.dart';
import 'farm_dashboard.dart';

class FarmsScreen extends StatefulWidget {
  const FarmsScreen({super.key});

  @override
  State<FarmsScreen> createState() => _FarmsScreenState();
}

class _FarmsScreenState extends State<FarmsScreen> {
  final FarmService _farmService = FarmService(Supabase.instance.client);

  List<FarmProfile> farms = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadFarms();
  }

  Future<void> loadFarms() async {
    try {
      farms = await _farmService.listMine();
    } catch (e) {
      debugPrint("Error loading farms: $e");
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> refreshFarms() async {
    setState(() {
      isLoading = true;
    });

    await loadFarms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Farms"),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: refreshFarms,
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : farms.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 250),
                      Center(
                        child: Text(
                          "No farms added yet.\nAdd a farm from Farm Management.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    itemCount: farms.length,
                    itemBuilder: (context, index) {
                      final farm = farms[index];

                      return FarmCard(
                        farmName: farm.name,
                        location: farm.cropType,
                        status: "Online",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FarmDashboard(
                                farmName: farm.name,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
      ),
    );
  }
}
