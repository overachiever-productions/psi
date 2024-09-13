Set-StrictMode -Version 3.0;

filter Get-FrameworkProvider {
	
	#TODO: It'll probably make most sense to evaluate which version of .NET is being run (e.g., .NET Framework/WindowsPowershell get System)
	# 	whereas .NET 8 ... SYstem, but .NET 9? ... would get Microsoft, etc.
	
	return "System";
}

function Get-ConnectionObject {
	[CmdletBinding()]
	param (
		[ValidateSet("System", "Microsoft")]
		[Parameter(Mandatory)]
		[string]$Framework,
		[Parameter(Mandatory)]
		[PSI.Models.Connection]$Connection,
		[Parameter(Mandatory)]
		[PSI.Models.BatchResult]$BatchResult
	);
	
	process {
		$connString = Get-ConnectionString -Framework $Framework -Connection $Connection;
		
		$output = $null;
		try {
			switch ($Framework) {
				"System" {
					$output = New-Object System.Data.SqlClient.SqlConnection($connString);
					$output.FireInfoMessageEventOnUserErrors = $true;
					$infoHandler = [System.Data.SqlClient.SqlInfoMessageEventHandler] {
						
# PICKUP / NEXT: Assign the OUTPUT of the following call into something(s)
						# 		and, potentially include line numbers and any OTHER details that SqlClient has that the OTHER clients did NOT. 
						# 		then ... pass the OUTPUTs into $BatchResult.<whateverHandlerFuncNameApplies>()
						Get-SqlInfoDetails -Framework $Framework -ErrorCollection $_.Errors -Message $_.Message;
						
						#$BatchResult.AddResultText($_);
					}
					$output.Add_InfoMessage($infoHandler);
				}
				"Microsoft" {
					throw "System.Data.SqlClient is currently the ONLY supported -Provider.";
				}
				default {
					throw "System.Data.SqlClient is currently the ONLY supported -Provider.";
				}
			}
		}
		catch {
			throw "CONN SETUP ERROR: $_";
		}
		
		try {
			$cmd = Get-CommandObject -Framework $Framework;
			$cmd.Connection = $output;
			$cmd.CommandText = "SELECT @@SERVERNAME [psi.command.connection-test]; ";
			$cmd.CommandType = "TEXT";
			
			$output.Open() | Out-Null -WarningAction SilentlyContinue;
			$cmd.ExecuteScalar() | Out-Null;
			$output.Close();
			
		}
		catch {
			throw "xCONN TEST ERROR: $_";
		}
		finally {
			# anything I should be cleaning up here ? 			
		}
		
		return $output;
	}
}

function Get-SqlInfoDetails {
	param (
		[ValidateSet("System", "Microsoft")]
		[Parameter(Mandatory)]
		[string]$Framework,
		$ErrorCollection,
		[string]$Message
	);
	
	Write-Host "  INFO MESSAGE: $Message";
	
	Write-Host "	ERRORS: $($ErrorCollection.Count)"
	foreach ($rrr in $ErrorCollection) {
		
		Write-Host "		Message: $($rrr.Message)"
		if ("SQLCLIENT" -eq $Framework) {
			Write-Host "		State: $($rrr.State)"
			Write-Host "		Number: $($rrr.Number)"
			Write-Host "		Line #: $($rrr.LineNumber)"
		}
	}
}

function Get-CommandObject {
	param (
		[ValidateSet("System", "Microsoft")]
		[string]$Framework = "System"
	);
	
	try {
		switch ($Framework) {
			"System" {
				return New-Object System.Data.SqlClient.SqlCommand;
			}
			default{
				throw "System.Data.SqlClient is currently the ONLY supported -Provider.";
			}
		}
	}
	catch {
		throw "TODO: something ugly happening while getting COMMAND object: $_";
	}
	
	throw "TODO: Improper Implementation of Get-CommandObject";
}

