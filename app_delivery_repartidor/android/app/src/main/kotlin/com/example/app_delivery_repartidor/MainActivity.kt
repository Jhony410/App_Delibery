package com.example.app_delivery_repartidor

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity (y no FlutterActivity) porque local_auth usa
// BiometricPrompt en Android, que exige un host FragmentActivity. Con
// FlutterActivity el plugin falla en runtime con "no_fragment_activity".
class MainActivity : FlutterFragmentActivity()
