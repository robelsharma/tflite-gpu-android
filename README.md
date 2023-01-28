# tflite-gpu-android
Build TensorFlow Lite GPU for ARM android platform with just single command on Ubuntu.


Tested Build System
----------------------
| Host PC             | Target Device           |
|:-------------------:|:-----------------------:|
| Ubuntu 20.04.5 LTS  | arm64-v8a               |
| Android NDK r21e    | Android 9 (API Level 28)|


How to build
-------------
Execute the shell script with the TensorFlow version number.

```./build-android.sh r2.11```

Where is the artifacts
----------------------
After successful build the headers and libs will be available on the root directory of the cloned project.

What are the artifacts
----------------------
| Host PC             |
|:-------------------:|
| include/  |
| lib/    |

Some test logs from Qualcomm GPU
--------------------------------
- Mobilenet-SSD-quantized
- Qualcomm 450
```
I/tflite: Initialized TensorFlow Lite runtime.
I/tflite: Created TensorFlow Lite delegate for GPU.
E/tflite: Following operations are not supported by GPU delegate:
    CUSTOM TFLite_Detection_PostProcess: TFLite_Detection_PostProcess
    63 operations will run on the GPU, and the remaining 1 operations will run on the CPU.
I/tflite: Replacing 63 node(s) with delegate (TfLiteGpuDelegateV2) node, yielding 2 partitions.
```
```7FPS detection```

Acknowledgements
----------------
- https://github.com/ValYouW/tflite-dist
- https://github.com/terryky/android_tflite
