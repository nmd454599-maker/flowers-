String productImage(String productId) => switch (productId) {
      'p1' => 'assets/images/catalog/photo_05.png',
      'p2' => 'assets/images/catalog/photo_20.png',
      'p3' => 'assets/images/catalog/photo_13.png',
      'p4' || 'p5' => 'assets/images/catalog/photo_02.png',
      _ => 'assets/images/catalog/photo_05.png',
    };
