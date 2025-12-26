build_version=5

declare -A PARAMS

# 默认值
PARAMS[build_all]="false"
PARAMS[build_pre]="false"
PARAMS[arch]="linux-amd64"

# 解析 key=value 格式的参数
for arg in "$@"; do
  if [[ "$arg" == *=* ]]; then
    key="${arg%%=*}"
    value="${arg#*=}"
    PARAMS["$key"]="$value"
  else
    # 处理标志参数
    case "$arg" in
      --pre)
        PARAMS[pre]="true"
        ;;
      *)
        echo "忽略未知参数: $arg"
        ;;
    esac
  fi
done

bin_file="OpenList/app/bin/openlist"
build_all="${PARAMS[build_all]}"
build_pre="${PARAMS[build_pre]}"
arch="${PARAMS[arch]}"
echo "build_all: ${build_all}"
echo "pre: ${build_pre}"
echo "arch: ${arch}"


if [ "${build_all}" == "true" ] || [ ! -f "${bin_file}" ]; then
    echo "openlist 预编译文件不存在: $bin_file, 开始下载预编译版本..."
    # wget -O openlist-linux-amd64.tar.gz "https://github.com/OpenListTeam/OpenList/releases/latest/download/openlist-linux-amd64.tar.gz"
    download_url="https://github.com/OpenListTeam/OpenList/releases/latest/download/openlist-${arch}.tar.gz"
    # download_url="https://gh.llkk.cc/${download_url}"
    echo "开始下载OpenList: ${download_url}"
    wget -O openlist.tar.gz "${download_url}"
    echo "下载完成，开始解压文件"
    tar -xzf openlist.tar.gz
    echo "$(ls -lh)"
    mkdir -p OpenList/app/bin/
    echo "移动文件到 $bin_file 位置"
    mv openlist "$bin_file"
    # echo "删除下载的压缩包"
    # rm -f openlist.tar.gz
fi

# echo "$(file ./OpenList/app/bin/openlist)"
# echo "$(./OpenList/app/bin/openlist version)"
openlist_version=$(./OpenList/app/bin/openlist version | awk '/^Version:/{print $2}' | sed 's/^v//')
echo "当前openlist版本: ${openlist_version}"
fpk_version="${openlist_version}-${build_version}"
if [ "$build_pre" == 'true' ];then 
    fpk_version="${fpk_version}-pre"
fi
sed -i "s|^[[:space:]]*version[[:space:]]*=.*|version=${fpk_version}|" 'OpenList/manifest'
echo "设置 FPK 版本号为: ${fpk_version}"

# platform 取值 x86, arm, all
platform="all"
if [ "${arch}" == "linux-amd64" ]; then
    platform="x86"
elif [ "${arch}" == "linux-arm64" ]; then
    platform="arm"
else
    echo "未知的 arch 参数，使用默认值: ${arch}"
fi
echo "设置 platform 为: ${platform}"
sed -i "s|^[[:space:]]*platform[[:space:]]*=.*|platform=${platform}|" 'OpenList/manifest'

echo "开始打包 OpenList.fpk"
# fnpack build --directory OpenList/
./fnpack.sh build --directory OpenList

fpk_name="OpenList-${arch}-${fpk_version}.fpk"
mv OpenList.fpk "${fpk_name}"
echo "打包完成: ${fpk_name}"
