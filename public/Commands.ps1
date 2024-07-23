Set-StrictMode -Version 3.0;

<#
	

#$query = Get-Content "D:\Dropbox\Desktop\.junk\psi_script_test.sql" -Raw;


$query = @"
USE [admindb];   /* multi line comment here - to make sure that multi-line comments
can
and will
be ignored */
GO

IF OBJECT_ID(N'abc', N'U') IS NULL BEGIN 
    CREATE TABLE abc (id int);
END; 
GO

USE [admindb];  -- comment here - just for fun. 
GO 

IF OBJECT_ID(N'xyz', N'U') IS NULL BEGIN 
    CREATE TABLE xyz (id int);
END;
GO
"@;



	Import-Module -Name "D:\Dropbox\Repositories\psi" -Force;

	Invoke-PsiCommand -SqlInstance "sql-150a.sqlserver.id" -Database "admindb" -Query $query;



	Invoke-PsiCommand -SqlInstance "dev.sqlserver.id", "sql-150a.sqlserver.id" -Database "master", "admindb" -Query $query, "SELECT TOP (10) Tables ORDER BY Size DESC;"



	#Invoke-PsiCommand  -ConnectionString "first" -Query "SELECT TOP 200 session_id FROM sys.dm_exec_sessions;" -AsJson;

# should throw:
	#Invoke-PsiCommand -SqlInstance "dev.sqlserver.id"  -ConnectionString "first" -Query "SELECT TOP 200 session_id FROM sys.dm_exec_sessions;"


#>




function Get-PsiConnectionString {
	# for more 'advanced' options - i.e., pass in a bunch of arguments and such to this func... 
	# and it'll spit back a connection-string that can then be used to connect to servers 
	# with 'more advanced' options like: 
	# 		port #
	# 		things like ANSI_NULLS, ARITHABORT, and the likes. 
	
}

