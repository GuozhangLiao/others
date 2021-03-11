#!/bin/bash
# @Author: Aliao  
# @Repository: https://github.com/vod-ka  
# @Date: 2021-02-05 16:43:30  
# @Last Modified by:   Aliao  
# @Last Modified time: 2021-02-05 16:43:30

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:~/bin
export PATH

urltxt="$HOME/node-url.txt"
node_bin_dst="/usr/local/lib/nodejs"
nodedst=$(which node)

#颜色
Green(){
    echo -e "\033[32;01m$1\033[0m"
}

Red(){
    echo -e "\033[31;01m$1\033[0m"
}

Blue(){
    echo -e "\033[34;01m$1\033[0m"
}

#更新系统
update_system(){
    yum update -y 
}

#安装 git
git_install(){
    yum install -y git
}

get_node(){
    yum install -y lynx
    lynx -dump http://nodejs.cn/download/ > "$urltxt"
    node_src_url=$(grep " 8\." "$urltxt" | sed 's/..8\. //g')
    node_src=$(grep " 8\." "$urltxt" | cut -d/ -f7 | cut -d. -f1-3)
    node_bin_url=$(grep "15\." "$urltxt" | sed 's/..15\. //g')
    node_ver=$(grep "15\." "$urltxt" | cut -d/ -f7 | cut -d. -f1-3)
}

nodejs_binary(){
    cd "$HOME"
    curl -sOL "$node_bin_url"
    if [ -d $node_bin_dst ]
    then
        echo
    else
        mkdir -p "$node_bin_dst"
    fi
    tar -Gxvf "$HOME"/"$node_ver".tar.xz -C $node_bin_dst
    echo "export PATH=/usr/local/lib/nodejs/$node_ver/bin:$PATH" >> /etc/profile
    source /etc/profile
    node -v
    npm -v
    npx -v
    Green "nodejs二进制安装完成！"
}

#安装 gcc-7.3
gcc_install(){
    yum install -y centos-release-scl 
    yum install -y devtoolset-7-gcc*
    source /opt/rh/devtoolset-7/enable
    ln -s /opt/rh/devtoolset-7/root/usr/bin/gcc /usr/bin/gcc
    ln -s /opt/rh/devtoolset-7/root/usr/bin/g++ /usr/bin/g++
    gcc -v
    g++ -v
    Green "安装 gcc-7.3 完成"
}

#编译安装最新 LTS的 Node.js
compile_nodejs(){
    cd "$HOME"
    curl -sOL "$node_src_url"
    tar -zxvf "$node_src".tar.gz
    cd "$node_src"
    ./configure
    make && make install
    clear
    node -v
    npm -v
    echo -e "export NODE_HOME=$nodedst\nexport PATH=\$NODE_HOME/bin:\$PATH"
    clear
    node -v
    npm -v
    Green "编译安装 Node.js 完成"
}

#安装 Hexo 
hexoinstall() {
    npm install -g hexo-cli 
    hexo -v
    Green "Hexo 安装完成"
}

#初始化 Hexo
inithexo(){
    read -p '请输入需要初始化的项目路径: ' lj
    if [ -d "$lj" ]
    then
        Green "路径 $lj 存在！"
    else
        Red "路径不存在，现在创建..."
        mkdir -p "$lj"
    fi
    hexo init "$lj"
    cd "$lj" 
    npm install
    hexo g
    hexo s
    Green "初始 Hexo 成功，可以用浏览器打开 http://localhost:4000/ 查看测试页面！"
}

#菜单
menu(){
    clear
    set -e
    Red "========================================================================="
    Red "#                                                                       #"
    Red "#                  @Name: hexo_centos7_install_script                   #"
    Red "#                  @Author: Aliao                                       #"
    Red "#                  @Repository: https://github.com/vod-ka               #"
    Red "#                                                                       #"
    Red "========================================================================="
    echo
    echo
    Red "1，安装Hexo（nodejs二进制安装）        推荐\n--------------------------"
    Red "2，安装Hexo（nodejs编译安装)\n--------------------------"
    Red "3，初始化Hexo\n--------------------------"
    Red "0，exit\n--------------------------"
    read -p "请输入数字，回车键继续： " number
    case "$number" in
        1)
        update_system
        git_install
        get_node
        nodejs_binary
        hexoinstall
        menu
        ;;
        2)
        update_system
        git_install
        gcc_install
        get_node
        compile_nodejs
        hexoinstall
        menu
        ;;
        3)
        inithexo
        ;;
        0)
        exit 1
        ;;
    esac
}

#main
if [ $(id -u) -eq 0 ]
then
    menu
else
    Red "请使用 root 用户执行脚本"
    exit 1
fi