function Get-DataAdapter {
	param (
		[ValidateSet("System", "Microsoft")]
		[string]$Framework = "System",
		$Command
	);
	
	try {
		switch ($Framework) {
			"System" {
				return New-Object System.Data.SqlClient.SqlDataAdapter($Command);
			}
			default {
				throw "System.Data.SqlClient is currently the ONLY supported -Provider.";
			}
		}
	}
	catch {
		# output info about the source of the error and such... i.e., need some context here... 
	}
	
	throw "TODO: Improper Implementation of Get-DataAdapter";
}

function Get-ConnectionString {
	[CmdletBinding()]
	param (
		[ValidateSet("System", "Microsoft")]
		[string]$Framework,
		[Parameter(Mandatory)]
		[PSI.Models.Connection]$Connection
	);
	
	# TODO: need to wrap all of this logic in a try/catch - with some decent stack/location context... i.e., need to know exactly which lines are throwing errors/etc. 
	# TODO: along the lines of the above, add some VERBOSE and DEBUG details... i.e., instrument the HELL out of this code. 
	process {
		
		$user, $pass = $null;
		if ($Connection.Credential) {
			$user = $Connection.Credential.UserName;
			$pass = $Connection.Credential.GetNetworkCredential().Password;
		}
		
		$constructedString = "";
		# TODO: I probably no longer need this switch - unless Microsoft.Data.SqlClient provides different connection strings (which... it probably can due to different AUTH types?)
		switch ($Framework) {
			"System" {
				$constructedString = "Data Source=$($Connection.Server); Persist Security Info=True; Trusted_Connection=yes; Initial Catalog=$($Connection.Database);";
				
				if ($Connection.Credential) {
					$constructedString = "Data Source=$($Connection.Server); Persist Security Info=True; User ID=$user; Password=$pass;Initial Catalog=$($Connection.Database);";
				}
			}
			default {
				throw "System.Data.SqlClient is currently the ONLY supported -Framework.";
			}
		}
		
		if ($Connection.ConnectionTimeout -gt 0) {
			$constructedString += "Connection Timeout=$($Connection.ConnectionTimeout);";
		}
		
		if ($Connection.ApplicationName) {
			$constructedString += "Application Name=$($Connection.ApplicationName);";
		}
		
		# TODO: Address $Connection.
		# 		.Encrypt 
		# 		.TrustServerCertificate 
		# 		.ReadOnly 	
		
		
		return $constructedString;
		
		# TODO: the train-wreck below - where I called into the FUNC that i was CALLING FROM and wondered why func i was originally calling into
		# 	was asking for ... -Connection and -Batch ... needs to be addressed SOMEWHERE within the pipeline. 
		
		# TODO: 'cache' these connection details? ... ah yeah, easy enough: a hashtable of <connectionstring, true|false> (where true|false is whether it works or not.)
#		$testResult = Test-ConnectionString -Framework $Framework -ConnectionString $constructedString;
#		
#		if ($null -eq $testResult) {
#			return $constructedString;
#		}
#		
#		throw "Connection Configuration Error: $testResult";
	}
}

#function Test-ConnectionString {
#	param (
#		[ValidateSet("ODBC", "OLEDB", "SQLClient")]
#		[string]$Framework = "ODBC",
#		[Parameter(Mandatory)]
#		[string]$ConnectionString
#	);
#	
#	try {
#		
##		$conn = Get-ConnectionObject -Framework $Framework;
#		$conn.ConnectionString = $ConnectionString;
#		$conn.ConnectionTimeout = 20; # hmmmm. or ... should I pass this in from the callers?
#		
#		$cmd = Get-CommandObject -Framework $Framework;
#		$cmd.Connection = $conn;
#		$cmd.CommandText = "SELECT @@SERVERNAME [psi.command.connection-test]; ";
#		$cmd.CommandType = "TEXT";
#		
#		$conn.Open();
#		$cmd.ExecuteScalar() | Out-Null;
#		$conn.Close();
#		
#		return $null;
#	}
#	catch {
#		return $_;
#	}
#	
#	# TODO: Need a FINALLY here to get rid of any objects I've created to this point. 
#}