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

  DateTime _obterDataFaturamentoInicial(DateTime data, int diaVencimento) {
    if (diaVencimento <= 10) {
      int diaFechamentoMesAnterior = diaVencimento - 10 + 30;
      if (data.day >= diaFechamentoMesAnterior) {
        int proximoMes = data.month + 2;
        int proximoAno = data.year;
        if (proximoMes > 12) {
          proximoMes -= 12;
          proximoAno += 1;
        }
        return DateTime(proximoAno, proximoMes, 1);
      } else {
        int proximoMes = data.month + 1;
        int proximoAno = data.year;
        if (proximoMes > 12) {
          proximoMes -= 12;
          proximoAno += 1;
        }
        return DateTime(proximoAno, proximoMes, 1);
      }
    } else {
      int diaFechamentoMesAtual = diaVencimento - 10;
      if (data.day >= diaFechamentoMesAtual) {
        int proximoMes = data.month + 1;
        int proximoAno = data.year;
        if (proximoMes > 12) {
          proximoMes -= 12;
          proximoAno += 1;
        }
        return DateTime(proximoAno, proximoMes, 1);
      } else {
        return DateTime(data.year, data.month, 1);
      }
    }
  }

  int calcularParcelaNoMes(DateTime mesAlvo, int diaVencimento) {
    if (ehAssinatura) return 1;

    DateTime dataInicioFaturamento = _obterDataFaturamentoInicial(
      dataCompra,
      diaVencimento,
    );
    DateTime dataAlvoFiltro = DateTime(mesAlvo.year, mesAlvo.month, 1);

    final diferencaMeses =
        (dataAlvoFiltro.year - dataInicioFaturamento.year) * 12 +
        (dataAlvoFiltro.month - dataInicioFaturamento.month);

    return diferencaMeses + 1;
  }

  bool estaAtivaNoMes(DateTime mesAlvo, int diaVencimento) {
    if (ehAssinatura) {
      DateTime dataInicioFaturamento = _obterDataFaturamentoInicial(
        dataCompra,
        diaVencimento,
      );
      final DateTime dataFiltroAlvo = DateTime(mesAlvo.year, mesAlvo.month, 1);

      return dataFiltroAlvo.isAfter(dataInicioFaturamento) ||
          (dataFiltroAlvo.year == dataInicioFaturamento.year &&
              dataFiltroAlvo.month == dataInicioFaturamento.month);
    }

    final parcela = calcularParcelaNoMes(mesAlvo, diaVencimento);
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
