import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/compra_model.dart';
import '../utils/formatadores.dart';

class StorageService {
  static const String _keyCompras = 'fatora_compras_key';
  static const String _keyConfigurado = 'fatora_configurado_key';
  static const String _keyCartoesLista = 'fatora_cartoes_lista_key';
  static const String _keyVersao = 'fatora_schema_versao';
  static const int _versaoAtual = 2;

  // ---------------------------------------------------------------
  // Migração v1 -> v2 (roda uma vez, no main)
  // ---------------------------------------------------------------

  /// Converte os dados antigos preservando o comportamento atual do app:
  /// - cartões com "fechamento" > 10 eram tratados como vencimento
  ///   (fechamento = valor - 10); o valor já é convertido aqui;
  /// - valores em reais (double) viram centavos (int);
  /// - nomes de pessoas e de cartões são unificados (Maria = maria);
  /// - guarda uma cópia dos dados originais em chaves *_backup_v1.
  static Future<void> migrar() async {
    final prefs = await SharedPreferences.getInstance();
    final versao = prefs.getInt(_keyVersao) ?? 1;
    if (versao >= _versaoAtual) return;

    try {
      final comprasBruto = prefs.getString(_keyCompras);
      final cartoesBruto = prefs.getString(_keyCartoesLista);

      if (comprasBruto != null) {
        await prefs.setString('${_keyCompras}_backup_v1', comprasBruto);
      }
      if (cartoesBruto != null) {
        await prefs.setString('${_keyCartoesLista}_backup_v1', cartoesBruto);
      }

      // Tudo é calculado em memória primeiro; só depois grava.
      List<Map<String, dynamic>>? cartoesNovos;
      if (cartoesBruto != null) {
        cartoesNovos = (jsonDecode(cartoesBruto) as List).map((item) {
          final c = Map<String, dynamic>.from(item as Map);
          final f = (c['fechamento'] as num).toInt();
          return <String, dynamic>{
            'nome': c['nome'],
            'fechamento': f > 10 ? f - 10 : f,
          };
        }).toList();
      }

      List<CompraModel>? comprasNovas;
      if (comprasBruto != null) {
        final compras = (jsonDecode(comprasBruto) as List)
            .map(
              (e) => CompraModel.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
        comprasNovas = _unificarNomes(
          compras,
          (cartoesNovos ?? []).map((c) => c['nome'] as String).toList(),
        );
        ordenar(comprasNovas);
      }

      if (cartoesNovos != null) {
        await prefs.setString(_keyCartoesLista, jsonEncode(cartoesNovos));
      }
      if (comprasNovas != null) {
        await prefs.setString(
          _keyCompras,
          jsonEncode(comprasNovas.map((c) => c.toJson()).toList()),
        );
      }
      await prefs.setInt(_keyVersao, _versaoAtual);
    } catch (e) {
      // Não grava a versão: tenta de novo na próxima abertura.
      // Os dados originais continuam intactos.
      debugPrint('Falha na migração (dados originais preservados): $e');
    }
  }

  static List<CompraModel> _unificarNomes(
    List<CompraModel> compras,
    List<String> nomesCartoes,
  ) {
    // Pessoas: vence a grafia mais frequente.
    final contagem = <String, Map<String, int>>{};
    for (final c in compras) {
      final nome = limparNome(c.parente);
      final grafias = contagem.putIfAbsent(chaveNome(nome), () => {});
      grafias[nome] = (grafias[nome] ?? 0) + 1;
    }
    final canonicoPessoa = <String, String>{};
    contagem.forEach((chave, grafias) {
      final ordenadas = grafias.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      canonicoPessoa[chave] = ordenadas.first.key;
    });

    // Cartões: vale a grafia cadastrada na lista de cartões.
    final canonicoCartao = <String, String>{
      for (final n in nomesCartoes) chaveNome(n): n,
    };

    return compras.map((c) {
      return c.copyWith(
        parente: canonicoPessoa[chaveNome(c.parente)] ?? c.parente,
        cartao: canonicoCartao[chaveNome(c.cartao)] ?? c.cartao,
      );
    }).toList();
  }

  // ---------------------------------------------------------------
  // Cartões
  // ---------------------------------------------------------------

  static Future<void> salvarConfiguracaoCartoes(
    List<Map<String, dynamic>> cartoes,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCartoesLista, jsonEncode(cartoes));
    await prefs.setBool(_keyConfigurado, true);
  }

