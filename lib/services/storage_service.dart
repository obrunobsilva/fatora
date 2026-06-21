import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/compra_model.dart';

class StorageService {
  static const String _keyCompras = 'fatora_compras_key';
  static const String _keyConfigurado = 'fatora_configurado_key';
  static const String _keyCartoesLista = 'fatora_cartoes_lista_key';

  static Future<void> salvarConfiguracaoCartoes(
    List<Map<String, dynamic>> cartoes,
  ) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(cartoes);
    await prefs.setString(_keyCartoesLista, jsonString);
    await prefs.setBool(_keyConfigurado, true);
  }

  static Future<bool> isConfigurado() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyConfigurado) ?? false;
  }

  static Future<List<Map<String, dynamic>>> obterConfiguracaoCartoes() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_keyCartoesLista);
    if (jsonString == null) {
      return [
        {'nome': 'Mercado Pago', 'fechamento': 10},
        {'nome': 'Carrefour', 'fechamento': 15},
      ];
    }
    final List<dynamic> listaDecodificada = jsonDecode(jsonString);
    return listaDecodificada
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<void> salvarCompras(List<CompraModel> compras) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> mapaCompras = compras.map((compra) {
      return {
        'id': compra.id,
        'parente': compra.parente,
        'valorTotal': compra.valorTotal,
        'local': compra.local,
        'cartao': compra.cartao,
        'totalParcelas': compra.totalParcelas,
        'dataCompra': compra.dataCompra.toIso8601String(),
      };
    }).toList();
    await prefs.setString(_keyCompras, jsonEncode(mapaCompras));
  }

  static Future<List<CompraModel>> carregarCompras() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_keyCompras);
    if (jsonString == null) return [];
    final List<dynamic> listaDecodificada = jsonDecode(jsonString);
    return listaDecodificada.map((item) {
      return CompraModel(
        id: item['id'],
        parente: item['parente'],
        valorTotal: (item['valorTotal'] as num).toDouble(),
        local: item['local'],
        cartao: item['cartao'],
        totalParcelas: item['totalParcelas'],
        dataCompra: DateTime.parse(item['dataCompra']),
      );
    }).toList();
  }
}
