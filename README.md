# DellBIOSDriver

<pre>
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







Install-DellBIOSDriver

Install-DellBIOSDriver -File  <string> 
                       -BiosPass  <Object>
                       -LogFile  <string>
                       -SupressUI
                       -OverrideSoftDependencyError
                       -AutoReboot
                       -PurgeLeftOvers  {LogFile | Exe | All}

 Install-DellBIOSDriver -Syntax
                        -IncludeExamples



REMARKS:

Default path for  [-LogFile]  is ''C:\Windows\Temp'' 

LogFile is saved as (ex.  $("DellBios__$("{0:M-dd-yy-HH_mm_ss}" -f (Get-Date)).log") )

[-File] will only show if initialized on the entrypoint of the pipeline

[-OverrideSoftDependencyError] is used in the event that the same BIOS version 
is being installed or other sofwtare dependency related errors  


TAB COMPLETION:

[-File] - Will open FILE Dialog

[-BiosPass]  - Will execute securestring form that will be captured in separate contained variable


  </pre>
  
