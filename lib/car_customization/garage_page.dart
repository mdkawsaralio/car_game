import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'car_skin_service.dart';
import '../login/user_data.dart';
import '../game/car.dart';

class GaragePage extends StatefulWidget {
  const GaragePage({super.key});

  @override
  State<GaragePage> createState() => _GaragePageState();
}

class _GaragePageState extends State<GaragePage> {
  final CarSkinService skinService = Get.find<CarSkinService>();
  final UserDataService userDataService = Get.find<UserDataService>();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await skinService.init();
    await userDataService.init();
    setState(() {
      _isLoading = false;
    });
  }

  void _refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Garage'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      backgroundColor: const Color(0xFF0A0A0F),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.redAccent),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: CarSkinService.allSkins.length,
              itemBuilder: (context, index) {
                final skin = CarSkinService.allSkins[index];
                final isUnlocked = skinService.isSkinUnlocked(skin.id);
                final isSelected = skinService.getSelectedSkinId() == skin.id;

                return Card(
                  color: isSelected
                      ? Colors.blue.withOpacity(0.15)
                      : Colors.grey[850],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected ? Colors.blueAccent : Colors.grey[700]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      if (isUnlocked) {
                        skinService.setSelectedSkinId(skin.id);
                        Get.snackbar(
                          'Equipped',
                          '${skin.name} is now your active car!',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.green.shade700,
                          colorText: Colors.white,
                        );
                        _refresh();
                      } else {
                        _showBuyDialog(skin);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Car preview — reuses the same widget the game
                          // itself uses for the player car. Shows the real
                          // PNG if present; otherwise falls back to the
                          // drawn car (windshield, lights, mirrors) tinted
                          // to this skin's color, so it's never just a
                          // plain colored box.
                          Container(
                            width: 92,
                            height: 92,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: RadialGradient(
                                colors: [
                                  skin.primaryColor.withOpacity(0.35),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: PlayerCarWidget(
                              width: 80,
                              height: 80,
                              nitroActive: false,
                              assetPath: skin.assetPath,
                              previewColor: skin.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            skin.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          if (isSelected)
                            const Text(
                              '✅ EQUIPPED',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (!isUnlocked)
                            Text(
                              '🔒 ${skin.cost} coins',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          if (isUnlocked && !isSelected)
                            const Text(
                              'TAP TO SELECT',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showBuyDialog(CarSkin skin) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        title: Text(
          'Unlock ${skin.name}',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: skin.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: PlayerCarWidget(
                    width: 40,
                    height: 40,
                    nitroActive: false,
                    assetPath: skin.assetPath,
                    previewColor: skin.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cost: ${skin.cost} coins',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Unlock this stylish car skin to customise your ride!',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final currentCoins = await userDataService.getCoins();
              if (currentCoins >= skin.cost) {
                await userDataService.saveCoins(currentCoins - skin.cost);
                await skinService.unlockSkin(skin.id);
                await skinService.setSelectedSkinId(skin.id);
                Get.back();
                Get.snackbar(
                  '🎉 Unlocked!',
                  '${skin.name} is now yours and equipped!',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green.shade700,
                  colorText: Colors.white,
                );
                _refresh();
              } else {
                Get.snackbar(
                  'Not enough coins',
                  'You need ${skin.cost} coins to buy this skin.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red.shade700,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Buy'),
          ),
        ],
      ),
    );
  }
}
