#!/bin/sh
#----------------------------------可以自定义的配置项--------------------------------------
#1.需要打包的工程路径,全部是绝对路径
#2.路径必须到.xcodeproj
#3.如果该工程有多个Target,需要指定一个特定的Target来编译，在路径后面加(两个下划线)__Target名称 例如:xxx/projectName.xcodeproj__TargetName
PROJECT_PATH_ARR=(
"/Users/pobo/源码/SourceCode/C/core/xxx/xxx/iPhone/xxx.xcodeproj" \
"/Users/xxx/源码/SourceCode/C/core/xxx/xxx/iphone/xxx.xcodeproj" \
)
 
#将PROJECT_PATH_ARR配置的地址【全部】Build出来的SDK所支持架构，设置0或者1
#0:支持真机和模拟器
#1:只支持真机
BUILD_SUPPORT_PLATFORM=0
#路径相关配置
TMP_PATH="${HOME}/Desktop"   #编译后的文件存放根路径，此路径默认是桌面路径，可以自己指定对应的路径
 
#---------------------------------------------------------------------------------------------------------
 
#开始时间
start_seconds=$(date +%s);
CURRENT_DATE=`date +%Y-%m-%d_%H-%M-%S`
ROOT_BUILDPATH="${TMP_PATH}/PbLib${CURRENT_DATE}"
TMP_SYMROOT="${ROOT_BUILDPATH}"
TMP_OBJROOT="${TMP_SYMROOT}/TMP_build"
LOG_DIR="${ROOT_BUILDPATH}/Build_Log"
TMP_BUILDSETTING_DIR="${ROOT_BUILDPATH}/TMP_BuildSetting"
 
#build类型  有elease和dDebug两种选项
BUILD_TYPE="Release"
 
TMP_TARGET_NAME="Common"
TMP_FULL_PRODUCT_NAME="Common"
 
 
#创建文件路径
#清除某个目录里面的内容，如果有则清除内容，没有的直接创建该目录
#参数1:目录
clearDirAll(){
        if [ ! -d $1 ];
    then
        mkdir -p $1
    else
        #先删除，再创建
        rm -rf $1
        mkdir -p $1
    fi
    return 0
}
 
#创建Build根目录
clearDirAll ${ROOT_BUILDPATH}
clearDirAll ${TMP_BUILDSETTING_DIR}
clearDirAll ${LOG_DIR}
 
