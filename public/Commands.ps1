Set-StrictMode -Version 3.0;

<#
	

					#$query = Get-Content "D:\Dropbox\Desktop\.junk\psi_script_test.sql" -Raw;


					#$query = @"
					#USE [admindb];   /* multi line comment here - to make sure that multi-line comments
					#can
					#and will
					#be ignored */
					#GO
					#
					#IF OBJECT_ID(N'abc', N'U') IS NULL BEGIN 
					#    CREATE TABLE abc (id int);
					#END; 
					#GO
					#
					#USE [admindb];  -- comment here - just for fun. 
					#GO 
					#
					#IF OBJECT_ID(N'xyz', N'U') IS NULL BEGIN 
					#    CREATE TABLE xyz (id int);
					#END;
					#GO
					#"@;


					#$query = Get-Content "D:\Dropbox\Repositories\S4\Common\Tables\restore_log.sql" -Raw;


$query = @"
IF OBJECT_ID('dbo.settings','U') IS NULL BEGIN
	SELECT N'Settings Table does NOT exist.' [fake_outcome];
  END;
ELSE BEGIN 
	PRINT 'found it';
	SELECT * FROM dbo.settings;
	PRINT 'selected from it';
END;
"@




	#$query = "SELECT * FROM dbo.Settings;";
	Import-Module -Name "D:\Dropbox\Repositories\psi" -Force;
	Invoke-PsiCommand -SqlInstance "dev.sqlserver.id" -Database "admindb" -Query $query -SqlCredential (Get-Credential sa) -ConnectionTimeout 30;





