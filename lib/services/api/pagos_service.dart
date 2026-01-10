import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/pago.dart';
import '../../providers/providers.dart';

class PagosService {
  final Dio _dio;

  PagosService(this._dio);

  // ============================================================================
  // TIPO DE CAMBIO
  // ============================================================================

  /// Obtener tipo de cambio actual USD/NIO
  Future<TipoCambio> getTipoCambio() async {
    try {
      final response = await _dio.get('/pagos/tipo-cambio');

      if (response.data['success'] == true) {
        return TipoCambio.fromJson(response.data['data']);
      }
      return _defaultTipoCambio();
    } on DioException {
      return _defaultTipoCambio();
    }
  }

  TipoCambio _defaultTipoCambio() {
    return TipoCambio(
      compra: 36.32,
      venta: 36.80,
      tipoCambio: 36.80,
      monedaBase: 'USD',
      monedaDestino: 'NIO',
    );
  }

  // ============================================================================
  // FACTURAS PARA PAGO
  // ============================================================================

  /// Obtener facturas de un cliente con saldo pendiente
  Future<ClienteConFacturas?> getFacturasCliente(int clienteId) async {
    try {
      final response = await _dio.get('/pagos/facturas-cliente/$clienteId');

      if (response.data['success'] == true) {
        return ClienteConFacturas.fromJson(response.data['data']);
      }
      return null;
    } on DioException {
      return null;
    }
  }

