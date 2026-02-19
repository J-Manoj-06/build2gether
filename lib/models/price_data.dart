class PriceData {
  final DateTime date;
  final double price;

  PriceData({required this.date, required this.price});

  /// Factory constructor to parse data from Government Agmarknet API
  factory PriceData.fromApi(Map<String, dynamic> json) {
    try {
      // Parse date from "arrival_date" field (format: DD/MM/YYYY)
      String dateStr = json['arrival_date'] ?? '';
      DateTime parsedDate = DateTime.now();

      if (dateStr.isNotEmpty) {
        try {
          List<String> parts = dateStr.split('/');
          if (parts.length == 3) {
            int day = int.parse(parts[0]);
            int month = int.parse(parts[1]);
            int year = int.parse(parts[2]);
            parsedDate = DateTime(year, month, day);
          }
        } catch (e) {
          print('⚠️ Error parsing date: $dateStr - $e');
        }
      }

      // Parse price from "modal_price" field
      double parsedPrice = 0.0;
      dynamic priceValue = json['modal_price'];

      if (priceValue != null) {
        if (priceValue is double) {
          parsedPrice = priceValue;
        } else if (priceValue is int) {
          parsedPrice = priceValue.toDouble();
        } else if (priceValue is String) {
          parsedPrice = double.tryParse(priceValue) ?? 0.0;
        }
      }

      return PriceData(date: parsedDate, price: parsedPrice);
    } catch (e) {
      print('❌ Error creating PriceData from API: $e');
      return PriceData(date: DateTime.now(), price: 0.0);
    }
  }

  @override
  String toString() {
    return 'PriceData(date: $date, price: ₹$price)';
  }
}
