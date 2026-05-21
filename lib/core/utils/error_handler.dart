import 'package:firebase_auth/firebase_auth.dart';

class ErrorHandler {
  static String getMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email. (এই ইমেইল দিয়ে কোনো অ্যাকাউন্ট পাওয়া যায়নি।)';
        case 'wrong-password':
          return 'Incorrect password. (ভুল পাসওয়ার্ড।)';
        case 'email-already-in-use':
          return 'Email is already registered. (এই ইমেইলটি ইতিমধ্যে ব্যবহৃত হচ্ছে।)';
        case 'invalid-email':
          return 'Invalid email address. (অকার্যকর ইমেইল ঠিকানা।)';
        case 'weak-password':
          return 'Password is too weak. (পাসওয়ার্ডটি খুবই দুর্বল।)';
        case 'network-request-failed':
          return 'Network error. Please check your connection. (নেটওয়ার্ক সমস্যা। আপনার ইন্টারনেট সংযোগ পরীক্ষা করুন।)';
        case 'user-disabled':
          return 'This user account has been disabled. (এই অ্যাকাউন্টটি নিষ্ক্রিয় করা হয়েছে।)';
        case 'too-many-requests':
          return 'Too many login attempts. Please try again later. (অতিরিক্ত চেষ্টার কারণে অ্যাকাউন্টটি সাময়িকভাবে ব্লক করা হয়েছে। পরে আবার চেষ্টা করুন।)';
        case 'operation-not-allowed':
          return 'This operation is not allowed. (এই অপারেশনটি অনুমোদিত নয়।)';
        default:
          return error.message ?? 'An authentication error occurred. (একটি অথেন্টিকেশন ত্রুটি ঘটেছে।)';
      }
    } else if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'You do not have permission to perform this action. (এই কাজটি করার অনুমতি আপনার নেই।)';
        case 'unavailable':
          return 'Service is temporarily unavailable. Please try again later. (সার্ভিসটি সাময়িকভাবে বন্ধ আছে। দয়া করে পরে চেষ্টা করুন।)';
        case 'not-found':
          return 'Requested document was not found. (অনুরোধকৃত ফাইলটি পাওয়া যায়নি।)';
        default:
          return error.message ?? 'A database error occurred. (ডাটাবেজ ত্রুটি ঘটেছে।)';
      }
    }
    
    return error?.toString() ?? 'An unknown error occurred. (একটি অজানা ত্রুটি ঘটেছে।)';
  }
}
