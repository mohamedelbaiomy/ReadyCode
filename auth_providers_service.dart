import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/flushbar.dart';
import '../../features/buttom_navigation_bar/bottom_navigation_bar.dart';
import '../../features/home/provider/nearby_your_location_provider.dart';
import '../../features/home/provider/property_provider.dart';
import '../../features/profile/model/user_model.dart';
import '../../features/profile/provider/user_provider.dart';
import 'firestore_service.dart';

class AuthProviders {
  static CollectionReference<Map<String, dynamic>> users = FirebaseFirestore
      .instance
      .collection('users');

  static Future<bool> checkIfDocExists(String docId) async {
    try {
      final DocumentSnapshot<Object?> doc = await users.doc(docId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  static void navigate() {
    Get.offAll<void>(
      () => const BottomNavigationScreen(),
      transition: Transition.fadeIn,
    );
  }

  static void fetchUserDataAndProperties(BuildContext context, User user) {
    context.read<UserProvider>().fetchUserData(user.uid);
    context.read<PropertyProvider>().fetchProperties().timeout(
      const Duration(seconds: 10),
    );
    context.read<NearbyYourLocationProvider>().fetchProperties().timeout(
      const Duration(seconds: 10),
    );
  }

  static Future<void> _saveUserAndToken(
    User user,
    String? displayName,
    String? email,
  ) async {
    final UserModel userModel = UserModel.fromSignupData(
      name: displayName ?? 'User',
      email: email ?? '',
      password: '',
      uid: user.uid,
      signUpDate: DateFormat('d,M,yyyy', 'en_US').format(DateTime.now()),
    );

    await FirestoreRepo.createCollectionWithDoc(
      collectionName: 'users',
      docName: user.uid,
      data: userModel.toMap(),
    );

    // Get and save FCM token
    final String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirestoreRepo.createSubCollectionWithDoc(
        firstCollectionName: 'users',
        secondCollectionName: 'tokens',
        firstDocName: user.uid,
        secondDocName: user.uid,
        data: <String, dynamic>{
          'token': token,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    }
  }

  static Future<void> _checkDeletedAccount(
    String? email,
    BuildContext context,
  ) async {
    if (email != null) {
      final DocumentSnapshot<Map<String, dynamic>> deletedAccountSnapshot =
          await FirestoreRepo.getDocData('deleted_accounts', email);
      if (deletedAccountSnapshot.exists && context.mounted) {
        showError(
          context,
          context.tr('Deleted account please contact the owner\n01009429689'),
        );
        throw Exception('Deleted account');
      }
    }
  }

  static Future<void> signInWithGitHub(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();

      final GithubAuthProvider githubProvider = GithubAuthProvider();
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithProvider(githubProvider);
      final User? user = userCredential.user;

      if (user == null) {
        if (context.mounted) {
          showError(context, context.tr('GitHub Sign-In was canceled'));
        }
        return;
      }

      if (context.mounted) await _checkDeletedAccount(user.email, context);

      final bool docExists = await checkIfDocExists(user.uid);
      if (!docExists) {
        await _saveUserAndToken(user, user.displayName, user.email);
      } else {
        await _updateToken(user);
      }

      if (context.mounted) {
        fetchUserDataAndProperties(context, user);
        navigate();
      }
    } on FirebaseAuthException catch (e) {
      log(e.toString());
      if (e.code ==
          '[firebase_auth/web-context-canceled] The web operation was canceled by the user.') {
        if (context.mounted) {
          showError(context, context.tr('GitHub Sign-In was canceled'));
        }
      }
      if (context.mounted) _handleAuthException(e, context);
    } catch (e) {
      log(e.toString());

      if (context.mounted && e.toString() != 'Exception: Deleted account') {
        kDebugMode
            ? showError(context, e.toString())
            : showError(context, context.tr('error occurred'));
      }
    }
  }

  static Future<void> signInWithFacebook(BuildContext context) async {
    try {
      await FacebookAuth.instance.logOut();

      final String rawNonce = generateNonce();
      final String nonce = sha256ofString(rawNonce);
      final LoginResult loginResult = await FacebookAuth.instance.login(
        nonce: nonce,
      );

      if (loginResult.accessToken == null) {
        if (context.mounted) {
          showError(context, context.tr('Facebook Sign-In was canceled'));
        }
        return;
      }

      final OAuthCredential facebookAuthCredential;
      if (Platform.isIOS) {
        switch (loginResult.accessToken!.type) {
          case AccessTokenType.classic:
            final ClassicToken token = loginResult.accessToken as ClassicToken;
            facebookAuthCredential = FacebookAuthProvider.credential(
              token.authenticationToken!,
            );
          case AccessTokenType.limited:
            final LimitedToken token = loginResult.accessToken as LimitedToken;
            facebookAuthCredential = OAuthCredential(
              providerId: 'facebook.com',
              signInMethod: 'oauth',
              idToken: token.tokenString,
              rawNonce: rawNonce,
            );
        }
      } else {
        facebookAuthCredential = FacebookAuthProvider.credential(
          loginResult.accessToken!.tokenString,
        );
      }

      final Map<String, dynamic> userData =
          await FacebookAuth.instance.getUserData();
      final String? email =
          userData['email'] is String ? userData['email'] as String : null;

      if (context.mounted) await _checkDeletedAccount(email, context);

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(facebookAuthCredential);
      final User? user = userCredential.user;

      if (user == null) {
        if (context.mounted) {
          showError(context, context.tr('Facebook Sign-In failed'));
        }
        return;
      }

      final bool docExists = await checkIfDocExists(user.uid);
      if (!docExists) {
        await _saveUserAndToken(
          user,
          userData['name']?.toString() ?? user.displayName,
          email ?? user.email,
        );
      } else {
        await _updateToken(user);
      }

      if (context.mounted) {
        fetchUserDataAndProperties(context, user);
        navigate();
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) _handleAuthException(e, context);
    } catch (e) {
      if (context.mounted && e.toString() != 'Exception: Deleted account') {
        kDebugMode
            ? showError(context, e.toString())
            : showError(context, context.tr('error occurred'));
      }
    }
  }

  // MARK: - UI Setup
  /// MARK: - Data Handling

  static Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize();
      await googleSignIn.signOut();
      final GoogleSignInAccount googleUser = await googleSignIn.authenticate(
        scopeHint: <String>[
          'https://www.googleapis.com/auth/userinfo.profile',
          'https://www.googleapis.com/auth/userinfo.email',
        ],
      );

      if (context.mounted) {
        await _checkDeletedAccount(googleUser.email, context);
      }

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user == null) {
        if (context.mounted) {
          showError(context, context.tr('Google Sign-In failed'));
        }
        return;
      }

      final bool docExists = await checkIfDocExists(user.uid);
      if (!docExists) {
        await _saveUserAndToken(user, user.displayName, user.email);
      } else {
        await _updateToken(user);
      }

      if (context.mounted) {
        fetchUserDataAndProperties(context, user);
        navigate();
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) _handleAuthException(e, context);
    } catch (e) {
      if (e.toString() ==
          'GoogleSignInException(code GoogleSignInExceptionCode.canceled, activity is cancelled by the user., null)') {
        if (context.mounted) {
          showError(context, context.tr('Google Sign-In was canceled'));
        }
      } else if (e.toString().contains('Failed to launch the selector UI')) {
        if (context.mounted) {
          showError(
            context,
            context.tr('Please check Google Play Services and try again'),
          );
        }
      } else if (context.mounted &&
          e.toString() != 'Exception: Deleted account') {
        kDebugMode
            ? showError(context, e.toString())
            : showError(context, context.tr('error occurred'));
      }
    }
  }

