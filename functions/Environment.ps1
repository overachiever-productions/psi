Set-StrictMode -Version 1.0;

filter Get-FrameworkProvider {
	$poshVersion = $PSVersionTable.PSVersion;
	if ($poshVersion.Major -ge 5) {
		return "ODBC";
	}
	
	return "SQLClient";
}

# FODDER: https://vexx32.github.io/2019/01/31/PowerShell-Error-Handling/ 
# FODDER: https://learn.microsoft.com/en-us/dotnet/api/system.management.automation.errorrecord.-ctor?view=powershellsdk-7.3.0#system-management-automation-errorrecord-ctor(system-exception-system-string-system-management-automation-errorcategory-system-object)
# FODDER: https://gist.github.com/wpsmith/e8a9c54ca1c7c741b5e9
filter New-Exception {
	param (
		[Parameter(Mandatory)]
		[string]$Message,
		[Exception]$InnerException,
		[Alias("Id")]
		[string]$ErrorId,
		[Parameter(Mandatory)]
		[Alias("Category")]
		[System.Management.Automation.ErrorCategory]$ErrorCategory,
		[Alias("Source")]
		[System.Object]$Target
	);
	
	[Exception]$exception = [Exception]::new($ErrorMessage);
	
	if ($InnerException) {
		$exception.InnerException = $InnerException;
	}
	
	[System.Management.Automation.ErrorRecord]$output = [System.Management.Automation.ErrorRecord]::new($exception, $ErrorId, $ErrorCategory, $Target);
	
	return $output;
}