#合并真机和模拟器
#参数1:当前创建的Build目录
mergeSDK(){
    #1.找到真机和模拟器路径
    tmpIphonesPath="$1/${BUILD_TYPE}-iphoneos"
    tmpIphonesimulatorPath="$1/${BUILD_TYPE}-iphonesimulator"
    tmpSDKName=""
    #2.获取当前SDK名称
    for file in ${tmpIphonesPath}/*
    do
        #拿到SDK文件名称
        tmpName=`basename ${file}`
        if [[ $tmpName =~ $TMP_FULL_PRODUCT_NAME ]];then
            tmpSDKName=${tmpName}
        fi
    done
 
    #3.根据BUILD_SUPPORT_PLATFORM配置项判断Build模拟器还是真机
    if [ $BUILD_SUPPORT_PLATFORM -eq 0 ]; then  #支持真机和模拟器
 
        #判断当前的SDK时.a类型的还是.framework类型的,并且各自合并
        tmpAStr=".a" #当前是.a形式的SDK
        tmpFStr=".framework" #当前是.framework形式的SDK
        if [[ $tmpSDKName =~ $tmpFStr ]];then
            #获取SDK名称
            tmpFrameWorkName=${tmpSDKName%.*}
            #合并SDK
            #将真机模式下的FrameWork拷贝一份到根目录下
            cp -r ${tmpIphonesPath}/${tmpSDKName} $1/${tmpSDKName}
            lipo -create "${tmpIphonesPath}/${tmpSDKName}/${tmpFrameWorkName}" "${tmpIphonesimulatorPath}/${tmpSDKName}/${tmpFrameWorkName}" -output "$1/${tmpSDKName}/${tmpFrameWorkName}"
        elif [[ $tmpSDKName =~ $tmpAStr ]]; then
            #合并SDK
            lipo -create "${tmpIphonesPath}/${tmpSDKName}" "${tmpIphonesimulatorPath}/${tmpSDKName}" -output "$1/${tmpSDKName}"
        fi
 
    elif [ $BUILD_SUPPORT_PLATFORM -eq 1 ]; then #只支持真机
        #如果只支持真机，就直接将真机目录下的SDK拷贝到根目录下就可以
        cp -r ${tmpIphonesPath}/${tmpSDKName} $1/${tmpSDKName}
    fi
 
    #4.将.h文件拷贝到.a文件的同级目录下
    find $1 -maxdepth 1 -type d -name "*.h" -exec rm -rf {} \;
    find ${tmpIphonesPath} -maxdepth 1 -type f -name "*.h" -exec mv -f {} $1 \;
 
    #5.移除iphones目录和iphonesimulator目录
    rm -rf "${tmpIphonesPath}"
    rm -rf "${tmpIphonesimulatorPath}"
}
 
#.a库打包方法，接收两个参数
#参数1:工程路径,精确到xxx.xcodeproj
#参数2:TARGET名称
buildLibrary(){
    if [ -n $1 ];then
        if [ -n $2 ];then
            #创建每个.a的Build路径
            buildDir="${ROOT_BUILDPATH}/$2"
            objRootPath="${TMP_OBJROOT}/$2"
            echo "--正在编译 $2........."
            #创建目录
            clearDirAll ${buildDir}
 
            logFile="${LOG_DIR}/$2-Build.log"
            #根据BUILD_SUPPORT_PLATFORM配置项判断Build模拟器还是真机
            if [ $BUILD_SUPPORT_PLATFORM -eq 0 ]; then  #支持真机和模拟器
 
            echo "---------------开始Build模拟器---------------" >>${logFile}
            #开始Build模拟器
            xcodebuild  -configuration "${BUILD_TYPE}" ONLY_ACTIVE_ARCH=NO -project "$1" -target "$2" SYMROOT="${TMP_SYMROOT}" OBJROOT="${objRootPath}" BUILD_DIR="${buildDir}" -sdk iphonesimulator clean build >>${logFile}
 
            echo "---------------开始Build真机---------------" >>${logFile}
            #开始Build真机
            xcodebuild -configuration "${BUILD_TYPE}" ONLY_ACTIVE_ARCH=NO -project "$1" -target "$2" SYMROOT="${TMP_SYMROOT}" OBJROOT="${objRootPath}" BUILD_DIR="${buildDir}" -sdk iphoneos clean build >>${logFile}
 
            elif [ $BUILD_SUPPORT_PLATFORM -eq 1 ]; then #只支持真机
 
            echo "---------------开始Build真机---------------" >>${logFile}
            #开始Build真机
            xcodebuild -configuration "${BUILD_TYPE}" ONLY_ACTIVE_ARCH=NO -project "$1" -target "$2" SYMROOT="${TMP_SYMROOT}" OBJROOT="${objRootPath}" BUILD_DIR="${buildDir}" -sdk iphoneos clean build >>${logFile}
 
            fi
 
            #3.合并真机和模拟器
            mergeSDK ${buildDir};
 
            #4.移除工程根目录下的build目录
            tmpPath=$1
            projectPath=${tmpPath%/*}
            rm -rf "${projectPath}/build"
            rm -rf "${TMP_OBJROOT}"
        else
            echo "Target不能为空"
        fi
    else
        echo "工程路径不能为空"
    fi
}
 
#导出BuildSetting文件并且找出TARGET_NAME和PRODUCT_NAME环境变量的值
#param1:工程路径
#param2:TARGET名称，如果没有可以传nil
readBuildSetting(){
    #0.清除全局变量的值
    TMP_TARGET_NAME=""
    TMP_FULL_PRODUCT_NAME=""
    #1.将工程工程对应Target的BuildSetting文件导出到本地
    BuildSettingFile="${TMP_BUILDSETTING_DIR}/tmp_buildSetting.txt"
    if [ -n "$1" ]; then
        cmdStr="xcodebuild -list -project $1 -showBuildSettings >${BuildSettingFile}"
        if [ -n "$2" ]; then
            cmdStr="xcodebuild -list -project $1 -target $2 -showBuildSettings >${BuildSettingFile} "
        fi
        #执行导出BuildSetting的文件
#        echo "命令:${cmdStr}"
        eval ${cmdStr}
    fi
    #2.解析导出的BuildSetting文件，找出其中的TARGET_NAME和PRODUCT_NAME,并赋值给TMP_TARGET_NAME，TMP_PRODUCT_NAME
    IFS='='
    while read k v
    do
    if [[ "$k" == *FULL_PRODUCT_NAME* ]];then
       TMP_FULL_PRODUCT_NAME=$(echo $v | sed 's/[[:space:]]//g')
    elif [[ "$k" == *TARGET_NAME* ]];then
       TMP_TARGET_NAME=$(echo $v | sed 's/[[:space:]]//g')
    fi
    done < ${BuildSettingFile}
#    echo "TMP_FULL_PRODUCT_NAME=${TMP_FULL_PRODUCT_NAME}  TMP_TARGET_NAME=${TMP_TARGET_NAME}"
    rm -rf "${BuildSettingFile}"
}
 
startBuild(){
    #1.遍历数组，根据路径截取到相应的工程路径以及工程名
    for proPath in ${PROJECT_PATH_ARR[*]}
    do
 
        #2.获取工程路径
        projectPath=${proPath}
        targetName=""
        #3.判断工程路径中是否包含__,如果包含了则说明指定了Target
        tmpStr="__"
        if [[ $proPath =~ $tmpStr ]]
        then
            projectPath=${proPath%__*}
            #取到需要的Target名称
            targetName=${proPath#*__}
        fi
 
        #4.判断targetName是否为空，如果为空则代表TargetName和工程名称相同
#        if [ -z "${targetName}" ];then
#            xcodeproj=${projectPath##*/}
#            projectName=${xcodeproj%.*}
#            targetName=${projectName}
#        fi
        #5.读取TARGET_NAME和PRODUCT_NAME
        readBuildSetting ${projectPath} ${targetName}
        #6.调用Build函数进行Build
        buildLibrary ${projectPath} ${TMP_TARGET_NAME}
    done
}
echo "-----------------开始Build-----------------"
startBuild;
end_seconds=$(date +%s);
echo "-----------------Build完成  耗时:$((end_seconds-start_seconds))s-----------------"
#移除BuildSetting工作目录
rm -rf "${TMP_BUILDSETTING_DIR}"
open ${ROOT_BUILDPATH}
