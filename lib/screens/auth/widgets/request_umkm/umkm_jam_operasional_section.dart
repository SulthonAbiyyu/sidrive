import 'package:flutter/material.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';

class UmkmJamOperasionalSection extends StatelessWidget {
  final TimeOfDay jamBuka;
  final TimeOfDay jamTutup;
  final Function(BuildContext, bool) onSelectTime;

  const UmkmJamOperasionalSection({
    super.key,
    required this.jamBuka,
    required this.jamTutup,
    required this.onSelectTime,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => onSelectTime(context, true),
            child: Container(
              padding: ResponsiveMobile.allScaledPadding(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jam Buka',
                    style: TextStyle(
                      fontSize: ResponsiveMobile.captionSize(context),
                      color: Colors.grey,
                    ),
                  ),
                  ResponsiveMobile.vSpace(4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: ResponsiveMobile.scaledFont(20)),
                      ResponsiveMobile.hSpace(8),
                      Text(
                        jamBuka.format(context),
                        style: TextStyle(
                          fontSize: ResponsiveMobile.bodySize(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        ResponsiveMobile.hSpace(12),
        Expanded(
          child: InkWell(
            onTap: () => onSelectTime(context, false),
            child: Container(
              padding: ResponsiveMobile.allScaledPadding(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jam Tutup',
                    style: TextStyle(
                      fontSize: ResponsiveMobile.captionSize(context),
                      color: Colors.grey,
                    ),
                  ),
                  ResponsiveMobile.vSpace(4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: ResponsiveMobile.scaledFont(20)),
                      ResponsiveMobile.hSpace(8),
                      Text(
                        jamTutup.format(context),
                        style: TextStyle(
                          fontSize: ResponsiveMobile.bodySize(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}