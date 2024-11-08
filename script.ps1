
$baselinefilepath="D:\FIM Project\hashesfile.csv"

##add a fileshash to csv file
$filetoMonitorpath="D:\FIM Project\txtfile\f1.txt"
$hash=Get-FileHash -Path $filetoMonitorpath

"$($filetoMonitorpath),$($hash.hash)" | Out-File -FilePath $baselinefilepath -Append

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
           }
        }
    }
    else{
        Write-Output "$($file.path) is not found!!"
    }
}