// lib/providers/cart_provider.dart

import 'package:flutter/foundation.dart';
import 'package:sidrive/models/cart_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  static const String _cartKey = 'shopping_cart';

  List<CartItem> get items => _items;
  
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  
  List<CartItem> get selectedItems => _items.where((item) => item.isSelected).toList();
  
  double get totalPrice => selectedItems.fold(0.0, (sum, item) => sum + item.subtotal);
  
  int get selectedCount => selectedItems.length;

  // Load cart from local storage
  Future<void> loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_cartKey);
      
      if (cartJson != null) {
        final List<dynamic> decoded = json.decode(cartJson);
        _items = decoded.map((item) => CartItem.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error loading cart: $e');
    }
  }

  // Save cart to local storage
  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = json.encode(_items.map((item) => item.toJson()).toList());
      await prefs.setString(_cartKey, cartJson);
    } catch (e) {
      debugPrint('❌ Error saving cart: $e');
    }
  }

  // Add item to cart
  Future<bool> addItem(CartItem item) async {
    try {
      final existingIndex = _items.indexWhere((i) => i.idProduk == item.idProduk);
      
      if (existingIndex >= 0) {
        // Update quantity if exists
        final newQty = _items[existingIndex].quantity + item.quantity;
        
        if (newQty > item.stokTersedia) {
          debugPrint('⚠️ Stok tidak cukup');
          return false;
        }
        
        _items[existingIndex].quantity = newQty;
      } else {
        // Add new item
        _items.add(item);
      }
      
      await _saveCart();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error add to cart: $e');
      return false;
    }
  }

  // Update quantity
  Future<void> updateQuantity(String idProduk, int newQuantity) async {
    final index = _items.indexWhere((item) => item.idProduk == idProduk);
    
    if (index >= 0) {
      if (newQuantity <= 0) {
        await removeItem(idProduk);
      } else if (newQuantity <= _items[index].stokTersedia) {
        _items[index].quantity = newQuantity;
        await _saveCart();
        notifyListeners();
      }
    }
  }

  // Remove item
  Future<void> removeItem(String idProduk) async {
    _items.removeWhere((item) => item.idProduk == idProduk);
    await _saveCart();
    notifyListeners();
  }

  // Toggle selection
  Future<void> toggleSelection(String idProduk) async {
    final index = _items.indexWhere((item) => item.idProduk == idProduk);
    
    if (index >= 0) {
      _items[index].isSelected = !_items[index].isSelected;
      await _saveCart();
      notifyListeners();
    }
  }

  // Select all
  Future<void> selectAll(bool selected) async {
    for (var item in _items) {
      item.isSelected = selected;
    }
    await _saveCart();
    notifyListeners();
  }

  // Clear cart
  Future<void> clearCart() async {
    _items.clear();
    await _saveCart();
    notifyListeners();
  }

  // Clear selected items (after checkout)
  Future<void> clearSelectedItems() async {
    _items.removeWhere((item) => item.isSelected);
    await _saveCart();
    notifyListeners();
  }

  // Get item by product id
  CartItem? getItem(String idProduk) {
    try {
      return _items.firstWhere((item) => item.idProduk == idProduk);
    } catch (e) {
      return null;
    }
  }

  // Check if product is in cart
  bool isInCart(String idProduk) {
    return _items.any((item) => item.idProduk == idProduk);
  }

  // Get quantity in cart
  int getQuantityInCart(String idProduk) {
    final item = getItem(idProduk);
    return item?.quantity ?? 0;
  }
}