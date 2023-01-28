set -e

export TENSORFLOW_VER=r2.11
export TENSORFLOW_DIR=`pwd`/tensorflow

export ANDROID_NDK_HOME=${HOME}/Android/android-ndk-r21e
export ANDROID_NDK_API_LEVEL="28"
export ANDROID_BUILD_TOOLS_VERSION="30.0.0"
export ANDROID_SDK_API_LEVEL="28"
export ANDROID_SDK_HOME=${HOME}/Android/Sdk
export ANDROID_API_LEVEL="28"

function log() {
	echo "-------------"
	echo "----->>> $1"
	echo "-------------"
}

if [ ! -d $ANDROID_NDK_HOME ]; then
    log "Downloading NDK r21e"
    mkdir -p ~/Android
    cd ~/Android
    wget https://dl.google.com/android/repository/android-ndk-r21e-linux-x86_64.zip
    unzip android-ndk-r21e-linux-x86_64.zip
    rm android-ndk-r21e-linux-x86_64.zip
fi

if [ ! -d $ANDROID_SDK_HOME ]; then
    log "Downloading android SDK..."
    mkdir -p $ANDROID_SDK_HOME
    cd $ANDROID_SDK_HOME
    curl --output sdk-tools-linux.zip https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip
    unzip sdk-tools-linux.zip
    echo -ne "y" | ./tools/bin/sdkmanager --install 'build-tools;30.0.0' 'platform-tools' 'platforms;android-28' 'tools'
fi
#if [ ! -d $TENSORFLOW_DIR ]; then
#    log "Clonning tensorflow..."
#    #git clone -b ${TENSORFLOW_VER} --depth 1 https://github.com/tensorflow/tensorflow.git ${TENSORFLOW_DIR}
#    git clone --depth 1 https://github.com/tensorflow/tensorflow.git ${TENSORFLOW_DIR}
#    log "Downloading and installing bazel..."
#    wget https://github.com/bazelbuild/bazel/releases/download/3.1.0/bazel-3.1.0-installer-linux-x86_64.sh
#    chmod 755 bazel-3.1.0-installer-linux-x86_64.sh
#    sudo ./bazel-3.1.0-installer-linux-x86_64.sh
#fi





function rmdir() {
	if [ -d $1 ]; then
		log "Removing folder $1"
		rm -rf $1
	fi
}

function collectHeaders() {
	log "Collecting headers..."
	cd $TF_DIR/tensorflow
	rm -f headers.tar
	find ./lite -name "*.h" | tar -cf headers.tar -T -
	if [ ! -f headers.tar ]; then
		log "headers.tar not created not error given"
		exit 1
	fi
    
    find ./../bazel-tensorflow/external/flatbuffers/include/flatbuffers -name "*.h" | tar -cf include.tar -T -
    if [ ! -f include.tar ]; then
        log "flatbuffer.tar not created not error given"
        exit 1
    fi

    find ./../bazel-tensorflow/external/com_google_absl/ -name "*.h" | tar -cf absl.tar -T -
    if [ ! -f absl.tar ]; then
        log "absl.tar not created not error given"
        exit 1
    fi
 
    mv include.tar $DIST_DIR
    mv absl.tar $DIST_DIR
	mv headers.tar $DIST_DIR
	cd $DIST_DIR
	mkdir -p include/tensorflow
	tar xvf headers.tar -C include/tensorflow
	rm headers.tar

    mkdir -p include/flatbuffers
	tar xvf include.tar -C include/flatbuffers
	rm include.tar

    mkdir -p include/com_google_absl
	tar xvf absl.tar -C include/com_google_absl
	rm absl.tar
}

function buildArch() {
	log "Building for $1 --> $2"
	cd $TF_DIR

	bazel build //tensorflow/lite/c:libtensorflowlite_c.so --config=$1 -c opt
	bazel build //tensorflow/lite/delegates/gpu:libtensorflowlite_gpu_delegate.so -c opt --config $1 --copt -Os --copt -DTFLITE_GPU_BINARY_RELEASE --copt -s --strip always

	mkdir -p $DIST_DIR/libs/android/$2

	cp bazel-bin/tensorflow/lite/c/libtensorflowlite_c.so $DIST_DIR/libs/android/$2/
	cp bazel-bin/tensorflow/lite/delegates/gpu/libtensorflowlite_gpu_delegate.so $DIST_DIR/libs/android/$2/
}

# The order of these two should match
ARCHS=("android_arm64") #"android_arm" "android_x86_64" "android_x86")
ABIS=("arm64-v8a") #"armeabi-v7a" "x86_64" "x86")


DIST_DIR=`dirname ${BASH_SOURCE[0]}`
DIST_DIR=`realpath $DIST_DIR`
TF_DIR=$TENSORFLOW_DIR
#`realpath $1`
BRANCH=$1

echo $DIST_DIR
echo $TF_DIR
echo $BRANCH
echo "Current path: " `pwd`

#if [ ! -d $TF_DIR ]; then
#	log "First param must be tensorflow repo path"
#	exit 1
#fi

if [ -e $BRANCH ]; then
	log "Second param must be a branch/tag"
	#exit 1
    log "Setting default to $TENSORFLOW_VER"
fi

cd $DIST_DIR
log "clean local dist"
rmdir include
rmdir libs/android
mkdir -p libs/android

#cd $TF_DIR
#log "Update repo"
#git checkout master
#git pull
#log "Switching to $BRANCH"
#git checkout $BRANCH

if [ ! -d $TENSORFLOW_DIR ]; then
    log "Clonning tensorflow..."
    git clone -b ${TENSORFLOW_VER} --depth 1 https://github.com/tensorflow/tensorflow.git ${TENSORFLOW_DIR}
    #git clone --depth 1 https://github.com/tensorflow/tensorflow.git ${TENSORFLOW_DIR}
    log "Downloading and installing bazel..."
    #wget https://github.com/bazelbuild/bazel/releases/download/3.1.0/bazel-3.1.0-installer-linux-x86_64.sh
    #chmod 755 bazel-3.1.0-installer-linux-x86_64.sh
    #sudo ./bazel-3.1.0-installer-linux-x86_64.sh
    cd "/usr/local/lib/bazel/bin" && curl -LO https://releases.bazel.build/5.3.0/release/bazel-5.3.0-linux-x86_64 && chmod +x bazel-5.3.0-linux-x86_64
fi


cd $TF_DIR
log "bazel clean"
bazel clean

for i in ${!ARCHS[@]}; do
	buildArch ${ARCHS[$i]} ${ABIS[$i]}
done

collectHeaders

