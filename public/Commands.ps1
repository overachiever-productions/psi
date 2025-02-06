Set-StrictMode -Version 3.0;

<#
	
	SUPER SIMPLE QUERY Example: 
		Import-Module -Name "D:\Dropbox\Repositories\psi" -Force;
		$creds = New-Object PSCredential("sa", (ConvertTo-SecureString "Pass@word1" -AsPlainText -Force));
		$id = Invoke-PsiCommand -SqlInstance "dev.sqlserver.id" -Database "master" -Query "Select [database_id] FROM sys.databases WHERE [name] = 'admindb';" -SqlCredential $creds;
		$id;

	SIMPLE QUERY WITH PARAMS:
		Import-Module -Name "D:\Dropbox\Repositories\psi" -Force;
		$creds = New-Object PSCredential("sa", (ConvertTo-SecureString "Pass@word1" -AsPlainText -Force));
		$parameters = New-PsiParameterSet;
		Add-PsiParameter -Name "@myDbName" -Type "sysname" -Value "admindb";
		$id = Invoke-PsiCommand -SqlInstance "dev.sqlserver.id" -Database "master" -Query "Select [database_id] FROM sys.databases WHERE [name] = @myDbName;" `
			-Parameters $parameters -SqlCredential $creds;
		$id;

	SIMPLE QUERY WITH PARAMS-STRING
		Import-Module -Name "D:\Dropbox\Repositories\psi" -Force;
		$creds = New-Object PSCredential("sa", (ConvertTo-SecureString "Pass@word1" -AsPlainText -Force));
		$myDbName = "admindb";
		$id = Invoke-PsiCommand -SqlInstance "dev.sqlserver.id" -Database "master" -Query "Select [database_id] FROM sys.databases WHERE [name] = @myDbName;" `
			-ParameterString "@myDbName sysname = $myDbName" -SqlCredential $creds;
		$id;


	PARAMS-STRING - with VARIABLE LENGTH DATA TYPEs: 



	PARAMS-STRING WITH NULL INPUTs: 



	SUPER SIMPLE SPROC (no parameters):
		Import-Module -Name "D:\Dropbox\Repositories\psi" -Force;
		$creds = New-Object PSCredential("sa", (ConvertTo-SecureString "Pass@word1" -AsPlainText -Force));
		Invoke-PsiCommand -SqlInstance "dev.sqlserver.id" -Database "lifingdb" -Sproc "load_import_meta_fields" -SqlCredential $creds;

	SPROC with ONE input parameter (using simplified, inline, approach):
				#TODO: not sure I love how i'm passing in VALUES for strings - i.e., PVCLeanData vs N'PVCleanData'. 
				# 		it makes plenty of sense ... but I think that the 'other' (native-ish) way makes a lot of sense too. 
				# i.e., might make sense to provide an option that STRIPS 'native' string handling  'back/down' to basics and go that route?
		Import-Module -Name "D:\Dropbox\Repositories\psi" -Force;
		Invoke-PsiCommand -SqlInstance "dev.sqlserver.id" -Database "lifingdb" -Sproc "load_import_data_ranges" -ParameterString "@ImportType sysname = '; PRINT 'oh crap!' --" -SqlCredential (Get-Credential sa);


	PRINT / OUTPUT EXAMPLES: 
		
		IMPLIED PRINT:
			Import-Module -Name "D:\Dropbox\Repositories\psi" -Force;
			$creds = New-Object PSCredential("sa", (ConvertTo-SecureString "Pass@word1" -AsPlainText -Force));
			Invoke-PsiCommand -SqlInstance "dev.sqlserver.id" -Database "admindb" -Query "PRINT 'this is printed'" -SqlCredential $creds;

		EXPLICIT PRINT: 
			TODO ... implement this. 
			AND call out how it has a much more 'complex' set of outputs. 
				Probably, also, need to create a method or whatever on .Messages to 
				Get summary or whatever. 


	EXCEPTION Example: 
		Import-Module -Name "D:\Dropbox\Repositories\psi" -Force;
