import 'dart:io';

final bool platformIsTestEnvironment =
    Platform.environment['FLUTTER_TEST'] == 'true';
