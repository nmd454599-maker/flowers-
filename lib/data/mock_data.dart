import '../models/models.dart';
import 'photo_catalog.dart';

const stores = <Store>[
  Store(
      id: 's1',
      name: 'روز بغداد',
      city: 'بغداد',
      rating: 4.9,
      emoji: '🌷',
      minOrder: 20000,
      deliveryMinutes: 35),
  Store(
      id: 's2',
      name: 'دار الهدية',
      city: 'بغداد',
      rating: 4.8,
      emoji: '🎁',
      minOrder: 15000,
      deliveryMinutes: 45),
  Store(
      id: 's3',
      name: 'حلويات لافندر',
      city: 'بغداد',
      rating: 4.7,
      emoji: '🧁',
      minOrder: 10000,
      deliveryMinutes: 30),
];

const products = <Product>[
  Product(
      id: 'p1',
      storeId: 's1',
      name: 'باقة بيوني فاخرة',
      category: 'الزهور',
      price: 45000,
      emoji: '💐',
      rating: 4.8,
      description: 'باقة ورد أنيقة للميلاد والمناسبات والتهاني.'),
  Product(
      id: 'p2',
      storeId: 's1',
      name: 'باقة حب حمراء',
      imageUrl: 'assets/images/catalog/photo_20.png',
      category: 'الزهور',
      price: 35000,
      emoji: '🌹',
      rating: 4.7,
      description: 'ورد أحمر بتغليف فاخر مع بطاقة إهداء.'),
  Product(
      id: 'p3',
      storeId: 's3',
      name: 'علبة شوكولاتة فاخرة',
      category: 'الحلويات',
      price: 28000,
      emoji: '🍫',
      rating: 4.6,
      description: 'تشكيلة شوكولاتة بلجيكية مناسبة كهدية.'),
  Product(
      id: 'p4',
      storeId: 's2',
      name: 'صندوق هدية دافئ',
      category: 'الهدايا',
      price: 25000,
      emoji: '🎁',
      rating: 4.9,
      description: 'صندوق هدايا لطيف منسق مع الورد.'),
  Product(
      id: 'p5',
      storeId: 's2',
      name: 'عطر وإهداء',
      imageUrl: 'assets/images/catalog/photo_24.png',
      category: 'العطور',
      price: 60000,
      emoji: '🧴',
      rating: 4.7,
      description: 'عطر مميز ضمن تغليف هدايا أنيق.'),
  Product(
      id: 'p6',
      storeId: 's1',
      name: 'نبتة منزلية',
      category: 'النباتات',
      price: 22000,
      emoji: '🪴',
      rating: 4.5,
      description: 'نبتة منزلية جميلة وسهلة العناية.'),
  ...photoCatalogProducts,
];
