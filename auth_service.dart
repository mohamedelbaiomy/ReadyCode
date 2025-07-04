import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:sakank/core/widgets/flushbar.dart';
import 'package:flutter/foundation.dart';

class AuthRepo {
  AuthRepo._();

  static final AuthRepo instance = AuthRepo._();

  static final FirebaseAuth auth = FirebaseAuth.instance;

  static Future<void> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    await auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  static Future<void> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    await auth.signInWithEmailAndPassword(email: email, password: password);
  }

  static Future<void> sendEmailVerification() async {
    try {
      await currentUser!.sendEmailVerification();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  static String get uid {
    return currentUser!.uid;
  }

  static User? get currentUser {
    return auth.currentUser;
  }

  static Future<void> reloadUserData() async {
    await currentUser!.reload();
  }

  static Future<void> updateUserName(String displayName) async {
    await currentUser!.updateDisplayName(displayName);
  }

  static Future<bool> checkEmailVerification() async {
    try {
      return currentUser!.emailVerified == true;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return false;
    }
  }

  static Future<void> logOut() async {
    // await FirebaseFirestore.instance.clearPersistence();
    await auth.signOut();
  }

  static Future<void> sendPasswordResetEmail(
    String email,
    BuildContext context,
  ) async {
    try {
      await auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (context.mounted) showError(context, e.message.toString());
    } catch (e) {
      if (context.mounted) showError(context, e.toString());
    }
  }

  static Future<bool> checkOldPassword(String email, String password) async {
    final AuthCredential authCredential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    try {
      final UserCredential credentialResult = await currentUser!
          .reauthenticateWithCredential(authCredential);
      return credentialResult.user != null;
    } catch (e) {
      return false;
    }
  }

  static Future<void> updateUserPassword(String newPassword) async {
    try {
      await currentUser!.updatePassword(newPassword);
    } catch (e) {
      // ignore: avoid_print
    }
  }
}
