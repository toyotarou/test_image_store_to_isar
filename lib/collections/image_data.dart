import 'dart:typed_data';
import 'package:isar/isar.dart';

part 'image_data.g.dart';

@collection
class ImageData {
  Id id = Isar.autoIncrement;

  List<int>? imageBytes;

  String? title;
  DateTime? createdAt;

  ///
  Uint8List? getUint8List() {
    if (imageBytes == null) {
      return null;
    }

    return Uint8List.fromList(imageBytes!);
  }

  ///
  void setUint8List(Uint8List? bytes) => imageBytes = bytes?.toList();
}
