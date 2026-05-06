import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_widgets.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  int _selected = 0;
  int _filter = 0;
  static const _filters = ['Todos', 'Cliente', 'Comercio', 'Repartidor'];
  static const _tickets = [
    ('#T-1842', 'María Contreras', 'No llega mi pedido #RN-24891',
        'Hace 4m', 'Urgente', 'red', true, 'Cliente'),
    ('#T-1841', 'Pedro Quispe (Repartidor)', 'Cliente no responde',
        'Hace 12m', 'En proceso', 'amber', true, 'Repartidor'),
    ('#T-1840', 'El Norky\'s - Lince', 'Necesito pausar el comercio',
        'Hace 28m', 'En proceso', 'amber', false, 'Comercio'),
    ('#T-1839', 'Carlos Mendoza', 'Reembolso por producto faltante',
        'Hace 1h', 'Esperando', 'blue', false, 'Cliente'),
    ('#T-1838', 'Ana Salas (Repartidora)', 'Problema con la app',
        'Hace 2h', 'Resuelto', 'gray', false, 'Repartidor'),
    ('#T-1837', 'Lucía Paredes', 'Cambio de método de pago',
        'Hace 3h', 'Resuelto', 'gray', false, 'Cliente'),
  ];

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      activeId: 'soporte',
      title: 'Soporte',
      actions: const [
        AdminBadge('3 urgentes', tone: 'red'),
        SizedBox(width: 8),
        AdminButton(
            label: 'Plantillas',
            variant: AdminBtnVariant.secondary,
            size: AdminBtnSize.sm),
      ],
      child: SizedBox(
        height: 760,
        child: LayoutBuilder(builder: (context, c) {
          if (c.maxWidth < 900) {
            return Column(
              children: [
                Expanded(child: _ticketsList()),
                const SizedBox(height: 16),
                Expanded(child: _chatPane()),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 360, child: _ticketsList()),
              const SizedBox(width: 16),
              Expanded(child: _chatPane()),
              const SizedBox(width: 16),
              SizedBox(width: 280, child: const _ContextPane()),
            ],
          );
        }),
      ),
    );
  }

  Widget _ticketsList() {
    return AdminCard.flush(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tickets',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    const Text('42 abiertos',
                        style: TextStyle(
                            fontSize: 11,
                            color: AdminColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 10),
                AdminPillToggle(
                  options: _filters,
                  selectedIndex: _filter,
                  onSelected: (i) => setState(() => _filter = i),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _tickets.length,
              itemBuilder: (context, i) {
                final t = _tickets[i];
                final selected = i == _selected;
                return InkWell(
                  onTap: () => setState(() => _selected = i),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selected
                          ? AdminColors.bg
                          : Colors.transparent,
                      border: Border(
                        top: BorderSide(color: AdminColors.border),
                        left: BorderSide(
                          width: 3,
                          color: selected
                              ? AdminColors.primary
                              : Colors.transparent,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AdminAvatar(
                          name: t.$2,
                          size: 36,
                          tone: const [
                            'coral',
                            'blue',
                            'green',
                            'amber',
                            'purple'
                          ][i % 5],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(t.$1,
                                      style: GoogleFonts.robotoMono(
                                          fontSize: 11,
                                          color: AdminColors.textMuted,
                                          fontWeight:
                                              FontWeight.w600)),
                                  Text(t.$4,
                                      style: const TextStyle(
                                          fontSize: 10.5,
                                          color: AdminColors
                                              .textMuted)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(t.$2,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: t.$7
                                          ? FontWeight.w800
                                          : FontWeight.w600),
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(t.$3,
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AdminColors.textMuted),
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                children: [
                                  AdminBadge(t.$5, tone: t.$6),
                                  AdminBadge(t.$8, tone: 'gray'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (t.$7)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: const BoxDecoration(
                                color: AdminColors.primary,
                                shape: BoxShape.circle),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatPane() {
    return AdminCard.flush(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: AdminColors.border)),
            ),
            child: Row(
              children: [
                AdminAvatar(name: 'María Contreras', size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AdminColors.text),
                          children: [
                            const TextSpan(text: 'María Contreras '),
                            TextSpan(
                              text: '· #T-1842',
                              style: GoogleFonts.plusJakartaSans(
                                  color: AdminColors.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 1),
                      const Text(
                          'No llega mi pedido #RN-24891 · abierto hace 4m',
                          style: TextStyle(
                              fontSize: 12,
                              color: AdminColors.textMuted)),
                    ],
                  ),
                ),
                const AdminButton(
                    label: 'Asignar a mí',
                    variant: AdminBtnVariant.secondary,
                    size: AdminBtnSize.sm),
                const SizedBox(width: 8),
                const AdminButton(
                    label: 'Resolver',
                    icon: Icons.check,
                    variant: AdminBtnVariant.success,
                    size: AdminBtnSize.sm),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: AdminColors.bg,
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  _bubble(
                      'Hola, hice un pedido hace 50 minutos y todavía no llega. La app dice que está "en camino" desde hace 30 min.',
                      '7:42 PM',
                      isMe: false),
                  const SizedBox(height: 10),
                  _attachmentBubble(),
                  const SizedBox(height: 10),
                  _bubble(
                      'Hola María, ya estoy revisando. Veo que el repartidor Julio está a 200m de tu dirección, debe estar llegando en 2-3 minutos. ¿Te confirmo cuando lo veas?',
                      'Andrea · 7:46 PM ✓✓',
                      isMe: true),
                  const SizedBox(height: 10),
                  _bubble('Sí porfa, te aviso. Gracias!', '7:46 PM',
                      isMe: false),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border:
                  Border(top: BorderSide(color: AdminColors.border)),
            ),
            child: Row(
              children: [
                const Icon(Icons.attach_file,
                    size: 18, color: AdminColors.textMuted),
                const SizedBox(width: 8),
                const Expanded(
                  child: AdminFakeField(
                      text: 'Escribe tu respuesta…',
                      width: double.infinity),
                ),
                const SizedBox(width: 8),
                const AdminButton(
                    label: 'Enviar',
                    icon: Icons.send,
                    size: AdminBtnSize.sm),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(String text, String meta, {required bool isMe}) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: 360),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isMe ? AdminColors.text : Colors.white,
            border: isMe
                ? null
                : Border.all(color: AdminColors.border),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft:
                  Radius.circular(isMe ? 12 : 2),
              bottomRight:
                  Radius.circular(isMe ? 2 : 12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text,
                  style: TextStyle(
                      fontSize: 13,
                      color:
                          isMe ? Colors.white : AdminColors.text)),
              const SizedBox(height: 4),
              Text(meta,
                  style: TextStyle(
                      fontSize: 10,
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.7)
                          : AdminColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attachmentBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AdminColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.inventory_2_outlined,
                      size: 12, color: AdminColors.textMuted),
                  SizedBox(width: 6),
                  Text('Pedido adjunto',
                      style: TextStyle(
                          fontSize: 11,
                          color: AdminColors.textMuted,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 4),
              const Text('#RN-24891 · El Norky\'s',
                  style:
                      TextStyle(fontWeight: FontWeight.w700)),
              const Text('S/ 80.90 · Repartidor: Julio Ramírez',
                  style: TextStyle(
                      fontSize: 11,
                      color: AdminColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContextPane extends StatelessWidget {
  const _ContextPane();
  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Contexto del pedido',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            const AdminEyebrow('PEDIDO'),
            const SizedBox(height: 6),
            Text('#RN-24891',
                style: GoogleFonts.robotoMono(
                    fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            const Text('Iniciado 7:02 PM · S/ 80.90',
                style: TextStyle(
                    fontSize: 11.5, color: AdminColors.textMuted)),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(color: AdminColors.border),
            ),
            const AdminEyebrow('TIMELINE'),
            const SizedBox(height: 8),
            for (final t in const [
              ('7:02', 'Recibido'),
              ('7:08', 'Aceptado por Norky\'s'),
              ('7:24', 'Listo para recoger'),
              ('7:28', 'Recogido por Julio R.'),
              ('7:46', 'En camino · 200m'),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text(t.$1,
                          style: GoogleFonts.robotoMono(
                              fontSize: 12,
                              color: AdminColors.textMuted)),
                    ),
                    Expanded(
                      child: Text(t.$2,
                          style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(color: AdminColors.border),
            ),
            const AdminEyebrow('ACCIONES RÁPIDAS'),
            const SizedBox(height: 8),
            const AdminButton(
                label: 'Ver en mapa',
                icon: Icons.map_outlined,
                variant: AdminBtnVariant.secondary,
                size: AdminBtnSize.sm),
            const SizedBox(height: 6),
            const AdminButton(
                label: 'Llamar al repartidor',
                icon: Icons.phone_outlined,
                variant: AdminBtnVariant.secondary,
                size: AdminBtnSize.sm),
            const SizedBox(height: 6),
            const AdminButton(
                label: 'Ofrecer cupón',
                variant: AdminBtnVariant.secondary,
                size: AdminBtnSize.sm),
            const SizedBox(height: 6),
            const AdminButton(
                label: 'Reembolso parcial',
                variant: AdminBtnVariant.secondary,
                size: AdminBtnSize.sm),
          ],
        ),
      ),
    );
  }
}
