import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String? gender;
  final DateTime? birthday;
  final String? country;
  final String? currencyCode;
  final String? profilePicUrl;
  final String? coverPicUrl;
  final Map<String, String> customExpenseCategories;
  final Map<String, String> customIncomeCategories;

  UserModel({
    required this.uid,
    required this.name,
    this.gender,
    this.birthday,
    this.country,
    this.currencyCode,
    this.profilePicUrl,
    this.coverPicUrl,
    this.customExpenseCategories = const {},
    this.customIncomeCategories = const {},
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      name: map['name'] ?? '',
      gender: map['gender'],
      birthday: map['birthday'] != null ? (map['birthday'] as Timestamp).toDate() : null,
      country: map['country'],
      currencyCode: map['currencyCode'],
      profilePicUrl: map['profilePicUrl'],
      coverPicUrl: map['coverPicUrl'],
      customExpenseCategories: Map<String, String>.from(map['customExpenseCategories'] ?? {}),
      customIncomeCategories: Map<String, String>.from(map['customIncomeCategories'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'gender': gender,
      'birthday': birthday != null ? Timestamp.fromDate(birthday!) : null,
      'country': country,
      'currencyCode': currencyCode,
      'profilePicUrl': profilePicUrl,
      'coverPicUrl': coverPicUrl,
      'customExpenseCategories': customExpenseCategories,
      'customIncomeCategories': customIncomeCategories,
    };
  }

  int get age {
    if (birthday == null) return 0;
    final now = DateTime.now();
    int age = now.year - birthday!.year;
    if (now.month < birthday!.month || (now.month == birthday!.month && now.day < birthday!.day)) {
      age--;
    }
    return age;
  }
}
