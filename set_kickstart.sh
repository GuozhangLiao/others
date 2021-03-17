#!/bin/bash
# @Author: Aliao  
# @Repository: https://github.com/vod-ka   
# @Date: 2021-03-14 13:57:43  
# @Last Modified by:   Aliao  
# @Last Modified time: 2021-03-14 13:57:43

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$HOME
export PATH
INTERFACE=$(find /etc/ -name "ifcfg-e*")
STATUS=$(grep "^BOOT" "$INTERFACE" | cut -d= -f2 | sed 's/"//g;s/"//g')
CUIP=$(grep "IPADDR=" "$INTERFACE" | cut -d= -f2)
IPG=$(echo "$CUIP" | cut -d. -f1-3)

Green(){
    echo -e "\033[32;01m$1\033[0m"
}

Red(){
    echo -e "\033[31;01m$1\033[0m"
}

Blue(){
    echo -e "\033[34;01m$1\033[0m"
}

#检验用户
check_user(){
    if [ $(id -u) -eq 0 ]
    then
        echo
    else
        Red "请使用roo用户执行脚本！"
        exit 1
    fi
}

#升级系统
update_system(){
    yum update -y
    yum install -y wget
    clear
    Green "系统升级完成！"
}

#安装设置TFTP
install_tftp(){
    yum install -y xinetd tftp-server
    sed -i '14s/yes/no/g' /etc/xinetd.d/tftp
    systemctl restart xinetd
    systemctl enable xinetd
    firewall-cmd --permanent --add-port=69/udp
    firewall-cmd --permanent --add-port=21/tcp
    firewall-cmd --permanent --add-service=ftp
    firewall-cmd --reload
    clear
    Green "tftp部署完成！"
}