  static Future<bool> isConfigurado() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyConfigurado) ?? false;
  }

  /// Cada cartão: {'nome': String, 'fechamento': int}.
  /// "fechamento" = melhor dia de compra (primeiro dia que cai na próxima fatura).
  static Future<List<Map<String, dynamic>>> obterConfiguracaoCartoes() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_keyCartoesLista);
    if (texto == null) return [];
    return (jsonDecode(texto) as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  // ---------------------------------------------------------------
  // Compras
  // ---------------------------------------------------------------

  static Future<void> salvarCompras(List<CompraModel> compras) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyCompras,
      jsonEncode(compras.map((c) => c.toJson()).toList()),
    );
  }

  /// Lança exceção se os dados estiverem corrompidos (a tela mostra o erro).
  static Future<List<CompraModel>> carregarCompras() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_keyCompras);
    if (texto == null) return [];
    return (jsonDecode(texto) as List)
        .map((e) => CompraModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Mais recentes primeiro. Use sempre este método para ordenar.
  static void ordenar(List<CompraModel> compras) {
    compras.sort((a, b) => b.dataCompra.compareTo(a.dataCompra));
  }

  static String novoId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(100000)}';

  /// Pessoas já cadastradas (sem repetir "Maria"/"maria"), em ordem alfabética.
  static List<String> nomesPessoas(Iterable<CompraModel> compras) {
    final mapa = <String, String>{};
    for (final c in compras) {
      mapa.putIfAbsent(chaveNome(c.parente), () => limparNome(c.parente));
    }
    return mapa.values.toList()
      ..sort((a, b) => chaveNome(a).compareTo(chaveNome(b)));
  }

  // ---------------------------------------------------------------
  // Backup (sem nuvem): texto JSON que a pessoa copia e cola
  // ---------------------------------------------------------------

  static Future<String> exportarBackup() async {
    final cartoes = await obterConfiguracaoCartoes();
    final compras = await carregarCompras();
    return jsonEncode({
      'app': 'fatora',
      'versao': _versaoAtual,
      'exportadoEm': DateTime.now().toIso8601String(),
      'cartoes': cartoes,
      'compras': compras.map((c) => c.toJson()).toList(),
    });
  }

  /// Substitui TODOS os dados atuais. Valida tudo antes de gravar.
  /// Lança FormatException se o texto não for um backup válido.
  /// Devolve quantas compras foram importadas.
  static Future<int> importarBackup(String texto) async {
    late final List<Map<String, dynamic>> cartoes;
    late final List<CompraModel> compras;
    try {
      final dados = jsonDecode(texto.trim());
      if (dados is! Map ||
          dados['app'] != 'fatora' ||
          dados['versao'] != _versaoAtual) {
        throw const FormatException('Backup inválido');
      }
      cartoes = (dados['cartoes'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      for (final c in cartoes) {
        final nome = c['nome'];
        final dia = c['fechamento'];
        if (nome is! String ||
            nome.trim().isEmpty ||
            dia is! int ||
            dia < 1 ||
            dia > 31) {
          throw const FormatException('Cartão inválido');
        }
      }
      if (cartoes.isEmpty) throw const FormatException('Sem cartões');
      compras = (dados['compras'] as List)
          .map((e) => CompraModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Backup inválido');
    }

    final prefs = await SharedPreferences.getInstance();
    // Cópia de segurança do que existia antes.
    final atual = prefs.getString(_keyCompras);
    if (atual != null) {
      await prefs.setString('${_keyCompras}_antes_importar', atual);
    }

    ordenar(compras);
    await salvarConfiguracaoCartoes(cartoes);
    await salvarCompras(compras);
    return compras.length;
  }
}
