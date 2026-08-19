class AjustesService {
  static Future<Map<String, dynamic>> getAjustes() async {
    return {};
  }

  static bool tieneTimbrado(Map<String, dynamic> ajustes) {
    return ajustes['timbrado'] != null &&
        ajustes['timbrado'].toString().trim().isNotEmpty;
  }
}