#$global:VerbosePreference = "Continue";
		$creds = New-Object PSCredential("sa", (ConvertTo-SecureString "Pass@word1" -AsPlainText -Force));
		Invoke-PsiCommand -SqlInstance "dev.sqlserver.id" -Database "admindb" -Query "RAISERROR(N'oink', 16, 1); " -SqlCredential $creds;


	ROWCOUNT Example: 
		Import-Module -Name "D:\Dropbox\Repositories\psi" -Force;
#$global:VerbosePreference = "Continue";
		$creds = New-Object PSCredential("sa", (ConvertTo-SecureString "Pass@word1" -AsPlainText -Force));
		Invoke-PsiCommand -SqlInstance "dev.sqlserver.id" -Database "admindb" -Query "DECLARE @x table (r int); INSERT INTO @x (r) VALUES (1), (2), (3);" -SqlCredential $creds;

	BIT Sproc (input and OUTPUT) Example: 
		Import-Module -Name "D:\Dropbox\Repositories\psi" -Force;
		$creds = New-Object PSCredential("sa", (ConvertTo-SecureString "Pass@word1" -AsPlainText -Force));
		$parameters = New-PsiParameterSet;
		Add-PsiParameter -Name "@TrueOrFalse" -Type "bit" -Value $true;
		Add-PsiParameter -Name "@OutValue" -Type "bit" -Direction Output;
		$results = Invoke-PsiCommand -SqlInstance dev.sqlserver.id -Database meddling -Sproc "BitTesting" -Parameters $parameters -SqlCredential $creds -AsObject;
		write-host "@OutValue = $($results[0].OutputParameters[0].Value)";

	Slightly more Complicated OUTPUT PARAMETERs Example: 
	NOTE: -AsNonQuery returns the OUTPUT parameters - whereas -AsObject returns an entire $results object... 
		Import-Module -Name "D:\Dropbox\Repositories\psi" -Force;
		$creds = New-Object PSCredential("sa", (ConvertTo-SecureString "Pass@word1" -AsPlainText -Force));
		$parameters = New-PsiParameterSet;
		Add-PsiParameter -Name "@InputValue" -Type "Sysname" -Value "SAMPLE_INPUT";
		Add-PsiParameter -Name "@OutputA" -Type "Sysname" -Direction "Output";
		Add-PsiParameter -Name "@OutputB" -Type "int" -Direction Output;
		$results = Invoke-PsiCommand -SqlInstance "dev.sqlserver.id" -Database "meddling" -Sproc "TestProc" -Parameters $parameters -SqlCredential $creds -AsObject;
		write-host "@OutputA = [$($results[0].OutputParameters[0].Value)]; @OutputB = [$($results[0].OutputParameters[1].Value)]";

	SPROC WITH MULTIPLE PARAMS, no projections, and MULTIPLE text outputs:

		Import-Module -Name "D:\Dropbox\Repositories\psi" -Force;
		$creds = New-Object PSCredential("sa", (ConvertTo-SecureString "Pass@word1" -AsPlainText -Force));

		$parameters = New-PsiParameterSet;
		Add-PsiParameter -Name "@BackupType" -Type sysname -Value "FULL";
		Add-PsiParameter -Name "@DatabasesToBackup" -Type Nvarchar -Size 1000 -Value "{SYSTEM}";
		Add-PsiParameter -Name "@BackupRetention" -Type Nvarchar -Size 10 -Value "120 hours";
		
		Invoke-PsiCommand -SqlInstance "sql-160-04.sqlserver.id" -SqlCredential $creds -Database admindb -Sproc 'dbo.backup_databases' -Parameters $parameters;

	NATIVE FOR XML as the OUTPUT: 
		Import-Module -Name "D:\Dropbox\Repositories\psi" -Force;
		$creds = New-Object PSCredential("sa", (ConvertTo-SecureString "Pass@word1" -AsPlainText -Force));		
		$parameters = New-PsiParameterSet;
		Add-PsiParameter -Name "@ProjectNumber" -Type "nvarchar" -Size 12 -Value "PV24.2682";
		Add-PsiParameter -Name "@Errors" -Type "xml" -Direction "Output";
		$results = Invoke-PsiCommand -SqlInstance "dev.sqlserver.id" -Database "lifingdb" -Sproc "[dbo].[validate_staged_equipment]" -Parameters $parameters -SqlCredential $creds -AsObject;
		$xmlData = $results[0].OutputParameters[0].Value;
		if("" -eq $xmlData){
			Write-Host "No Problems";
		}
		else {
			$xmlData | ConvertTo-Xml;
		}


	ERRORing Example: 
		Import-Module -Name "D:\Dropbox\Repositories\psi" -Force;
