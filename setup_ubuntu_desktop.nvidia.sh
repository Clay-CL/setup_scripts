#! /bin/bash

install_ubuntu_desktop() {
    # Install Ubuntu Desktop
    sudo apt-get update
    sudo apt-get install ubuntu-desktop

    sudo apt install gdm3

    cat /etc/X11/default-display-manager

    # Edit /etc/gdm3/custom.conf to disable Wayland
    sudo sed -i 's/^#WaylandEnable=false/WaylandEnable=false/' /etc/gdm3/custom.conf

    # If the line doesn't exist, add it under [daemon] section
    if ! grep -q "WaylandEnable=false" /etc/gdm3/custom.conf; then
        sudo sed -i '/^\[daemon\]/a WaylandEnable=false' /etc/gdm3/custom.conf
    fi

    sudo systemctl restart gdm3


    sudo systemctl get-default

    sudo systemctl isolate graphical.target

    ps aux | grep X | grep -v grep

    sudo apt install mesa-utils

    sudo DISPLAY=:0 XAUTHORITY=$(ps aux | grep "X.*\-auth" | grep -v Xdcv | grep -v grep | sed -n 's/.*-auth \([^ ]\+\).*/\1/p') glxinfo | grep -i "opengl.*version"
}

install_gpu_driver() {
    curl https://raw.githubusercontent.com/GoogleCloudPlatform/compute-gpu-installation/main/linux/install_gpu_driver.py --output install_gpu_driver.py

    sudo python3 install_gpu_driver.py

    sudo systemctl isolate multi-user.target
    sudo systemctl isolate graphical.target

    sudo DISPLAY=:0 XAUTHORITY=$(ps aux | grep "X.*\-auth" | grep -v Xdcv | grep -v grep | sed -n 's/.*-auth \([^ ]\+\).*/\1/p') glxinfo | grep -i "opengl.*version"
}

install_docker() {
    sudo apt-get update
    sudo apt-get install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update

    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    sudo usermod -aG docker $USER

    sudo docker run hello-world
}

install_nvidia_container_toolkit() {
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
    && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list \
    && \
    sudo apt-get update

    sudo apt-get install -y nvidia-container-toolkit

    sudo systemctl restart docker
    sudo nvidia-ctk runtime configure --runtime=docker

    sudo systemctl restart docker

    sudo docker run --rm --runtime=nvidia --gpus all ubuntu nvidia-smi
}

main() {
    install_ubuntu_desktop
    install_gpu_driver
    install_docker
    install_nvidia_container_toolkit

    echo "Done"

    # Ask for user confirmation before rebooting
    read -p "Installation complete. Do you want to reboot the system now? (y/n): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Rebooting system..."
        sudo reboot
    else
        echo "Please remember to reboot your system to complete the installation."
    fi
}

main
