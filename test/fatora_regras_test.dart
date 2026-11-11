import 'package:flutter_test/flutter_test.dart';
import 'package:fatora/models/compra_model.dart';
import 'package:fatora/utils/formatadores.dart';

CompraModel compra(
  DateTime data, {
  int parcelas = 1,
  int parcelaInicial = 1,
  int centavos = 10000,
}) {
  return CompraModel(
    id: 'x',
    parente: 'Ana',
    valorTotalCentavos: centavos,
    local: 'Mercado',
    cartao: 'Cartão',
    totalParcelas: parcelas,
    parcelaInicial: parcelaInicial,
    dataCompra: data,
  );
}

void main() {
  group('dias do mês', () {
    test('28, 29 (bissexto), 30 e 31 dias', () {
      expect(CompraModel.diasNoMes(2027, 2), 28);
      expect(CompraModel.diasNoMes(2028, 2), 29);
      expect(CompraModel.diasNoMes(2027, 4), 30);
      expect(CompraModel.diasNoMes(2027, 12), 31);
    });
  });

  group('primeira fatura (corte = melhor dia de compra)', () {
    test('corte 10: dia 9 fica no mês, dia 10 vai para o seguinte', () {
      expect(
        compra(DateTime(2027, 1, 9)).mesPrimeiraFatura(10),
        DateTime(2027, 1),
      );
      expect(
        compra(DateTime(2027, 1, 10)).mesPrimeiraFatura(10),
        DateTime(2027, 2),
      );
    });

    test('corte 31 em fevereiro de 28 dias vale dia 28', () {
      expect(
        compra(DateTime(2027, 2, 27)).mesPrimeiraFatura(31),
        DateTime(2027, 2),
      );
      expect(
        compra(DateTime(2027, 2, 28)).mesPrimeiraFatura(31),
        DateTime(2027, 3),
      );
    });

    test('corte 31 em fevereiro bissexto vale dia 29', () {
      expect(
        compra(DateTime(2028, 2, 28)).mesPrimeiraFatura(31),
        DateTime(2028, 2),
      );
      expect(
        compra(DateTime(2028, 2, 29)).mesPrimeiraFatura(31),
        DateTime(2028, 3),
      );
    });

    test('corte 30 e 31 em mês de 30 dias valem dia 30', () {
      expect(
        compra(DateTime(2027, 4, 29)).mesPrimeiraFatura(30),
        DateTime(2027, 4),
      );
      expect(
        compra(DateTime(2027, 4, 30)).mesPrimeiraFatura(30),
        DateTime(2027, 5),
      );
      expect(
        compra(DateTime(2027, 4, 30)).mesPrimeiraFatura(31),
        DateTime(2027, 5),
      );
    });

    test('virada de ano', () {
      expect(
        compra(DateTime(2026, 12, 20)).mesPrimeiraFatura(10),
        DateTime(2027, 1),
      );
    });
  });

  group('parcelas', () {
    test('parcelaInicial desloca a numeração sem mexer na data', () {
      final c = compra(DateTime(2027, 1, 5), parcelas: 6, parcelaInicial: 4);
      expect(c.calcularParcelaNoMes(DateTime(2027, 1), 10), 4);
      expect(c.calcularParcelaNoMes(DateTime(2027, 2), 10), 5);
      expect(c.calcularParcelaNoMes(DateTime(2027, 3), 10), 6);
      expect(c.estaAtivaNoMes(DateTime(2027, 3), 10), isTrue);
      expect(c.estaAtivaNoMes(DateTime(2027, 4), 10), isFalse);
      expect(c.dataCompra, DateTime(2027, 1, 5));
    });

    test('rótulos', () {
      final c = compra(DateTime(2027, 1, 5), parcelas: 3);
      expect(c.rotuloParcelaNoMes(DateTime(2027, 1), 10), 'Parcela 1 de 3');
      expect(c.rotuloParcelaNoMes(DateTime(2027, 4), 10), 'Quitada');
      expect(c.rotuloParcelaNoMes(DateTime(2026, 12), 10), 'Ainda não começou');
      expect(
        compra(DateTime(2027, 1, 5)).rotuloParcelaNoMes(DateTime(2027, 1), 10),
        'À vista',
      );
    });

    test('assinatura vale a partir do mês da primeira fatura', () {
      final c = compra(
        DateTime(2027, 1, 5),
        parcelas: CompraModel.tipoAssinatura,
      );
      expect(c.ehAssinatura, isTrue);
      expect(c.estaAtivaNoMes(DateTime(2026, 12), 10), isFalse);
      expect(c.estaAtivaNoMes(DateTime(2027, 1), 10), isTrue);
      expect(c.estaAtivaNoMes(DateTime(2028, 6), 10), isTrue);
      expect(c.calcularParcelaNoMes(DateTime(2028, 6), 10), 1);
    });
  });

  group('dinheiro e JSON', () {
    test('100,00 em 3x vira 33,33 por parcela', () {
      final c = compra(DateTime(2027, 1, 5), parcelas: 3, centavos: 10000);
      expect(c.valorParcelaCentavos, 3333);
      expect(c.valorParcela, 33.33);
    });

    test('lê o formato antigo (valorTotal em reais, sem parcelaInicial)', () {
      final c = CompraModel.fromJson({
        'id': '1',
        'parente': 'Ana',
        'valorTotal': 19.99,
        'local': 'Mercado',
        'cartao': 'X',
        'totalParcelas': 3,
        'dataCompra': '2027-01-05T10:00:00.000',
      });
      expect(c.valorTotalCentavos, 1999);
      expect(c.parcelaInicial, 1);
    });

    test('ida e volta do JSON', () {
      final original = compra(
        DateTime(2027, 1, 5, 10),
        parcelas: 4,
        parcelaInicial: 2,
      );
      final volta = CompraModel.fromJson(original.toJson());
      expect(volta.valorTotalCentavos, original.valorTotalCentavos);
      expect(volta.totalParcelas, 4);
      expect(volta.parcelaInicial, 2);
      expect(volta.dataCompra, original.dataCompra);
    });

    test('formatar e ler centavos', () {
      expect(formatarCentavos(0), '0,00');
      expect(formatarCentavos(5), '0,05');
      expect(formatarCentavos(123456), '1.234,56');
      expect(formatarCentavos(100000), '1.000,00');
      expect(lerCentavos('1.234,56'), 123456);
      expect(lerCentavos(''), isNull);
    });
  });

  group('nomes', () {
    test('ignora maiúscula, acento e espaços', () {
      expect(chaveNome(' João '), chaveNome('joao'));
      expect(chaveNome('MARIA   Silva'), chaveNome('maria silva'));
    });

    test('reaproveita a grafia que já existe', () {
      const existentes = ['Maria', 'João'];
      expect(canonicalizarNome(' maria ', existentes), 'Maria');
      expect(canonicalizarNome('joao', existentes), 'João');
      expect(canonicalizarNome('Pedro  Lima', existentes), 'Pedro Lima');
    });
  });
}
