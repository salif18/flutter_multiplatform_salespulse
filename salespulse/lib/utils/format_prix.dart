import 'package:intl/intl.dart';
class FormatPrice {
  String formatNombre(String prixString) {
    final int? prix = int.tryParse(prixString);

    if (prix == null) {
      return prixString;
    }

    final formatter = NumberFormat("#,###", "fr_FR");
    final result = formatter.format(prix).replaceAll(',', ' ');
    return "${result} FCFA";
  }
}