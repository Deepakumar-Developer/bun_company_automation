import 'package:flutter/material.dart';

import 'function.dart';

class LightControlBox extends StatelessWidget {
  final TubeLight light;
  final Function(TubeLight, String) onToggle;

  const LightControlBox({
    super.key,
    required this.light,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    // Determine colors based on the light's state
    final Color boxColor = light.isOn ? Colors.amber[400]! : Colors.grey[900]!;
    final Color textColor = light.isOn ? Colors.black : Colors.white;
    final IconData icon = light.isOn ? Icons.lightbulb : Icons.lightbulb_outline;

    return GestureDetector(
      onTap: () => onToggle(light, 'phone'),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        margin: EdgeInsets.only(top: 16),
        decoration: BoxDecoration(
          color: boxColor,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            // Subtle glow effect when ON
            if (light.isOn)
              BoxShadow(
                color: Colors.amber.withOpacity(0.5),
                blurRadius: 15,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Light Name
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  light.name,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(onPressed: (){onToggle(light, 'switch');}, icon: Icon(Icons.restart_alt,size: 32,color: textColor,))
              ],
            ),

            SizedBox(
              height: 12,
            ),

            // Status and Power Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                // Text Status
                Text(
                  light.isOn ? 'ON ' : 'OFF',
                  style: TextStyle(
                    color: textColor.withOpacity(0.7),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // Power Button Icon
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: light.isOn ? Colors.white : Colors.grey[700],
                  ),
                  child: Icon(
                    icon,
                    size: 40,
                    color: light.isOn ? Colors.amber : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}