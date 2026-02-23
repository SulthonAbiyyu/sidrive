// lib/models/cart_model.dart

class CartItem {
  final String idProduk;
  final String namaProduk;
  final double hargaProduk;
  final String? fotoProduk;
  final String idUmkm;
  final String namaToko;
  int quantity;
  final int stokTersedia;
  bool isSelected;

  CartItem({
    required this.idProduk,
    required this.namaProduk,
    required this.hargaProduk,
    this.fotoProduk,
    required this.idUmkm,
    required this.namaToko,
    this.quantity = 1,
    required this.stokTersedia,
    this.isSelected = true,
  });

  double get subtotal => hargaProduk * quantity;

  Map<String, dynamic> toJson() {
    return {
      'id_produk': idProduk,
      'nama_produk': namaProduk,
      'harga_produk': hargaProduk,
      'foto_produk': fotoProduk,
      'id_umkm': idUmkm,
      'nama_toko': namaToko,
      'quantity': quantity,
      'stok_tersedia': stokTersedia,
      'is_selected': isSelected,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      idProduk: json['id_produk'],
      namaProduk: json['nama_produk'],
      hargaProduk: (json['harga_produk'] ?? 0).toDouble(),
      fotoProduk: json['foto_produk'],
      idUmkm: json['id_umkm'],
      namaToko: json['nama_toko'],
      quantity: json['quantity'] ?? 1,
      stokTersedia: json['stok_tersedia'] ?? 0,
      isSelected: json['is_selected'] ?? true,
    );
  }

  CartItem copyWith({
    String? idProduk,
    String? namaProduk,
    double? hargaProduk,
    String? fotoProduk,
    String? idUmkm,
    String? namaToko,
    int? quantity,
    int? stokTersedia,
    bool? isSelected,
  }) {
    return CartItem(
      idProduk: idProduk ?? this.idProduk,
      namaProduk: namaProduk ?? this.namaProduk,
      hargaProduk: hargaProduk ?? this.hargaProduk,
      fotoProduk: fotoProduk ?? this.fotoProduk,
      idUmkm: idUmkm ?? this.idUmkm,
      namaToko: namaToko ?? this.namaToko,
      quantity: quantity ?? this.quantity,
      stokTersedia: stokTersedia ?? this.stokTersedia,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}