import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/providers/theme_provider.dart';
import 'package:sidrive/config/app_colors.dart';
import 'package:sidrive/models/order_ojek_models.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';

class OrderSearchBar extends StatelessWidget {
  final TextEditingController pickupController;
  final TextEditingController destinationController;
  final FocusNode pickupFocus;
  final FocusNode destinationFocus;
  final LatLng? destinationPosition;
  final VoidCallback onClearDestination;
  final VoidCallback onClose;
  final bool showSearchResults;
  final List<OsmPlace> searchResults;
  final Function(OsmPlace) onSelectPlace;
  final bool showPickupInput;
  final VoidCallback? onPickupFieldTap;
  final VoidCallback? onDestinationFieldTap; 

  const OrderSearchBar({
    super.key,
    required this.pickupController,
    required this.destinationController,
    required this.pickupFocus,
    required this.destinationFocus,
    required this.destinationPosition,
    required this.onClearDestination,
    required this.onClose,
    required this.showSearchResults,
    required this.searchResults,
    required this.onSelectPlace,
    required this.showPickupInput,
    this.onPickupFieldTap,
    this.onDestinationFieldTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          ResponsiveMobile.scaledW(16),
          ResponsiveMobile.scaledH(12),
          ResponsiveMobile.scaledW(16),
          0,
        ),
        child: Column(
          children: [
            Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(8)),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(8)),
                ),
                child: Column(
                  children: [
                    if (showPickupInput)
                      Row(
                        children: [
                          SizedBox(width: ResponsiveMobile.scaledW(12)),
                          Icon(
                            Icons.my_location,
                            color: Color(0xFF4285F4),
                            size: ResponsiveMobile.scaledFont(20),
                          ),
                          SizedBox(width: ResponsiveMobile.scaledW(12)),
                          Expanded(
                            child: InkWell(
                              onTap: onPickupFieldTap,
                              child: IgnorePointer(
                                child: TextField(
                                  controller: pickupController,
                                  focusNode: pickupFocus,
                                  decoration: InputDecoration(
                                    hintText: 'Lokasi jemput',
                                    hintStyle: TextStyle(
                                      fontSize: ResponsiveMobile.bodySize(context),
                                      color: isDark ? AppColors.textSecondaryDark : Colors.grey[600],
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: ResponsiveMobile.scaledH(12),
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontSize: ResponsiveMobile.bodySize(context),
                                    color: isDark ? AppColors.textPrimaryDark : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.pin_drop,
                              size: ResponsiveMobile.scaledFont(20),
                              color: Color(0xFF4285F4),
                            ),
                            onPressed: onPickupFieldTap,
                            tooltip: 'Pilih lokasi jemput',
                          ),
                          if (pickupController.text.isNotEmpty)
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                size: ResponsiveMobile.scaledFont(18),
                                color: isDark ? AppColors.textSecondaryDark : Colors.grey,
                              ),
                              onPressed: () {
                                pickupController.clear();
                              },
                              padding: EdgeInsets.zero,
                              tooltip: 'Hapus lokasi jemput',
                            ),
                        ],
                      ),

                    if (showPickupInput)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                      ),

                    // ✅ Destination field - bisa ketik ATAU tap untuk dialog
                    Stack(
                      children: [
                        // TextField untuk ketik manual
                        Row(
                          children: [
                            SizedBox(width: ResponsiveMobile.scaledW(12)),
                            Icon(
                              Icons.location_on,
                              color: Color(0xFFEA4335),
                              size: ResponsiveMobile.scaledFont(20),
                            ),
                            SizedBox(width: ResponsiveMobile.scaledW(12)),
                            Expanded(
                              child: TextField(
                                controller: destinationController,
                                focusNode: destinationFocus,
                                decoration: InputDecoration(
                                  hintText: 'Tujuan',
                                  hintStyle: TextStyle(
                                    fontSize: ResponsiveMobile.bodySize(context),
                                    color: isDark ? AppColors.textSecondaryDark : Colors.grey[600],
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: ResponsiveMobile.scaledH(12),
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: ResponsiveMobile.bodySize(context),
                                  color: isDark ? AppColors.textPrimaryDark : Colors.black,
                                ),
                              ),
                            ),
                            // ✅ Icon pilih di map (selalu ada)
                            IconButton(
                              icon: Icon(
                                Icons.pin_drop,
                                size: ResponsiveMobile.scaledFont(20),
                                color: Color(0xFF5DADE2),
                              ),
                              onPressed: onDestinationFieldTap,
                              tooltip: 'Pilih di peta',
                            ),
                            if (destinationController.text.isNotEmpty)
                              IconButton(
                                icon: Icon(
                                  Icons.close,
                                  size: ResponsiveMobile.scaledFont(18),
                                  color: isDark ? AppColors.textSecondaryDark : Colors.grey,
                                ),
                                onPressed: onClearDestination,
                                padding: EdgeInsets.zero,
                                tooltip: 'Hapus tujuan',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Search results
            if (showSearchResults && searchResults.isNotEmpty)
              Container(
                margin: EdgeInsets.only(top: ResponsiveMobile.scaledH(8)),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(8)),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black38 : Colors.black12,
                      blurRadius: 4,
                    ),
                  ],
                ),
                constraints: BoxConstraints(
                  maxHeight: ResponsiveMobile.hp(context, 40),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: searchResults.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                  ),
                  itemBuilder: (context, index) {
                    final place = searchResults[index];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: ResponsiveMobile.scaledW(16),
                        vertical: ResponsiveMobile.scaledH(4),
                      ),
                      leading: Icon(
                        Icons.location_on,
                        color: isDark ? AppColors.textSecondaryDark : Colors.grey[700],
                        size: ResponsiveMobile.scaledFont(20),
                      ),
                      title: Text(
                        place.name,
                        style: TextStyle(
                          fontSize: ResponsiveMobile.bodySize(context),
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textPrimaryDark : Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        place.displayName,
                        style: TextStyle(
                          fontSize: ResponsiveMobile.captionSize(context),
                          color: isDark ? AppColors.textSecondaryDark : Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => onSelectPlace(place),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}