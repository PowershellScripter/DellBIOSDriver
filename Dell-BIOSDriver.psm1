Function Get-DellBIOSDriver {

[CmdletBinding(DefaultParameterSetName = 'Local')]
    param(

        [Parameter(Mandatory=$False, ParameterSetName='Tag', Position=0)]
        [String]
        $ServiceTag,

        
        [Parameter(Mandatory=$False, ParameterSetName='Platform', Position=0)]
        [ValidateSet('Desktop','Laptop','Server')]
        $Platform,


        
        [Parameter(Mandatory, ParameterSetName='Platform', Position=1)]
        [ArgumentCompleter({
            param ( $commandName,
                    $parameterName,
                    $wordToComplete,
                    $commandAst,
                    $fakeBoundParameters )
                
            
            Switch($fakeBoundParameters.Platform){

                {$_ -match 'Server'}
                    {
                        return 'PowerEdge'
                    }

                {$_ -match 'Desktop'}
                    {
                        return 'Optiplex','XPS','AlienWare','Inspiron','Vostro' | Sort-Object | ?{$_ -like "*$wordToComplete*"}
                    }

                {$_ -match 'Laptop'}
                    {
                        return 'XPS','AlienWare','Inspiron', 'Vostro', 'Latitude' | Sort-Object | ?{$_ -like "*$wordToComplete*"}
                    }
                {[string]::IsNullOrEmpty($_)}
                    {
                        return 'Platform must NOT be null'
                    }
            }

        })]
        $Make,


        
        [Parameter(Mandatory, ParameterSetName='Platform', Position=2)]
        [ArgumentCompleter({
        param ( $commandName,
                $parameterName,
                $wordToComplete,
                $commandAst,
                $fakeBoundParameters )
        
            $Headers = @{
                "method"="GET"
                "accept"="application/json, text/javascript, */*; q=0.01"
                "x-requested-with"="XMLHttpRequest"
                    }
            
            $productResults = @()
            $allProducts = (irm 'https://www.dell.com/support/components/productselector/allproducts?' -Headers $Headers | Select-String -AllMatches -Pattern '((?<=data-vmpath=").+?(?="))').Matches.Value | ?{$_ -match 'laptop|desktop|server|workstations'}
            $configPlatform = $allProducts | ?{$_ -match $fakeBoundParameters.Platform}
            $configModel = $fakeBoundParameters.Make
            $wordToComplete = $fakeBoundParameters.Model

            (irm "https://www.dell.com/support/components/productselector/allproducts?category=$($configPlatform)/$(($configPlatform | Select-String -AllMatches -Pattern '(?<=.\/).+$').Matches.Value)_$($configModel)" -Method GET -Headers $Headers | Select-String -AllMatches -Pattern '((?<=data-vmpath=").+?(?="))').Matches.Value | %{
    
                    (irm "https://www.dell.com/support/components/productselector/allproducts?category=$($_)" -Method GET -Headers $Headers | Select-String -AllMatches -Pattern '((?<=data-prodcode=").+?(?="))').Matches.Value | %{
                        $productResults += $_
                    }        
            }

            if(($productResults | ?{$_ -like "*$wordToComplete*"}).Count -gt 0)
            {

                $productResults | ?{$_ -like "*$wordToComplete*"} |  %{
                    [System.Management.Automation.CompletionResult]::new("'"+ $($_.ToUpper() -replace '-',' ')+ "'", $_, 'ParameterValue', $_)
                    }

            }
            else{
                return '''No Models Found'''
                
            }

        })]
        $Model,


        [Parameter(Mandatory=$False, ParameterSetName='Local', Position=0)]
        [Parameter(Mandatory=$False, ParameterSetName='Tag', Position=1)]
        [Parameter(Mandatory=$False, ParameterSetName='Platform', Position=3)]
        [Switch]
        $Download,

        [Parameter(Mandatory=$False, ParameterSetName='Local', Position=1)]
        [Parameter(Mandatory=$False, ParameterSetName='Tag', Position=2)]
        [Parameter(Mandatory=$False, ParameterSetName='Platform', Position=4)]
        [ArgumentCompleter({

        param ( $commandName,
                $parameterName,
                $wordToComplete,
                $commandAst,
                $fakeBoundParameters )


                if([String]::IsNullorEmpty($fakeBoundParameters.FolderPath)){
                    
                    Add-Platform -AssemblyName 'System.Windows.Forms'

                    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
                    

                    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                        $Path = $dialog.SelectedPath
                        return """$Path"""
                    }
                    else{
                        
                        return ' ' + [System.Windows.Forms.SendKeys]::SendWait("{BACKSPACE}")
                    }


                }

        })]    
        $FolderPath = $([System.Environment]::GetEnvironmentVariable('TEMP','Machine')),


        [Parameter(Mandatory, ParameterSetName='Syntax', Position=0)]
        [Switch]
        $Syntax,

        [Parameter(Mandatory=$False, ParameterSetName='Syntax', Position=1)]
        [Switch]
        $IncludeExamples,

        [Parameter(DontShow)]
        $DebugPreference



        



    )


   


