Set-StrictMode -Version 1.0;

<#
	
	Import-Module -Name "D:\Dropbox\Repositories\psi" -Force;
	
	$jobName = "Fake Job";
	$result = Invoke-PsiCommand -SqlInstance dev.sqlserver.id -Database msdb -Credentials (Get-Credential sa) -Query "SELECT [enabled] FROM msdb.dbo.[sysjobs] WHERE [name] = @jobName; " -ParameterString "@jobName sysname = $jobName";
	write-host $result.enabled;

#>

function Invoke-PsiQuery {
	param (
		[string]$SqlInstance = ".",
		[string]$Database = "master",
		[string]$Query,
		[PSCredential]$Credentials,
		[string]$ConnectionString,
		[int]$ConnectionTimeout = -1,
		[int]$QueryTimeout = -1,
		[ValidateSet("AUTO", "ODBC", "OLEDB", "SQLClient")]
		[string]$Framework = "AUTO",
		[switch]$AsScalar = $false,
		[switch]$AsDataSet = $false,
		[switch]$AsJson = $false,
		[switch]$AsXml = $false
	);
	
	# rough sample/example - i.e., note the args above... $SprocName, $AsNonQuery are missing... 
	# then... just call Invoke-LscCommand with the applicable operations passed in... 
	
}

function Invoke-PsiSproc {
	param (
		[Alias("ServerInstance", "ServerName", "Instance")]
		[string]$SqlInstance = ".",
		[string]$Database = "master",
		[string]$SprocName,
		[PSCredential]$Credentials,
		[string]$ConnectionString,
		[int]$ConnectionTimeout = -1,
		[int]$QueryTimeout = -1,
		[ValidateSet("AUTO", "ODBC", "OLEDB", "SQLClient")]
		[string]$Framework = "AUTO",
		[switch]$AsScalar = $false,
		[switch]$AsDataSet = $false,
		[switch]$AsJson = $false,
		[switch]$AsXml = $false
	);
	
	# similar to the above - but ... inverse. 
}

# TODO: need to figure out which of the 2x patterns below to use for 'overloads'. 
# 	Invoke-XxxJsonYYYYY works great cuz... you know the output is JSON... 
# 		but ... you'd have to know JSON vs XML vs SCALAR vs all the other modifiers OUT OF THe gate... 
function Invoke-PsiJsonQuery {
	
}

# whereas... Invoke-XyzSPROC|QUERY ... as the first part is good ... and, then from there, you can use intellisense to complete whether
# 		you want ... just Sproc/Query or SprocForXml or SprocAsScalar or QueryAsDataSet etc... 
function Invoke-PsiSprocAsScalar {
	
}

