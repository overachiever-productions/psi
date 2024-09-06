Set-StrictMode -Version 3.0;

<#

	Framework Docs: 

		CLR / .NET 4.8 
			System.Data.SqlClient: https://learn.microsoft.com/en-us/dotnet/api/system.data.sqlclient.sqlconnection.fireinfomessageeventonusererrors?view=netframework-4.8.1 

		
		.NET 8 
			ODBC: 			https://learn.microsoft.com/en-us/dotnet/api/system.data.odbc.odbcconnection?view=net-8.0
			OLEDB: 			https://learn.microsoft.com/en-us/dotnet/api/system.data.oledb?view=net-8.0
			SQLClient: 	
				=> sigh... it's part of Microsoft.Data.SqlClient - which is fine. 
				BUT... that's not documented in .NET 8 'stuff'. 
					it's documented as .NET Standard 
							https://learn.microsoft.com/en-us/dotnet/api/microsoft.data.sqlclient.sqlconnection?view=sqlclient-dotnet-standard-5.2


#>


filter Get-FrameworkProvider {
	# TODO: might also make sense to look to see which drivers are installed on box. 
	
	$poshVersion = $PSVersionTable.PSVersion;
	if ($poshVersion.Major -ge 5) {
		return "SQLClient";
	}
	
	return "SQLClient";
}

