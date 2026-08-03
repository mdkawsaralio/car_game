import 'dart:math';
import 'package:flutter/material.dart';

class Car {
  double x;
  double y;
  double width;
  double height;
  String asset;
  String type;

  Car({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.asset,
    required this.type,
  });
}

class PlayerCar extends Car {
  PlayerCar({
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    required super.asset,
  }) : super(type: 'player');
}

class EnemyCar extends Car {
  double speed;
  Color color;

  EnemyCar({
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    required super.asset,
    required super.type,
    required this.speed,
    required this.color,
  });
}

class CarFactory {
  static final List<Map<String, dynamic>> _vehicleTypes = [
    {
      'asset': 'lib/assets/car1.png',
      'type': 'car',
      'widthMul': 1.0,
      'heightMul': 1.0,
      'speedMul': 0.85,
      'weight': 20,
    },
    {
      'asset': 'lib/assets/motorcycle.png',
      'type': 'bike',
      'widthMul': 0.6,
      'heightMul': 0.7,
      'speedMul': 1.3,
      'weight': 10,
    },
    {
      'asset': 'lib/assets/cycle.png',
      'type': 'cycle',
      'widthMul': 0.5,
      'heightMul': 0.6,
      'speedMul': 0.55,
      'weight': 5,
    },
    {
      'asset': 'lib/assets/taxi.png',
      'type': 'taxi',
      'widthMul': 1.0,
      'heightMul': 1.0,
      'speedMul': 0.8,
      'weight': 15,
    },
    {
      'asset': 'lib/assets/van.png',
      'type': 'van',
      'widthMul': 1.1,
      'heightMul': 1.2,
      'speedMul': 0.65,
      'weight': 12,
    },
    {
      'asset': 'lib/assets/bus.png',
      'type': 'bus',
      'widthMul': 1.2,
      'heightMul': 1.8,
      'speedMul': 0.35,
      'weight': 6,
    },
    {
      'asset': 'lib/assets/school_bus.png',
      'type': 'school_bus',
      'widthMul': 1.2,
      'heightMul': 1.8,
      'speedMul': 0.3,
      'weight': 4,
    },
    {
      'asset': 'lib/assets/truck.png',
      'type': 'truck',
      'widthMul': 1.2,
      'heightMul': 1.5,
      'speedMul': 0.38,
      'weight': 8,
    },
    {
      'asset': 'lib/assets/ambulance.png',
      'type': 'ambulance',
      'widthMul': 1.0,
      'heightMul': 1.2,
      'speedMul': 1.15,
      'weight': 4,
    },
    {
      'asset': 'lib/assets/scuti.png',
      'type': 'scooter',
      'widthMul': 0.5,
      'heightMul': 0.6,
      'speedMul': 0.7,
      'weight': 6,
    },
  ];

  static final int _totalVehicleWeight = _vehicleTypes.fold(
    0,
    (sum, v) => sum + v['weight'] as int,
  );

  static final List<Color> _enemyColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.cyan,
    Colors.pink,
    Colors.white,
    Colors.teal,
  ];

  static EnemyCar createEnemy({
    required Random random,
    required List<double> lanes,
    required double playerWidth,
    required double playerHeight,
    required double startY,
    required double baseSpeed,
  }) {
    int lane = random.nextInt(lanes.length);

    double w = playerWidth;
    double h = playerHeight;
    double spd = baseSpeed * 0.5;

    String asset = "lib/assets/car1.png";
    String type = "car";

    int randomWeight = random.nextInt(_totalVehicleWeight);
    int cumulativeWeight = 0;
    Map<String, dynamic> selectedVehicle = _vehicleTypes.first;
    for (var vehicle in _vehicleTypes) {
      cumulativeWeight += vehicle['weight'] as int;
      if (randomWeight < cumulativeWeight) {
        selectedVehicle = vehicle;
        break;
      }
    }

    w = playerWidth * (selectedVehicle['widthMul'] as double);
    h = playerHeight * (selectedVehicle['heightMul'] as double);
    spd = baseSpeed * (selectedVehicle['speedMul'] as double);
    asset = selectedVehicle['asset'] as String;
    type = selectedVehicle['type'] as String;

    spd *= (0.9 + random.nextDouble() * 0.2);
    if (spd < 0.3) spd = 0.3;
    if (spd > baseSpeed * 1.4) spd = baseSpeed * 1.4;

    return EnemyCar(
      x: lanes[lane],
      y: startY,
      width: w,
      height: h,
      asset: asset,
      type: type,
      speed: spd,
      color: _enemyColors[random.nextInt(_enemyColors.length)],
    );
  }
}

