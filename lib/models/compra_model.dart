class CompraModel {
  final String id;
  final String parente;
  final double valorTotal;
  final String local;
  final String cartao;
  final int totalParcelas;
  final DateTime dataCompra;

  CompraModel({
    required this.id,
    required this.parente,
    required this.valorTotal,
    required this.local,
    required this.cartao,
    required this.totalParcelas,
    required this.dataCompra,
  });

  bool get ehAssinatura => totalParcelas == 999;

  int calcularParcelaNoMes(DateTime mesAlvo, int diaFechamento) {
    if (ehAssinatura) return 1;

    DateTime dataInicioFaturamento = DateTime(
      dataCompra.year,
      dataCompra.month,
      diaFechamento,
    );

    if (dataCompra.day >= diaFechamento) {
      dataInicioFaturamento = DateTime(
        dataCompra.year,
        dataCompra.month + 1,
        diaFechamento,
      );
    }

    final diferencaMeses =
        (mesAlvo.year - dataInicioFaturamento.year) * 12 +
        (mesAlvo.month - dataInicioFaturamento.month);
    final parcela = diferencaMeses + 1;

    return parcela;
  }

  bool estaAtivaNoMes(DateTime mesAlvo, int diaFechamento) {
    if (ehAssinatura) {
      DateTime dataInicioFaturamento = DateTime(
        dataCompra.year,
        dataCompra.month,
        diaFechamento,
      );
      if (dataCompra.day >= diaFechamento) {
        dataInicioFaturamento = DateTime(
          dataCompra.year,
          dataCompra.month + 1,
          diaFechamento,
        );
      }
      return mesAlvo.isAfter(dataInicioFaturamento) ||
          (mesAlvo.year == dataInicioFaturamento.year &&
              mesAlvo.month == dataInicioFaturamento.month);
    }

    final parcela = calcularParcelaNoMes(mesAlvo, diaFechamento);
    return parcela >= 1 && parcela <= totalParcelas;
  }

  int get parcelaAtual {
    if (ehAssinatura) return 1;
    final dataAtual = DateTime.now();
    final diferencaMeses =
        (dataAtual.year - dataCompra.year) * 12 +
        (dataAtual.month - dataCompra.month);
    final parcela = diferencaMeses + 1;

    if (parcela < 1) return 1;
    if (parcela > totalParcelas) return totalParcelas;
    return parcela;
  }

  bool get estaAtiva {
    if (ehAssinatura) return true;
    final dataAtual = DateTime.now();
    final diferencaMeses =
        (dataAtual.year - dataCompra.year) * 12 +
        (dataAtual.month - dataCompra.month);
    return diferencaMeses < totalParcelas;
  }

  double get valorParcela =>
      ehAssinatura ? valorTotal : (valorTotal / totalParcelas);
}
