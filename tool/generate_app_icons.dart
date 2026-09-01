// ignore_for_file: avoid_print
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final logoFile = File('logo.png');
  if (!logoFile.existsSync()) {
    print('logo.png not found!');
    return;
  }

  final rawBytes = logoFile.readAsBytesSync();
  final image = img.decodeImage(rawBytes);
  if (image == null) {
    print('Failed to decode logo.png');
    return;
  }

  final sizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  for (final entry in sizes.entries) {
    final folder = Directory('android/app/src/main/res/${entry.key}');
    if (!folder.existsSync()) {
      folder.createSync(recursive: true);
    }

    final resized = img.copyResize(image, width: entry.value, height: entry.value);
    final outFile = File('${folder.path}/ic_launcher.png');
    outFile.writeAsBytesSync(img.encodePng(resized));
    print('Wrote ${outFile.path} (${entry.value}x${entry.value})');
  }

  print('All Android launcher icons successfully updated with Nivora logo!');
}
