import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'collections/image_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final Directory dir = await getApplicationSupportDirectory();

  // ignore: strict_raw_type, always_specify_types
  final Isar isar = await Isar.open(<CollectionSchema>[ImageDataSchema], directory: dir.path);

  runApp(MyApp(isar: isar));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.isar});

  final Isar isar;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Isar Multi-Image (List<int>)',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyHomePage(isar: isar),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.isar});

  final Isar isar;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<ImageData> _loadedImages = <ImageData>[];

  ///
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('List<int> Multi-Image Example')),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              if (_loadedImages.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _loadedImages.map((ImageData imgData) {
                    final Uint8List? imgBytes = imgData.getUint8List();
                    return imgBytes == null
                        ? Container(
                            width: 100, height: 100, color: Colors.grey, child: const Center(child: Text('No Data')))
                        : Image.memory(imgBytes, width: 100, height: 100, fit: BoxFit.cover);
                  }).toList(),
                )
              else
                Container(padding: const EdgeInsets.all(16), child: const Text('No images loaded.')),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _pickAndSaveImages, child: const Text('Pick Multiple Images & Save to Isar')),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadImagesFromIsar, child: const Text('Load Images from Isar')),
            ],
          ),
        ),
      ),
    );
  }

  ///
  Future<void> _pickAndSaveImages() async {
    try {
      final ImagePicker picker = ImagePicker();

      final List<XFile> pickedFiles = await picker.pickMultiImage();

      if (pickedFiles.isEmpty) {
        return;
      }

      await widget.isar.writeTxn(() async {
        for (final XFile file in pickedFiles) {
          final Uint8List bytes = await file.readAsBytes();

          final ImageData imageData = ImageData()
            ..title = 'Selected from Gallery'
            ..createdAt = DateTime.now();

          imageData.setUint8List(bytes);

          await widget.isar.imageDatas.put(imageData);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${pickedFiles.length} images saved to Isar!')),
        );
      }
    } catch (e) {
      debugPrint('Error picking or saving multiple images: $e');
    }
  }

  ///
  Future<void> _loadImagesFromIsar() async {
    try {
      final List<ImageData> images = await widget.isar.imageDatas.where().findAll();

      setState(() => _loadedImages = images);

      if (images.isEmpty) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No saved images found in Isar.')));
      }
    } catch (e) {
      debugPrint('Error loading images from Isar: $e');
    }
  }
}
