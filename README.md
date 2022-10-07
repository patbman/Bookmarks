# Bookmarks
 edge and chrome bookmark exporter

To run open powershell in script directory and run `type exportbookmarks.ps1 | powershell.exe -noprofile -`

`Invoke-Expression $($(Invoke-WebRequest https://raw.githubusercontent.com/patbman/Bookmarks/main/exportbookmarks.ps1).Content)`