begin{

    
    
}

process{
    


Switch($PSCmdlet.MyInvocation.Line)
{
    {$_ -match 'Get-DellBIOSDriver.+?Syntax \| Install-DellBIOSDriver|Get-DellBIOSDriver \| Install-DellBIOSDriver.+?Syntax'}
        {
            return Write-Error 'Invalid Arguments!'
        }
}


    
Switch($Syntax){
    'True'{
        DellBIOSSyntax
        return
    }
}




$Host.PrivateData.ProgressBackgroundColor='Black' 
$Host.PrivateData.ProgressForegroundColor='Cyan'




# Check for first launch value


if(!$Null -eq (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main" -Name "DisableFirstRunCustomize" -ea si)){

    if((Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main" -Name "DisableFirstRunCustomize") -ne 2) {
        [void](Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main" -Name "DisableFirstRunCustomize" -Value 2)
    }
}
elseif($Null -eq (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main" -Name "DisableFirstRunCustomize" -ea si)) {
    [void](New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main" -Name "DisableFirstRunCustomize" -Value 2)
}




$Script:Product = ""
$File = ""
$Headers = @{
    "method"="GET"
    "accept"="application/json, text/javascript, */*; q=0.01"
    "x-requested-with"="XMLHttpRequest"
      }
$Script:Result = [PSCustomObject]@{
}







Function local:ProductCode
{

    $requestedURL = iwr -Uri "https://www.dell.com/support/home/en-us/product-support/servicetag/$sTag" -Method Options -Headers $Headers

    $productCode = ($requestedURL | Select-String -AllMatches -Pattern '(?<=Dell\.Metrics\.sc\.supportsystem = \").+(?=\")').Matches.Value
    $System = ($requestedURL | Select-String -AllMatches -Pattern '(?<=Support for ).+?(?= \|)').Matches.Value | Select -First 1
    $encryptedServiceTag =  ($requestedURL | Select-String -AllMatches -Pattern '(?<=serviceEncryptedkey = '').+(?='';)').Matches.Value
    
    $Script:Product = (irm "https://www.dell.com/support/driver/en-us/ips/api/driverlist/getdriversbytag?productcode=$productCode&servicetag=$encryptedServiceTag" -Method GET -Headers $Headers).DriverListData  | ?{$_.CatName -match 'bios'} | Sort-Object DriverName -Descending | 
    Select -First 1 |
    Select @{n='System';e={"$System"}},@{n='ServiceTag';e={"$sTag"}}, DriverId, DriverName, @{n="DriverVersion";e={$_.DellVer}}, ReleaseDate, @{n='FileName';e={"$(($_.FileFrmtInfo.HttpFileLocation | Select-String -AllMatches -Pattern '\/((?:.(?!\/))+$)').Matches.Groups[1].value)"}}, @{n="URL";e={$_.FileFrmtInfo.HttpFileLocation}}
     
    
   
}






Function local:Result
{

    foreach($prop in $Product.PSObject.Properties)
        {
            $Script:Result | Add-Member -MemberType NoteProperty -Name $prop.Name -Value $prop.Value -fo
        }

    if((!$Download) -and !($PSCmdlet.MyInvocation.Line -match 'Install-DellBIOSDriver'))
    {

        return $Script:Result
        
    }
    
}





Function local:Download{
    
    Start-BitsTransfer -Source $Product.URL -Destination $Script:File -DisplayName "   $($Product.System)" -Description " Downloading `'$($Product.FileName)`' to `'$((Get-Culture).TextInfo.ToTitleCase($FolderPath.ToLower()))`'"
        
}












Switch([string]::IsNullOrEmpty($ServiceTag) -and [string]::IsNullOrEmpty($Platform)){


'True'{

    $sTag = (Get-CimInstance -ClassName Win32_BIOS).SerialNumber
    
    ProductCode

}

'False' {




    if($Null -ne $ServiceTag){


        $sTag = $ServiceTag

        ProductCode
        
        
        
        } # End if




    if($Null -ne $Platform){


        Switch($Model -match 'No Models Found'){
        
            'True' {
                Write-Warning 'You are inquiring an empty result, please try again'
            }
        
            'False' {              

                $Script:Product = (irm "https://www.dell.com/support/driver/en-us/ips/api/driverlist/getdriversbyproduct?productcode=$($Model -replace ' ','-')" -Method GET -Headers $Headers).DriverListData | ?{$_.CatName -match 'bios'} | Sort-Object DriverName -Descending | 
                Select -First 1 |
                Select @{n='System';e={$Model}}, DriverId, DriverName, @{n="DriverVersion";e={$_.DellVer}}, ReleaseDate, @{n='FileName';e={"$(($_.FileFrmtInfo.HttpFileLocation | Select-String -AllMatches -Pattern '\/((?:.(?!\/))+$)').Matches.Groups[1].value)"}}, @{n="URL";e={$_.FileFrmtInfo.HttpFileLocation}}

                
            }

        }
        
        
    } # End if






}




} # End MatchLocalSystem Switch


$Script:File = "$($FolderPath)\$($Product.FileName)" | %{
    $Path = ($_ | Select-String -All '.+(?=\.(?=\w+$).+)|\.(?=\w+$).+').Matches.Value
    $(($Path[0] -replace '.+', (Get-Culture).TextInfo.ToTitleCase($Path[0].ToLower()))+$Path[1])
}





Switch($Download){

'True'{

        Download

    }

}


Result







If((!$Download) -and ($PSCmdlet.MyInvocation.Line -match 'Get-DellBIOSDriver \| Install-DellBIOSDriver')){

    Download

}


If(($PSCmdlet.MyInvocation.Line -match 'Install-DellBIOSDriver')){

    return $Script:File

}


[GC]::Collect()


} #End Process




} #End Function

















Function Install-DellBIOSDriver{ 


[CmdletBinding(DefaultParameterSetName = 'Install')]
param(


        [Parameter(Mandatory, ParameterSetName='Install', Position=0, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ArgumentCompleter({
        
            param ( $commandName,
                    $parameterName,
                    $wordToComplete,
                    $commandAst,
                    $fakeBoundParameters )
        
        
                    if([String]::IsNullorEmpty($fakeBoundParameters.File)){
        
                            Add-Platform -AssemblyName 'System.Windows.Forms'
                        
                            $dialog = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
                            InitialDirectory = "C:\" 
                            Filter = 'DELL BIOS FILE (*.exe)|*.exe'
                        }
        
                        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                            $Path = $dialog.FileName
                            return """$Path"""
                        }
                        else{
                            
                            return ' ' + [System.Windows.Forms.SendKeys]::SendWait("{BACKSPACE}")
                        }
        
        
        
                    }
            
        })]
        [String]$File = $Script:File,



        [Parameter(Mandatory=$False, ParameterSetName='Install', Position=1)]
        [ArgumentCompleter({

            param ( $commandName,
                    $parameterName,
                    $wordToComplete,
                    $commandAst,
                    $fakeBoundParameters )

                    if([string]::IsNullOrEmpty($fakeBoundParameters.BiosPass)){
                        $Global:PassPhrase = ([System.Management.Automation.PSCredential]::new(' ', $(Read-Host -AsSecureString))).GetNetworkCredential().Password
                        $count = '~' * ($PassPhrase.length / 2 )
        
                        $Script:ReturnableValue = """$($count + "SECUREPASSWORD" + $count)"""
                        return $Script:ReturnableValue
        
                    }       

        })]
        $BiosPass = "",



        [Parameter(Mandatory=$False, ParameterSetName='Install', Position=2)]
        [ArgumentCompleter({

            param ( $commandName,
                    $parameterName,
                    $wordToComplete,
                    $commandAst,
                    $fakeBoundParameters )


                    if([String]::IsNullorEmpty($fakeBoundParameters.LogFile)){

                        Add-Platform -AssemblyName 'System.Windows.Forms'
                        
                        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog

                        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                            $Path = $dialog.SelectedPath
                            return """$Path"""
                        }
                        else{
                            
                            return ' ' + [System.Windows.Forms.SendKeys]::SendWait("{BACKSPACE}")
                        }



                    }
            
        })]
        [String]$LogFile = "$([System.Environment]::GetEnvironmentVariable('TEMP','Machine'))",
        
        
        [Parameter(Mandatory=$False, ParameterSetName='Install', Position=3)]
        [Switch]$SupressUI,
                
        [Parameter(Mandatory=$False, ParameterSetName='Install', Position=4)]
        [Switch]$OverrideSoftError,

        [Parameter(Mandatory=$False, ParameterSetName='Install', Position=5)]
        [Switch]$AutoReboot,

        [Parameter(Mandatory=$False, ParameterSetName='Install', Position=6)]
        [ValidateSet('LogFile','Exe','All')]
        [String]$PurgeLeftOvers,

        [Parameter(Mandatory, ParameterSetName='Syntax', Position=0)]
        [Switch]
        $Syntax,

        [Parameter(Mandatory=$False, ParameterSetName='Syntax', Position=1)]
        [Switch]
        $IncludeExamples,

        [Parameter(DontShow)]
        $DebugPreference



)







begin
{

}

process
{





Switch($Syntax){
    'True'{
        DellBIOSSyntax
        return
        
    }
}





Switch($OverrideSoftError)
{

    'True'
        {
            $comSwitch = '/s','/f'
        }

    'False'
        {

            Switch($SupressUI)
            {
                'True'
                    {
                        $comSwitch = '/s'
                    }

            } #End SupressUI Switch
            
        } #End OverrideSoftError False



} #End OverrideSoftError Switch





if(![String]::IsNullOrEmpty($Global:PassPhrase)){

    $cred = "/p=$Global:PassPhrase"
}
elseif(![String]::IsNullOrEmpty($BiosPass)){

    $cred = "/p=$BiosPass"
}
else{
    $cred = ""
}
    


[String]$Script:LogFile = "/l=""$($LogFile + "\DellBios__$("{0:M-dd-yy-HH_mm_ss}" -f (Get-Date)).log")"""

& "$File" $comSwitch $Script:LogFile $cred



While(Get-Process | ?{$_.Path -match "$(Split-Path $File -Leaf)"})
{
    start-sleep -seconds 1
}




Try
{

    switch([System.IO.File]::Exists("$($Script:LogFile -replace '/l=|"')"))
    {
        'True'
        {
            
            switch(Get-Content -raw "$($Script:LogFile -replace '/l=|"')" )
            {

                                
                {![String]::IsNullOrEmpty(($_ | Select-String -All 'Unsupported BIOS image').Matches.Value)}
                    {
                        return "`n`nError: Unsupported BIOS image`n`nPlease verify correct image was downloaded`n`n`n""$File""`n`n`n"
                    }


                {![String]::IsNullOrEmpty(($_ | Select-String -All 'Password Validation failure').Matches.Value)}
                    {
                        return "`n`nError: Password Validation Failure`n`nIt seems there is a password locking the BIOS`n`nPlease use the 'BiosPass' parameter to supply a bios password to continue`n`n`n"
                    }


                {![String]::IsNullOrEmpty(($_ | Select-String -All 'Soft.+?Dep.+?Error').Matches.Value)}
                    {

                        switch($_)
                        {
                            {$_ -match ($_ | Select-String -All 'new.+?same.+?current').Matches.Value}
                                {
                                    Write-Output "`n`nError: New BIOS is the same as the current BIOS.`n`nTo override please use '-OverrideSoftError' parameter`n`n`n"
                                }
                            {$_ -notmatch ($_ | Select-String -All 'new.+?same.+?current').Matches.Value}
                                {
                                    Write-Output "`n`nError: Soft Dependency Error.`n`n$($_)`n`nTo override please use '-OverrideSoftError' parameter`n`n`n"   
                                }
                            }
                            Write-Output "QUICK COMMAND:`n`nInstall-DellBIOSDriver -File '$($File)' -SupressUI -OverrideSoftError -AutoReboot`n`n`n"
                            return
                    }




                {![String]::IsNullOrEmpty(($_ | Select-String -All 'Hard.+?Qualification').Matches.Value)}
                    {
                    
                        switch($_)
                        {
                            {$_ -match ($_ | Select-String -All 'Unsupported.+?System').Matches.Value}
                                {
                                    Write-Output "`n`nError: Unsupported System ID Found.`n`nPlease verify you have the correct file for this system.`n`nFile: `'$File`'`n`n`n"
                                }
                            {$_ -notmatch ($_ | Select-String -All 'Unsupported.+?System').Matches.Value}
                                {
                                    Write-Output "`n`n$_`n`n`n"
                                }
                        }
                        return
                    }



                {![String]::IsNullOrEmpty(($_ | Select-String -All 'new.+?older.+?current').Matches.Value)}
                    {
                        Write-Output "`n`n$(($_ |  Select-String -All 'Error.+?new.+?older.+?current.+').Matches.Value)`n`n`n`n`nQUICK COMMAND TO UPDATE TO LATEST BIOS:`n`nGet-DellBIOSDriver | Install-DellBIOSDriver -SupressUI -AutoReboot`n`n`n" 
                        return
                    }



            }


        } #End True


    }

   

}
Catch{
    $ErrorActionPreference = 'silentlycontinue'
}








'cred','passphrase','BiosPass', 'Product','Result' | %{

Clear-Variable $_ -ea si

}



[GC]::Collect()



Switch($PurgeLeftOvers)
{

    {$_ -match 'All'}

        {
            "$File","$($Script:LogFile -replace '/l=|"')" | Remove-Item -fo -ea -si
        }


    {$_ -match 'LogFile'}

        {
            "$($Script:LogFile -replace '/l=|"')" | Remove-Item -fo -ea si
        }


    {$_ -match 'Exe'}

        {
            "$File" | Remove-Item -fo -ea si
        }
        

}




Switch($AutoReboot)
{
    'True'
        {
            Restart-Computer -force
        }
}






} #End of install process

    












} #End of Function







Function DellBIOSSyntax{

    switch($PSCmdlet.MyInvocation.Line){
  
      {$_ -match 'Get-DellBiosDriver -Syntax'}
          {
              
  Write-Output "
  
  Get-DellBIOSDriver
  
  
  Get-DellBIOSDriver -Download
                     -FolderPath  <Object>
  
  
  Get-DellBIOSDriver -ServiceTag  <string> 
                     -Download
                     -FolderPath  <Object>
  
                     
  Get-DellBIOSDriver -Platform  {Desktop | Laptop | Server} 
                     -Make  <Object>
                     -Model  <Object>
                     -Download 
                     -FolderPath  <Object>
  
  
  Get-DellBIOSDriver -Syntax
                     -IncludeExamples
        
  
  
  REMARKS:
  
  Default Path for [-Download] is 'C:\Windows\Temp'
  
  Using Get-DellBIOSDriver by itself is permitted and filterable through the pipeline or with standalone properties
  
  
  TAB COMPLETION:
  
  [-Make] - Returns available makes based on  [-Platform]  chosen
  
  [-Model] - Returns webrequest array of models based on  [-Platform]  and  [-Make]  chosen
  
  [-FolderPath] - Will open FOLDER dialog
  
  
  "
  
          }



      {$_ -match 'Install-DellBIOSDriver -Syntax'}
          {


  Write-Output "
  
  Install-DellBIOSDriver
      
  Install-DellBIOSDriver -File  <string> 
                         -BiosPass  <Object>
                         -LogFile  <string>
                         -SupressUI
                         -OverrideSoftError
                         -AutoReboot
                         -PurgeLeftOvers  {LogFile | Exe | All}
    
   Install-DellBIOSDriver -Syntax
                          -IncludeExamples
      
  
                         
  REMARKS:
     
  Default path for  [-LogFile]  is ''C:\Windows\Temp'' 
  
  LogFile is saved as (ex.  $("DellBios__$("{0:M-dd-yy-HH_mm_ss}" -f (Get-Date)).log") )
      
  [-File] will only show if initialized on the entrypoint of the pipeline
  
  [-OverrideSoftError] is used in the event that the same BIOS version 
  is being installed or other sofwtare dependency related errors  
  
  
  TAB COMPLETION:
  
  [-File] - Will open FILE Dialog
  
  [-BiosPass]  - Will execute securestring form that will be captured in separate contained variable
  
  
  
  
  "


          }
  
      }
  
      switch($PSCmdlet.MyInvocation.Line)
      {
  
          {$_ -match '-IncludeExamples'}
              {
           Write-Output '
  
  EXAMPLES:
  

  Get-DellBIOSDriver || (Get-DellBIOSDriver).DriverName || Get-DellBIOSDriver | FL DriverName

  (Get-DellBIOSDriver).DriverVersion -match (Get-CimInstance -ClassName Win32_BIOS).SMBIOSBIOSVERSION
  
  Get-DellBIOSDriver -ServiceTag ''HJ7H5D'' -Download
  
  Get-DellBIOSDriver -ServiceTag ''HJ7H5D'' -Download -FolderPath ''C:\Temp''
  
  Get-DellBIOSDriver | Install-DellBIOSDriver
  
  Get-DellBIOSDriver -Download -FolderPath ''C:\Temp'' | Install-DellBIOSDriver -SupressUI -AutoReboot -PurgeLeftOvers All
  
  
  

  Install-DellBIOSDriver -File ''C:\Windows\Temp\DellBios.exe'' -SupressUI -AutoReboot -PurgeLeftOvers All
  
  
  
                  '
              }
  
          }
  return
  }
