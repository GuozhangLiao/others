#!/bin/bash
# @Author: Aliao  
# @Repository: https://github.com/vod-ka  
# @Date: 2021-02-05 16:43:30  
# @Last Modified by:   Aliao  
# @Last Modified time: 2021-02-05 16:43:30

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:~/bin
export PATH

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
    curl -sOL https://nodejs.org/dist/v14.15.4/node-v14.15.4.tar.gz
    tar -zxf node-v14.15.4.tar.gz
    cd node-v14.15.4
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
    Red "1，安装Hexo\n--------------------------"
    Red "2，初始化Hexo\n--------------------------"
    Red "0，exit\n--------------------------"
    read -p "请输入数字，回车键继续： " number
    case "$number" in
        1)
        update_system
        git_install
        gcc_install
        compile_nodejs
        hexoinstall
        menu
        ;;
        2)
        inithexo
        ;;
        0)
        exit 1
        ;;
    esac
}

#main
menu