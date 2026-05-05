import 'package:cloud_firestore/cloud_firestore.dart';

class SeedService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> seedIfEmpty() async {
    final snap = await _db.collection('stores').limit(1).get();
    if (snap.docs.isNotEmpty) return;
    await _seedStores();
  }

  static Future<void> _seedStores() async {
    final stores = [
      {
        'name': 'Sabor de Casa',
        'category': 'Comida criolla',
        'categorySlug': 'comida',
        'rating': 4.8,
        'reviewCount': 1240,
        'deliveryTime': '25-35',
        'deliveryFee': 5.90,
        'isOpen': true,
        'address': 'Av. Arequipa 2450, Lince',
        'promo': '-20%',
        'tone': 'warm',
      },
      {
        'name': "El Norky's",
        'category': 'Pollería · Comida criolla',
        'categorySlug': 'comida',
        'rating': 4.8,
        'reviewCount': 2100,
        'deliveryTime': '25-35',
        'deliveryFee': 5.90,
        'isOpen': true,
        'address': 'Av. Arequipa 2450, Lince',
        'promo': null,
        'tone': 'warm',
      },
      {
        'name': 'La Botica Express',
        'category': 'Farmacia · 24h',
        'categorySlug': 'farmacia',
        'rating': 4.9,
        'reviewCount': 890,
        'deliveryTime': '15-20',
        'deliveryFee': 3.90,
        'isOpen': true,
        'address': 'Jr. Camaná 345, Cercado',
        'promo': null,
        'tone': 'green',
      },
      {
        'name': 'Plaza Vea Cerca',
        'category': 'Supermercado',
        'categorySlug': 'market',
        'rating': 4.6,
        'reviewCount': 3200,
        'deliveryTime': '35-45',
        'deliveryFee': 7.90,
        'isOpen': true,
        'address': 'Av. Javier Prado 4200, Surco',
        'promo': null,
        'tone': 'cool',
      },
      {
        'name': 'Pizzería Don Carlos',
        'category': 'Pizzería · Italiana',
        'categorySlug': 'comida',
        'rating': 4.7,
        'reviewCount': 560,
        'deliveryTime': '30-40',
        'deliveryFee': 5.00,
        'isOpen': true,
        'address': 'Calle Los Laureles 120, San Isidro',
        'promo': null,
        'tone': 'warm',
      },
      {
        'name': 'Chifa Xian',
        'category': 'Chifa · Fusión',
        'categorySlug': 'comida',
        'rating': 4.5,
        'reviewCount': 780,
        'deliveryTime': '20-30',
        'deliveryFee': 4.50,
        'isOpen': true,
        'address': 'Jr. Capón 230, Cercado',
        'promo': null,
        'tone': 'cool',
      },
    ];

    for (final store in stores) {
      final ref = await _db.collection('stores').add(store);
      await _seedProducts(ref.id, store['categorySlug'] as String,
          store['name'] as String);
    }
  }

  static Future<void> _seedProducts(
      String storeId, String slug, String storeName) async {
    final products = _products(slug, storeName);
    final batch = _db.batch();
    for (final p in products) {
      final ref = _db
          .collection('stores')
          .doc(storeId)
          .collection('products')
          .doc();
      batch.set(ref, p);
    }
    await batch.commit();
  }

  static List<Map<String, dynamic>> _products(String slug, String storeName) {
    switch (slug) {
      case 'comida':
        if (storeName.contains("Norky") || storeName.contains("Sabor")) {
          return [
            {
              'name': 'Pollo a la brasa (1/4)',
              'description':
                  'Pollo marinado 24h al carbón. Con papas doradas y ensalada fresca.',
              'price': 22.90,
              'tone': 'warm',
              'badge': 'Top',
              'category': 'Destacados',
              'isAvailable': true,
              'sizes': [
                {'name': 'Personal', 'price': 22.90},
                {'name': 'Mediano', 'price': 42.00},
                {'name': 'Familiar', 'price': 75.00},
              ],
              'extras': [
                {'name': 'Papas extra', 'price': 5.00},
                {'name': 'Ensalada', 'price': 3.50},
                {'name': 'Ají de la casa', 'price': 0.0},
              ],
            },
            {
              'name': 'Combo familiar',
              'description': '1 pollo entero + papas grandes + gaseosa 1.5L.',
              'price': 75.00,
              'tone': 'warm',
              'badge': null,
              'category': 'Combos',
              'isAvailable': true,
              'sizes': [],
              'extras': [
                {'name': 'Ensalada extra', 'price': 3.50},
                {'name': 'Ají extra', 'price': 0.0},
              ],
            },
            {
              'name': 'Ensalada mixta',
              'description': 'Lechuga, tomate, pepino, palta y aderezo de la casa.',
              'price': 12.50,
              'tone': 'green',
              'badge': null,
              'category': 'Entradas',
              'isAvailable': true,
              'sizes': [],
              'extras': [
                {'name': 'Sin cebolla', 'price': 0.0},
              ],
            },
            {
              'name': 'Inca Kola 1.5L',
              'description': 'Bebida gaseosa 1.5 litros.',
              'price': 8.00,
              'tone': 'cool',
              'badge': null,
              'category': 'Bebidas',
              'isAvailable': true,
              'sizes': [],
              'extras': [],
            },
          ];
        }
        if (storeName.contains('Pizza')) {
          return [
            {
              'name': 'Pizza familiar hawaiana',
              'description':
                  'Jamón, piña y queso mozzarella. Tamaño familiar.',
              'price': 54.00,
              'tone': 'warm',
              'badge': 'Top',
              'category': 'Destacados',
              'isAvailable': true,
              'sizes': [
                {'name': 'Personal', 'price': 28.00},
                {'name': 'Mediana', 'price': 42.00},
                {'name': 'Familiar', 'price': 54.00},
              ],
              'extras': [
                {'name': 'Doble queso', 'price': 5.00},
                {'name': 'Borde relleno', 'price': 8.00},
              ],
            },
            {
              'name': 'Lasaña de carne',
              'description':
                  'Capas de pasta, carne molida, bechamel y queso gratinado.',
              'price': 32.00,
              'tone': 'warm',
              'badge': null,
              'category': 'Entradas',
              'isAvailable': true,
              'sizes': [],
              'extras': [],
            },
          ];
        }
        // Chifa
        return [
          {
            'name': 'Arroz chaufa especial',
            'description':
                'Arroz frito con pollo, res, mariscos, huevo y verduras.',
            'price': 22.00,
            'tone': 'cool',
            'badge': 'Top',
            'category': 'Destacados',
            'isAvailable': true,
            'sizes': [
              {'name': 'Personal', 'price': 22.00},
              {'name': 'Para 2', 'price': 38.00},
            ],
            'extras': [
              {'name': 'Extra pollo', 'price': 6.00},
              {'name': 'Salsa de soja', 'price': 0.0},
            ],
          },
          {
            'name': 'Wantán frito',
            'description': '8 piezas de wantán relleno de cerdo y camarón.',
            'price': 18.00,
            'tone': 'warm',
            'badge': null,
            'category': 'Entradas',
            'isAvailable': true,
            'sizes': [],
            'extras': [],
          },
        ];

      case 'farmacia':
        return [
          {
            'name': 'Paracetamol 500mg x20',
            'description': 'Analgésico y antipirético. Caja 20 tabletas.',
            'price': 8.50,
            'tone': 'green',
            'badge': null,
            'category': 'Destacados',
            'isAvailable': true,
            'sizes': [],
            'extras': [],
          },
          {
            'name': 'Ibuprofeno 400mg x10',
            'description': 'Antiinflamatorio y analgésico. Caja 10 tabletas.',
            'price': 12.00,
            'tone': 'green',
            'badge': null,
            'category': 'Destacados',
            'isAvailable': true,
            'sizes': [],
            'extras': [],
          },
          {
            'name': 'Alcohol en gel 250ml',
            'description': 'Gel antibacterial 70% alcohol.',
            'price': 9.90,
            'tone': 'cool',
            'badge': null,
            'category': 'Higiene',
            'isAvailable': true,
            'sizes': [],
            'extras': [],
          },
          {
            'name': 'Mascarilla KN95 x5',
            'description': 'Protección KN95. Paquete x5 unidades.',
            'price': 15.00,
            'tone': 'cool',
            'badge': null,
            'category': 'Higiene',
            'isAvailable': true,
            'sizes': [],
            'extras': [],
          },
        ];

      default: // market
        return [
          {
            'name': 'Leche Gloria 1L',
            'description': 'Leche evaporada entera. Tarro 1 litro.',
            'price': 4.50,
            'tone': 'cool',
            'badge': null,
            'category': 'Lácteos',
            'isAvailable': true,
            'sizes': [],
            'extras': [],
          },
          {
            'name': 'Pan de molde Bimbo',
            'description': 'Pan de molde blanco, bolsa 500g.',
            'price': 6.50,
            'tone': 'warm',
            'badge': null,
            'category': 'Panadería',
            'isAvailable': true,
            'sizes': [],
            'extras': [],
          },
          {
            'name': 'Arroz Costeño 5kg',
            'description': 'Arroz extra fino, saco 5 kilogramos.',
            'price': 22.90,
            'tone': 'warm',
            'badge': 'Oferta',
            'category': 'Abarrotes',
            'isAvailable': true,
            'sizes': [],
            'extras': [],
          },
          {
            'name': 'Aceite Primor 1L',
            'description': 'Aceite vegetal de girasol. Botella 1 litro.',
            'price': 9.90,
            'tone': 'warm',
            'badge': null,
            'category': 'Abarrotes',
            'isAvailable': true,
            'sizes': [],
            'extras': [],
          },
        ];
    }
  }
}
