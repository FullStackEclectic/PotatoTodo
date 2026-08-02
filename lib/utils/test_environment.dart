import 'test_environment_stub.dart'
    if (dart.library.io) 'test_environment_io.dart'
    if (dart.library.html) 'test_environment_web.dart';

bool get isTestEnvironment => platformIsTestEnvironment;