#$global:VerbosePreference = "Continue";
		$creds = New-Object PSCredential("sa", (ConvertTo-SecureString "Pass@word1" -AsPlainText -Force));
		Invoke-PsiCommand -SqlInstance "dev.sqlserver.id" -Database "meddling" -Query "PRINT 'NICE';`r`nSELECT * FROM dbo.does_not_exist" -SqlCredential $creds;


	PIPELINE/MULTI-PLEXED Example: 
		Import-Module -Name "D:\Dropbox\Repositories\psi" -Force;
		$creds = New-Object PSCredential("sa", (ConvertTo-SecureString "Pass@word1" -AsPlainText -Force));
		Invoke-PsiCommand -SqlInstance "dev.sqlserver.id", "sql-150-02.sqlserver.id" -Database "master", "admindb" -Query $query, "SELECT TOP (10) Tables ORDER BY Size DESC;" -SqlCredential $creds;
	

	PIPELINE / FILES Example: 
		Import-Module -Name "D:\Dropbox\Repositories\psi" -Force;
		$creds = New-Object PSCredential("sa", (ConvertTo-SecureString "Pass@word1" -AsPlainText -Force));
		$files = Get-ChildItem -Path "D:\Dropbox\Repositories\dda\tests\capture" -Filter "*.sql";
		Invoke-PsiCommand -SqlInstance "dev.sqlserver.id" -Database "dda_test" -File $files -SqlCredential $creds -MessagesOnly;





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



Import-Module -Name "D:\Dropbox\Repositories\psi" -Force;
[PSCredential]$creds;

Invoke-PsiCommand -SqlInstance "dev.sqlserver.id" -Database "master" -Query "SELECT @@SERVERNAME [server_name];" -SqlCredential $creds;






#>

function Get-PsiConnectionString {
	# for more 'advanced' options - i.e., pass in a bunch of arguments and such to this func... 
	# and it'll spit back a connection-string that can then be used to connect to servers 
	# with 'more advanced' options like: 
	# 		port #
	# 		things like ANSI_NULLS, ARITHABORT, and the likes. 
	
}

# Aliases (ideas/options): Invoke-PsiCmd, Invoke-Sql, Invoke-PsiSql... (i quite like Invoke-PsiCmd )

