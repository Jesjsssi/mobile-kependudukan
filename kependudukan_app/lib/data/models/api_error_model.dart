class ApiErrorModel {
  final bool status;
  final String message;
  final Map<String, List<String>>? errors;

  ApiErrorModel({
    required this.status,
    required this.message,
    this.errors,
  });

  factory ApiErrorModel.fromJson(Map<String, dynamic> json) {
    Map<String, List<String>>? errorMap;

    if (json['errors'] != null && json['errors'] is Map) {
      errorMap = {};
      json['errors'].forEach((key, value) {
        if (value is List) {
          errorMap![key] = List<String>.from(value.map((e) => e.toString()));
        } else if (value is String) {
          errorMap![key] = [value];
        }
      });
    }

    return ApiErrorModel(
      status: json['status'] ?? false,
      message: json['message'] ?? 'Unknown error',
      errors: errorMap,
    );
  }

  String get firstError {
    if (errors != null && errors!.isNotEmpty) {
      final firstKey = errors!.keys.first;
      if (errors![firstKey]!.isNotEmpty) {
        return errors![firstKey]!.first;
      }
    }
    return message;
  }
}
