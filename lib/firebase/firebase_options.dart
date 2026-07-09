import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB_VpsarJPy3tuml3-7gLnMkjbP5Gc45Do',
    appId: '1:367980621544:android:41262476c7563baaad235d',
    messagingSenderId: '367980621544',
    projectId: 'fixup-app-uad',
    storageBucket: 'fixup-app-uad.firebasestorage.app',
  );
}
