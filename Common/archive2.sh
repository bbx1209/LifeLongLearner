
#! /bin/bash -il

# 合并在真机和模拟器上编译出的QiShareSDK
# 如果工程名称和Framework的Target名称不一样的话，要自定义FMKNAME
FMK_NAME="Common"
# INSTALL_DIR 是导出framework的路径
# 在工程的根目录创建framework的文件夹.
INSTALL_DIR=${SRCROOT}/QiShareFrameworks/${FMK_NAME}.framework
# 合成framework后，WRK_DIR会被删除
WRK_DIR=build
DEVICE_DIR=${WRK_DIR}/Release-iphoneos/${FMK_NAME}.framework
SIMULATOR_DIR=${WRK_DIR}/Release-iphonesimulator/${FMK_NAME}.framework
# Clean两个架构的framework
xcodebuild OTHER_CFLAGS="-fembed-bitcode" -configuration "Release" -target "${FMK_NAME}" -sdk iphoneos clean build
xcodebuild OTHER_CFLAGS="-fembed-bitcode" -configuration "Release" -target "${FMK_NAME}" -sdk iphonesimulator clean build
# 删除之前生成的framework
if [ -d "${INSTALL_DIR}" ]
then
rm -rf "${INSTALL_DIR}"
fi
mkdir -p "${INSTALL_DIR}"
cp -R "${DEVICE_DIR}/" "${INSTALL_DIR}/"
# 合成
lipo -create "${DEVICE_DIR}/${FMK_NAME}" "${SIMULATOR_DIR}/${FMK_NAME}" -output "${INSTALL_DIR}/${FMK_NAME}"
# 删除 WRK_DIR
#rm -r "${WRK_DIR}"
# 打开 INSTALL_DIR
#open "${INSTALL_DIR}"


