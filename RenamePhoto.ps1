function Rename-Photo {
    [CmdletBinding()]

    Param (
        [Parameter(Mandatory=$true,
        ValueFromPipeline=$true)]
        [ValidateScript({Test-Path $_})]
        [String]$FileName,

        [Parameter(Mandatory=$true)]
        [Int]$FileIndex,

        [Parameter(Mandatory=$false)]
        [String]$TagName,

        [Parameter(Mandatory=$false)]
        [Switch]$IsVideo
    )

    Begin {
        $shell = New-Object -ComObject Shell.Application
        $null = [reflection.assembly]::LoadWithPartialName("System.Drawing")
        if ($TagName -eq "") { $TagName = "IMG" }
        $offset = 0
    }
    Process {
        $file = Get-Item $FileName
        Write-Verbose ("Renaming " + $file.Name)
        $dateTime = $null
        $modelName = $null
        
        try {
            if ($IsVideo) {
                # via http://web.archive.org/web/20160201231836/http://powershell.com/cs/blogs/tobias/archive/2011/01/07/organizing-videos-and-music.aspx
                $shellFolder = $shell.NameSpace($file.DirectoryName)
                $shellFile = $shellFolder.ParseName($file.Name)
                <# 0..333 | Where-Object { $shellFolder.GetDetailsOf($shellFile,$_) } |
                ForEach-Object { "{0} - {1} - {2}" -f $_,
                $shellFolder.GetDetailsOf($null,$_),
                $shellFolder.GetDetailsOf($shellFile,$_) } #>
                $stringDate = $shellFolder.GetDetailsOf($shellFile,208)
                # Write-Host $stringDate

                # via https://stackoverflow.com/questions/25474023/file-date-metadata-not-displaying-properly
                $stringDate = ($stringDate -replace [char]8206) -replace [char]8207
                $dateTime = [datetime]::ParseExact($stringDate,"yyyy/M/d H:mm",$null)
            } else {
                # via https://stackoverflow.com/questions/6834259/how-can-i-get-programmatic-access-to-the-date-taken-field-of-an-image-or-video
                $img = New-Object System.Drawing.Bitmap($file.FullName)

                $byteArrayDate = $img.GetPropertyItem(0x9003).Value # PropertyTagExifDTOrig
                $stringDate = [System.Text.Encoding]::ASCII.GetString($byteArrayDate)
                $dateTime = [datetime]::ParseExact($stringDate,"yyyy:MM:dd HH:mm:ss`0",$null)

                $byteArrayModel = $img.GetPropertyItem(0x0110).Value # PropertyTagEquipModel
                $stringModel = [System.Text.Encoding]::ASCII.GetString($byteArrayModel)
                $modelName = $stringModel.TrimEnd("`0") -replace "\s+",""
            }
        }
        catch {
        	# if we could not extract "Date Taken" or "Media Created".
		    # perhaps we can use one of these dates instead.
		    # CreationTime              Property       datetime CreationTime {get;set;}
		    # CreationTimeUtc           Property       datetime CreationTimeUtc {get;set;}
		    # LastAccessTime            Property       datetime LastAccessTime {get;set;}
		    # LastAccessTimeUtc         Property       datetime LastAccessTimeUtc {get;set;}
		    # LastWriteTime             Property       datetime LastWriteTime {get;set;}
		    # LastWriteTimeUtc          Property       datetime LastWriteTimeUtc {get;set;}
            if ($dateTime -eq $null) { $dateTime = $file.LastWriteTime }
        }
        finally {
            if ($img -ne $null) { $img.Dispose() }
        }

        $sortName = $TagName
        if ($modelName -ne $null) { $sortName += "_" + $modelName }

        if ($FileIndex -eq 0) {
            $curIndex = "{0:HHmmss}" -f $dateTime
        } else {
            $curIndex = "{0:d4}" -f ($FileIndex + $offset)
        }
        $offset++

        $newBaseName = "{0:yyyy-MM-dd}_{1}_{2}" -f $dateTime,$sortName,$curIndex
        # Write-Host $newBaseName
        if (($FileIndex -eq 0) -and ($file.BaseName -match $newBaseName)) {
            # skip files that already been renamed
            Write-Verbose "Skip`n"
            return
        }
        
        try {
            Rename-Item $file.FullName ($newBaseName + $file.Extension) -ErrorAction Stop
        }
        catch {
            $dupCount = [System.IO.Directory]::GetFiles($file.DirectoryName, "$newBaseName*").Count
            $newBaseName += "_" + $dupCount
            Rename-Item $file.FullName ($newBaseName + $file.Extension)
        }
        Write-Verbose ("To       " + $newBaseName + $file.Extension + "`n")
    }
    End { Write-Host $offset,"files completed" }
}
