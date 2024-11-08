Function Add-filetoBaseline{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]$baselinefilepath,
        [Parameter(Mandatory)]$targetfilePath
    )
    try{
        if((Test-Path -Path $baselinefilepath) -eq $false){
            Write-Error -Message "$baselinefilePath does not exist" -ErrorAction Stop
        }
        if((Test-Path -Path $targetfilePath) -eq $false){
            Write-Error -Message "$targetfilePath does not exist" -ErrorAction Stop
        }

        $currentBasline=Import-Csv -Path $baselinefilepath -Delimiter ","

        if($targetfilePath -in $currentBasline.path){
            Write-Output "File path detected already in baseline file"
            do{
            $overwrite=Read-Host -Prompt "Path exists already in the baseline file, would you like to overwrite it [Y/N] :"

            if($overwrite -in @('y','yes')){
                Write-Output "path will be overwritted"

                $currentBasline | Where-Object path -ne $targetfilePath| Export-Csv -Path $baselinefilepath -Delimiter "," -NoTypeInformation
                
                $hash=Get-FileHash -Path $targetfilePath

                "$($targetfilePath),$($hash.hash)" | Out-File -FilePath $baselinefilepath -Append

                Write-Output "Entry  successfully added into baseline"


            }elseif($overwrite -in @('n','no')){
                Write-Output "File path will not be overwrite"
            }else{
                Write-Output "Invalid entry,please enter y to overwrite or n to not overwrite"
            }
        }while($overwrite -notin @('y','yes','n','no'))

        }else{
            $hash=Get-FileHash -Path $targetfilePath

            "$($targetfilePath),$($hash.hash)" | Out-File -FilePath $baselinefilepath -Append

            Write-Output "Entry  successfully added into baseline"
        }
        
        $currentBasline=Import-Csv -Path $baselinefilepath -Delimiter ","
        $currentBasline | Export-Csv -Path $baselinefilepath -Delimiter "," -NoTypeInformation
        
    }catch{
        return $_.Exception.Message
    }
}

function Verify-Baseline {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$baselinefilepath
    )
    try {
        if((Test-Path -Path $baselinefilepath) -eq $false){
            Write-Error -Message "$baselinefilePath does not exist" -ErrorAction Stop
        }
        ##add a fileshash to csv file

    ##monitor the file 
    $baselinefiles=Import-Csv -Path $baselinefilepath -Delimiter ","

    foreach($file in $baselinefiles){
    if(Test-Path -Path $file.path){
           $currenthash=Get-FileHash -Path $file.path
           if($currenthash.Hash -eq $file.hash){
            Write-Output "$($file.path) hash is still same"
           }else{
            Write-Output "$($file.path) hash is different something has changed"
           }
        }
    else{
        Write-Output "$($file.path) is not found!!"
    }
}
    }
    catch {
        return $_.Exception.Message
    }
    
}

function Create-Baseline {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]$baselinefilePath
    )

    try{
        if((Test-Path -Path $baselinefilepath)){
            Write-Error -Message "$baselinefilePath already exists with this name" -ErrorAction Stop
        }

        path.hash | Out-File -FilePath $baselinefilePath -Force
    }catch{
        return $_.Exception.Message
    }
    
}

$baselinefilepath="D:\FIM Project\hashesfile.csv"

# Create-Baseline -baselinefilepath $baselinefilepath

Add-filetoBaseline -baselinefilepath $baselinefilepath -targetfilePath "D:\FIM Project\txtfile\f2.txt"

# Verify-Baseline -baselinefilepath $baselinefilepath