  /// Obtener todas las facturas pendientes
  Future<List<FacturaParaPago>> getFacturasPendientes({
    int limite = 50,
    String? busqueda,
  }) async {
    try {
      final queryParams = {
        'limite': limite,
        if (busqueda != null && busqueda.isNotEmpty) 'busqueda': busqueda,
      };

      final response = await _dio.get('/pagos/facturas-pendientes', queryParameters: queryParams);

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((e) => FacturaParaPago.fromJson(e)).toList();
      }
      return [];
    } on DioException {
      return [];
    }
  }

  // ============================================================================
  // REGISTRAR PAGOS
  // ============================================================================

  /// Registrar pago individual (una factura)
  Future<Map<String, dynamic>?> registrarPago({
    required int facturaId,
    required double monto,
    required String moneda,
    required String tipoPago,
    String? banco,
    String? tipoCuenta,
    double? montoCordobasFisico,
    double? montoDolaresFisico,
    double? montoCordobasElectronico,
    double? montoDolaresElectronico,
    double? montoRecibido,
    double? vuelto,
    double? tipoCambio,
    String? observaciones,
  }) async {
    try {
      final body = {
        'facturaId': facturaId,
        'monto': monto,
        'moneda': moneda,
        'tipoPago': tipoPago,
        if (banco != null) 'banco': banco,
        if (tipoCuenta != null) 'tipoCuenta': tipoCuenta,
        if (montoCordobasFisico != null) 'montoCordobasFisico': montoCordobasFisico,
        if (montoDolaresFisico != null) 'montoDolaresFisico': montoDolaresFisico,
        if (montoCordobasElectronico != null) 'montoCordobasElectronico': montoCordobasElectronico,
        if (montoDolaresElectronico != null) 'montoDolaresElectronico': montoDolaresElectronico,
        if (montoRecibido != null) 'montoRecibido': montoRecibido,
        if (vuelto != null) 'vuelto': vuelto,
        if (tipoCambio != null) 'tipoCambio': tipoCambio,
        if (observaciones != null && observaciones.isNotEmpty) 'observaciones': observaciones,
      };

      final response = await _dio.post('/pagos', data: body);
      
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      return null;
    } on DioException {
      return null;
    }
  }

  /// Registrar pago múltiple (varias facturas)
  Future<Map<String, dynamic>?> registrarPagoMultiple({
    required List<int> facturaIds,
    required double montoTotal,
    required String moneda,
    required String tipoPago,
    String? banco,
    String? tipoCuenta,
    double? montoCordobasFisico,
    double? montoDolaresFisico,
    double? montoCordobasElectronico,
    double? montoDolaresElectronico,
    double? montoRecibido,
    double? vuelto,
    double? tipoCambio,
    String? observaciones,
  }) async {
    try {
      final body = {
        'facturaIds': facturaIds,
        'montoTotal': montoTotal,
        'moneda': moneda,
        'tipoPago': tipoPago,
        if (banco != null) 'banco': banco,
        if (tipoCuenta != null) 'tipoCuenta': tipoCuenta,
        if (montoCordobasFisico != null) 'montoCordobasFisico': montoCordobasFisico,
        if (montoDolaresFisico != null) 'montoDolaresFisico': montoDolaresFisico,
        if (montoCordobasElectronico != null) 'montoCordobasElectronico': montoCordobasElectronico,
        if (montoDolaresElectronico != null) 'montoDolaresElectronico': montoDolaresElectronico,
        if (montoRecibido != null) 'montoRecibido': montoRecibido,
        if (vuelto != null) 'vuelto': vuelto,
        if (tipoCambio != null) 'tipoCambio': tipoCambio,
        if (observaciones != null && observaciones.isNotEmpty) 'observaciones': observaciones,
      };

      final response = await _dio.post('/pagos/multiples', data: body);
      
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      return null;
    } on DioException {
      return null;
    }
  }

  // ============================================================================
  // ESTADÍSTICAS Y REPORTES
  // ============================================================================

  /// Resumen del día
  Future<ResumenDia?> getResumenDia({DateTime? fecha}) async {
    try {
      final queryParams = fecha != null 
          ? {'fecha': fecha.toIso8601String().split('T')[0]} 
          : null;

      final response = await _dio.get('/pagos/resumen-dia', queryParameters: queryParams);

      if (response.data['success'] == true) {
        return ResumenDia.fromJson(response.data['data']);
      }
      return null;
    } on DioException {
      return null;
    }
  }

  /// Resumen por período
  Future<Map<String, dynamic>?> getResumenPeriodo({int? mes, int? anio}) async {
    try {
      final queryParams = {
        if (mes != null) 'mes': mes,
        if (anio != null) 'anio': anio,
      };

      final response = await _dio.get('/pagos/resumen-periodo', queryParameters: queryParams);

      if (response.data['success'] == true) {
        return response.data['data'];
      }
      return null;
    } on DioException {
      return null;
    }
  }

  /// Total ingresos
  Future<Map<String, dynamic>?> getTotalIngresos() async {
    try {
      final response = await _dio.get('/pagos/total-ingresos');

      if (response.data['success'] == true) {
        return response.data['data'];
      }
      return null;
    } on DioException {
      return null;
    }
  }

  /// Estadísticas completas
  Future<Map<String, dynamic>?> getEstadisticas() async {
    try {
      final response = await _dio.get('/pagos/estadisticas');

      if (response.data['success'] == true) {
        return response.data['data'];
      }
      return null;
    } on DioException {
      return null;
    }
  }

  // ============================================================================
  // LISTADO Y BÚSQUEDA
  // ============================================================================

  /// Listar pagos con filtros
  Future<PagosResponse> getPagos({
    int pagina = 1,
    int tamanoPagina = 20,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? tipoPago,
    String? banco,
  }) async {
    try {
      final queryParams = {
        'pagina': pagina,
        'tamanoPagina': tamanoPagina,
        if (fechaInicio != null) 'fechaInicio': fechaInicio.toIso8601String(),
        if (fechaFin != null) 'fechaFin': fechaFin.toIso8601String(),
        if (tipoPago != null) 'tipoPago': tipoPago,
        if (banco != null) 'banco': banco,
      };

      final response = await _dio.get('/pagos', queryParameters: queryParams);

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        final pagination = response.data['pagination'];

        return PagosResponse(
          pagos: data.map((e) => Pago.fromJson(e)).toList(),
          currentPage: pagination?['currentPage'] ?? 1,
          totalPages: pagination?['totalPages'] ?? 1,
          totalItems: pagination?['totalItems'] ?? 0,
        );
      }
      return PagosResponse(pagos: [], currentPage: 1, totalPages: 1, totalItems: 0);
    } on DioException {
      return PagosResponse(pagos: [], currentPage: 1, totalPages: 1, totalItems: 0);
    }
  }

  /// Buscar pagos
  Future<List<Pago>> buscarPagos(String termino, {int limite = 20}) async {
    try {
      final response = await _dio.get(
        '/pagos/buscar',
        queryParameters: {'q': termino, 'limite': limite},
      );

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((e) => Pago.fromJson(e)).toList();
      }
      return [];
    } on DioException {
      return [];
    }
  }

  // ============================================================================
  // ELIMINAR
  // ============================================================================

  /// Eliminar pago individual
  Future<bool> eliminarPago(int id) async {
    try {
      final response = await _dio.delete('/pagos/$id');
      return response.data['success'] == true;
    } on DioException {
      return false;
    }
  }

  /// Eliminar múltiples pagos
  Future<Map<String, dynamic>?> eliminarPagosMultiples(List<int> pagoIds) async {
    try {
      final response = await _dio.delete(
        '/pagos/multiples',
        data: {'pagoIds': pagoIds},
      );

      if (response.data['success'] == true) {
        return response.data['data'];
      }
      return null;
    } on DioException {
      return null;
    }
  }
}

class PagosResponse {
  final List<Pago> pagos;
  final int currentPage;
  final int totalPages;
  final int totalItems;

  PagosResponse({
    required this.pagos,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
  });
}

// Provider
final pagosServiceProvider = Provider<PagosService>((ref) {
  final dio = ref.watch(dioProvider);
  return PagosService(dio);
});