function Invoke-PsiCommand {
	[CmdletBinding()]
	param (
		[Alias("ServerInstance", "ServerName", "Instance")]
		[string[]]$SqlInstance,
		[string[]]$ConnectionString,
		[Alias("Credential", "Credentials")]
		[PSCredential[]]$SqlCredential,
		[string[]]$SetOptions = $null,
		[string[]]$Database = "master",
		[Alias("Command", "CommandText")]
		[string[]]$Query = $null,
		[Alias("InputFile", "Script", "SQLFile", "SQLScript")]
		[string[]]$File = $null, 
		[Alias("Sproc", "ProcedureName", "Procedure")]
		[string[]]$SprocName = $null,
		[PSI.Models.ParameterSet[]]$Parameters = $null,
		# TODO: can I create a DIFFERENT (PowerShell) ParameterSET that allows -Parameters to be a [String[]] instead of a Psi.Models.ParamSet[]?
		# 		if so, that'd be much easier than remembering that there's a DIFF between parameters/paremeterString
		[string[]]$ParameterString = $null,
		[int]$ConnectionTimeout = -1,
		[int]$CommandTimeout = -1,
		[int]$QueryTimeout = -1,
		[Alias("AppName")]
		[string]$ApplicationName = "PSI.Command",		# TODO: possibly use "reflection" to get module version and shove it in to app name? e.g., "PSI.Command (1.2)"
#		[ValidateSet("AUTO", "System", "Microsoft")]
#		[Alias("Driver", "Provider")]
#		[string]$Framework = "AUTO",
		[switch]$ReadOnly = $false,
		[switch]$Encrypt = $true,
		[switch]$TrustServerCert = $true,
		# MAYBE: [switch]$MultiSubnetFailover = $false,
		[switch]$AsObject = $false,  # i.e., as a BatchResult (full/robust details and output)
		[switch]$MessagesOnly = $false,  # i.e., just "messages" tab types of output... 
		[switch]$AsDataSet = $false,
		[switch]$AsDataTable = $false,
		[switch]$AsDataRow = $false,
		[switch]$AsScalar = $false,
		[switch]$AsNonQuery = $false,  # see notes on (roughly) line #483 - about combining -AsObject and -AsNonQuery into 'same thing'
		[switch]$AsJson = $false,
		[switch]$AsXml = $false
	);
	
	begin {
		[bool]$xVerbose = ("Continue" -eq $global:VerbosePreference) -or ($PSBoundParameters["Verbose"] -eq $true);
		[bool]$xDebug = ("Continue" -eq $global:DebugPreference) -or ($PSBoundParameters["Debug"] -eq $true);
		
		$outputOptions = @{
			"PsiObject" 	= $AsObject
			"MessagesOnly" 	= $MessagesOnly
			"NonQuery"  	= $AsNonQuery
			"Scalar"    	= $AsScalar
			"Json"	  		= $AsJson
			"Xml"	    	= $AsXml
			"DataRow"   	= $AsDataRow
			"DataTable" 	= $AsDataTable
			"DataSet"   	= $AsDataSet
		}
		
		if(($outputOptions.GetEnumerator() | Where-Object { $true -eq $_.Value; } | Measure-Object).Count -gt 1) {
			throw "Invalid Parameter Usage for Invoke-PsiCommand. Only 1x -AsXXX switch can be set at a time.";
		}
		
		$outputType = ($outputOptions).GetEnumerator() | Where-Object { $true -eq $_.Value;	} | Select-Object -Property Name;
		$resultType = "PsiObject";
		if ($null -ne $outputType) {
			$resultType = $outputType.Name;
		}
		
		#if ($Framework -eq "AUTO") {
			$Framework = Get-FrameworkProvider;
		#}
		
		[PSI.Models.BatchResult[]]$results = @();
	}
	
	process {
		$connections = @();
		$commands = @();
		$setsOfSetOptions = @();
		$parameterSets = @();
		$credentialSets = @();
			
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
			$parameterSets += [Psi.Models.ParameterSet]::EmptyParameterSet();
		}
		
		# ====================================================================================================
		# Credentials:
		# ====================================================================================================			
		foreach ($credSet in $SqlCredential) {
			$credentialSets += $credSet
		}
		# IF NO Creds supplied, we'll assume Native/Windows Auth - i.e., current user. BUT, still need a 'creds'
		# 	place-holder object to iterate through/over in the nested loops part of assembling batches/commands: 
		if (-not (Array-IsPopulated $SqlCredential)) {
			# REFACTOR: have the following, bogus, cred created by a FACTORY (static .ctor) method... (and move the "notes" above into said method...)
			$credentialSets += [PSCredential]::new("Psi_Bogus_C9F014B5-9C08-4C9D-B205-E3A7DFAB3C18", ("_PLACEHOLDER_" | ConvertTo-SecureString -AsPlainText -Force ));
		}
		
		# ====================================================================================================
		# Combine Options:
		# ====================================================================================================	
		[int]$batchNumber = 1;
		foreach ($connection in $connections) {
			foreach ($optionsSet in $setsOfSetOptions) {
				foreach ($credential in $credentialSets) {
					foreach ($db in $Database) {
						foreach ($command in $commands) {
							foreach ($paramSet in $parameterSets) {
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
		
		<# TODO: 
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
		#>
		
		# Processing of outputs is a BIT complex. But the best way to tackle that is to:
		#  -2. If -AsObject... we're done
		#  -1. If $results.Count -gt 1 ... return $results (i.e., same as -AsObject) UNLESS there's some sort of directive. 
		# 	0. Check for any ERROR conditions or issues that would PREVENT normal, projected, output from being returned. 
		# 	0.01 ... see IF there's even a DataTable ... (very similar to the above - but a number of legit operations WON'T have any kind of projection)
		# 			at which point, look for (x) row(s) affected or ... errors, or return params or .. whatever? 
		# 	1. Check for any EXPLICIT -AsXXX output types first (going 'up' from smallest/least output type to largest output type)
		# 	2. Once those EXPLICIT options are handled, try going 'down' from largest to smallest to return whatever makes the most SENSE. 		
		
		if ($AsObject) {
			return $results;
		}
		
		if ($MessagesOnly) {
			$messages = @();
			foreach ($r in $results) {
				$messages += $r.Messages;
			}
			
			return $messages;
		}
		
		if ($results.Count -gt 1) {
			Write-Verbose "More than 1x Result was Returned.";
			# TODO: need a FUNC for each -AsXXXX so that, if/when there are > 1 result and -AsXXXX is set, 
			# 		I can return an ARRAY of XXXX 
			
			# If NOT -AsXXXX then... 
			return $results; 
		}
		
		$emptyProjection = $false;
		if ($results.Count -eq 1) {
			if ($null -eq $results[0].DataSet) {
				$emptyProjection = $true;
			}
			else {
				if ($results[0].DataSet.Tables.Count -eq 0) {
					$emptyProjection = $true;
				}
			}
		}
		
		if ($emptyProjection) {
			$firstResult = $results[0];
			Write-Debug "Single Result - No PROJECTION.";
			
			if ($firstResult.HasErrors) {
				Write-Debug "	Single Result - ERRORs.";
 				return $firstResult.Errors;
			}
			
			if ($firstResult.OutputParameters.Count -gt 0) {
				return $firstResult.OutputParameters;
			}
			
			if ($firstResult.RowCounts.Count -gt 0) {
				$rowCounts = @();
				foreach ($count in $firstResult.RowCounts) {
					$rowCounts += $count.Item1;
				}
				return $rowCounts;
			}
		}
		
		# ====================================================================================================
		# OLD / PREVIOUS (v0.2) Logic:
		# ====================================================================================================		
# TODO: I should probably evaluate making -AsQuery an ALIAS for -AsObject ... 
#   because... the current implementation of -AsQuery ... returns an object that does NOT have a .HasErrors property or ... anything else 'needed';
# 		arguably, someone could always 'get at' those values via Get-PsiHistory (or whatever it ends up being called), but ... hmmm.
		if ($AsNonQuery) {
			# IF someone executed (a single) -AsNonQuery with OUTPUT params, return THOSE. Otherwise, return ... nothing.
			if (($results.Count -eq 1) -and ($results[0].OutputParameters.Count -gt 0)) {
				return $results[0].OutputParameters;
			}
			
			# TODO: MIGHT make sense to also look for 1x result and ... row-counts, or printed output, or ... errrors? 
			
			return;
		}
		
		if ($AsObject) {
			return $results;
		}
		
		# from here on out, need the DataSet...
		$dataSet = $results[0].DataSet;
		
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
		
		if ($dataSet.Tables.Count -gt 0) {
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
			if ($table.Columns.Count -gt 1) {
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
		else {
			# If there were no PROJECTIONS, attempt to return JUST messages. 
			# 	however, unlike EXPLICIT messages, just want to return STRINGS only... 
			foreach ($r in $results) {
				$messages = @();
				foreach ($r in $results) {
					$messages += $r.Messages;
				}
				
				if ($null -ne $messages) {
					$strings = @();
					foreach ($m in $messages) {
						foreach ($s in $m.Split([Environment]::NewLine)) {
							if ($s -like 'Msg 0*' -or $s -like '*Level 0*' -or $s -like '*Level 1*') {
								continue;
							}
							$strings += $s;
						}
					}
					
					return $strings;
				}
			}
		}
	}
}