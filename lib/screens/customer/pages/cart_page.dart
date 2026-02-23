// lib/screens/customer/pages/cart_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:sidrive/core/utils/currency_formatter.dart';
import 'package:sidrive/core/utils/error_dialog_utils.dart';
import 'package:sidrive/providers/cart_provider.dart';
import 'package:sidrive/models/cart_model.dart';
import 'package:sidrive/screens/customer/pages/umkm_checkout_screen.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _isSelectAll = true;

  // ✅ COLOR PALETTE (Full Blue Theme)
  final Color _primaryBlue = const Color(0xFF2563EB); // Darker Blue
  final Color _lightBlue = const Color(0xFF3B82F6);   // Lighter Blue

  @override
  void initState() {
    super.initState();
    _checkSelectAll();
  }

  void _checkSelectAll() {
    final cart = context.read<CartProvider>();
    if (cart.items.isNotEmpty) {
      setState(() {
        _isSelectAll = cart.items.every((item) => item.isSelected);
      });
    }
  }

  void _toggleSelectAll(bool? value) {
    if (value != null) {
      context.read<CartProvider>().selectAll(value);
      setState(() => _isSelectAll = value);
    }
  }

  Future<void> _confirmDelete(CartItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade600),
            ResponsiveMobile.hSpace(8),
            const Text('Hapus Produk?'),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${item.namaProduk}" dari keranjang?',
          style: TextStyle(fontSize: ResponsiveMobile.bodySize(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: ResponsiveMobile.bodySize(context),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(8)),
              ),
            ),
            child: Text(
              'Hapus',
              style: TextStyle(fontSize: ResponsiveMobile.bodySize(context)),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await context.read<CartProvider>().removeItem(item.idProduk);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Produk dihapus dari keranjang',
              style: TextStyle(fontSize: ResponsiveMobile.bodySize(context)),
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _proceedToCheckout() {
    final cart = context.read<CartProvider>();
    
    if (cart.selectedCount == 0) {
      ErrorDialogUtils.showWarningDialog(
        context: context,
        title: 'Tidak Ada Produk Dipilih',
        message: 'Pilih minimal 1 produk untuk melanjutkan checkout',
      );
      return;
    }

    // ✅ VALIDASI: Hanya 1 toko
    final selectedItems = cart.items.where((item) => item.isSelected).toList();
    final umkmGroups = <String, List>{};
    
    for (var item in selectedItems) {
      umkmGroups.putIfAbsent(item.idUmkm, () => []).add(item);
    }
    
    if (umkmGroups.length > 1) {
      ErrorDialogUtils.showWarningDialog(
        context: context,
        title: 'Hanya Bisa 1 Toko',
        message: 'Saat ini hanya bisa checkout dari 1 toko per transaksi.\n\nSilakan hapus produk dari toko lain.',
      );
      return;
    }

    // ✅ NAVIGATE ke checkout screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UmkmCheckoutScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light grey background
      appBar: AppBar(
        // ✅ Changed to Blue Gradient
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_lightBlue, _primaryBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Consumer<CartProvider>(
          builder: (context, cart, child) {
            return Text(
              'Keranjang (${cart.itemCount})',
              style: TextStyle(
                fontSize: ResponsiveMobile.scaledFont(18),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          },
        ),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              if (cart.items.isEmpty) return const SizedBox.shrink();
              
              return IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: ResponsiveMobile.scaledFont(24),
                  color: Colors.white,
                ),
                tooltip: 'Hapus Semua',
                onPressed: () => _confirmDeleteAll(cart),
              );
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) {
            return _buildEmptyCart();
          }

          return Column(
            children: [
              _buildSelectAllBar(cart),
              Expanded(
                child: ListView.builder(
                  padding: ResponsiveMobile.allScaledPadding(16),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return _buildCartItem(item, cart);
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) return const SizedBox.shrink();
          return _buildBottomBar(cart);
        },
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: ResponsiveMobile.allScaledPadding(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: ResponsiveMobile.scaledFont(100),
              color: Colors.grey.shade300,
            ),
            ResponsiveMobile.vSpace(24),
            Text(
              'Keranjang Kosong',
              style: TextStyle(
                fontSize: ResponsiveMobile.titleSize(context),
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            ResponsiveMobile.vSpace(12),
            Text(
              'Yuk mulai belanja dan tambahkan produk\nfavorit ke keranjang!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveMobile.bodySize(context),
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            ResponsiveMobile.vSpace(32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue, // ✅ Changed to Blue
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveMobile.scaledW(32),
                  vertical: ResponsiveMobile.scaledH(14),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.shopping_bag),
              label: Text(
                'Mulai Belanja',
                style: TextStyle(
                  fontSize: ResponsiveMobile.bodySize(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectAllBar(CartProvider cart) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveMobile.scaledW(16),
        vertical: ResponsiveMobile.scaledH(12),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _isSelectAll,
            onChanged: _toggleSelectAll,
            activeColor: _primaryBlue, // ✅ Changed to Blue
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          Text(
            'Pilih Semua',
            style: TextStyle(
              fontSize: ResponsiveMobile.bodySize(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            '${cart.selectedCount} dipilih',
            style: TextStyle(
              fontSize: ResponsiveMobile.bodySize(context),
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item, CartProvider cart) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveMobile.scaledH(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: ResponsiveMobile.allScaledPadding(12),
        child: Column(
          children: [
            // Store header
            Row(
              children: [
                Icon(
                  Icons.store,
                  size: ResponsiveMobile.scaledFont(18),
                  color: _primaryBlue, // ✅ Changed to Blue
                ),
                ResponsiveMobile.hSpace(8),
                Text(
                  item.namaToko,
                  style: TextStyle(
                    fontSize: ResponsiveMobile.bodySize(context),
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  size: ResponsiveMobile.scaledFont(20),
                  color: Colors.grey.shade400,
                ),
              ],
            ),
            
            Divider(height: ResponsiveMobile.scaledH(24), color: Colors.grey.shade100),
            
            // Product item
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox
                Padding(
                  padding: EdgeInsets.only(right: ResponsiveMobile.scaledW(8)),
                  child: Checkbox(
                    value: item.isSelected,
                    onChanged: (value) {
                      cart.toggleSelection(item.idProduk);
                      _checkSelectAll();
                    },
                    activeColor: _primaryBlue, // ✅ Changed to Blue
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                
                // Product image
                ClipRRect(
                  borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(8)),
                  child: item.fotoProduk != null
                      ? CachedNetworkImage(
                          imageUrl: item.fotoProduk!,
                          width: ResponsiveMobile.scaledW(70),
                          height: ResponsiveMobile.scaledW(70),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey.shade100,
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey.shade100,
                            child: Icon(Icons.image_not_supported, color: Colors.grey.shade400),
                          ),
                        )
                      : Container(
                          width: ResponsiveMobile.scaledW(70),
                          height: ResponsiveMobile.scaledW(70),
                          color: Colors.grey.shade100,
                          child: Icon(Icons.image, color: Colors.grey.shade400),
                        ),
                ),
                
                ResponsiveMobile.hSpace(12),
                
                // Product info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.namaProduk,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: ResponsiveMobile.bodySize(context),
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      
                      ResponsiveMobile.vSpace(6),
                      
                      Text(
                        CurrencyFormatter.formatRupiahWithPrefix(item.hargaProduk),
                        style: TextStyle(
                          fontSize: ResponsiveMobile.bodySize(context),
                          fontWeight: FontWeight.bold,
                          color: _primaryBlue, // ✅ Changed to Blue
                        ),
                      ),
                      
                      ResponsiveMobile.vSpace(12),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Quantity control
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(6)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildQtyButton(
                                  icon: Icons.remove,
                                  onTap: item.quantity > 1
                                      ? () => cart.updateQuantity(item.idProduk, item.quantity - 1)
                                      : null,
                                ),
                                Container(
                                  constraints: BoxConstraints(minWidth: ResponsiveMobile.scaledW(32)),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${item.quantity}',
                                    style: TextStyle(
                                      fontSize: ResponsiveMobile.bodySize(context),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                _buildQtyButton(
                                  icon: Icons.add,
                                  onTap: item.quantity < item.stokTersedia
                                      ? () => cart.updateQuantity(item.idProduk, item.quantity + 1)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          
                          // Delete button
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.red.shade400,
                              size: ResponsiveMobile.scaledFont(20),
                            ),
                            onPressed: () => _confirmDelete(item),
                          ),
                        ],
                      ),
                      
                      // Stock warning
                      if (item.quantity >= item.stokTersedia)
                        Padding(
                          padding: EdgeInsets.only(top: ResponsiveMobile.scaledH(4)),
                          child: Text(
                            'Stok maksimal: ${item.stokTersedia}',
                            style: TextStyle(
                              fontSize: ResponsiveMobile.captionSize(context) - 1,
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyButton({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(ResponsiveMobile.scaledW(6)),
        child: Icon(
          icon,
          size: ResponsiveMobile.scaledFont(16),
          color: onTap != null ? Colors.black87 : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildBottomBar(CartProvider cart) {
    return Container(
      padding: EdgeInsets.all(ResponsiveMobile.scaledW(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Summary row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total (${cart.selectedCount} produk)',
                      style: TextStyle(
                        fontSize: ResponsiveMobile.captionSize(context),
                        color: Colors.grey.shade600,
                      ),
                    ),
                    ResponsiveMobile.vSpace(4),
                    Text(
                      CurrencyFormatter.formatRupiahWithPrefix(cart.totalPrice),
                      style: TextStyle(
                        fontSize: ResponsiveMobile.scaledFont(18),
                        fontWeight: FontWeight.bold,
                        color: _primaryBlue, // ✅ Changed to Blue
                      ),
                    ),
                  ],
                ),
                
                ElevatedButton(
                  onPressed: _proceedToCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue, // ✅ Changed to Blue
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveMobile.scaledW(32),
                      vertical: ResponsiveMobile.scaledH(12),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Checkout',
                    style: TextStyle(
                      fontSize: ResponsiveMobile.bodySize(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAll(CartProvider cart) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade600),
            ResponsiveMobile.hSpace(8),
            const Text('Hapus Semua?'),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus semua produk dari keranjang?',
          style: TextStyle(fontSize: ResponsiveMobile.bodySize(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: ResponsiveMobile.bodySize(context),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(8)),
              ),
            ),
            child: Text(
              'Hapus Semua',
              style: TextStyle(fontSize: ResponsiveMobile.bodySize(context)),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await cart.clearCart();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Keranjang dikosongkan',
              style: TextStyle(fontSize: ResponsiveMobile.bodySize(context)),
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }
}