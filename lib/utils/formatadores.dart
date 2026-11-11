import 'package:flutter/services.dart';

/// Chave para comparar nomes: minúscula, sem acento, espaços normalizados.
/// "João ", "joao" e "JOÃO" geram a mesma chave.
String chaveNome(String texto) {
  const de = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  const para = 'aaaaaeeeeiiiiooooouuuucn';
  final saida = StringBuffer();
  for (final ch in texto.trim().toLowerCase().split('')) {
    final i = de.indexOf(ch);
    saida.write(i >= 0 ? para[i] : ch);
  }
  return saida.toString().replaceAll(RegExp(r'\s+'), ' ');
}

String limparNome(String texto) => texto.trim().replaceAll(RegExp(r'\s+'), ' ');

/// Se já existe alguém com o mesmo nome (ignorando maiúscula/acento),
/// devolve a grafia que já existe. Senão, devolve o texto limpo.
String canonicalizarNome(String digitado, Iterable<String> existentes) {
  final chave = chaveNome(digitado);
  for (final nome in existentes) {
    if (chaveNome(nome) == chave) return nome;
  }
  return limparNome(digitado);
}

/// 123456 -> "1.234,56"
String formatarCentavos(int centavos) {
  final reais = (centavos ~/ 100).toString();
  final cents = (centavos % 100).toString().padLeft(2, '0');
  final milhar = reais.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (m) => '.',
  );
  return '$milhar,$cents';
}

/// "1.234,56" -> 123456. Devolve null se estiver vazio ou inválido.
int? lerCentavos(String texto) {
  final digitos = texto.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitos.isEmpty || digitos.length > 12) return null;
  return int.tryParse(digitos);
}

/// Campo de dinheiro: o usuário digita só números e o valor vai se
/// formando da direita para a esquerda (12345 -> 123,45).
class MoedaInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitos = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitos.isEmpty) return const TextEditingValue(text: '');
    if (digitos.length > 10) return oldValue;
    final texto = formatarCentavos(int.parse(digitos));
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}
