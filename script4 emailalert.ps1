Import-Module "C:\FIM Project\Mailmodule.ps1"

# $Creds=Get-Credential
# $creds | Export-Clixml -path "C:\FIM Project\Emailcread.xml"
$EmailCredsPath="C:\FIM Project\Emailcread.xml"
$EmailCreds=Import-Clixml -Path $EmailCredsPath
$EmailServer="smtp-mail.outlook.com"
$EmailPort="587"
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
        if($baselinefilepath.Substring($baselinefilepath.Length-4,4) -ne ".csv"){
            Write-Error -Message "$baselinefilePath needs to be .csv file" -ErrorAction Stop

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
        [Parameter(Mandatory)]$baselinefilepath,
        [Parameter()]$emailTo
    )
    try {
        if((Test-Path -Path $baselinefilepath) -eq $false){
            Write-Error -Message "$baselinefilePath does not exist" -ErrorAction Stop
        }
        if($baselinefilepath.Substring($baselinefilepath.Length-4,4) -ne ".csv"){
            Write-Error -Message "$baselinefilePath needs to be .csv file" -ErrorAction Stop

        }
        ##add a fileshash to csv file

    ##monitor the file 
    $baselinefiles=Import-Csv -Path $baselinefilepath -Delimiter ","

    foreach($file in $baselinefiles){
    if ($null -ne $file.path -and $file.path -ne ""){
        if(Test-Path -Path $file.path){
           $currenthash=Get-FileHash -Path $file.path
           if($currenthash.Hash -eq $file.hash){
            Write-Output "$($file.path) hash is still same"
           }else{
            Write-Output "$($file.path) hash is different something has changed"
           if($emailTo){
             Send-MailKitMessage -To $emailTo -From $EmailCreds.UserName -Subject "!!FIM notification, file has changed" -Body "$($file.path) hash is different something has changed" -SMTPServer $EmailServer -Port $EmailPort -Credential $EmailCreds
            }   
          }
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
        if($baselinefilepath.Substring($baselinefilepath.Length-4,4) -ne ".csv"){
            Write-Error -Message "$baselinefilePath needs to be .csv file" -ErrorAction Stop

        }

        "path.hash" | Out-File -FilePath $baselinefilePath -Force
    }catch{
        return $_.Exception.Message
    }
    
}

$baselinefilepath="C:\FIM Project\hashesfile1.csv"

Write-Host "File monitor System version 20.24" -ForegroundColor Red
do{
    Write-Host "Please select one of the Following options or enter q to quit" -ForegroundColor blue
    Write-Host "1. Set baseline file: Current set baseline $($baselinefilepath)" -ForegroundColor Green
    Write-Host "2. Add path to baseline "-ForegroundColor Green
    Write-Host "3. Check files against baseline" -ForegroundColor Green
    Write-Host "4. Check files against baseline !!EmailAlert!! " -ForegroundColor Green
    Write-Host "5. Create a new baseline" -ForegroundColor Green
   $entry=Read-Host -Prompt "Please enter a selection" 
    
   switch($entry){
    "1"{ 
        $baselinefilepath=Read-Host -Prompt "Enter the baseline file path"
        if(Test-Path -Path $baselinefilepath){
            if($baselinefilepath.Substring($baselinefilepath.Length-4,4) -eq ".csv"){

            }else{
                 $baselinefilepath=""
                 Write-Host "Invalid file need to be a .csv file" -ForegroundColor Yellow
            }

        }else{
            $baselinefilepath=""
            Write-Host"Invalid file path for baseline" -ForegroundColor Green
        }
    }
    "2"{
        $targetfilePath=Read-Host -Prompt "Enter the path of the file you want to monitor"
        
        # Add-filetoBaseline -baselinefilepath $baselinefilepath -targetfilePath "C:\FIM Project\txtfile\f2.txt"

        Add-filetoBaseline -baselinefilepath $baselinefilepath -targetfilePath $targetfilePath
    }
    "3"{
        # Verify-Baseline -baselinefilepath $baselinefilepath
        Verify-Baseline -baselinefilepath $baselinefilepath
    }
    "4"{
        $email=Read-Host -Prompt "Enter your Email"
        # Verify-Baseline -baselinefilepath $baselinefilepath
        Verify-Baseline -baselinefilepath $baselinefilepath -emailTo $email
    }
    "5"{
        $newBaselinefilePath=Read-Host -Prompt "Enter path for new baseline file"
        # Create-Baseline -baselinefilepath $baselinefilepath
        Create-Baseline -baselinefilePath $newBaselinefilePath
    }
    "q"{}
    "quit"{}
    default{
        Write-Host " !!Invalid entry!!" -ForegroundColor Green
    }
   }

}while($entry -notin @('q','quit'))

Verify-Baseline -baselinefilepath $baselinefilepath -emailTo "Gopibigb@outlook.com"