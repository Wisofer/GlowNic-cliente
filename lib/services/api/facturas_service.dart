import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/factura.dart';
import '../../providers/providers.dart';

class FacturasService {
  final Dio _dio;

  FacturasService(this._dio);

  /// Listar facturas con paginación y filtros
  Future<FacturasResponse> getFacturas({
    int pagina = 1,
    int tamanoPagina = 20,
    String? estado,
    String? categoria,
    int? mes,
    int? anio,
  }) async {
    try {
      final queryParams = {
        'pagina': pagina,
        'tamanoPagina': tamanoPagina,
        if (estado != null) 'estado': estado,
        if (categoria != null) 'categoria': categoria,
        if (mes != null) 'mes': mes,
        if (anio != null) 'anio': anio,
      };

      final response = await _dio.get('/facturas', queryParameters: queryParams);

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        final pagination = response.data['pagination'];

        return FacturasResponse(
          facturas: data.map((e) => Factura.fromJson(e)).toList(),
          currentPage: pagination?['currentPage'] ?? 1,
          totalPages: pagination?['totalPages'] ?? 1,
          totalItems: pagination?['totalItems'] ?? 0,
        );
      }
      throw Exception(response.data['message'] ?? 'Error al cargar facturas');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error de conexión');
    }
  }

  /// Obtener factura por ID
  Future<Factura> getFactura(int id) async {
    try {
      final response = await _dio.get('/facturas/$id');

      if (response.data['success'] == true) {
        return Factura.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Factura no encontrada');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error de conexión');
    }
  }

  /// Facturas de un cliente específico
  Future<List<Factura>> getFacturasCliente(int clienteId, {String? estado}) async {
    try {
      final queryParams = estado != null ? {'estado': estado} : null;
      final response = await _dio.get(
        '/facturas/cliente/$clienteId',
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((e) => Factura.fromJson(e)).toList();
      }
      return [];
    } on DioException {
      return [];
    }
  }

  /// Facturas pendientes
  Future<List<Factura>> getFacturasPendientes({int limite = 50}) async {
    try {
      final response = await _dio.get(
        '/facturas/pendientes',
        queryParameters: {'limite': limite},
      );

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((e) => Factura.fromJson(e)).toList();
      }
      return [];
    } on DioException {
      return [];
    }
  }

  /// Estadísticas de facturas
  Future<Map<String, dynamic>> getEstadisticas() async {
    try {
      final response = await _dio.get('/facturas/estadisticas');

      if (response.data['success'] == true) {
        return response.data['data'] ?? {};
      }
      return {};
    } on DioException {
      return {};
    }
  }
}

class FacturasResponse {
  final List<Factura> facturas;
  final int currentPage;
  final int totalPages;
  final int totalItems;

  FacturasResponse({
    required this.facturas,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
  });
}

// Provider
final facturasServiceProvider = Provider<FacturasService>((ref) {
  final dio = ref.watch(dioProvider);
  return FacturasService(dio);
});

