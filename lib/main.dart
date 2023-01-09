import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'camera_feature_controller.dart';

late List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  cameras = await availableCameras();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Colors.redAccent),
      ),
      home: const CameraPage(),
    );
  }
}

class CameraPage extends ConsumerStatefulWidget {
  const CameraPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CameraPageState();
}

class _CameraPageState extends ConsumerState with WidgetsBindingObserver {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    ref.watch(applicationCameraControllerProvider.notifier).onNewCameraSelected(
        cameras.firstWhere((element) => element.lensDirection == CameraLensDirection.back));

    WidgetsBinding.instance.addObserver(this);
  }

  bool showFocusCircle = false;
  double x = 0;
  double y = 0;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController =
        ref.watch(applicationCameraControllerProvider).controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      ref
          .watch(applicationCameraControllerProvider.notifier)
          .onNewCameraSelected(cameraController.description);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var stateController = ref.watch(applicationCameraControllerProvider);

    return Scaffold(
      body: Stack(
        children: [
          _cameraPreviewWidget(),
          Padding(
            padding: const EdgeInsets.only(bottom: 30.0),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  CameraButton(
                    callback: ref.watch(applicationCameraControllerProvider.notifier).switchCamera,
                    buttonStyle: OutlinedButton.styleFrom(
                      shape: const CircleBorder(side: BorderSide(width: 2.0, color: Colors.white)),
                      backgroundColor: Colors.grey[800],
                    ),
                    child: Row(
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(15.0),
                          child: Icon(Icons.flip_camera_android_outlined),
                        ),
                      ],
                    ),
                  ),
                  CameraButton(
                    callback: () {},
                    buttonStyle: ButtonStyle(
                      shape: MaterialStateProperty.all<CircleBorder>(
                        const CircleBorder(side: BorderSide.none),
                      ),
                    ),
                    child: Row(
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(15.0),
                          child: Icon(Icons.camera_alt_outlined),
                        ),
                      ],
                    ),
                  ),
                  CameraButton(
                    callback: () {},
                    buttonStyle: OutlinedButton.styleFrom(
                      shape: const CircleBorder(
                        side: BorderSide(width: 2.0, color: Colors.white),
                      ),
                      backgroundColor: Colors.grey[800],
                    ),
                    child: stateController.lastPictureTaken!.path.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(15.0),
                            child: Icon(Icons.camera_alt_outlined),
                          )
                        : Image.file(
                            File(stateController.lastPictureTaken!.path),
                            height: 30,
                          ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cameraPreviewWidget() {
    final size = MediaQuery.of(context).size;

    final CameraController? controller = ref.watch(applicationCameraControllerProvider).controller;

    if (controller == null || !controller.value.isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            Text(
              'Initialising Camera Controller',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 50.0),
            CircularProgressIndicator()
          ],
        ),
      );
    } else {
      var scale = size.aspectRatio * controller.value.aspectRatio;
      if (scale < 1) scale = 1 / scale;
      return ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(20.0)),
        child: Transform.scale(
          scale: scale,
          child: Stack(
            children: [
              Center(
                child: GestureDetector(
                  onTapUp: (details) => _onTap(details),
                  child: CameraPreview(
                    ref.watch(applicationCameraControllerProvider).controller!,
                  ),
                ),
              ),
              if (showFocusCircle)
                Positioned(
                  top: y,
                  left: x,
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
                      ),
                    ),
                  ),
                )
            ],
          ),
        ),
      );
    }
  }

  Future<void> _onTap(TapUpDetails details) async {
    if (ref.watch(applicationCameraControllerProvider).controller!.value.isInitialized) {
      showFocusCircle = true;
      x = details.localPosition.dx;
      y = details.localPosition.dy;

      double fullWidth = MediaQuery.of(context).size.width;
      double cameraHeight =
          fullWidth * ref.watch(applicationCameraControllerProvider).controller!.value.aspectRatio;

      double xp = x / fullWidth;
      double yp = y / cameraHeight;

      Offset point = Offset(xp, yp);

      await ref.watch(applicationCameraControllerProvider).controller!.setFocusPoint(point);
      setState(() {
        Future.delayed(const Duration(seconds: 2)).whenComplete(() {
          showFocusCircle = false;
        });
      });
    }
  }
}

class CameraButton extends StatelessWidget {
  final VoidCallback callback;
  final Widget child;
  final ButtonStyle buttonStyle;

  const CameraButton({
    Key? key,
    required this.callback,
    required this.child,
    required this.buttonStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ButtonTheme(
      child: ElevatedButton(
        onPressed: callback,
        style: buttonStyle,
        child: child,
      ),
    );
  }
}
