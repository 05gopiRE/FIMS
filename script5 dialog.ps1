Import-Module "C:\FIM Project\Mailmodule.ps1"
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

$Creds=Get-Credential
$creds | Export-Clixml -path "C:\FIM Project\Emailcread.xml"
$EmailCredsPath="C:\FIM Project\Emailcread.xml"
$EmailCreds=Import-Clixml -Path $EmailCredsPath
$EmailServer="smtp.gmail.com"
$EmailPort="587"

$configPath = "C:\FIM Project\config.json"
$config = Get-Content -Path $configPath | ConvertFrom-Json
$baselinefilepath = $config.baselinefilepath
$emailto = $config.emailto
Function Add-filetoBaseline{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]$baselinefilepath,
        [Parameter(Mandatory)]$targetfilePath
    )
    try{
        if((Test-Path -Path $baselinefilepath) -eq $false){
            Write-Error -Message "$baselinefilepath does not exist" -ErrorAction Stop
        }
        if((Test-Path -Path $targetfilePath) -eq $false){
            Write-Error -Message "$targetfilePath does not exist" -ErrorAction Stop
        }
        if($baselinefilepath.Substring($baselinefilepath.Length-4,4) -ne ".csv"){
            Write-Error -Message "$baselinefilepath needs to be .csv file" -ErrorAction Stop

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

function Verify-Baseline{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]$baselinefilepath,
        [Parameter()]$emailto
    )
    try {
        if((Test-Path -Path $baselinefilepath) -eq $false){
            Write-Error -Message "$baselinefilepath does not exist" -ErrorAction Stop
        }
        if($baselinefilepath.Substring($baselinefilepath.Length-4,4) -ne ".csv"){
            Write-Error -Message "$baselinefilepath needs to be .csv file" -ErrorAction Stop

        }
        ##add a fileshash to csv file

    ##monitor the file 
    $baselinefiles=Import-Csv -Path $baselinefilepath -Delimiter ","

    foreach($file in $baselinefiles){
    if ($null -ne $file.path -and $file.path -ne ""){
        if(Test-Path -Path $file.Path){
           $currenthash=Get-FileHash -Path $file.path
           if($currenthash.Hash -eq $file.hash){
            Write-Output "$($file.path) hash is still same"
           }else{
            Write-Output "$($file.path) hash is different something has changed"
           if($emailto){
            Send-MailMessage -From $EmailCreds.UserName -To $emailto -Subject "!!!!!! FIM notification, file has changed" -Body "$($file.path) hash is different something has changed !!!!!!"  -Credential $EmailCreds -SmtpServer $EmailServer -Port $EmailPort -UseSsl
    #   Send-MailKitMessage -To $PSEmailServer -From $EmailCreds.UserName -Subject "!!FIM notification, file has changed" -Body "$($file.path) hash is different something has changed" -SMTPServer $EmailServer -Port $EmailPort -Credential $EmailCreds
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


function Send-EmailAlert {
    param (
        [Parameter(Mandatory = $true)]
        [string]$to,
        
        [Parameter(Mandatory = $true)]
        [string]$subject,
        
        [Parameter(Mandatory = $true)]
        [string]$body
    )

    # Path to the credential file
    $EmailCredsPath = "C:\FIM Project\Emailcread.xml"

    # Import the credentials securely
    $EmailCreds = Import-Clixml -Path $EmailCredsPath

    # Define SMTP settings
    $EmailServer = "smtp.gmail.com"
    $EmailPort = 587

    try {
        Send-MailMessage -From $EmailCreds.UserName `
                         -To $to `
                         -Subject $subject `
                         -Body $body `
                         -SmtpServer $EmailServer `
                         -Port $EmailPort `
                         -Credential $EmailCreds `
                         -UseSsl
                        
        Write-Output "Email sent successfully to $to."
    }
    catch {
        Write-Error "Failed to send email: $_"
    }
}

function Create-Baseline {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]$baselinefilepath
    )class ClassName {
        <# Define the class. Try constructors, properties, or methods. #>
    }

    try{
        if((Test-Path -Path $baselinefilepath)){
            Write-Error -Message "$baselinefilepath already exists with this name" -ErrorAction Stop
        }
        if($baselinefilepath.Substring($baselinefilepath.Length-4,4) -ne ".csv"){
            Write-Error -Message "$baselinefilepath needs to be .csv file" -ErrorAction Stop

        }

        "path.hash" | Out-File -FilePath $baselinefilepath -Force
    }catch{
        return $_.Exception.Message
    }
    
}

$baselinefilepath=""

Write-Host "File monitor System version 20.24" -ForegroundColor Yellow
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
       $inputFilePick= New-Object System.Windows.Forms.OpenFileDialog
       ##filter the only a particular file format
       $inputFilePick.Filter= "CSV (*.csv)| *.csv"
       ##show's the file explorer or file
       $inputFilePick.ShowDialog()
       $baselinefilepath=$inputFilePick.FileName
        if(Test-Path -Path $baselinefilepath){
            if($baselinefilepath.Substring($baselinefilepath.Length-4,4) -eq ".csv"){

            }else{
                 $baselinefilepath=""
                 Write-Host "Invalid file need to be a .csv file" -ForegroundColor Yellow
            }

        }else{
            $baselinefilepath=""
            Write-Host"Invalid file path for baseline" -ForegroundColor Red
        }
    }
    "2"{
        # $targetfilePath=Read-Host -Prompt "Enter the path of the file you want to monitor"
        $inputFilePick= New-Object System.Windows.Forms.OpenFileDialog
        $inputFilePick.ShowDialog()
        $targetfilePath=$inputFilePick.FileName
        # Add-filetoBaseline -baselinefilepath $baselinefilepath -targetfilePath "C:\FIM Project\txtfile\f2.txt"

        Add-filetoBaseline -baselinefilepath $baselinefilepath -targetfilePath $targetfilePath
    }
    "3"{
        Verify-Baseline -baselinefilepath $baselinefilepath
        # Update-Item -baselinefilepath $baselinefilepath
    }
    "4"{
        $email=Read-Host -Prompt "Enter your Email"
        Verify-Baseline -baselinefilepath $baselinefilepath -emailto $email
        # Update-Item -baselinefilepath $baselinefilepath -emailTo $email
    }
    "5"{
        # $newBaselinefilePath=Read-Host -Prompt "Enter path for new baseline file"
       
        $inputFilePick= New-Object System.Windows.Forms.SaveFileDialog
       
        ##filter the only a particular file format
       $inputFilePick.Filter= "CSV (*.csv)| *.csv"
       
       ##show's the file explorer or file
       $inputFilePick.ShowDialog()
       
       $newBaselinefilePath=$inputFilePick.FileName
        # Create-Baseline -baselinefilepath $baselinefilepath
        Create-Baseline -baselinefilePath $newBaselinefilePath
    }
    "q"{}
    "quit"{}
    default{
        Write-Host " !!Invalid entry!!" -ForegroundColor Red
    }
   }

}while($entry -notin @('q','quit'))

# Verify-Baseline -baselinefilepath $baselinefilepath $emailTo "gopibigb@gmail.com"