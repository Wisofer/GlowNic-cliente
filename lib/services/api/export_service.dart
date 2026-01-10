import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../providers/providers.dart';

class ExportService {
  final Dio _dio;

  ExportService(this._dio);

  /// Exportar citas
  Future<File> exportAppointments({
    String format = 'csv',
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{'format': format};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final response = await _dio.get(
        '/barber/export/appointments',
        queryParameters: queryParams,
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );

      
      // Validar que la respuesta sea exitosa y tenga datos
      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'Error al exportar citas: Status ${response.statusCode}',
        );
      }
      
      // Validar que response.data sea una lista de bytes
      if (response.data == null || !(response.data is List<int>)) {
        throw Exception('Respuesta inválida del servidor: se esperaba un archivo');
      }
      
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().split('T')[0].replaceAll('-', '');
      final extension = format == 'excel' ? 'xlsx' : format;
      final file = File('${directory.path}/citas_$timestamp.$extension');
      await file.writeAsBytes(response.data as List<int>);
      
      return file;
    } on DioException catch (e) {
      
      // Intentar decodificar el mensaje de error si viene en bytes
      String errorMessage = 'Error al exportar citas';
      if (e.response?.data != null) {
        try {
          if (e.response!.data is List<int>) {
            final bytes = e.response!.data as List<int>;
            final jsonString = utf8.decode(bytes);
            final jsonData = json.decode(jsonString);
            errorMessage = jsonData['message'] ?? errorMessage;
          } else if (e.response!.data is Map) {
            errorMessage = e.response!.data['message'] ?? errorMessage;
          } else if (e.response!.data is String) {
            errorMessage = e.response!.data;
          }
        } catch (decodeError) {
        }
      }
      
      // Lanzar una excepción con el mensaje decodificado
      throw DioException(
        requestOptions: e.requestOptions,
        response: e.response,
        type: e.type,
        error: e.error,
        message: errorMessage,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Exportar finanzas
  Future<File> exportFinances({
    String format = 'csv',
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{'format': format};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final response = await _dio.get(
        '/barber/export/finances',
        queryParameters: queryParams,
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );

      
      // Validar que la respuesta sea exitosa y tenga datos
      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'Error al exportar finanzas: Status ${response.statusCode}',
        );
      }
      
      // Validar que response.data sea una lista de bytes
      if (response.data == null || !(response.data is List<int>)) {
        throw Exception('Respuesta inválida del servidor: se esperaba un archivo');
      }
      
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().split('T')[0].replaceAll('-', '');
      final extension = format == 'excel' ? 'xlsx' : format;
      final file = File('${directory.path}/finanzas_$timestamp.$extension');
      await file.writeAsBytes(response.data as List<int>);
      
      return file;
    } on DioException catch (e) {
      
      String errorMessage = 'Error al exportar finanzas';
      if (e.response?.data != null) {
        try {
          if (e.response!.data is List<int>) {
            final bytes = e.response!.data as List<int>;
            final jsonString = utf8.decode(bytes);
            final jsonData = json.decode(jsonString);
            errorMessage = jsonData['message'] ?? errorMessage;
          } else if (e.response!.data is Map) {
            errorMessage = e.response!.data['message'] ?? errorMessage;
          } else if (e.response!.data is String) {
            errorMessage = e.response!.data;
          }
        } catch (decodeError) {
        }
      }
      
      throw DioException(
        requestOptions: e.requestOptions,
        response: e.response,
        type: e.type,
        error: e.error,
        message: errorMessage,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Exportar clientes
  Future<File> exportClients({String format = 'csv'}) async {
    try {
      final response = await _dio.get(
        '/barber/export/clients',
        queryParameters: {'format': format},
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );

      
      // Validar que la respuesta sea exitosa y tenga datos
      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'Error al exportar clientes: Status ${response.statusCode}',
        );
      }
      
      // Validar que response.data sea una lista de bytes
      if (response.data == null || !(response.data is List<int>)) {
        throw Exception('Respuesta inválida del servidor: se esperaba un archivo');
      }
      
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().split('T')[0].replaceAll('-', '');
      final extension = format == 'excel' ? 'xlsx' : format;
      final file = File('${directory.path}/clientes_$timestamp.$extension');
      await file.writeAsBytes(response.data as List<int>);
      
      return file;
    } on DioException catch (e) {
      
      String errorMessage = 'Error al exportar clientes';
      if (e.response?.data != null) {
        try {
          if (e.response!.data is List<int>) {
            final bytes = e.response!.data as List<int>;
            final jsonString = utf8.decode(bytes);
            final jsonData = json.decode(jsonString);
            errorMessage = jsonData['message'] ?? errorMessage;
          } else if (e.response!.data is Map) {
            errorMessage = e.response!.data['message'] ?? errorMessage;
          } else if (e.response!.data is String) {
            errorMessage = e.response!.data;
          }
        } catch (decodeError) {
        }
      }
      
      throw DioException(
        requestOptions: e.requestOptions,
        response: e.response,
        type: e.type,
        error: e.error,
        message: errorMessage,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Crear backup completo
  Future<File> exportBackup() async {
    try {
      final response = await _dio.get(
        '/barber/export/backup',
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );

      
      // Validar que la respuesta sea exitosa y tenga datos
      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'Error al crear backup: Status ${response.statusCode}',
        );
      }
      
      // Validar que response.data sea una lista de bytes
      if (response.data == null || !(response.data is List<int>)) {
        throw Exception('Respuesta inválida del servidor: se esperaba un archivo');
      }
      
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '').split('.')[0];
      final file = File('${directory.path}/backup_$timestamp.json');
      await file.writeAsBytes(response.data as List<int>);
      
      return file;
    } on DioException catch (e) {
      
      String errorMessage = 'Error al crear backup';
      if (e.response?.data != null) {
        try {
          if (e.response!.data is List<int>) {
            final bytes = e.response!.data as List<int>;
            final jsonString = utf8.decode(bytes);
            final jsonData = json.decode(jsonString);
            errorMessage = jsonData['message'] ?? errorMessage;
          } else if (e.response!.data is Map) {
            errorMessage = e.response!.data['message'] ?? errorMessage;
          } else if (e.response!.data is String) {
            errorMessage = e.response!.data;
          }
        } catch (decodeError) {
        }
      }
      
      throw DioException(
        requestOptions: e.requestOptions,
        response: e.response,
        type: e.type,
        error: e.error,
        message: errorMessage,
      );
    } catch (e) {
      rethrow;
    }
  }
}

final exportServiceProvider = Provider<ExportService>((ref) {
  final dio = ref.watch(dioProvider);
  return ExportService(dio);
});

