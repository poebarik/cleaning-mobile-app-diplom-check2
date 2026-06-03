import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:typed_data';
import '../../data/datasources/remote/file_api.dart';
import '../../data/network/dio_client.dart';
import '../../data/models/file/file_upload_response.dart';

final fileProvider = Provider<FileApi>((ref) {
  return FileApi(DioClient.instance);
});

final fileUploadProvider = StateNotifierProvider<FileUploadNotifier, FileUploadState>((ref) {
  return FileUploadNotifier(ref.read(fileProvider));
});

class FileUploadNotifier extends StateNotifier<FileUploadState> {
  final FileApi _fileApi;

  FileUploadNotifier(this._fileApi) : super(const FileUploadStateInitial());

  Future<List<FileUploadResponse>> uploadImages(List<XFile> images, {String? folder}) async {
    state = const FileUploadStateLoading();

    try {
      final compressedImages = <MapEntry<String, Uint8List>>[];

      for (var image in images) {
        final bytes = await image.readAsBytes();
        final compressedBytes = await _compressImage(bytes);
        compressedImages.add(MapEntry(image.name, compressedBytes));
      }

      final responses = await _fileApi.uploadFiles(compressedImages, folder: folder);
      state = FileUploadStateSuccess(responses);
      return responses;
    } catch (e) {
      state = FileUploadStateError(e.toString());
      return [];
    }
  }

  Future<Uint8List> _compressImage(Uint8List bytes) async {
    final result = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: 800,
      minHeight: 800,
      quality: 80,
    );
    return result ?? bytes;
  }

  Future<String> getImageUrl(String objectName) async {
    return await _fileApi.getFileUrl(objectName);
  }

  Future<void> deleteImage(String objectName) async {
    await _fileApi.deleteFile(objectName);
  }

  void reset() {
    state = const FileUploadStateInitial();
  }
}

// States
sealed class FileUploadState {
  const FileUploadState();
}

class FileUploadStateInitial extends FileUploadState {
  const FileUploadStateInitial();
}

class FileUploadStateLoading extends FileUploadState {
  const FileUploadStateLoading();
}

class FileUploadStateSuccess extends FileUploadState {
  final List<FileUploadResponse> files;
  const FileUploadStateSuccess(this.files);
}

class FileUploadStateError extends FileUploadState {
  final String error;
  const FileUploadStateError(this.error);
}

extension FileUploadStateExtension on FileUploadState {
  bool get isLoading => this is FileUploadStateLoading;
  bool get isSuccess => this is FileUploadStateSuccess;
  List<FileUploadResponse>? get files {
    if (this is FileUploadStateSuccess) {
      return (this as FileUploadStateSuccess).files;
    }
    return null;
  }
  String? get error {
    if (this is FileUploadStateError) {
      return (this as FileUploadStateError).error;
    }
    return null;
  }
}