#安装设置vsftp
install_vsftp(){
    yum install -y vsftpd
    mv /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf_bak
    cat > /etc/vsftpd/vsftpd.conf<<-EOF
anonymous_enable=YES
anon_upload_enable=NO
anon_root=/var/ftp
anon_mkdir_write_enable=NO
anon_other_write_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=YES
xferlog_std_format=YES
listen=NO
listen_ipv6=YES
pam_service_name=vsftpd
userlist_enable=YES
tcp_wrappers=YES
EOF
    systemctl enable vsftpd
    systemctl start vsftpd
    cp -r "$ISODST"/* /var/ftp
    clear
    Green "vsftpd部署完成！"
}

#安装设置dhcp
install_dhcp(){
    if [ "$STATUS" != dhcp ]
    then
        echo
    else
        Red "请把当期的网卡工作方式改为 static "
        exit 1
    fi
    yum install -y dhcp
    cat > /etc/dhcp/dhcpd.conf <<-EOF
allow booting;
allow bootp;
ddns-update-style interim;
ignore client-updates;
subnet $IPG.0 netmask 255.255.255.0 {
    option subnet-mask
    255.255.255.0;
    option domain-name-servers $CUIP;
    range dynamic-bootp $IPG.100 $IPG.200;
    default-lease-time 21600;
    max-lease-time 43200;
    next-server
    $CUIP;
    filename "pxelinux.0";
}
EOF
    systemctl start dhcpd
    systemctl enable dhcpd
    clear
    Green "部署DHCP完成！"
}

#部署syslinux
intall_syslinux(){
    SYSISO="$HOME/centos.iso"
    ISOURL="http://mirrors.huaweicloud.com/centos/7.9.2009/isos/x86_64/CentOS-7-x86_64-Minimal-2009.iso"
    ISODST="/mnt/iso"
    DEFAULTDST="/var/lib/tftpboot/pxelinux.cfg"
    yum install -y syslinux
    wget -O "$SYSISO" $ISOURL
    mkdir $ISODST $DEFAULTDST
    mount -o loop "$SYSISO" $ISODST
    cp $ISODST/images/pxeboot/{vmlinuz,initrd.img} /var/lib/tftpboot/
    cp $ISODST/isolinux/{vesamenu.c32,boot.msg} /var/lib/tftpboot/
    cp /usr/share/syslinux/pxelinux.0 /var/lib/tftpboot/
    cat > $DEFAULTDST/default<<-EOF
default linux
timeout 600

display boot.msg

# Clear the screen when exiting the menu, instead of leaving the menu displayed.
# For vesamenu, this means the graphical background is still displayed without
# the menu itself for as long as the screen remains in graphics mode.
menu clear
menu background splash.png
menu title CentOS 7
menu vshift 8
menu rows 18
menu margin 8
#menu hidden
menu helpmsgrow 15
menu tabmsgrow 13

# Border Area
menu color border * #00000000 #00000000 none

# Selected item
menu color sel 0 #ffffffff #00000000 none

# Title bar
menu color title 0 #ff7ba3d0 #00000000 none

# Press [Tab] message
menu color tabmsg 0 #ff3a6496 #00000000 none

# Unselected menu item
menu color unsel 0 #84b8ffff #00000000 none

# Selected hotkey
menu color hotsel 0 #84b8ffff #00000000 none

# Unselected hotkey
menu color hotkey 0 #ffffffff #00000000 none

# Help text
menu color help 0 #ffffffff #00000000 none

# A scrollbar of some type? Not sure.
menu color scrollbar 0 #ffffffff #ff355594 none

# Timeout msg
menu color timeout 0 #ffffffff #00000000 none
menu color timeout_msg 0 #ffffffff #00000000 none

# Command prompt text
menu color cmdmark 0 #84b8ffff #00000000 none
menu color cmdline 0 #ffffffff #00000000 none

# Do not display the actual menu unless the user presses a key. All that is displayed is a timeout message.

menu tabmsg Press Tab for full configuration options on menu items.

menu separator # insert an empty line
menu separator # insert an empty line

label linux
  menu label ^Install CentOS 7
  kernel vmlinuz
  append initrd=initrd.img inst.stage2=ftp://$CUIP ks=ftp://$CUIP/pub/ks.cfg quiet

label check
  menu label Test this ^media & install CentOS 7
  menu default
  kernel vmlinuz
  append initrd=initrd.img inst.stage2=hd:LABEL=CentOS\x207\x20x86_64 rd.live.check quiet

menu separator # insert an empty line

# utilities submenu
menu begin ^Troubleshooting
  menu title Troubleshooting

label vesa
  menu indent count 5
  menu label Install CentOS 7 in ^basic graphics mode
  text help
        Try this option out if you're having trouble installing
        CentOS 7.
  endtext
  kernel vmlinuz
  append initrd=initrd.img inst.stage2=hd:LABEL=CentOS\x207\x20x86_64 xdriver=vesa nomodeset quiet

label rescue
  menu indent count 5
  menu label ^Rescue a CentOS system
  text help
        If the system will not boot, this lets you access files
        and edit config files to try to get it booting again.
  endtext
  kernel vmlinuz
  append initrd=initrd.img inst.stage2=hd:LABEL=CentOS\x207\x20x86_64 rescue quiet

label memtest
  menu label Run a ^memory test
  text help
        If your system is having issues, a problem with your
        system's memory may be the cause. Use this utility to
        see if the memory is working correctly.
  endtext
  kernel memtest

menu separator # insert an empty line

label local
  menu label Boot from ^local drive
  localboot 0xffff

menu separator # insert an empty line
menu separator # insert an empty line

label returntomain
  menu label Return to ^main menu
  menu exit

menu end
EOF
    clear
    Green "syslinux部署完成！"
}

#部署kickstart文件
kickstart_file(){
    sourcefile="$HOME/anaconda-ks.cfg"
    KSDST="/var/ftp/pub"
    ksfile="$KSDST/ks.cfg"
    CT1="$HOME/ct1.txt"
    CT2="$HOME/ct2.txt"
    if [ -f "$sourcefile" ]
    then
        echo
    else
        Red "$sourcefile 文件不存在请检查文件路径！"
        exit 1
    fi
    echo
    if [ -d $KSDST ]
    then
        echo
    else
        mkdir -p $KSDST
    fi
    cp "$sourcefile" "$ksfile"
    chmod +r "$ksfile"
    echo "url --url=ftp://$CUIP" > "$CT1"
    echo "clearpart --all --initlabel" > "$CT2"
    sed -i '/cdrom/r ct1.txt' "$ksfile"
    sed -i '/cdrom/d' "$ksfile"
    sed -i '/clearpart/d' "$ksfile"
    sed -i '/Partition/r ct2.txt' "$ksfile"
    clear
    Green "kickstart部署完成！"
}

#清除垃圾
remove_depans(){
    umount $ISODST
    for i in $SYSISO $ISODST $CT1 $CT2
    do
        rm -rf "$i"
    done
    clear
}

#main
clear
check_user
update_system
install_dhcp
install_tftp
intall_syslinux
install_vsftp
kickstart_file
remove_depans
Green " PXE + TFTP + FTP + DHCP + Kickstart部署完成！"