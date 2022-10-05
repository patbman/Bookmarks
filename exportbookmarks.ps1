#export edge and chrome bookmarks to respective html files to be imported
#modified version of gunnarhaslinger edge bookmark script 
#bookmarks will export as HTML files to the users desktop



$HTML_File_Dir = "$($env:userprofile)\Desktop\$($env:COMPUTERNAME)_bookmarks"
#Edge export
$Edge_JSON_File_Path = "$($env:localappdata)\Microsoft\Edge\User Data\Default\Bookmarks"
$Edge_File_Path = "$($HTML_File_Dir)\Edge-Bookmarks.html"


bookmark_export $Edge_JSON_File_Path $Edge_File_Path $HTML_File_Dir


#Chrome export
$chrome_JSON_File_Path = "$($env:localappdata)\Google\Chrome\User Data\Default\Bookmarks"
$Chrome_File_Path = "$($HTML_File_Dir)\Chrome-Bookmarks.html"

bookmark_export $chrome_JSON_File_Path $Chrome_File_Path $HTML_File_Dir






function bookmark_export{
    param($json_file, $output_html, $HTML_File_Dir)



    
    $Date_LDAP_NT_EPOCH = Get-Date -Year 1601 -Month 1 -Day 1 -Hour 0 -Minute 0 -Second 0

    if (!(Test-Path -Path $json_file -PathType Leaf)) {
    throw "Source-File Path $json_file does not exist!" 
}
if (!(Test-Path -Path $HTML_File_Dir -PathType Container)) { 
    throw "Destination-Directory Path $HTML_File_Dir does not exist!" 
}

# ---- HTML Header ----
$BookmarksHTML_Header = @'
<!DOCTYPE NETSCAPE-Bookmark-file-1>
<!-- This is an automatically generated file.
     It will be read and overwritten.
     DO NOT EDIT! -->
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
<TITLE>Bookmarks</TITLE>
<H1>Bookmarks</H1>
<DL><p>
'@

$BookmarksHTML_Header | Out-File -FilePath $output_html -Force -Encoding utf8

# ---- Enumerate Bookmarks Folders ----
Function Get-BookmarkFolder {
    [cmdletbinding()] 
    Param( 
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        $Node 
    )
    function ConvertTo-UnixTimeStamp {
        param(
            [Parameter(Position = 0, ValueFromPipeline = $True)]
            $TimeStamp 
        )
        $date = [Decimal] $TimeStamp
        if ($date -gt 0) { 
            # Timestamp Conversion: JSON-File uses Timestamp-Format "Ticks-Offset since LDAP/NT-Epoch" (reference Timestamp, Epoch since 1601 see above), HTML-File uses Unix-Timestamp (Epoch, since 1970)																																																   
            $date = $Date_LDAP_NT_EPOCH.AddTicks($date * 10) # Convert the JSON-Timestamp to a valid PowerShell date
            # $DateAdded # Show Timestamp in Human-Readable-Format (Debugging-purposes only)																					
            $date = $date | Get-Date -UFormat %s # Convert to Unix-Timestamp
            $unixTimeStamp = [int][double]::Parse($date) - 1 # Cut off the Milliseconds
            return $unixTimeStamp
        }
    }   
    if ($node.name -like "Favorites Bar") {
        $DateAdded = [Decimal] $node.date_added | ConvertTo-UnixTimeStamp
        $DateModified = [Decimal] $node.date_modified | ConvertTo-UnixTimeStamp
        "        <DT><H3 FOLDED ADD_DATE=`"$($DateAdded)`" LAST_MODIFIED=`"$($DateModified)`" PERSONAL_TOOLBAR_FOLDER=`"true`">$($node.name )</H3>" | Out-File -FilePath $output_html -Append -Force -Encoding utf8
        "        <DL><p>" | Out-File -FilePath $output_html -Append -Force -Encoding utf8
    }
    foreach ($child in $node.children) {
        $DateAdded = [Decimal] $child.date_added | ConvertTo-UnixTimeStamp    
        $DateModified = [Decimal] $child.date_modified | ConvertTo-UnixTimeStamp
        if ($child.type -eq 'folder') {
            "        <DT><H3 ADD_DATE=`"$($DateAdded)`" LAST_MODIFIED=`"$($DateModified)`">$($child.name)</H3>" | Out-File -FilePath $output_html -Append -Force -Encoding utf8
            "        <DL><p>" | Out-File -FilePath $output_html -Append -Force -Encoding utf8
            Get-BookmarkFolder $child # Recursive call in case of Folders / SubFolders
            "        </DL><p>" | Out-File -FilePath $output_html -Append -Force -Encoding utf8
        }
        else {
            # Type not Folder => URL
            "        <DT><A HREF=`"$($child.url)`" ADD_DATE=`"$($DateAdded)`">$($child.name)</A>" | Out-File -FilePath $output_html -Append -Encoding utf8
        }
    }
    if ($node.name -like "Favorites Bar") {
        "        </DL><p>" | Out-File -FilePath $output_html -Append -Force -Encoding utf8
    }
}

# ---- Convert the JSON Contens (recursive) ----
$data = Get-content $json_file -Encoding UTF8 | out-string | ConvertFrom-Json
$sections = $data.roots.PSObject.Properties | Select-Object -ExpandProperty name
ForEach ($entry in $sections) { 
    $data.roots.$entry | Get-BookmarkFolder
}

# ---- HTML Footer ----
'</DL>' | Out-File -FilePath $output_html -Append -Force -Encoding utf8

}
