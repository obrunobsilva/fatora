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

  DateTime _obterDataFaturamentoInicial(
    DateTime data,
    int diaFechamentoOuVencimento,
  ) {
    int anoAtual = data.year;
    int mesAtual = data.month;
    int diaFechamentoReal = diaFechamentoOuVencimento;

    if (diaFechamentoOuVencimento > 10) {
      diaFechamentoReal = diaFechamentoOuVencimento - 10;
    }

    DateTime limiteFaturaMesAtual = DateTime(
      anoAtual,
      mesAtual,
      diaFechamentoReal,
    );

    if (data.isAfter(limiteFaturaMesAtual) ||
        data.isAtSameMomentAs(limiteFaturaMesAtual)) {
      int proximoMes = mesAtual + 1;
      int anoDoProximoMes = anoAtual;
      if (proximoMes > 12) {
        proximoMes = 1;
        anoDoProximoMes += 1;
      }
      return DateTime(anoDoProximoMes, proximoMes, 1);
    } else {
      return DateTime(anoAtual, mesAtual, 1);
    }
  }

  int calcularParcelaNoMes(DateTime mesAlvo, int diaFechamentoOuVencimento) {
    if (ehAssinatura) {
      return 1;
    }

    DateTime dataInicioFaturamento = _obterDataFaturamentoInicial(
      dataCompra,
      diaFechamentoOuVencimento,
    );
    DateTime dataAlvoFiltro = DateTime(mesAlvo.year, mesAlvo.month, 1);

    final diferencaMeses =
        (dataAlvoFiltro.year - dataInicioFaturamento.year) * 12 +
        (dataAlvoFiltro.month - dataInicioFaturamento.month);

    return diferencaMeses + 1;
  }

  bool estaAtivaNoMes(DateTime mesAlvo, int diaFechamentoOuVencimento) {
    if (ehAssinatura) {
      DateTime dataInicioFaturamento = _obterDataFaturamentoInicial(
        dataCompra,
        diaFechamentoOuVencimento,
      );
      final DateTime dataFiltroAlvo = DateTime(mesAlvo.year, mesAlvo.month, 1);

      return dataFiltroAlvo.isAfter(dataInicioFaturamento) ||
          (dataFiltroAlvo.year == dataInicioFaturamento.year &&
              dataFiltroAlvo.month == dataInicioFaturamento.month);
    }

    final parcela = calcularParcelaNoMes(mesAlvo, diaFechamentoOuVencimento);
    return parcela >= 1 && parcela <= totalParcelas;
  }

  int get parcelaAtual {
    return calcularParcelaNoMes(DateTime.now(), 15);
  }

  bool get estaAtiva {
    return estaAtivaNoMes(DateTime.now(), 15);
  }

  double get valorParcela =>
      ehAssinatura ? valorTotal : (valorTotal / totalParcelas);
}
