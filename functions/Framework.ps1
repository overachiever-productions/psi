Set-StrictMode -Version 1.0;

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
		[PSCredential]$Credentials = $null,
		[string]$ConnectionString = $null
	);
	
	# if -ConnectionString is provided, verify that it looks good (and or test it?) then return it. 
	if (-not ([string]::IsNullOrEmpty($ConnectionString))) {
		return $ConnectionString; # MVP implementation... 
	}
	
	$user, $pass = $null;
	if ($Credentials) {
		$user = $Credentials.UserName;
		$pass = $Credentials.GetNetworkCredential().Password;
	}
	
	# otherwise, time to build-up a connection-string from the info provided.
	switch ($Framework) {
		"ODBC" {
			# MVP implementation:
			if ($Credentials) {
				return "Driver={ODBC Driver 17 for SQL Server}; Server=$Server; Database=$Database; UID=$user; PWD=$pass;";
			}
			return "Driver={ODBC Driver 17 for SQL Server}; Server=$Server; Database=$Database; Trusted_Connection=yes;";
		}
		"OLEDB" {
			# MVP implementation:
			if ($Credentials) {
				return "Provider=MSOLEDBSQL; Data Source=$Server; Persist Security Info=True; Trusted_Connection=yes; Initial Catalog=$Database;";
			}
			return "Provider=MSOLEDBSQL; Data Source=$Server; Persist Security Info=True; User ID=$user; Password=$pass; Initial Catalog=$Database;";
		}
		"SQLClient" {
			# MVP implementation:
			if ($Credentials) {
				
			}
			return "Data Source=$Server; Persist Security Info=True; User ID=$user; Password=$pass;Initial Catalog=$Database;";
		}
	}
	
	throw "TODO: Improper Implementation of Get-ConnectionString";
}

function Get-ConnectionStringBuilder {
	param (
		
	);
	
	# ARGUABLY, I could use this a bit like an interface. Er, well, I could pass out an OBJECT that was something like an I_SQL_ConnStringBuilder ... 
	# 	that provided methods for ALL of the connection-string params I want to be able to set for a given connection string type (ODBC, OLEDB, SQLClient)
	# 		and... nothing more. 
	# Or, in other words:
	# 	ODBCConnectionStringBuilder and OledbConnectionStringBuilder are WILDLY different from SqlConnectionStringBuilder (cuz they have to support all sorts of endpoints/etc)
	# 			and ODBCConnBuilder + OledbConnBuilder are also quite different (engouh) from each other. 
	# 		so... what I want is 'translations' or 'implementations' of a 'common interface' (the exact options I need to build a connection to SQL SERVER - for each driver/provider)
	# 			and... that's it. 
	
	# and... to accomplish the above (i.e., the equivalent of an interface with 3x different implementations) ... 
	# 	I have 2 main options: 
	# 		a. cheat and/or create some sort of object in powershell that does what I want/need. 
	# 		b. create some sort of 'bridge' implementation + full-on interfaces ... from within C# and just lump the code in for said interface + the bridge/implementations. 
	
	# 		option B seems like the best option.
	
	
	# Fodder: 
	# 		ODBC: https://learn.microsoft.com/en-us/dotnet/api/system.data.odbc.odbcconnectionstringbuilder?view=dotnet-plat-ext-7.0 
	# 		OLEDB: https://learn.microsoft.com/en-us/dotnet/api/system.data.oledb.oledbconnectionstringbuilder?view=dotnet-plat-ext-7.0
	# 		SQLCLI: https://learn.microsoft.com/en-us/dotnet/api/system.data.sqlclient.sqlconnectionstringbuilder?view=dotnet-plat-ext-7.0
	
	#   ODBC Connection Strings: https://www.connectionstrings.com/microsoft-odbc-driver-17-for-sql-server/ 
	# 	OLEDB Conn Strings: https://www.connectionstrings.com/ole-db-driver-for-sql-server/ 
	
	
	# THEN, the implementation (once option B above has been tackled) for Get-ConnectionString would look a bit like: 
	
	# $builder = Get-ConnStringBuilder $framework;
	# $builder.Server $Server;
	# $builder.Database $Db... 
	# ... handle creds and other details here. 
	
	# now... handle 'generic' stuff that isn't 'core' but still is important, like:
	# 	.ApplicationName = $appName, .IsReadOnly ... .AllowEncryption & .TrustServerCert & .MultiSubnetFailover etc... 
	
	# then:
	# return $builder.GetConnectionString();
	
	
}


