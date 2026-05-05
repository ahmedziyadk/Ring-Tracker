// import 'dart:convert';
//
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:http/http.dart' as http;
//
// class GoogleContactsService {
//   static const List<String> _scopes = [
//     'https://www.googleapis.com/auth/contacts',
//   ];
//
//   final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
//   bool _initialized = false;
//
//   Future<void> _initialize() async {
//     if (_initialized) return;
//     await _googleSignIn.initialize();
//     _initialized = true;
//   }
//
//   Future<void> saveContact({
//     required String name,
//     required String phoneNumber,
//   }) async {
//     final cleanName = name.trim();
//     final cleanPhone = phoneNumber.trim();
//
//     if (cleanName.isEmpty || cleanPhone.isEmpty) return;
//
//     await _initialize();
//
//     GoogleSignInAccount? account =
//     await _googleSignIn.attemptLightweightAuthentication();
//
//     account ??= await _googleSignIn.authenticate();
//
//     final authorization =
//         await account.authorizationClient.authorizationForScopes(_scopes) ??
//             await account.authorizationClient.authorizeScopes(_scopes);
//
//     final response = await http.post(
//       Uri.parse('https://people.googleapis.com/v1/people:createContact'),
//       headers: {
//         'Authorization': 'Bearer ${authorization.accessToken}',
//         'Content-Type': 'application/json',
//       },
//       body: jsonEncode({
//         'names': [
//           {'givenName': cleanName}
//         ],
//         'phoneNumbers': [
//           {'value': cleanPhone}
//         ],
//       }),
//     );
//
//     if (response.statusCode < 200 || response.statusCode >= 300) {
//       throw Exception('Google contact save failed: ${response.body}');
//     }
//   }
// }
