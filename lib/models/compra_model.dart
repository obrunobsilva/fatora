import 'dart:math';

class CompraModel {
  /// Valor usado em totalParcelas para marcar assinatura mensal.
  static const int tipoAssinatura = 999;

  final String id;
  final String parente;

  /// Dinheiro sempre em centavos (int), para não ter erro de ponto flutuante.
  final int valorTotalCentavos;
  final String local;
  final String cartao;
  final int totalParcelas;

  /// Em qual parcela a compra estava quando foi registrada (padrão 1).
  /// Substitui o antigo "truque" de voltar a dataCompra alguns meses.
  final int parcelaInicial;
  final DateTime dataCompra;

  const CompraModel({
    required this.id,
    required this.parente,
    required this.valorTotalCentavos,
    required this.local,
    required this.cartao,
    required this.totalParcelas,
    required this.dataCompra,
    this.parcelaInicial = 1,
  });

  double get valorTotal => valorTotalCentavos / 100;

  bool get ehAssinatura => totalParcelas == tipoAssinatura;

  int get valorParcelaCentavos => ehAssinatura
      ? valorTotalCentavos
      : (valorTotalCentavos / totalParcelas).round();

  double get valorParcela => valorParcelaCentavos / 100;

  /// Quantos dias o mês tem (28, 29, 30 ou 31). Considera ano bissexto.
  static int diasNoMes(int ano, int mes) => DateTime(ano, mes + 1, 0).day;

  /// Mês (dia 1) da primeira fatura em que a compra aparece.
  ///
  /// [diaCorte] é o "melhor dia de compra": a partir desse dia, a compra
  /// já cai na fatura seguinte. Se o mês não tem esse dia (ex.: dia 31 em
  /// fevereiro ou abril), vale o último dia do mês.
  DateTime mesPrimeiraFatura(int diaCorte) {
    final corte = min(diaCorte, diasNoMes(dataCompra.year, dataCompra.month));
    if (dataCompra.day >= corte) {
      return DateTime(dataCompra.year, dataCompra.month + 1);
    }
    return DateTime(dataCompra.year, dataCompra.month);
  }

  /// Número da parcela que cai no mês [mesAlvo] (pode ser < 1 ou > total).
  int calcularParcelaNoMes(DateTime mesAlvo, int diaCorte) {
    if (ehAssinatura) return 1;
    final inicio = mesPrimeiraFatura(diaCorte);
    final alvo = DateTime(mesAlvo.year, mesAlvo.month);
    final diferencaMeses =
        (alvo.year - inicio.year) * 12 + (alvo.month - inicio.month);
    return diferencaMeses + parcelaInicial;
  }

  bool estaAtivaNoMes(DateTime mesAlvo, int diaCorte) {
    if (ehAssinatura) {
      final inicio = mesPrimeiraFatura(diaCorte);
      final alvo = DateTime(mesAlvo.year, mesAlvo.month);
      return !alvo.isBefore(inicio);
    }
    final parcela = calcularParcelaNoMes(mesAlvo, diaCorte);
    return parcela >= 1 && parcela <= totalParcelas;
  }

  /// Texto para listas: "Parcela 3 de 10", "Quitada", "À vista"...
  String rotuloParcelaNoMes(DateTime mes, int diaCorte) {
    if (ehAssinatura) return 'Assinatura';
    if (totalParcelas == 1) return 'À vista';
    final p = calcularParcelaNoMes(mes, diaCorte);
    if (p > totalParcelas) return 'Quitada';
    if (p < 1) return 'Ainda não começou';
    return 'Parcela $p de $totalParcelas';
  }

  CompraModel copyWith({String? parente, String? cartao}) {
    return CompraModel(
      id: id,
      parente: parente ?? this.parente,
      valorTotalCentavos: valorTotalCentavos,
      local: local,
      cartao: cartao ?? this.cartao,
      totalParcelas: totalParcelas,
      dataCompra: dataCompra,
      parcelaInicial: parcelaInicial,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'parente': parente,
    'valorTotalCentavos': valorTotalCentavos,
    'local': local,
    'cartao': cartao,
    'totalParcelas': totalParcelas,
    'parcelaInicial': parcelaInicial,
    'dataCompra': dataCompra.toIso8601String(),
  };

  /// Lê tanto o formato novo quanto o antigo (valorTotal em reais).
  factory CompraModel.fromJson(Map<String, dynamic> json) {
    final centavos =
        (json['valorTotalCentavos'] as num?)?.toInt() ??
        ((json['valorTotal'] as num).toDouble() * 100).round();
    return CompraModel(
      id: json['id'] as String,
      parente: json['parente'] as String,
      valorTotalCentavos: centavos,
      local: json['local'] as String,
      cartao: json['cartao'] as String,
      totalParcelas: (json['totalParcelas'] as num).toInt(),
      parcelaInicial: (json['parcelaInicial'] as num?)?.toInt() ?? 1,
      dataCompra: DateTime.parse(json['dataCompra'] as String),
    );
  }
}
