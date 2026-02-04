build_version=10

declare -A PARAMS

# 默认值
PARAMS[build_all]="false"
PARAMS[build_pre]="false"
PARAMS[arch]="amd64"
PARAMS[download_proxy_url]="https://gh.llkk.cc"

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
download_proxy_url="${PARAMS[download_proxy_url]}"
arch="${PARAMS[arch]}"
echo "build_all: ${build_all}"
echo "arch: ${arch}"
echo "download_proxy_url: ${download_proxy_url}"
echo "pre: ${build_pre}"

# platform 取值 x86, arm, risc-v, all
platform="unknown"
openlist_arch="unknown"
os_min_version="1.0.0"
if [ "${arch}" == "amd64" ]; then
    platform="x86"
    os_min_version="1.1.8"
    openlist_arch="linux-amd64"
elif [ "${arch}" == "aarch64" ]; then
    platform="arm"
    os_min_version="1.0.2"
    openlist_arch="linux-arm64"
elif [ "${arch}" == "risc-v" ]; then
    platform="risc-v"
    openlist_arch="linux-riscv64"
else
    echo "未知的 arch 参数: ${arch}"
    exit 1
fi
echo "设置 platform 为: ${platform}"

get_last_openlist_version(){
    # GitHub API URL
    api_url="https://api.github.com/repos/OpenListTeam/OpenList/releases/latest"
    # 使用 curl 获取 JSON 数据
    json_data=$(curl -s "$api_url")
    # 使用 grep 和 sed 提取版本号
    latest_version=$(echo "$json_data" | grep -oP '"tag_name": "\Kv[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    # 去除版本号前的 'v'
    latest_version=${latest_version#v}
    # 输出最新版本号
    echo "$latest_version"
}

if [ "${build_all}" == "true" ] || [ ! -f "${bin_file}" ]; then
    echo "openlist 预编译文件不存在: $bin_file, 开始下载预编译版本..."
    # wget -O openlist-linux-amd64.tar.gz "https://github.com/OpenListTeam/OpenList/releases/latest/download/openlist-linux-amd64.tar.gz"
    download_url="https://github.com/OpenListTeam/OpenList/releases/latest/download/openlist-${openlist_arch}.tar.gz"
    # download_url="https://gh.llkk.cc/${download_url}"
    if [ -n "${download_proxy_url}" ]; then
      echo "使用下载代理: ${download_proxy_url}"
      download_url="${download_proxy_url}/${download_url}"
    fi
    echo "开始下载OpenList: ${download_url}"
    wget -O openlist.tar.gz "${download_url}" || { echo "下载文件失败"; exit 1; }
    echo "下载完成，开始解压文件"
    tar -xzf openlist.tar.gz || { echo "解压文件失败"; exit 1; }
    # echo "$(ls -lh)"
    mkdir -p OpenList/app/bin/
    echo "移动文件到 $bin_file 位置"
    mv openlist "$bin_file" || { echo "移动文件失败"; exit 1; }
    # echo "删除下载的压缩包"
    # rm -f openlist.tar.gz
else
    echo "使用已有的 openlist 预编译文件: $bin_file, 版本: ${openlist_version}"
fi

# echo "$(file ./OpenList/app/bin/openlist)"
# echo "$(./OpenList/app/bin/openlist version)"
# 改用api获取最新版本号，支持多架构打包
openlist_version=$(get_last_openlist_version)
# openlist_version=$(./OpenList/app/bin/openlist version | awk '/^Version:/{print $2}' | sed 's/^v//')
echo "当前openlist版本: ${openlist_version}"
fpk_version="${openlist_version}-${build_version}"
if [ "$build_pre" == 'true' ];then 
    cur_time=$(date +"%Y%m%d_%H%M%S")
    echo "当前时间：$cur_time"
    fpk_version="${fpk_version}-${cur_time}"
fi

sed -i "s|^[[:space:]]*version[[:space:]]*=.*|version=${fpk_version}|" 'OpenList/manifest'
echo "设置 manifest 的 version 为: ${fpk_version}"
sed -i "s|^[[:space:]]*platform[[:space:]]*=.*|platform=${platform}|" 'OpenList/manifest'
echo "设置 manifest 的 platform 为: ${platform}"
sed -i "s|^[[:space:]]*os_min_version[[:space:]]*=.*|os_min_version=${os_min_version}|" 'OpenList/manifest'
echo "设置 manifest 的 os_min_version 为: ${os_min_version}"

jq ".[0].items |= map(if .field == \"openlist_version\" then .initValue = \"$openlist_version\" else . end)" OpenList/wizard/config > temp.json \
  && mv temp.json OpenList/wizard/config
echo "更新配置向导中的OpenList版本号为: ${openlist_version}"

echo "开始打包 OpenList.fpk"


if command -v fnpack >/dev/null 2>&1; then
    echo "使用系统已安装的 fnpack $(fnpack | grep Version) 进行打包"
    fnpack build --directory OpenList/ || { echo "打包失败"; exit 1; }
else
    echo "使用本地 fnpack 脚本进行打包"
    ./fnpack.sh build --directory OpenList || { echo "打包失败"; exit 1; }
fi 

fpk_name="OpenList-${fpk_version}-${arch}.fpk"
mv OpenList.fpk "${fpk_name}"
echo "打包完成: ${fpk_name}"