class PlayerCarWidget extends StatelessWidget {
  final double width;
  final double height;
  final bool nitroActive;
  final String assetPath; // new

  final Color? previewColor;

  const PlayerCarWidget({
    super.key,
    required this.width,
    required this.height,
    required this.nitroActive,
    required this.assetPath,
    this.previewColor,
  });

  @override
  Widget build(BuildContext context) {
    final scaledWidth = width * 0.72;
    final scaledHeight = height * 0.72;

    final Color accentColor =
        previewColor ?? (nitroActive ? Colors.cyanAccent : Colors.redAccent);
    final List<Color> bodyGradient = previewColor != null
        ? [previewColor!, Color.lerp(previewColor!, Colors.black, 0.55)!]
        : (nitroActive
              ? [Colors.cyanAccent, Colors.blue.shade900]
              : [Colors.red.shade400, Colors.red.shade900]);

    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Container(
            width: scaledWidth,
            height: scaledHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: bodyGradient,
              ),
              boxShadow: [
                BoxShadow(
                  color: previewColor != null
                      ? previewColor!.withOpacity(.5)
                      : (nitroActive
                            ? Colors.cyanAccent.withOpacity(.6)
                            : Colors.black.withOpacity(.4)),
                  blurRadius: nitroActive ? 18 : 6,
                  spreadRadius: nitroActive ? 2 : 1,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            // Fallback: keep the original drawn car if image not found
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // SIDE MIRRORS
                Positioned(
                  top: scaledHeight * 0.22,
                  left: -2,
                  child: Container(
                    width: 2.5,
                    height: 7,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
                Positioned(
                  top: scaledHeight * 0.22,
                  right: -2,
                  child: Container(
                    width: 2.5,
                    height: 7,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
                // RACING STRIPES
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: scaledWidth * 0.36,
                  width: 2,
                  child: Container(color: Colors.white.withOpacity(0.3)),
                ),
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: scaledWidth * 0.48,
                  width: 2,
                  child: Container(color: Colors.white.withOpacity(0.3)),
                ),
                // WINDSHIELDS
                Positioned(
                  top: scaledHeight * 0.20,
                  left: scaledWidth * 0.15,
                  right: scaledWidth * 0.15,
                  height: scaledHeight * 0.18,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withOpacity(0.9), Colors.black87],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                        bottomLeft: Radius.circular(2),
                        bottomRight: Radius.circular(2),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: scaledHeight * 0.62,
                  left: scaledWidth * 0.18,
                  right: scaledWidth * 0.18,
                  height: scaledHeight * 0.12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // HEADLIGHTS
                Positioned(
                  top: 2,
                  left: scaledWidth * 0.12,
                  child: Container(
                    width: scaledWidth * 0.16,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.8),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 2,
                  right: scaledWidth * 0.12,
                  child: Container(
                    width: scaledWidth * 0.16,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.8),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                // TAIL LIGHTS
                Positioned(
                  bottom: 2,
                  left: scaledWidth * 0.1,
                  child: Container(
                    width: scaledWidth * 0.14,
                    height: 2.5,
                    color: Colors.redAccent,
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: scaledWidth * 0.1,
                  child: Container(
                    width: scaledWidth * 0.14,
                    height: 2.5,
                    color: Colors.redAccent,
                  ),
                ),
                // NITRO FLAMES
                if (nitroActive) ...[
                  Positioned(
                    bottom: -10,
                    left: scaledWidth * 0.15,
                    width: scaledWidth * 0.2,
                    height: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Colors.cyanAccent,
                            Colors.blueAccent,
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -10,
                    right: scaledWidth * 0.15,
                    width: scaledWidth * 0.2,
                    height: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Colors.cyanAccent,
                            Colors.blueAccent,
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
