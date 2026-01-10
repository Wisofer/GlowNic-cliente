import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/cliente.dart';
import '../../providers/providers.dart';

class ClientesService {
  final Dio _dio;

  ClientesService(this._dio);

  /// Listar clientes con paginación y búsqueda
  Future<ClientesResponse> getClientes({
    int pagina = 1,
    int tamanoPagina = 20,
    String? busqueda,
    String? estado,
  }) async {
    try {
      final queryParams = {
        'pagina': pagina,
        'tamanoPagina': tamanoPagina,
        if (busqueda != null && busqueda.isNotEmpty) 'busqueda': busqueda,
        if (estado != null) 'estado': estado,
      };

      final response = await _dio.get('/clientes', queryParameters: queryParams);

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        final pagination = response.data['pagination'];

        return ClientesResponse(
          clientes: data.map((e) => Cliente.fromJson(e)).toList(),
          currentPage: pagination?['currentPage'] ?? 1,
          totalPages: pagination?['totalPages'] ?? 1,
          totalItems: pagination?['totalItems'] ?? 0,
        );
      }
      throw Exception(response.data['message'] ?? 'Error al cargar clientes');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error de conexión');
    }
  }

  /// Buscar clientes por término
  Future<List<Cliente>> buscarClientes(String termino) async {
    try {
      final response = await _dio.get('/clientes/buscar', queryParameters: {'q': termino});

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((e) => Cliente.fromJson(e)).toList();
      }
      return [];
    } on DioException {
      return [];
    }
  }

  /// Obtener cliente por ID
  Future<Cliente> getCliente(int id) async {
    try {
      final response = await _dio.get('/clientes/$id');

      if (response.data['success'] == true) {
        return Cliente.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Cliente no encontrado');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error de conexión');
    }
  }

  /// Estadísticas de clientes
  Future<Map<String, dynamic>> getEstadisticas() async {
    try {
      final response = await _dio.get('/clientes/estadisticas');

      if (response.data['success'] == true) {
        return response.data['data'] ?? {};
      }
      return {};
    } on DioException {
      return {};
    }
  }
}

class ClientesResponse {
  final List<Cliente> clientes;
  final int currentPage;
  final int totalPages;
  final int totalItems;

  ClientesResponse({
    required this.clientes,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
  });
}

// Provider
final clientesServiceProvider = Provider<ClientesService>((ref) {
  final dio = ref.watch(dioProvider);
  return ClientesService(dio);
});

