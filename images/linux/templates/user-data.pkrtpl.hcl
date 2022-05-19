#cloud-config
autoinstall:
  version: 1
  locale: ${locale}
  timezone: UTC
  keyboard:
    layout: ${keyboard_layout}
    variant: ${keyboard_variant}
  identity:
    hostname: ${hostname}
    username: ${username}
    password: ${password}
  network:
    network:
      version: 2
      ethernets:
        eth0:
          dhcp4: true
          dhcp-identifier: mac
  ssh:
    install-server: true
    allow-pw: true
    authorized-keys:
      - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGzaCMIBy1D4gb6q448lNdpQ2aXjxtYN1+9KaJJpZiRj magneto-core/id_ed25519
  user-data:
    disable_root: false
  storage:
    layout:
      name: lvm
  packages:
    - linux-virtual
    - linux-image-virtual
    - linux-tools-virtual
    - linux-cloud-tools-virtual
    - linux-azure
  early-commands:
    # workaround to stop ssh for packer as it thinks it timed out
    - sudo systemctl stop ssh
  late-commands:
    - echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /target/etc/sudoers.d/ubuntu
    - curtin in-target --target=/target -- chmod 440 /etc/sudoers.d/ubuntu

;; Local Variables:
;; mode: yaml
;; End:
