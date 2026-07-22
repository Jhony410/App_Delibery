import 'package:flutter/material.dart';
import '../theme.dart';

/// Ayuda y soporte.
///
/// NOTA: todo el contenido de esta pantalla (preguntas frecuentes y datos de
/// contacto) es ESTÁTICO y está definido en el código. No proviene de Firestore
/// ni de ninguna fuente remota.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  // Contenido estático de preguntas frecuentes.
  static const _faqs = [
    (
      '¿Cómo hago un pedido?',
      'Elige un comercio, agrega productos al carrito, confirma tu dirección '
          'de entrega y el método de pago. Recibirás actualizaciones del estado '
          'de tu pedido en la pantalla de seguimiento.'
    ),
    (
      '¿Cuánto cuesta el envío?',
      'El costo de envío depende de cada comercio y se muestra antes de '
          'confirmar el pedido, en el resumen de precios.'
    ),
    (
      '¿Qué métodos de pago aceptan?',
      'Actualmente puedes pagar con Yape o en efectivo contra entrega.'
    ),
    (
      '¿Puedo cancelar un pedido?',
      'Un pedido puede cancelarse mientras el comercio aún no lo ha preparado. '
          'Comunícate con soporte lo antes posible para gestionarlo.'
    ),
    (
      '¿Cómo califico mi pedido?',
      'Cuando tu pedido esté entregado, ábrelo desde "Mis pedidos" y usa el '
          'botón "Calificar" para valorar al comercio y al repartidor.'
    ),
  ];

  // Datos de contacto estáticos.
  static const _contacts = [
    (Icons.phone_outlined, 'Teléfono', '+51 900 000 000'),
    (Icons.email_outlined, 'Correo', 'soporte@delipuno.pe'),
    (Icons.access_time, 'Horario', 'Lun a Dom · 8:00 - 22:00'),
  ];

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          SizedBox(height: top + 8),
          _buildAppBar(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                const Text('Preguntas frecuentes',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Column(
                    children: [
                      for (var i = 0; i < _faqs.length; i++)
                        _FaqTile(
                          question: _faqs[i].$1,
                          answer: _faqs[i].$2,
                          isLast: i == _faqs.length - 1,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Contacto',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Column(
                    children: [
                      for (var i = 0; i < _contacts.length; i++)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: i == _contacts.length - 1
                                    ? Colors.transparent
                                    : AppColors.border,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.bg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(_contacts[i].$1,
                                    size: 18, color: AppColors.appText),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_contacts[i].$2,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textMuted)),
                                  const SizedBox(height: 2),
                                  Text(_contacts[i].$3,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.chevron_left, size: 22),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Ayuda y soporte',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;
  final bool isLast;

  const _FaqTile({
    required this.question,
    required this.answer,
    required this.isLast,
  });

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: widget.isLast ? Colors.transparent : AppColors.border,
          ),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.question,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                  Icon(_open ? Icons.remove : Icons.add,
                      size: 18, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(widget.answer,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        height: 1.4)),
              ),
            ),
        ],
      ),
    );
  }
}
