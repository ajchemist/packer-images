$ErrorActionPreference = "Stop"

function Validate-TemplateHCL {
    Param (
        [string]
        [Parameter(Mandatory=$true)]
        $path
    )
    Get-ChildItem $path -Recurse -File -Filter "*.pkr.hcl" | ForEach-Object {
        packer validate $_.FullName
    }
}

# packer validate
# packer inspect
# packer console

$PathLinux = "./images/linux"
Validate-TemplateHCL -Path $PathLinux
