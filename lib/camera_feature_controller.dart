import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'camera_state.dart';
import 'main.dart';

final applicationCameraControllerProvider =
    StateNotifierProvider<CameraFeatureController, CameraState>(
  (ref) {
    return CameraFeatureController(
      CameraState(
        controller: CameraController(
          cameras[0],
          ResolutionPreset.max,
          enableAudio: false,
          imageFormatGroup:
              Platform.isAndroid ? ImageFormatGroup.yuv420 : ImageFormatGroup.bgra8888,
        ),
        lastPictureTaken: XFile(''),
      ),
    );
  },
);

class CameraFeatureController extends StateNotifier<CameraState> {
  CameraFeatureController(super.state);

  Future<void> onNewCameraSelected(CameraDescription cameraDescription) async {
    final CameraController? oldController = state.controller;
    if (oldController != null) {
      state.copyWith(controller: null);
      await oldController.dispose();
    }

    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.max,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.yuv420 : ImageFormatGroup.bgra8888,
    );

    state = state.copyWith(controller: cameraController);

    // If the controller is updated then update the UI.
    cameraController.addListener(() {
      if (mounted) {
        state = state.copyWith(controller: state.controller);
      }
      if (cameraController.value.hasError) {
        log('Camera error ${cameraController.value.errorDescription}');
      }
    });

    try {
      await state.controller!.initialize();
    } on CameraException catch (e) {
      log('CameraException error is $e');
    }

    if (mounted) {
      state = state.copyWith(controller: state.controller);
    }
  }

  void updateLastPictureTaken(XFile lastPictureTaken) {
    log('Picture taken: ${lastPictureTaken.path}');
    state = state.copyWith(lastPictureTaken: lastPictureTaken);
  }

  Future<void> switchCamera() async {
    if (state.controller!.description.lensDirection == CameraLensDirection.back) {
      await onNewCameraSelected(cameras.firstWhere(
          (selectedCamera) => selectedCamera.lensDirection == CameraLensDirection.front));
    } else {
      await onNewCameraSelected(cameras.firstWhere(
          (selectedCamera) => selectedCamera.lensDirection == CameraLensDirection.back));
    }
  }

  Future<void> switchToFrontCamera() async {
    if (state.controller!.description.lensDirection == CameraLensDirection.front) {
      return;
    }

    await onNewCameraSelected(cameras
        .firstWhere((selectedCamera) => selectedCamera.lensDirection == CameraLensDirection.front));
  }

  Future<void> switchToRearCamera() async {
    if (state.controller!.description.lensDirection == CameraLensDirection.back) {
      return;
    }

    await onNewCameraSelected(cameras
        .firstWhere((selectedCamera) => selectedCamera.lensDirection == CameraLensDirection.back));
  }

  Future<XFile?> takePicture() async {
    final CameraController? cameraController = state.controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      log('Error: select a camera first.');
      return null;
    }

    if (cameraController.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      final XFile file = await cameraController.takePicture();
      return file;
    } on CameraException catch (e) {
      log('CameraException error is ${e.description}');
      return null;
    }
  }
}
