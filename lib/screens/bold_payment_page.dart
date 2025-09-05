import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class BoldPaymentPage extends StatefulWidget {
  final double totalPrice;
  final int totalItems;

  const BoldPaymentPage({
    Key? key,
    required this.totalPrice,
    required this.totalItems,
  }) : super(key: key);

  @override
  State<BoldPaymentPage> createState() => _BoldPaymentPageState();
}

class _BoldPaymentPageState extends State<BoldPaymentPage> with TickerProviderStateMixin {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  bool _hasError = false;
  late AnimationController _loadingController;
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;

  // Formatear números con formato colombiano
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _slideController.forward();
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // Generar HTML mejorado para el pago Bold
  String get htmlContent {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId ?? '';
    
    return """
    <!DOCTYPE html>
    <html lang="es">
    <head>
      <meta charset="UTF-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <title>Pago Seguro - Bold</title>
      <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
      <style>
        * {
          margin: 0;
          padding: 0;
          box-sizing: border-box;
        }
        
        body {
          font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
          background: #f8f9fa;
          min-height: 100vh;
          display: flex;
          align-items: center;
          justify-content: center;
          padding: 20px;
          color: #2d3748;
        }
        
        .payment-container {
          background: white;
          border-radius: 24px;
          padding: 40px 32px;
          box-shadow: 0 20px 60px rgba(0, 0, 0, 0.15);
          width: 100%;
          max-width: 420px;
          position: relative;
          overflow: hidden;
          animation: slideUp 0.6s ease-out;
        }
        
        .payment-container::before {
          content: '';
          position: absolute;
          top: 0;
          left: 0;
          right: 0;
          height: 4px;
          background: linear-gradient(90deg, #4facfe 0%, #00f2fe 100%);
        }
        
        @keyframes slideUp {
          from {
            opacity: 0;
            transform: translateY(30px);
          }
          to {
            opacity: 1;
            transform: translateY(0);
          }
        }
        
        .payment-header {
          text-align: center;
          margin-bottom: 32px;
        }
        
        .security-badge {
          display: inline-flex;
          align-items: center;
          gap: 8px;
          background: #e6fffa;
          color: #047857;
          padding: 8px 16px;
          border-radius: 20px;
          font-size: 13px;
          font-weight: 500;
          margin-bottom: 20px;
        }
        
        .payment-title {
          font-size: 28px;
          font-weight: 700;
          color: #1a202c;
          margin-bottom: 8px;
          letter-spacing: -0.025em;
        }
        
        .payment-subtitle {
          color: #718096;
          font-size: 16px;
          line-height: 1.5;
        }
        
        .amount-section {
          background: linear-gradient(135deg, #f7fafc 0%, #edf2f7 100%);
          border-radius: 16px;
          padding: 24px;
          margin: 24px 0;
          text-align: center;
          position: relative;
        }
        
        .amount-label {
          color: #718096;
          font-size: 14px;
          font-weight: 500;
          margin-bottom: 8px;
          text-transform: uppercase;
          letter-spacing: 0.05em;
        }
        
        .amount-value {
          font-size: 36px;
          font-weight: 700;
          color: #2d3748;
          margin-bottom: 8px;
          letter-spacing: -0.02em;
        }
        
        .items-count {
          color: #4a5568;
          font-size: 14px;
          font-weight: 500;
        }
        
        .payment-details {
          display: grid;
          gap: 12px;
          margin-bottom: 32px;
        }
        
        .detail-row {
          display: flex;
          justify-content: space-between;
          align-items: center;
          padding: 12px 0;
          border-bottom: 1px solid #e2e8f0;
        }
        
        .detail-row:last-child {
          border-bottom: none;
          font-weight: 600;
          font-size: 16px;
        }
        
        .detail-label {
          color: #718096;
          font-size: 14px;
        }
        
        .detail-value {
          color: #2d3748;
          font-weight: 500;
        }
        
        #contenedorBoton {
          margin-top: 32px;
        }
        
        .loading-state {
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          padding: 32px;
          text-align: center;
        }
        
        .loading-spinner {
          width: 48px;
          height: 48px;
          border: 3px solid #e2e8f0;
          border-top: 3px solid #4facfe;
          border-radius: 50%;
          animation: spin 1s linear infinite;
          margin-bottom: 16px;
        }
        
        @keyframes spin {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }
        
        .loading-text {
          color: #718096;
          font-size: 16px;
          font-weight: 500;
          margin-bottom: 8px;
        }
        
        .loading-subtext {
          color: #a0aec0;
          font-size: 14px;
        }
        
        .error-state {
          text-align: center;
          padding: 32px;
          color: #e53e3e;
        }
        
        .error-icon {
          font-size: 48px;
          margin-bottom: 16px;
        }
        
        .error-title {
          font-size: 18px;
          font-weight: 600;
          margin-bottom: 8px;
        }
        
        .error-message {
          color: #718096;
          font-size: 14px;
          line-height: 1.5;
        }
        
        .retry-button {
          background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
          color: white;
          border: none;
          border-radius: 12px;
          padding: 12px 24px;
          font-size: 14px;
          font-weight: 600;
          cursor: pointer;
          margin-top: 16px;
          transition: transform 0.2s ease;
        }
        
        .retry-button:hover {
          transform: translateY(-2px);
        }
        
        .trust-badges {
          display: flex;
          justify-content: center;
          align-items: center;
          gap: 16px;
          margin-top: 24px;
          padding-top: 20px;
          border-top: 1px solid #e2e8f0;
        }
        
        .trust-badge {
          display: flex;
          align-items: center;
          gap: 6px;
          color: #718096;
          font-size: 12px;
          font-weight: 500;
        }
        
        /* Responsive Design */
        @media (max-width: 480px) {
          body {
            padding: 16px;
          }
          
          .payment-container {
            padding: 32px 24px;
          }
          
          .payment-title {
            font-size: 24px;
          }
          
          .amount-value {
            font-size: 32px;
          }
        }
        
        /* Bold button customization */
        .bold-payment-button {
          width: 100% !important;
          border-radius: 12px !important;
          font-family: 'Inter', sans-serif !important;
          font-weight: 600 !important;
          font-size: 16px !important;
          padding: 16px !important;
          transition: all 0.2s ease !important;
        }
        
        .bold-payment-button:hover {
          transform: translateY(-2px) !important;
          box-shadow: 0 8px 25px rgba(0, 0, 0, 0.15) !important;
        }
      </style>
    </head>
    <body>
      <div class="payment-container">
        <div class="payment-header">
          <div class="security-badge">
            🔒 Pago 100% Seguro
          </div>
          <h1 class="payment-title">Finalizar Compra</h1>
          <p class="payment-subtitle">Completa tu pedido de forma segura</p>
        </div>
        
        <div class="amount-section">
          <div class="amount-label">Total a Pagar</div>
          <div class="amount-value">${_currencyFormat.format(widget.totalPrice)}</div>
          <div class="items-count">${widget.totalItems} ${widget.totalItems == 1 ? 'producto' : 'productos'}</div>
        </div>
        
        <div class="payment-details">
          <div class="detail-row">
            <span class="detail-label">Subtotal</span>
            <span class="detail-value">${_currencyFormat.format(widget.totalPrice)}</span>
          </div>
          <div class="detail-row">
            <span class="detail-label">Total</span>
            <span class="detail-value">${_currencyFormat.format(widget.totalPrice)}</span>
          </div>
        </div>
        
        <div id="contenedorBoton">
          <div class="loading-state">
            <div class="loading-spinner"></div>
            <div class="loading-text">Preparando pago seguro</div>
            <div class="loading-subtext">Conectando con Bold...</div>
          </div>
        </div>
        
        <div class="trust-badges">
          <div class="trust-badge">
            🔒 SSL Seguro
          </div>
          <div class="trust-badge">
            💳 Bold Payments
          </div>
          <div class="trust-badge">
            ✅ Verificado
          </div>
        </div>
      </div>
      
      <script>
        let retryCount = 0;
        const maxRetries = 3;
        
        async function generarBotonBold() {
          try {
            console.log("👉 Iniciando carga del botón Bold... (Intento:", retryCount + 1, ")");
            const userId = "$userId";
            console.log("📌 userId recibido:", userId);

            // Mostrar estado de carga mejorado
            const contenedor = document.getElementById("contenedorBoton");
            contenedor.innerHTML = 
              '<div class="loading-state">' +
                '<div class="loading-spinner"></div>' +
                '<div class="loading-text">Procesando solicitud</div>' +
                '<div class="loading-subtext">Generando token de seguridad...</div>' +
              '</div>';

            const res = await fetch("https://curly-waterfall-fee6.cr6145396.workers.dev/pago/firma/generar-firma", {
              method: "POST",
              headers: { 
                "Content-Type": "application/json",
                "Accept": "application/json"
              },
              body: JSON.stringify({ userId })
            });

            console.log("📡 Respuesta fetch Bold:", res.status);

            if (!res.ok) {
              throw new Error("Error HTTP: " + res.status + " - " + res.statusText);
            }

            const data = await res.json();
            console.log("✅ Datos de firma recibidos:", data);

            const { orderId, amount, currency, firma } = data;

            // Validar datos recibidos
            if (!orderId || !amount || !currency || !firma) {
              throw new Error("Datos de pago incompletos recibidos del servidor");
            }

            // Actualizar estado a "Cargando botón"
            contenedor.innerHTML = 
              '<div class="loading-state">' +
                '<div class="loading-spinner"></div>' +
                '<div class="loading-text">Cargando método de pago</div>' +
                '<div class="loading-subtext">Inicializando Bold Checkout...</div>' +
              '</div>';

            // Limpiar el contenedor después de un breve delay para mejor UX
            setTimeout(() => {
              contenedor.innerHTML = "";

              const botonScript = document.createElement("script");
              botonScript.src = "https://checkout.bold.co/library/boldPaymentButton.js";
              botonScript.setAttribute("data-bold-button", "dark-L");
              botonScript.setAttribute("data-api-key", "dcS3rZFaDw3dNa7nYM88pBsnL5Gz093pVirfSeafIBU");
              botonScript.setAttribute("data-order-id", orderId);
              botonScript.setAttribute("data-amount", amount);
              botonScript.setAttribute("data-currency", currency);
              botonScript.setAttribute("data-integrity-signature", firma);
              botonScript.setAttribute("type", "text/javascript");

              // Agregar evento de carga del script
              botonScript.onload = () => {
                console.log("✅ Script Bold cargado correctamente");
                // Aplicar estilos personalizados al botón cuando esté listo
                setTimeout(() => {
                  const boldButton = contenedor.querySelector('button, input[type="button"], .bold-button');
                  if (boldButton) {
                    boldButton.classList.add('bold-payment-button');
                  }
                }, 500);
              };

              botonScript.onerror = () => {
                console.error("❌ Error cargando el script de Bold");
                mostrarError("Error cargando el sistema de pagos");
              };

              contenedor.appendChild(botonScript);
              console.log("✅ Botón Bold insertado en el DOM");
            }, 800);

          } catch (err) {
            console.error("❌ Error generando botón Bold:", err);
            retryCount++;
            
            if (retryCount < maxRetries) {
              mostrarError("Error de conexión. Reintentando... (" + retryCount + "/3)", true);
              setTimeout(generarBotonBold, 2000);
            } else {
              mostrarError("No se pudo cargar el sistema de pagos. Verifica tu conexión e intenta nuevamente.");
            }
          }
        }
        
        function mostrarError(mensaje, esReintentoAutomatico = false) {
          const contenedor = document.getElementById("contenedorBoton");
          contenedor.innerHTML = 
            '<div class="error-state">' +
              '<div class="error-icon">⚠️</div>' +
              '<div class="error-title">Error de Conexión</div>' +
              '<div class="error-message">' + mensaje + '</div>' +
              (!esReintentoAutomatico ? '<button class="retry-button" onclick="reintentar()">Intentar Nuevamente</button>' : '') +
            '</div>';
        }
        
        function reintentar() {
          retryCount = 0;
          generarBotonBold();
        }
        
        // Cargar el botón cuando la página esté lista
        if (document.readyState === 'loading') {
          document.addEventListener('DOMContentLoaded', generarBotonBold);
        } else {
          generarBotonBold();
        }

        // Notificar a Flutter sobre cambios de estado
        window.addEventListener('load', () => {
          if (window.flutter_inappwebview) {
            window.flutter_inappwebview.callHandler('onPageReady');
          }
        });
      </script>
    </body>
    </html>
    """;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFf8f9fa),
      body: SafeArea(
        child: Column(
          children: [
            // Header mejorado con animación
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -1),
                end: Offset.zero,
              ).animate(_slideAnimation),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 30 : 20,
                  vertical: isTablet ? 24 : 20,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFf7fafc),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          color: const Color(0xFF2d3748),
                          size: isTablet ? 24 : 20,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Pago Seguro',
                            style: TextStyle(
                              fontSize: isTablet ? 24 : 20,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1a202c),
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            _currencyFormat.format(widget.totalPrice),
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4facfe),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFe6fffa),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.security,
                        color: const Color(0xFF047857),
                        size: isTablet ? 24 : 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // WebView del pago con mejor contenedor
            Expanded(
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(_slideAnimation),
                child: Container(
                  margin: EdgeInsets.all(isTablet ? 24 : 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(isTablet ? 28 : 24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(isTablet ? 28 : 24),
                    child: Stack(
                      children: [
                        InAppWebView(
                          initialData: InAppWebViewInitialData(data: htmlContent),
                          initialOptions: InAppWebViewGroupOptions(
                            crossPlatform: InAppWebViewOptions(
                              javaScriptEnabled: true,
                              useOnDownloadStart: true,
                              useOnLoadResource: true,
                              useShouldOverrideUrlLoading: true,
                              mediaPlaybackRequiresUserGesture: false,
                              transparentBackground: true,
                            ),
                            android: AndroidInAppWebViewOptions(
                              useHybridComposition: true,
                              allowContentAccess: true,
                              allowFileAccess: true,
                              domStorageEnabled: true,
                              databaseEnabled: true,
                              mixedContentMode: AndroidMixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                            ),
                            ios: IOSInAppWebViewOptions(
                              allowsInlineMediaPlayback: true,
                              allowsBackForwardNavigationGestures: true,
                              disallowOverScroll: true,
                            ),
                          ),
                          onWebViewCreated: (InAppWebViewController controller) {
                            _webViewController = controller;
                            
                            // Registrar handler para comunicación con JavaScript
                            controller.addJavaScriptHandler(
                              handlerName: 'onPageReady',
                              callback: (args) {
                                setState(() {
                                  _isLoading = false;
                                });
                              },
                            );
                          },
                          onLoadStart: (InAppWebViewController controller, Uri? url) {
                            debugPrint("🌍 Pago - Página comenzó a cargar: $url");
                            setState(() {
                              _isLoading = true;
                              _hasError = false;
                            });
                          },
                          onLoadStop: (InAppWebViewController controller, Uri? url) async {
                            debugPrint("✅ Pago - Página terminó de cargar: $url");
                            
                            // Auto-hide loading después de 3 segundos como fallback
                            Future.delayed(const Duration(seconds: 3), () {
                              if (mounted && _isLoading) {
                                setState(() {
                                  _isLoading = false;
                                });
                              }
                            });
                          },
                          onLoadError: (InAppWebViewController controller, Uri? url, int code, String message) {
                            debugPrint("❌ Pago - Error cargando página: $code - $message");
                            setState(() {
                              _isLoading = false;
                              _hasError = true;
                            });
                          },
                          onConsoleMessage: (InAppWebViewController controller, ConsoleMessage consoleMessage) {
                            debugPrint("📱 Console: ${consoleMessage.message}");
                          },
                          shouldOverrideUrlLoading: (controller, navigationAction) async {
                            var uri = navigationAction.request.url!;
                            
                            // Permitir URLs relacionadas con Bold y tu API
                            if (uri.host.contains('bold.co') || 
                                uri.host.contains('checkout.bold.co') ||
                                uri.host.contains('curly-waterfall-fee6.cr6145396.workers.dev')) {
                              return NavigationActionPolicy.ALLOW;
                            }
                            
                            debugPrint("🔄 Pago - Navegando a: $uri");
                            return NavigationActionPolicy.ALLOW;
                          },
                        ),
                        
                        // Indicador de carga superpuesto
                        if (_isLoading)
                          Container(
                            color: Colors.white.withOpacity(0.9),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedBuilder(
                                    animation: _loadingController,
                                    builder: (context, child) {
                                      return Transform.rotate(
                                        angle: _loadingController.value * 2.0 * 3.14159,
                                        child: Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                                            ),
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                          child: const Icon(
                                            Icons.payment,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Cargando pago seguro...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF4a5568),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Conectando con Bold',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF718096),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Footer con información de seguridad
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(_slideAnimation),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 30 : 20,
                  vertical: isTablet ? 20 : 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: isTablet ? 20 : 18,
                      color: const Color(0xFF718096),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Pago protegido por Bold • SSL 256-bit',
                      style: TextStyle(
                        color: const Color(0xFF718096),
                        fontSize: isTablet ? 14 : 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}