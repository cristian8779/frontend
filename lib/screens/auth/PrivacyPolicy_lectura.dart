import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // Función helper para obtener tamaños responsivos
  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 600) return baseSize * 1.2;
    if (screenWidth < 360) return baseSize * 0.9;
    return baseSize;
  }

  EdgeInsets _getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 600) return const EdgeInsets.all(32);
    if (screenWidth < 360) return const EdgeInsets.all(16);
    return const EdgeInsets.all(20);
  }

  Widget _buildSection(String title, String content) {
    return Container(
      margin: EdgeInsets.only(bottom: _getResponsiveSize(context, 24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: _getResponsiveSize(context, 18),
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: _getResponsiveSize(context, 12)),
          Text(
            content,
            style: TextStyle(
              fontSize: _getResponsiveSize(context, 15),
              height: 1.6,
              color: const Color(0xFF374151),
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(String item) {
    return Container(
      margin: EdgeInsets.only(bottom: _getResponsiveSize(context, 8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: _getResponsiveSize(context, 6),
            height: _getResponsiveSize(context, 6),
            margin: EdgeInsets.only(
              top: _getResponsiveSize(context, 8),
              right: _getResponsiveSize(context, 12),
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF6366F1),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              item,
              style: TextStyle(
                fontSize: _getResponsiveSize(context, 15),
                height: 1.5,
                color: const Color(0xFF374151),
              ),
              textAlign: TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberedItem(int number, String item) {
    return Container(
      margin: EdgeInsets.only(bottom: _getResponsiveSize(context, 12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: _getResponsiveSize(context, 24),
            height: _getResponsiveSize(context, 24),
            margin: EdgeInsets.only(right: _getResponsiveSize(context, 12)),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  fontSize: _getResponsiveSize(context, 12),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              item,
              style: TextStyle(
                fontSize: _getResponsiveSize(context, 15),
                height: 1.5,
                color: const Color(0xFF374151),
              ),
              textAlign: TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            'Política de Privacidad',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: _getResponsiveSize(context, 20),
              letterSpacing: -0.5,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1F2937),
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: const Color(0xFFE5E7EB),
            ),
          ),
        ),
        body: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: _getResponsivePadding(context),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header principal
                  Container(
                    padding: EdgeInsets.all(_getResponsiveSize(context, 24)),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF6366F1).withOpacity(0.1),
                          const Color(0xFF8B5CF6).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF6366F1).withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(_getResponsiveSize(context, 12)),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.security_rounded,
                                color: Colors.white,
                                size: _getResponsiveSize(context, 24),
                              ),
                            ),
                            SizedBox(width: _getResponsiveSize(context, 16)),
                            Expanded(
                              child: Text(
                                'Política de Privacidad y Términos de Uso',
                                style: TextStyle(
                                  fontSize: _getResponsiveSize(context, 20),
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1F2937),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: _getResponsiveSize(context, 16)),
                        Text(
                          'Insportswear respeta y protege tu privacidad. Esta Política explica cómo recolectamos, usamos, almacenamos y protegemos tus datos personales, de acuerdo con la Ley 1581 de 2012 y demás normas colombianas de protección de datos.',
                          style: TextStyle(
                            fontSize: _getResponsiveSize(context, 15),
                            height: 1.6,
                            color: const Color(0xFF374151),
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: _getResponsiveSize(context, 32)),

                  // Sección 1: Datos que recolectamos
                  _buildSection(
                    '1. Datos que recolectamos',
                    'Podemos solicitar o recolectar los siguientes datos personales:'
                  ),
                  _buildListItem('Nombre completo'),
                  _buildListItem('Dirección de correo electrónico'),
                  _buildListItem('Número de teléfono y/o celular'),
                  _buildListItem('Dirección de domicilio o entrega'),
                  _buildListItem('Información de compras o transacciones'),
                  _buildListItem('Preferencias relacionadas con nuestros productos'),

                  SizedBox(height: _getResponsiveSize(context, 24)),

                  // Sección 2: Finalidades del tratamiento
                  _buildSection(
                    '2. Finalidades del tratamiento',
                    'Tus datos serán usados únicamente para:'
                  ),
                  _buildNumberedItem(1, 'Gestionar tus compras, pedidos o solicitudes.'),
                  _buildNumberedItem(2, 'Enviar notificaciones relacionadas con tus pedidos.'),
                  _buildNumberedItem(3, 'Compartir promociones, descuentos, lanzamientos y novedades de Insportswear.'),
                  _buildNumberedItem(4, 'Mantenerte informado sobre cambios en nuestras políticas o servicios.'),
                  _buildNumberedItem(5, 'Atender consultas, quejas, reclamos y solicitudes.'),
                  _buildNumberedItem(6, 'Cumplir con obligaciones legales, contractuales y contables.'),
                  _buildNumberedItem(7, 'Prevenir fraudes y garantizar la seguridad de las transacciones.'),

                  // Sección 3: Conservación de los datos
                  _buildSection(
                    '3. Conservación de los datos',
                    'Tus datos se conservarán únicamente por el tiempo necesario para cumplir las finalidades descritas o mientras exista una relación comercial o legal contigo. Posteriormente, serán eliminados de manera segura.'
                  ),

                  // Sección 4: Acceso y destinatarios de la información
                  _buildSection(
                    '4. Acceso y destinatarios de la información',
                    'Tus datos podrán ser conocidos únicamente por:'
                  ),
                  _buildListItem('Personal autorizado de Insportswear.'),
                  _buildListItem('Proveedores que nos prestan servicios (por ejemplo: empresas de mensajería, pasarelas de pago, plataformas tecnológicas).'),
                  _buildListItem('Autoridades competentes, en caso de que la ley lo exija.'),
                  
                  Container(
                    margin: EdgeInsets.only(top: _getResponsiveSize(context, 16)),
                    padding: EdgeInsets.all(_getResponsiveSize(context, 16)),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_rounded,
                          color: const Color(0xFFF59E0B),
                          size: _getResponsiveSize(context, 20),
                        ),
                        SizedBox(width: _getResponsiveSize(context, 12)),
                        Expanded(
                          child: Text(
                            'En ningún caso vendemos, alquilamos ni cedemos tus datos personales a terceros no autorizados.',
                            style: TextStyle(
                              fontSize: _getResponsiveSize(context, 14),
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFA16207),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sección 5: Derechos de los titulares (ARCO)
                  _buildSection(
                    '5. Derechos de los titulares (ARCO)',
                    'Como titular de tus datos personales, tienes derecho a:'
                  ),
                  _buildListItem('Acceder a la información que tenemos sobre ti.'),
                  _buildListItem('Rectificar tus datos si son inexactos, incompletos o desactualizados.'),
                  _buildListItem('Cancelar o suprimir tus datos cuando lo desees (salvo que exista una obligación legal de conservarlos).'),
                  _buildListItem('Oponerte al uso de tus datos para fines que no quieras.'),
                  _buildListItem('Revocar tu autorización en cualquier momento.'),

                  // Sección 6: Seguridad de la información
                  _buildSection(
                    '6. Seguridad de la información',
                    'Insportswear adopta medidas técnicas, administrativas y físicas razonables para proteger tus datos personales contra pérdida, uso indebido, acceso no autorizado, alteración o destrucción.'
                  ),

                  // Sección 7: Actualizaciones de la política
                  _buildSection(
                    '7. Actualizaciones de la política',
                    'Insportswear podrá actualizar esta Política de Privacidad en cualquier momento. Si realizamos cambios importantes, te lo notificaremos por correo electrónico o a través de nuestra página web.'
                  ),



                  SizedBox(height: _getResponsiveSize(context, 50)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}