function Invoke-PsiCommand {
	[CmdletBinding()]
	param (
		[string]$SqlInstance = ".",
		[string]$Database = "master",
		[string]$Query,
		[string]$SprocName, # either $SprocName or $Query is populated - not BOTH. And ... obviously, if $SprocName then... $cmd.CommandType = ... sproc.
		[ValidateSet("Text", "StoredProcedure")]
		[string]$CommandType = "Text",
		[PSCredential]$SqlCredential,
		[PSI.Models.ParameterSet]$Parameters = $null,
		[string]$ParameterString = $null,  #REFACTOR: posssibly call these variables? I don't like that... but it's what Invoke-SqlCmd does... at any rate ParamsString sucks... 
		[string]$ConnectionString,  # optional... overwrites other stuff..
		[int]$ConnectionTimeout = -1,
		[int]$QueryTimeout = -1,
		[string]$ApplicationName,
		[ValidateSet("AUTO", "ODBC", "OLEDB", "SQLClient")]
		[string]$Framework = "AUTO",
		[switch]$ReadOnly = $false,
		[switch]$AsScalar = $false,
		[switch]$AsNonQuery = $false,
		[switch]$AsDataSet = $false,
		[switch]$AsJson = $false,
		[switch]$AsXml = $false
	);
	
	# Parameter Validation: 
	if (((@($AsScalar, $AsNonQuery, $AsDataSet, $AsJson, $AsXml) | Where-Object { $true -eq $_; } | Measure-Object).Count) -gt 1) {
		throw "Invalid Parameter Usage for Invoke-PsiCommand. Only 1x -AsXXX switch can be set at a time.";
	}
	
	$provider = $Framework;
	if ($provider -eq "AUTO") {
		$provider = Get-FrameworkProvider;
	}
	
	try {
		$conn = Get-ConnectionObject -Framework $provider;
		$conn.ConnectionString = Get-ConnectionString -Framework $provider -Server $SqlInstance -Database $Database -SqlCredential $SqlCredential -ConnectionString $ConnectionString;
		
		if ($ConnectionTimeout -gt 0) {
			$conn.ConnectionTimeout = $ConnectionTimeout;
		}
		
		$cmd = Get-CommandObject -Framework $provider;
		$cmd.Connection = $conn;
		$cmd.CommandText = $Query;
		
		if ($ConnectionTimeout -gt 0) {
			$cmd.CommandTimeout = $ConnectionTimeout;
		}
		
		if (-not ([string]::IsNullOrEmpty($ParameterString))) {
			if ($Parameters) {
				throw "Invalid Arguments. Only -Parameters OR -ParameterString can be used - not BOTH.";
			}
			
			$Parameters = Expand-SerializedParameters -Parameters $ParameterString;
		}
		
		if ($Parameters) {
			Bind-Parameters -Framework $provider -Command $cmd -Parameters $Parameters;
		}
		
		$dataSet = New-Object System.Data.DataSet;
		$adapter = Get-DataAdapter $provider;
		
		$adapter.SelectCommand = $cmd;
	}
	catch {
		# TODO: use https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.3#erroractionpreference 
		# 	 ErrorActionPreference to determine what to do ... 
		# 		along with -ErrorAction (via CmdletBinding())
		throw "CONFIG error: $_ "; #TODO: embellish this MVP implementation ... i.e., this error handling sucks... 
	}
	
	try {
		$conn.Open();
		$adapter.Fill($dataSet) | Out-Null; # TODO: I'm doing Out-Null to capture 'nocount off' (rowcount) kind of stuff. what about printed outputs? can i capture those? SHOULD I capture those? And, if I do... how do I return them to the user? 
		$conn.Close();
	}
	catch {
		# TODO: look at options for handling SQL errors ... i.e., silentlycontinue? output? or stop/throw?
		throw "OPERATION error: $_ "; #TODO: embellish this MVP implementation ... i.e., this error handling sucks... 
	}
	finally {
		$conn.Close();
	}
	
	if ($dataSet.Tables.Count -gt 1) {
		return $dataSet; # multiple tables (result-sets) - output the entire data set.
	}
	
	$table = $dataSet.Tables[0];
	if ($table.Rows.Count -gt 1) {
		return $table; # multiple rows - output the entire table.
	}
	
	# Non-Queries will NOT have any results (obviously). 
	if ($table.Rows.Count -eq 0) {
		# TODO: Obviously, by this point we've checkd for ERRORs and ... handled them. 
		# 	but...what about messages? e.g., "x rows modified?" or "successful?"
		# 		as in: how does Invoke-SqlCmd handle things like this (pretty sure that I look for "success" when deploying admindb right?)
		# 		AND... do I want to look into handling anything similar or ... differently? 
		return;
	}
	
	$row = $table.Rows[0];
	if ($row.Columns.Count -gt 1) {
		return $row; # multiple columns - return the entire row.
	}
	
	# TODO: determine how I want to handle scalar outputs. 
	# 		there are 3 options: 
	# 			a. just return the whole row - i.e., "don't bother" with this distinction. 
	# 			b. return a name-value pair ... i.e., the column-name + value - for this 'single' result. 
	# 			c. full on 'scalar' kind of output ... as in, JUST the value (no column-name or anything else.)
	# 		i think the only, real, options here are a & c. 
	
	# for now - option A. Which most closely resembles how Invoke-SqlCmd does this...  
	return $row; #.Columns[0]; 
}