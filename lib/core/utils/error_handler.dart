import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ErrorHandler {
  static String getMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'কোন অ্যাকাউন্ট পাওয়া যায়নি। (No account found with this email.)';
        case 'wrong-password':
          return 'পাসওয়ার্ড ভুল হয়েছে। (Incorrect password.)';
        case 'email-already-in-use':
          return 'এই ইমেইলটি ইতিমধ্যে ব্যবহৃত হচ্ছে। (Email already in use.)';
        case 'weak-password':
          return 'পাসওয়ার্ডটি খুব দুর্বল। (The password is too weak.)';
        case 'invalid-email':
          return 'ইমেইল এড্রেসটি সঠিক নয়। (Invalid email address.)';
        case 'user-disabled':
          return 'এই অ্যাকাউন্টটি নিষ্ক্রিয় করা হয়েছে। (This account has been disabled.)';
        case 'too-many-requests':
          return 'অনেক বেশি চেষ্টা করা হয়েছে। পরে চেষ্টা করুন। (Too many requests. Try again later.)';
        default:
          return 'লগইন করতে সমস্যা হচ্ছে। আবার চেষ্টা করুন। (Authentication failed. Please try again.)';
      }
    } else if (error is FirebaseException) {
      return 'সার্ভারের সাথে সংযোগে সমস্যা হচ্ছে। (Connection error with server.)';
    }
    return 'একটি ভুল হয়েছে। আবার চেষ্টা করুন। (Something went wrong. Please try again.)';
  }
}
