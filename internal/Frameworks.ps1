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
					
					# DOCS: 
					# 	SEVERITIES: https://learn.microsoft.com/en-us/sql/relational-databases/errors-events/database-engine-error-severities?view=sql-server-ver16
					# 	ERROR OBJECT: https://learn.microsoft.com/en-us/dotnet/api/system.data.sqlclient.sqlerror?view=netframework-4.8.1					
					$infoHandler = [System.Data.SqlClient.SqlInfoMessageEventHandler] {
						param (
							$sender,
							$eventArgs
						);
						
						foreach ($xput in $eventArgs.Errors) {
							$printedOutput = New-Object Psi.Models.PrintedOutput($xput.Message, $xput.Class, $xput.State, $xput.Number, $xput.LineNumber);
							$BatchResult.AddPrintedOutput($printedOutput);
							
							Write-Verbose "Msg $($xput.Number), Level $($xput.Class), State $($xput.State), Line $($xput.LineNumber)";
							Write-Verbose "	$($xput.Message)";
						}
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
		
		Test-DbConnection -ConnectionString $connString;
		
		return $output;
	}
}

$global:5EAF20FD_TestedConnections = @{ };
filter Test-DbConnection {
	param (
		[string]$ConnectionString
	);
	
	$lastTested = $global:5EAF20FD_TestedConnections[$ConnectionString];
	if ($lastTested) {
		if ($lastTested -gt [Datetime]::Now.AddMinutes(-30)) {
			return;
		}
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
		throw;
	}
	finally {
		# TODO: anything I should be cleaning up here ? 	(i.e., "can't" dispose the connection - it's ... what I'm passing out. 
		# but... command, and other things should be getting nuked, right? 
	}
	
	$global:5EAF20FD_TestedConnections[$ConnectionString] = [DateTime]::Now;
}

function Get-CommandObject {
	param (
		[ValidateSet("System", "Microsoft")]
		[string]$Framework = "System",
		[PSI.Models.BatchResult]$BatchResult
	);
	
	try {
		switch ($Framework) {
			"System" {
				$output = New-Object System.Data.SqlClient.SqlCommand;
				$handler = [System.Data.StatementCompletedEventHandler] {
					param (
						$sender,
						$eventArgs
					);
					
					# DOCS: https://learn.microsoft.com/en-us/dotnet/api/system.data.statementcompletedeventargs?view=netframework-4.8.1
					if ($BatchResult.AllowRowCounts) {
						
						$affected = "($($eventArgs.RecordCount) rows affected)";
						if ($eventArgs.RecordCount -eq 1) {
							$affected = $affected.Replace("rows", "row");
						}
						
						$BatchResult.AddRowCount($affected, (Get-Date));
						
						Write-Verbose $affected;
					}
				}
				
				$output.Add_StatementCompleted($handler);
				return $output;
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
		# 		.ReadOnly - i.e., ApplicationIntent
		# 		MAYBE: .AlwaysEncrypted (various directives)
		# 		MAYBE: ConnectionPoolingDirectives (loadbalancetimeout, maxpoolsize, minpoolsize)
		# 		.MultiSubnetFailover  
		# 		MAYBE: .PacketSize
		
		return $constructedString;
	}
}