function Get-ConnectionObject {
	[CmdletBinding()]
	param (
		[ValidateSet("ODBC", "OLEDB", "SQLClient")]
		[string]$Framework,
		[Parameter(Mandatory)]
		[PSI.Models.Connection]$Connection,
		[Parameter(Mandatory)]
		[PSI.Models.BatchResult]$BatchResult
	);
	
	process {
		$connString = Get-ConnectionString -Framework $Framework -Connection $Connection;
		
		
		# nice. I've got solid docs for all of the 'error' types  (i.e., what's returned from the INFO_MSGS)
		# 	SqlClient has some 'extra' options/features: https://learn.microsoft.com/en-us/dotnet/api/microsoft.data.sqlclient.sqlerror?view=sqlclient-dotnet-standard-5.2 
		# 	ODBC and OLEDB are virtually identical: 
		# 		https://learn.microsoft.com/en-us/dotnet/api/system.data.oledb.oledberror?view=net-8.0
		# 		https://learn.microsoft.com/en-us/dotnet/api/system.data.odbc.odbcerror?view=net-8.0
		
		
		$output = $null;
		try {
			switch ($Framework) {
				"ODBC" {
					$output = New-Object System.Data.Odbc.OdbcConnection($connString);
					$infoHandler = [System.Data.Odbc.OdbcInfoMessageEventHandler] {
						Get-SqlInfoDetails -ErrorCollection $_.Errors -Message $_.Message -Framework $Framework;
					#	Write-Host "ODBC INFO: [$($_)])";
					}
					$output.Add_InfoMessage($infoHandler);
				}
				"OLEDB" {
					$output = New-Object System.Data.OleDb.OleDbConnection($connString);
					$infoHandler = [System.Data.OleDb.OleDbInfoMessageEventHandler] {
						Get-SqlInfoDetails -ErrorCollection $_.Errors -Message $_.Message -Framework $Framework;
						
					#	Write-Host "OLEDB INFO: [$($_)])";
					}
					$output.Add_InfoMessage($infoHandler);
				}
				"SQLClient" {
					$output = New-Object System.Data.SqlClient.SqlConnection($connString);
					$output.FireInfoMessageEventOnUserErrors = $true;
					$infoHandler = [System.Data.SqlClient.SqlInfoMessageEventHandler] {
						Get-SqlInfoDetails -ErrorCollection $_.Errors -Message $_.Message -Framework $Framework;
						
						#$BatchResult.AddResultText($_);
					}
					$output.Add_InfoMessage($infoHandler);
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
			throw "CONN TEST ERROR: $_";
		}
		finally {
			# anything I should be cleaning up here ? 			
		}
		
		return $output;
	}
}

function Get-SqlInfoDetails {
	param (
		$ErrorCollection,
		[string]$Message,
		[string]$Framework
	);
	
	# WEIRD. 
	# 	- OLEDB DOESN'T treat PRINT outputs as errors. It ONLY provides 'Messages'
	# 		PERIOD. 
	# 	- ODBC ... on the other hand... provides all sorts of details - including 'USER ERRORs' - along with their Error #s (5701, 5703)
	# 			AND uses a STATE of 0100 for these 'user errors'
	# 			AND then REPEATS the damned things with a number of ... 0 
	# 				AND when it repeats, the STATE then becomes 01S00 ... 
	# 				honestly, ODBC is a fuggin' mess
	# 		meanwhile, the .Source (of each ErrorMessage) within ODBC is: 
	# 				NULL/EMPTY for the stupid 'user errors'
	# 				and ... becomes "msodbcsql17.dll" for ... PRINT 'xxx' results. 
	# 	- SqlClient ... does EVERYTHING 'right' - i.e., what I'd fully expect.
	
	Write-Host "  INFO MESSAGE: $Message";
	
	Write-Host "	ERRORS: $($ErrorCollection.Count)"
	foreach ($rrr in $ErrorCollection) {
		
		Write-Host "		Message: $($rrr.Message)"
		if ("SQLCLIENT" -eq $Framework) {
			Write-Host "		State: $($rrr.State)"
			Write-Host "		Number: $($rrr.Number)"
			Write-Host "		Line #: $($rrr.LineNumber)"
		}
		else{
			Write-Host "		State: $($rrr.SqlState)"
			Write-Host "		Number: $($rrr.NativeError)"
			Write-Host "		Ignored?  $($rrr.Source)"
		}
	}
}

function Get-CommandObject {
	param (
		[ValidateSet("ODBC", "OLEDB", "SQLClient")]
		[string]$Framework = "ODBC"
	);
	
	try {
		switch ($Framework) {
			"ODBC" {
				return New-Object System.Data.Odbc.OdbcCommand;
			}
			"OLEDB" {
				return New-Object System.Data.OleDb.OleDbCommand;
			}
			"SQLClient" {
				return New-Object System.Data.SqlClient.SqlCommand;
			}
		}
	}
	catch {
		
	}
	
	throw "TODO: Improper Implementation of Get-CommandObject";
}

function Get-DataAdapter {
	param (
		[ValidateSet("ODBC", "OLEDB", "SQLClient")]
		[string]$Framework = "ODBC",
		$Command
	);
	
	try {
		switch ($Framework) {
			"ODBC" {
				return New-Object System.Data.Odbc.OdbcDataAdapter($Command);
			}
			"OLEDB" {
				return New-Object System.Data.OleDb.OledbDataAdapter($Command);
			}
			"SQLClient" {
				return New-Object System.Data.SqlClient.SqlDataAdapter($Command);
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
		[ValidateSet("ODBC", "OLEDB", "SQLClient")]
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
		switch ($Framework) {
			"ODBC" {
				$constructedString = "Driver={ODBC Driver 17 for SQL Server}; Server=$($Connection.Server); Database=$($Connection.Database); Trusted_Connection=yes;";
				
				if ($Connection.Credential) {
					$constructedString = "Driver={ODBC Driver 17 for SQL Server}; Server=$($Connection.Server); Database=$($Connection.Database); UID=$user; PWD=$pass;";
				}
			}
			"OLEDB" {
				$constructedString = "Provider=MSOLEDBSQL; Data Source=$($Connection.Server); Persist Security Info=True; Trusted_Connection=yes; Initial Catalog=$($Connection.Database);";
				
				if ($Connection.Credential) {
					$constructedString = "Provider=MSOLEDBSQL; Data Source=$($Connection.Server); Persist Security Info=True; User ID=$user; Password=$pass; Initial Catalog=$($Connection.Database);";
				}
			}
			"SQLClient" {
				$constructedString = "Data Source=$($Connection.Server); Persist Security Info=True; Trusted_Connection=yes; Initial Catalog=$($Connection.Database);";
				
				if ($Connection.Credential) {
					$constructedString = "Data Source=$($Connection.Server); Persist Security Info=True; User ID=$user; Password=$pass;Initial Catalog=$($Connection.Database);";
				}
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