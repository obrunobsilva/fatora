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
    return diferencaMeses + 1;
  }

  bool estaAtivaNoMes(DateTime mesAlvo, int diaFechamento) {
    if (ehAssinatura) {
      final DateTime dataFiltroAlvo = DateTime(mesAlvo.year, mesAlvo.month);
      final DateTime dataFiltroCompra = DateTime(
        dataCompra.year,
        dataCompra.month,
      );
      return dataFiltroAlvo.isAfter(dataFiltroCompra) ||
          (dataFiltroAlvo.year == dataFiltroCompra.year &&
              dataFiltroAlvo.month == dataFiltroCompra.month);
    }

    final parcela = calcularParcelaNoMes(mesAlvo, diaFechamento);
    return parcela >= 1 && parcela <= totalParcelas;
  }

  int obterParcelaAtualDinamica(int diaFechamento) {
    if (ehAssinatura) return 1;
    final parcela = calcularParcelaNoMes(DateTime.now(), diaFechamento);
    if (parcela < 1) return 1;
    if (parcela > totalParcelas) return totalParcelas;
    return parcela;
  }

  bool verificarSeEstaAtivaDinamica(int diaFechamento) {
    if (ehAssinatura) return true;
    final parcela = calcularParcelaNoMes(DateTime.now(), diaFechamento);
    return parcela >= 1 && parcela <= totalParcelas;
  }

  int get parcelaAtual {
    return obterParcelaAtualDinamica(15);
  }

  bool get estaAtiva {
    return verificarSeEstaAtivaDinamica(15);
  }

  double get valorParcela =>
      ehAssinatura ? valorTotal : (valorTotal / totalParcelas);
}
