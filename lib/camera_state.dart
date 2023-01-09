import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class CameraState extends Equatable {
  final CameraController? controller;
  final XFile? lastPictureTaken;

  const CameraState({
    required this.controller,
    required this.lastPictureTaken,
  });

  CameraState copyWith({
    CameraController? controller,
    XFile? lastPictureTaken,
  }) {
    return CameraState(
      controller: controller ?? this.controller,
      lastPictureTaken: lastPictureTaken ?? this.lastPictureTaken,
    );
  }

  @override
  List<Object?> get props => [controller, lastPictureTaken];
}