# examples of MULTIPLE/DIFFERENT SET-OPTIONS (i.e., options-sets).
#Invoke-PsiCommand -SqlInstance "sql-150a.sqlserver.id" -Database "admindb" -Query $query -SetOptions "ARITHABORT:ON, ANSI_NULLS:ON", "ARITHABORT:OFF, ANSI_NULL:OFF";



	#Invoke-PsiCommand -SqlInstance "dev.sqlserver.id", "sql-150a.sqlserver.id" -Database "master", "admindb" -Query $query, "SELECT TOP (10) Tables ORDER BY Size DESC;"
	

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
		[string[]]$SetOptions = $null,
		[PSCredential]$SqlCredential,
		[string[]]$Database = "master",
		[Alias("Command", "CommandText")]
		[string[]]$Query = $null,
		[Alias("InputFile", "Script", "SQLFile", "SQLScript")]
		[string[]]$File = $null, 
		[Alias("Sproc", "ProcedureName", "Procedure")]
		[string[]]$SprocName = $null,
		[PSI.Models.ParameterSet[]]$Parameters = $null,
		[string[]]$ParameterString = $null,
		[int]$ConnectionTimeout = -1,
		[int]$CommandTimeout = -1,
		[int]$QueryTimeout = -1,
		[Alias("AppName")]
		[string]$ApplicationName = "PSI.Command",		# TODO: possibly use "reflection" to get module version and shove it in to app name? e.g., "PSI.Command (1.2)"
		[ValidateSet("AUTO", "ODBC", "OLEDB", "SQLClient")]
		[Alias("Driver", "Provider")]
		[string]$Framework = "AUTO",
		[switch]$ReadOnly = $false,
		[switch]$Encrypt = $true,
		[switch]$TrustServerCert = $true,
		# MAYBE: [switch]$MultiSubnetFailover = $false, ... this is ONLY supported for SqlClient. 
		[switch]$AsObject = $false,  # i.e., as a BatchResult (full/robust details and output)
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
			"Object"	= $AsObject
			"NonQuery"  = $AsNonQuery
			"Scalar"    = $AsScalar
			"Json"	  	= $AsJson
			"Xml"	    = $AsXml
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
		
		if ($Framework -eq "AUTO") {
			$Framework = Get-FrameworkProvider;
		}
		
		[PSI.Models.BatchResult[]]$results = @();
	}
	
	process {
		$connections = @();
		$commands = @();
		$setsOfSetOptions = @();
		$parameterSets = @();
		
		# ====================================================================================================
		# Connections:
		# ====================================================================================================			
		if ((Array-IsPopulated $SqlInstance) -and (Array-IsPopulated $ConnectionString)) {
			throw "one of the other - not both (instance and constrings).";
		}
		
		foreach ($cs in $ConnectionString) {
			$connections += [PSI.Models.Connection]::FromConnectionString($Framework, $cs);
		}
		
		foreach ($si in $SqlInstance) {
			$connections += [PSI.Models.Connection]::FromServerName($Framework, $si);
		}
		
		if ($connections.Count -lt 1) {
			throw "no connections - specify either -Instance or -ConnString";
		}
		
		# ====================================================================================================
		# Set Options:
		# ====================================================================================================	
		foreach ($optionSet in $SetOptions) {
			$setsOfSetOptions += [PSI.Models.OptionSet]::DeserializedOptionSet($optionSet);
		}
		
		if ($setsOfSetOptions.Count -eq 0) {
			$setsOfSetOptions += [PSI.Models.OptionSet]::PlaceHolderOptionSet();
		}
		
		# ====================================================================================================
		# Commands:
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
		# Parameters:
		# ====================================================================================================	
		if ((Array-IsPopulated $Parameters) -and (Array-IsPopulated $ParameterString)) {
			throw "one or the other - not both (-Parameters and -ParameterString).";
		}
		
		foreach ($pSet in $Parameters) {
			$parameterSets += $pSet;
		}
		
		foreach ($pString in $ParameterString) {
			$parameterSets += Expand-SerializedParameters -Parameters $pString;
		}
		
		if ($parameterSets.Count -lt 1) {
			$Parameters += [Psi.Models.ParameterSet]::EmptyParameterSet();
		}
		
		# ====================================================================================================
		# Credentials:
		# ====================================================================================================			
		# IF NO Creds supplied, we'll assume Native/Windows Auth - i.e., current user. BUT, still need a 'creds'
		# 	place-holder object to iterate through/over in the nested loops part of assembling batches/commands: 
		if (-not (Array-IsPopulated $SqlCredential)) {
			# REFACTOR: have the following, bogus, cred created by a FACTORY (static .ctor) method... (and move the "notes" above into said method...)
			$SqlCredential += [PSCredential]::new("Psi_Bogus_C9F014B5-9C08-4C9D-B205-E3A7DFAB3C18", ("_PLACEHOLDER_" | ConvertTo-SecureString -AsPlainText -Force ));
		}
		
		# ====================================================================================================
		# Combine Options:
		# ====================================================================================================	
		[int]$batchNumber = 0;
		foreach ($connection in $connections) {
			foreach ($optionsSet in $setsOfSetOptions) {
				foreach ($credential in $SqlCredential) {
					foreach ($db in $Database) {
						foreach ($command in $commands) {
							foreach ($paramSet in $Parameters) {
								foreach ($batch in $command.GetBatches()) {
									
									$connection.ConnectionTimeout = $ConnectionTimeout;
									$connection.CommandTimeout = $CommandTimeout;
									$connection.QueryTimeout = $QueryTimeout;
									
									$connection.Encrypt = $Encrypt;
									$connection.TrustServerCertificate = $TrustServerCert;
									$connection.ReadOnly = $ReadOnly;
									
									$connection.ApplicationName = $ApplicationName;
									
									$batchConnection = $connection.GetBatchConnection($credential, $db);
									$results += Execute-Batch -Framework $Framework -Connection $batchConnection -Batch $batch -SetOptions $optionsSet -Parameters $paramSet -BatchNumber $batchNumber;
									
									$batchNumber += 1;
								}
							}
						}
					}
				}
			}
		}
	}
	
	end {
		Add-ResultsToCommandHistory -Results $results;
		
		
		Write-Host "-------------------------------------------------------------------------------------------------------------";
		Write-Host "`n";
		
		# TODO: 
		# 		I've created problem for my self.  
		# 		$results is NOW a COLLECTION of 1 - N outputs/results. 
		# 				that wasn't, initially the case. 
		# 				but it is now. 
		# 		so. 
		# 		with the logic below. 
		# 		do i do a FOREACH? and return the outputs of EACH ... $result in $results? 
		# 			or, is there another way? 
		# 			i honestly can't think of any other way.
		# 				well. ONE option is: IF THERE are > 1 result(s)... then, return things -AsObject - i.e., just dump this piglet. 
		# 				AND, I was going to say: the PROBLEM with that is that it would make things hard for scenarios where I want to 
		# 				use PSI for, say, the equivalent of Redgate's Sql Multi Script ... and fire things off against a BUNCH of databases
		# 				or targets. 
		# 				ONLY... WHAT IF I made it so that I could format/output the 'printed' versions of this 'stuff' super clean/nice/good? 
		# 					at that point, I'm DONE. 
		# 				As in, programatic access for scripts, automation, etc. is LIKELY to typically be used one BATCH at a time. Or, against a handful 
		# 					of batches.
		# 				Consider using this against admindb.latest.sql ... 
		#  				as a script author, I could either: 
		# 					let $results bet parroted back to the user/caller - showing all of the 100s? of outputs for each batch. 
		# 				OR... as the author, I could LOOK FOR ERRORS and PROBLEMS and ... if there were none, say: "Executed 123 batches without issue.."
		# 					or whatever... 
		# 			POINT being:
		# 				there's PRINTING the results - which I can/will format as needed/optimal. 
		# 				and there's USING the results for further scripting. 
		# 				and I THINK the use case is: 
		# 				'scalar' results can/will return using 'dynamic' logic that figures out the right 'size' for the returned result 
		# 						(i.e., if/when there are no explicit -AsX directives defined.)
		# 				but 'array'/multi-results should just be shot back as $results - i.e., treated -AsObject 
		# 					and, I can then 'format' a collection (0 - N results) of [PSI.Models.BatchResult[]] for output as needed. 
		# 			AND, I think that formatting/output looks something like: 
		# 				> spit out any fatal or ugly errors if/as needed. 
		# 				> the above MIGHT be 'it'
		# 				> otherwise, if there were no projections/outputs, then mirror what SSMS does "Completion time xxxx" or "whatever it says upon success"
		# 				> 		and/or spit out anything that was 'printed'
		# 				> 		and/or POSSIBLY spit out the results of the RETURN x if htere was one or MAYBE ??? @output OUTPUT params/values? 
		# 				> otherwise, can/will spit out tables ... i guess to a point. 
		# 					or, maybe a description of a table in some cases. 
		# 					e.g., 3 tables with 12, 4, 6 columns and 128, 3, 333387 rows (respectively)
		
		
		# Processing of outputs is a BIT complex. But the best way to tackle that is to:
		# 	1. Check for any EXPLICIT -AsXXX output types first (going 'up' from smallest/least output type to largest output type)
		# 	2. Once those EXPLICIT options are handled, try going 'down' from largest to smallest to return whatever makes the most SENSE. 		
		if ($AsNonQuery) {
			return;
		}
		
		if ($AsObject) {
			return $results;
		}
		
		# from here on out, need the DataSet...
		$dataSet = $results.DataSet;
		
		if ($AsScalar -or $AsJson -or $AsXml) {
			return $dataSet.Tables[0].Rows[0][0];
			throw "Explicit -AsScalar, -AsJson, and -AsXml switches are not YET implemented.";
		}
		
		if ($AsDataRow) {
			return $dataSet.Tables[0].Rows[0];
		}
		
		if ($AsDataTable) {
			return $dataSet.Tables[0];
		}
		
		# Done with 1 (going 'up' vs explicit output types) and ... starting to go 'down' implicit types (in single clause):
		if (($AsDataSet) -or ($dataSet.Tables.Count -gt 1)) {
			return $dataSet;
		}
		
		$table = $dataSet.Tables[0];
		if ($table.Rows.Count -gt 1) {
			return $table;
		}
		
		if ($table.Rows.Count -eq 0) {
			return; # this is/was an 'implicit' -AsNonQuery
		}
		
		# there was ONLY 1 row (from a single table):
		$row = $table.Rows[0];
		
		# NOTE: Can't 'tell' how many columns per ROW - have to 'query' for this info against the parent table instead. 
		# 		otherwise, if we've got a table with 1 row and just 1 column, we've hit an implicit scalar:
		if ($table.Columns.Count -gt 1){
			return $row; 
		}
#		
#		if ($row.Columns.Count -gt 1) {
#			return $row; # multiple columns - return the entire row.
#		}
		
		# There are 3x options for returning scalar values:
		# 		a. Return the WHOLE ROW (even if it's just a single column-wide). This is what Invoke-SqlCmd does. 
		# 		b. Create a custom PSObject with column-name and value results. CAN'T see ANY benefit to this over a data-row.
		# 		c. No context info - just the scalar result itself (i.e., not the column-name - just the 'scalar value itself - fully isolated')/
		# For now, Invoke-PsiCommand will leverage option A. 
		return $row; # option C would be $row[0].		
	}
}