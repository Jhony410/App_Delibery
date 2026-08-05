import 'package:flutter/material.dart';
import '../delivery_config.dart';
import '../theme.dart';

/// Ayuda y soporte.
///
/// NOTA: todo el contenido de esta pantalla (preguntas frecuentes y datos de
/// contacto) es ESTÁTICO y está definido en el código. No proviene de Firestore
/// ni de ninguna fuente remota.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  // Contenido estático de preguntas frecuentes.
  static final _faqs = [
    (
      '¿Cómo hago un pedido?',
      'Elige un comercio, agrega productos al carrito, confirma tu dirección '
          'de entrega y el método de pago. Recibirás actualizaciones del estado '
          'de tu pedido en la pantalla de seguimiento.',
    ),
    (
      '¿Cuánto cuesta el envío?',
      'El delivery tiene una tarifa fija de ${DeliveryConfig.formattedFee} '
          'para cualquier comercio.',
    ),
    (
      '¿Qué métodos de pago aceptan?',
      'Actualmente puedes pagar con Yape o en efectivo contra entrega.',
    ),
    (
      '¿Puedo cancelar un pedido?',
      'La cancelación directa aún no está habilitada en la aplicación. Revisa '
          'tu pedido antes de confirmarlo.',
    ),
    (
      '¿Cómo califico mi pedido?',
      'Cuando tu pedido esté entregado, ábrelo desde "Mis pedidos" y usa el '
          'botón "Calificar" para valorar al comercio y al repartidor.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          SizedBox(height: top + 8),
          _buildAppBar(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Text(
                  'Preguntas frecuentes',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
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
                SizedBox(height: 24),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.support_agent_rounded,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Soporte directo en preparación',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Los canales de contacto se mostrarán aquí cuando estén habilitados.',
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.4,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
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
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.chevron_left, size: 22),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Ayuda y soporte',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
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
            color: widget.isLast
                ? Colors.transparent
                : Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _open ? Icons.remove : Icons.add,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.answer,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