  static Future<void> signInWithApple(BuildContext context) async {
    try {
      final String rawNonce = generateNonce();
      final String nonce = sha256ofString(rawNonce);

      final AuthorizationCredentialAppleID appleCredential =
          await SignInWithApple.getAppleIDCredential(
            scopes: <AppleIDAuthorizationScopes>[
              AppleIDAuthorizationScopes.email,
              AppleIDAuthorizationScopes.fullName,
            ],
            nonce: nonce,
          );

      if (context.mounted) {
        await _checkDeletedAccount(appleCredential.email, context);
      }

      final OAuthCredential oauthCredential = OAuthProvider(
        'apple.com',
      ).credential(idToken: appleCredential.identityToken, rawNonce: rawNonce);

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(oauthCredential);
      final User? user = userCredential.user;

      if (user == null) {
        if (context.mounted) {
          showError(context, context.tr('Apple Sign-In was canceled'));
        }
        return;
      }

      final bool docExists = await checkIfDocExists(user.uid);
      if (!docExists) {
        final String displayName =
            appleCredential.givenName != null &&
                    appleCredential.familyName != null
                ? '${appleCredential.givenName} ${appleCredential.familyName}'
                : user.displayName ?? 'Apple User';

        await _saveUserAndToken(
          user,
          displayName,
          appleCredential.email ?? user.email,
        );
      } else {
        await _updateToken(user);
      }

      if (context.mounted) {
        fetchUserDataAndProperties(context, user);
        navigate();
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) _handleAuthException(e, context);
    } catch (e) {
      if (context.mounted && e.toString() != 'Exception: Deleted account') {
        kDebugMode
            ? showError(context, e.toString())
            : showError(context, context.tr('error occurred'));
      }
    }
  }

  static Future<void> _updateToken(User user) async {
    final String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirestoreRepo.createSubCollectionWithDoc(
        firstCollectionName: 'users',
        secondCollectionName: 'tokens',
        firstDocName: user.uid,
        secondDocName: user.uid,
        data: <String, dynamic>{
          'token': token,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    }
  }

  static void _handleAuthException(
    FirebaseAuthException e,
    BuildContext context,
  ) {
    if (e.code == 'account-exists-with-different-credential' &&
        context.mounted) {
      showError(
        context,
        context.tr(
          'An account already exists with this email address using a different sign-in method. Please sign in using that method',
        ),
      );
    } else if (e.code == 'web-context-canceled' && context.mounted) {
      showError(context, context.tr('Sign-In was canceled'));
    } else if (context.mounted) {
      showError(context, e.toString());
    }
  }

  static String generateNonce([int length = 32]) {
    const String charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final math.Random random = math.Random.secure();
    return List<String>.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  static String sha256ofString(String input) {
    final Uint8List bytes = utf8.encode(input);
    final Digest digest = sha256.convert(bytes);
    return digest.toString();
  }
}