function Invoke-PsiCommand {
	[CmdletBinding()]
	param (
		[Alias("ServerInstance", "ServerName", "Instance")]
		[string[]]$SqlInstance,
		[string[]]$ConnectionString,   
		[Alias("Credential", "Credentials")]
		[PSCredential]$SqlCredential,
		[string[]]$Database = "master",
		[Alias("Command", "CommandText")]
		[string[]]$Query = $null,
		[Alias("InputFile", "Script", "SQLFile", "SQLScript")]
		[string[]]$File = $null, 
		[Alias("Sproc", "ProcedureName", "Procedure")]
		[string[]]$SprocName = $null,
		
# Users don't need to specify this IF I've got params for both -Query (FIle) and -SprocName
#		[ValidateSet("Text", "StoredProcedure")]
#		[string]$CommandType = "Text",
		
		[PSI.Models.ParameterSet]$Parameters = $null,
		[string]$ParameterString = $null,

		
		[int]$ConnectionTimeout = -1,
		[int]$CommandTimeout = -1,
		[int]$QueryTimeout = -1,
		[Alias("AppName")]
		[string]$ApplicationName,
		[ValidateSet("AUTO", "ODBC", "OLEDB", "SQLClient")]
		[Alias("Driver", "Provider")]
		[string]$Framework = "AUTO",
		[switch]$ReadOnly = $false,
		[switch]$Encrypt = $true,
		[switch]$TrustServerCert = $true,
		[switch]$AsDataSet = $false,
		[switch]$AsDataTable = $false,
		[switch]$AsDataRow = $false,
		[switch]$AsScalar = $false,
		[switch]$AsNonQuery = $false,
		[switch]$AsJson = $false,
		[switch]$AsXml = $false
	);
	
	begin {
		[bool]$xVerbose = ("Continue" -eq $global:VerbosePreference) -or ($PSBoundParameters["Verbose"] -eq $true);
		[bool]$xDebug = ("Continue" -eq $global:DebugPreference) -or ($PSBoundParameters["Debug"] -eq $true);
		
		$outputOptions = @{
			"NonQuery"  = $AsNonQuery
			"Scalar"    = $AsScalar
			"Json"	  = $AsJson
			"Xml"	      = $AsXml
			"DataRow"   = $AsDataRow
			"DataTable" = $AsDataTable
			"DataSet"   = $AsDataSet
		}
		
		if(($outputOptions.GetEnumerator() | Where-Object { $true -eq $_.Value; } | Measure-Object).Count -gt 1) {
			throw "Invalid Parameter Usage for Invoke-PsiCommand. Only 1x -AsXXX switch can be set at a time.";
		}
		
		$outputType = ($outputOptions).GetEnumerator() | Where-Object { $true -eq $_.Value;	} | Select-Object -Property Name;
		$resultType = "PsiObject";
		if ($null -ne $outputType) {
			$resultType = $outputType.Name;
		}
		
		$provider = $Framework;
		if ($provider -eq "AUTO") {
			$provider = Get-FrameworkProvider;
		}
		
		$results = @();
	}
	
	process {
		$connections = @();
		$commands = @();
		
		# ====================================================================================================
		# 1. Connections:
		# ====================================================================================================			
		if ((Array-IsPopulated $SqlInstance) -and (Array-IsPopulated $ConnectionString)) {
			throw "one of the other - not both (instance and constrings).";
		}
		
		foreach ($cs in $ConnectionString) {
			$connections += [PSI.Models.Connection]::FromConnectionString($provider, $cs);
		}
		
		foreach ($si in $SqlInstance) {
			$connections += [PSI.Models.Connection]::FromServerName($provider, $si);
		}
		
		if ($connections.Count -lt 1) {
			throw "no connections - specify either -Instance or -ConnString";
		}
		
		# ====================================================================================================
		# 2. Commands:
		# ====================================================================================================		
		if ((Array-IsPopulated $Query) -and (Array-IsPopulated $File)) {
			throw "one or the other - not both (query or file)";
		}
		
		foreach ($f in $File) {
			try {
				$path = Resolve-Path -Path $f;
				$Query += [System.IO.File]::ReadAllText($path)
			}
			catch {
				"ruh roh. problem reading file contents for file [$f] -> $_ ";
			}
		}
		
		if ((Array-IsPopulated $SprocName) -and (Array-IsPopulated $Query)) {
			throw "one or the other - sproc-names or Query (file-contents).";
		}
		
		foreach ($q in $Query) {
			$commands += [Psi.Models.Command]::FromQuery($q, $resultType);
		}
		
		foreach ($s in $SprocName) {
			$commands += [Psi.Models.Command]::ForSproc($s, $resultType)
		}
		
		if ($commands.Count -lt 1) {
			throw "Doh. No commands specified. Specify either -SprocName(s), -Query(s) ... or -File(s).";
		}
		
		# ====================================================================================================
		# 3. Credentials:
		# ====================================================================================================			
		# If Creds are supplied, they'll be applied to all ConnectionStrings/Server-Names. 
		# Otherwise, connections are attempted with Windows Auth using current user. 
		# 	However, rather than IF/ELSE and then BRANCH through nested foreach statements... 
		# 		IF no creds are specified, we'll use a placeholder (with bogus details - that'll be skipped by CLR objects)
		# 		so that we can at least 'loop 1x into' the foreach(Creds) loop below. 
		if (-not (Array-IsPopulated $SqlCredential)) {
			$SqlCredential += [PSCredential]::new("Psi_Bogus_C9F014B5-9C08-4C9D-B205-E3A7DFAB3C18", ("_PLACEHOLDER_" | ConvertTo-SecureString -AsPlainText -Force ));
		}
		
		[int]$batchNumber = 0;
		foreach ($connection in $connections) {
			foreach ($credential in $SqlCredential) {
				foreach ($db in $Database) {
					foreach ($command in $commands) {
						foreach ($serializedParameters in $ParameterString) {
							foreach ($batch in $command.GetBatchedCommands()) {
								
								# TODO: I THINK that the $batch (which is a BatchContext)
								# 	is PROBABLY the object that I'll send further into the pipeline.
								# 			or... maybe not. Maybe I'll work with something a bit 'flatter'.
#								Write-Host "------------------  ------------------";
#								Write-Host "[$batchNumber] CONNECTION: [$($connection.Server)]";
#								Write-Host "	CREDS: [$($SqlCredential.UserName)]"
#								Write-Host "		DATABASE: [$db]"
#								#Write-Host "			COMMAND: [$($command.CommandText)]"
#								Write-Host "			BATCH: [$($batch.BatchCommand.BatchText)]"
#								Write-Host "				PARAMS: "
								#								Write-Host " ";
								
#								Write-Host "-- $batchNumber ------------------------------------------------------------";
#								Write-Host "-- SERVER: [$($connection.Server)] --- DB: [$db] -------";
								
								Write-Host "========================================================================================";
								Write-Host $batch.BatchCommand.BatchText;
								
								$batchNumber += 1;
							}
							
							# bundle 
							# 	new CommandThingy - with following Props: 
							# 		.ConnectionString 
							# 		. 	Database (or is that part of the above - think it's both ... i.e., want to know which DB we connected against for history - but conn-string needs to be done/complete)
							# 		. 	Server (yeah, same as above)
							# 		. 	Framework (ditto - needs to be part of connstring - but also want to track it)
							# 		. 	AppName (ditto)
							# 		. 	Command - but this'll be per each GO-d block... 
							# 		. 	Command-type 
							# 		. 	Encrypt/Read-Only (AG)/TrustServer - i.e., these are all details. 
							# 		. 	SET options and other conn-string details. (like arithabort, ansi_nulls, etc)
							# 	so... use a .Connection object - with all of the props above - and ... .GetConnectionString() as a serialization func (that can't be leaked/output)
							# 		.ResultType (as x, y, or z - but only 1 option)
							# 		.Timeouts
							# 		. 	Connection (this'll have to be copied to .Connection object)
							# 		. 	Command 
							# 		.  	Query (how'z this diff than command? )
						}
					}
				}
			}
		}
		
		# now, foreach 'routable-object' ... hand-off to internal pipeline with a try-catch around each? 
	}
	
	end {
		# add $results to history manager thingy.
		
		# note if there was an -AsScalar... i'm going to need to slightly modify the return $results ... stuff below. 
		
		return $results;
	}
}