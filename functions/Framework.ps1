Set-StrictMode -Version 1.0;

filter Get-FrameworkProvider {
	$poshVersion = $PSVersionTable.PSVersion;
	if ($poshVersion.Major -ge 5) {
		return "ODBC";
	}
	
	return "SQLClient";
}

function Get-ConnectionObject {
	param (
		[ValidateSet("ODBC", "OLEDB", "SQLClient")]
		[string]$Framework = "ODBC"
	);
	
	try {
		switch ($Framework) {
			"ODBC" {
				return New-Object System.Data.Odbc.OdbcConnection;
			}
			"OLEDB" {
				return New-Object System.Data.OleDb.OleDbConnection;
			}
			"SQLClient" {
				return New-Object System.Data.SqlClient.SqlConnection;
			}
		}
	}
	catch {
		
	}
	
	throw "TODO: Improper Implementation of Get-ConnectionObject";
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
		[string]$Framework = "ODBC"
	);
	
	try {
		switch ($Framework) {
			"ODBC" {
				return New-Object System.Data.Odbc.OdbcDataAdapter;
			}
			"OLEDB" {
				return New-Object System.Data.OleDb.OledbDataAdapter;
			}
			"SQLClient" {
				return New-Object System.Data.SqlClient.SqlDataAdapter;
			}
		}
	}
	catch {
		
	}
	
	throw "TODO: Improper Implementation of Get-DataAdapter";
}

function Get-ConnectionString {
	param (
		[ValidateSet("ODBC", "OLEDB", "SQLClient")]
		[string]$Framework = "ODBC",
		[string]$Server = $null,
		[string]$Database = $null,
		[PSCredential]$SqlCredential = $null,
		[string]$ApplicationName,
		[string]$ConnectionString = $null,
		[switch]$ReadOnly,
		[switch]$Encrypt,
		[switch]$TrustCert
	);
	
	if (-not ([string]::IsNullOrEmpty($ConnectionString))) {
		$testResult = Test-ConnectionString -Framework $Framework -ConnectionString $ConnectionString;
		if ($null -eq $testResult) {
			return $ConnectionString;
		}
		
		throw "Invalid Connection String: $testResult ";
	}
	
	$user, $pass = $null;
	if ($SqlCredential) {
		$user = $SqlCredential.UserName;
		$pass = $SqlCredential.GetNetworkCredential().Password;
	}
	
	$constructedString = "";
	switch ($Framework) {
		"ODBC" {
			$constructedString = "Driver={ODBC Driver 17 for SQL Server}; Server=$Server; Database=$Database; Trusted_Connection=yes;";
			
			if ($SqlCredential) {
				$constructedString = "Driver={ODBC Driver 17 for SQL Server}; Server=$Server; Database=$Database; UID=$user; PWD=$pass;";
			}
		}
		"OLEDB" {
			# MVP implementation:
			if ($SqlCredential) {
				return "Provider=MSOLEDBSQL; Data Source=$Server; Persist Security Info=True; Trusted_Connection=yes; Initial Catalog=$Database;";
			}
			return "Provider=MSOLEDBSQL; Data Source=$Server; Persist Security Info=True; User ID=$user; Password=$pass; Initial Catalog=$Database;";
		}
		"SQLClient" {
			# MVP implementation:
			if ($SqlCredential) {
				
			}
			return "Data Source=$Server; Persist Security Info=True; User ID=$user; Password=$pass;Initial Catalog=$Database;";
		}
	}
	
	$testResult = Test-ConnectionString -Framework $Framework -ConnectionString $constructedString;
	
	if ($null -eq $testResult) {
		return $constructedString;
	}
	
	throw "Connection Configuration Error: $testResult";
}

function Test-ConnectionString {
	param (
		[ValidateSet("ODBC", "OLEDB", "SQLClient")]
		[string]$Framework = "ODBC",
		[Parameter(Mandatory)]
		[string]$ConnectionString
	);
	
	try {
		
		$conn = Get-ConnectionObject -Framework $provider;
		$conn.ConnectionString = $ConnectionString;
		$conn.ConnectionTimeout = 20; # hmmmm. or ... should I pass this in from the callers?
		
		$cmd = Get-CommandObject -Framework $Framework;
		$cmd.Connection = $conn;
		$cmd.CommandText = "SELECT @@SERVERNAME; ";
		$cmd.CommandType = "TEXT";
		
		$conn.Open();
		$cmd.ExecuteScalar() | Out-Null;
		$conn.Close();
		
		return $null;
	}
	catch {
		return $_;
	}
	
	# TODO: Need a FINALLY here to get rid of any objects I've created to this point. 
}