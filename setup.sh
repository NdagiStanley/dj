#!/bin/bash
# shellcheck disable=SC2059
# SC2059 - printf

__apt__() {
    print_out "Update apt and install apt packages"
    sudo apt update
    sudo apt install python3-pip python3-dev nginx curl
}

__createvenv__() {
    print_out "Upgrade pip, Create virtual env"
    sudo -H pip3 install --upgrade pip
    sudo -H pip3 install virtualenv
    virtualenv "venv"
}

__djangomigrate__() {
    print_out "Makemigrations, Migrate, Collectstatic"
    python manage.py makemigrations
    python manage.py migrate
    python manage.py collectstatic
}

__allowport__() {
    print_out "Add rule to open port"
    sudo ufw allow "$1"
}


print_out() {
    printf "\n\n${POWDER_BLUE}----------------------------------------${NORMAL}"
    printf "\n\t${POWDER_BLUE}$1${NORMAL}\n"
    printf "${POWDER_BLUE}----------------------------------------${NORMAL}\n\n"
}

if [ "$1" != "" ] && type "__$1__" &> /dev/null; then
    eval "__$1__"
elif [ "$1" == "--all" ]; then
    __apt__
    __createvenv__
    # shellcheck disable=SC1091
    # we don't have access to the file yet
    source venv/bin/activate
    python -m pip install -r requirements.txt
    __djangomigrate__
else
    echo "Usage: ./setup.sh (apt, createvenv, djangomigrate, allowport 'PORT')"
fi
