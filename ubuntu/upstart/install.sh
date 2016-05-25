#!/bin/bash

show_help() {
    cat<<EOF
Syntax: `basename $0` [option]

Options:
    -i      install
    -r      remove
    -l      re-enter config details
    -h      help

Report bugs to <hrishirt@iitk.ac.in>
EOF
}

check_access() {
    echo "Installation requires root privileges."
    sudo touch $HOME/.sudo_success

    if [ ! -f $HOME/.sudo_success ]; then
        echo "Aborted." > /dev/stderr
        exit 1;
    fi
}

get_info() {
    echo -n "Enter IITK username: "
    read user
    echo -n "Enter IITK password: "
    read -s pass
    echo
    echo -n "Is this information correct? (y/n): "
    read -n1 answer
    
    while [ "${answer,,}" != "y" ] && [ "${answer,,}" != "n" ]; do
        read -n1 answer
        echo -en '\b'
    done
                                    
    echo
    if [ "${answer,,}" == "n" ]; then
        get_info
    fi
    echo -en "${user}\n${pass}" > $HOME/.iitk-config
}

user_install() {
    [ -d $HOME/bin ] || mkdir $HOME/bin

    chmod -v 755 *-auth.sh
    cp -v *-auth.sh *.conf $HOME/bin
    chmod -v 644 *
}

install() {
    sudo cp -v $HOME/bin/firewall-auth.sh /usr/sbin/iitk-fortigate
    sudo cp -v $HOME/bin/ironport-auth.sh /usr/sbin/iitk-ironport

    echo "gcc -o daemonize daemonize.c"
    gcc -o daemonize daemonize.c
    sudo cp -v daemonize /usr/sbin/
    rm daemonize

    sudo cp -v *conf /etc/init/

    sudo mkdir -pv /usr/share/iitk-auth/
    sudo cp -v $HOME/.iitk-config /usr/share/iitk-auth/config
    sudo chmod 600 /usr/share/iitk-auth/config
}

uninstall() {
    sudo rm -v /usr/sbin/iitk-fortigate /usr/sbin/iitk-ironport /usr/sbin/daemonize /etc/init/fortigate.conf /etc/init/ironport.conf
    sudo rm -v $HOME/bin/firewall-auth.sh $HOME/bin/ironport.sh
    sudo rm -v $HOME/.iitk-config /usr/share/iitk-auth/config
}

restart_system() {
    action="uninstall"
    [ $1 ] || action="install"
    echo "System restart is recommended for $action to take effect."
    [ $action == "uninstal" ] || echo "You can now manually start/stop auth-daemons 'ironport' and 'fortigate'"
    echo -n "Restart now? (y/n): "
    read -n1 answer
    while [ "${answer,,}" != "y" ] && [ "${answer,,}" != "n" ]; do
        read -n1 answer
        echo -en '\b'
    done

    echo
    if [ "${answer,,}" == "y" ]; then
        sudo reboot
    fi
}

case $1 in
    "-l")
        get_info
        ;;
    "-i")
        check_access
        get_info
        user_install
        install
        restart_system
        ;;
    "-r")
        check_access
        uninstall
        restart_system 1
        ;;
    "-h")
        show_help
        exit 0
        ;;
    *)
        show_help
        exit 1
        ;;
esac


exit 0
