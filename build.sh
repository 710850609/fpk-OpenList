fpk_version=0.2
bin_file="OpenList/app/bin/openlist"

if [ ! -f "${bin_file}" ]; then
    echo "openlist 预编译文件不存在: $bin_file, 开始下载预编译版本..."
    # wget -O openlist-linux-amd64.tar.gz "https://github.com/OpenListTeam/OpenList/releases/latest/download/beta/openlist-linux-amd64.tar.gz"
    # wget -O openlist-linux-amd64.tar.gz "https://github.com/OpenListTeam/OpenList/releases/latest/download/openlist-linux-amd64.tar.gz"
    # wget -O openlist-linux-amd64.tar.gz "https://ghproxy.cn/https://github.com/OpenListTeam/OpenList/releases/latest/download/openlist-linux-amd64.tar.gz"
    wget -O openlist-linux-amd64.tar.gz "https://wget.la/https://github.com/OpenListTeam/OpenList/releases/latest/download/openlist-linux-amd64.tar.gz"
    echo "下载完成，开始解压文件到 $bin_file 目录"
    tar -xzf openlist-linux-amd64.tar.gz

    mv openlist "$bin_file"
    echo "删除下载的压缩包"
    rm -f openlist-linux-amd64.tar.gz
fi


openlist_version=$(./OpenList/app/bin/openlist version | awk '/^Version:/{print $2}' | sed 's/^v//')
echo "当前openlist版本: ${openlist_version}"
app_version="${fpk_version}-${openlist_version}"
sed -i "s|^[[:space:]]*version[[:space:]]*=.*|version=${app_version}|" 'OpenList/manifest'
echo "设置 FPK 版本号为: ${app_version}"

echo "开始打包 OpenList.fpk"
fnpack build --directory OpenList/

fpk_name="OpenList-${app_version}.fpk"
mv OpenList.fpk "${fpk_name}"
echo "打包完成: ${fpk_name}"
