---
titie: Packer Images
author: ajchemist
---


``` shell
sudo apt-get install whois
mkpasswd --method=SHA-512 --rounds=4096
```


``` powershell
$env:PACKER_LOG=1 # 0 default
packer build -on-error=ask `
    -var "cpus=$cpus" `
    $script
```
