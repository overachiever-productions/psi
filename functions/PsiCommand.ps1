Set-StrictMode -Version 1.0;

# REFACTOR:
# 		I'll probably end up using 'Invoke-Xyz????' as my primary syntax - i.e., Invoke as the Verb. 
# 			BUT... I COULD also either a) use Invoke AND the following or ... b) just the following:
# 		Get/Set.
# 			Get-XzyResult, Get-XyzResultAsXml, Get-XyzScalarResult... or Get-XyzResultAsScalar... etc 
# 			Set-Xyz<NOUN> ??? as the only 'flavor'/version/implementation of a .NonQuery().
# 					(maybe the <NOUN> is Sql(something?))
# 				a bit different (and then some) from all OTHER Invoke-SQLcmd implementations - but a lot clearer and ... not TERRIBLE.
# 			Along the lines of the above, Remove and Select are also core/approved verbs.
# 				I think that Select would be ... terrible... but maybe NOT. 
# 					and remove ... could be used identically to Set - ... just with the idea that end-users might want to use it for DELETEs and such.
# 						but I would NOT make any distinction between it and Set (i.e., it'd be an alias at BEST)
# 	


<#
	
	Import-Module -Name "D:\Dropbox\Repositories\psi" -Force;
	
# MVP tests: 

	# assessment tests: 
	$result = Invoke-PsiCommand -Query "SELECT 
	servicename, 
	startup_type_desc, 
	status_desc, 
	service_account, 
	is_clustered, 
	cluster_nodename
FROM 
	sys.dm_server_services WITH (NOLOCK) OPTION (RECOMPILE)
	FOR JSON AUTO;";

	# odd... this is _ALWAYS_ going to be JSON_F52E2B61-18A1-11d1-B105-00805F49916B ... and it's hard-coded... can't remove it. 
	#		note who provided this reply: https://social.msdn.microsoft.com/Forums/sqlserver/en-US/0902b532-2e0e-41fc-a027-7beac3fafbfe/for-json-column-jsonf52e2b6118a111d1b10500805f49916b?forum=sqldatabaseengine 			
	# 	that said... you can always put the query in a CTE and get just the primary/scalar result. 
	# 			I've done that... and, need to account for it with -AsJson
	# 			ditto on -AsXml... 
	$result.'JSON_F52E2B61-18A1-11d1-B105-00805F49916B';



	# plan-extraction example... MEGA bare-bones (i.e., needs a LOT of work to the actual query... but... if this works... damn): 
	# success!!!!
$query = "SELECT 
	x.id,
	eqp.query_plan
FROM 
	(SELECT id, plan_handle FROM (VALUES 
		(1,   0x05001A008B2C9E2E509FAB19CF01000001000000000000000000000000000000000000000000000000000000), 
		(2,   0x0500FF7F1CD8C8D500303129CF01000001000000000000000000000000000000000000000000000000000000), 
		(3,   0x05001A00CE0C670540F4A329CF01000001000000000000000000000000000000000000000000000000000000), 
		(4,   0x06001A00661F522D903C41DDCD01000001000000000000000000000000000000000000000000000000000000), 
		(6,   0x06001A002675BD1AD09EB2C1CD01000001000000000000000000000000000000000000000000000000000000), 
		(5,   0x06001A00261A7A2D609FB2C1CD01000001000000000000000000000000000000000000000000000000000000), 
		(7,   0x05001A00A8E16233002F860CCF01000001000000000000000000000000000000000000000000000000000000), 
		(8,   0x06001A00BD183006203D21C1CD01000001000000000000000000000000000000000000000000000000000000)
	)
		x(id, plan_handle)
	) x
	CROSS APPLY sys.dm_exec_query_plan(x.plan_handle) AS eqp
ORDER BY 
	x.id; "

	$plans = Invoke-PsiCommand -Query $query;
	foreach($row in $plans) {
		$i = $row[0];
		$plan = $row[1];
		
		Write-Host "Plan [$i]: $plan ";

	}

	#Premise Method (ish): (success!!!!!)
	$scheduleCount = (Invoke-PsiCommand -Query "SELECT 
			ISNULL(COUNT(*), 0) [count]
		FROM 
			msdb.dbo.sysjobs j 
			INNER JOIN msdb.dbo.[sysjobschedules] js ON [j].[job_id] = [js].[job_id]
			INNER JOIN msdb.dbo.[sysschedules] s ON [js].[schedule_id] = [s].[schedule_id]
		WHERE 
			j.[name] = N'Regular Restore Tests'; ").count;
	
		$scheduleCount;

	




# Basic Testing/Validation of CORE functionality... 
	Invoke-PsiCommand -Query "DROP TABLE IF EXISTS yak_test; CREATE TABLE yak_test (id int);";
	Invoke-PsiCommand -Query "SELECT [client_interface_name] FROM sys.dm_exec_sessions WHERE session_id = @@SPID; SELECT TOP 20 * FROM sys.databases;";
	Invoke-PsiCommand -Framework "SQLClient" -Query "SELECT [client_interface_name] FROM sys.dm_exec_sessions WHERE session_id = @@SPID;";
	Invoke-PsiCommand -Framework "OLEDB" -Query "SELECT [client_interface_name] FROM sys.dm_exec_sessions WHERE session_id = @@SPID;";


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

# REFACTOR: might want to make this Invoke-XxxOperation instead of command?
function Invoke-PsiCommand {
	param (
		[string]$SqlInstance = ".",
		[string]$Database = "master",
		[string]$Query,
		[string]$SprocName,
		# either $SprocName or $Query is populated - not BOTH. And ... obviously, if $SprocName then... $cmd.CommandType = ... sproc.
		[PSCredential]$Credentials,
		[string]$ConnectionString,
		# optional... overwrites other stuff..
		[int]$ConnectionTimeout = -1,
		[int]$QueryTimeout = -1,
		[ValidateSet("AUTO", "ODBC", "OLEDB", "SQLClient")]
		[string]$Framework = "AUTO",
		[switch]$AsScalar = $false,
		[switch]$AsNonQuery = $false,
		[switch]$AsDataSet = $false,
		[switch]$AsJson = $false,
		[switch]$AsXml = $false
	);
	
	# Parameter Validation: 
	# Only 1x of AsXyz can be true at a time. So put them in an array and count # of them that are true... if it's > 1... throw... 
	
	
	#MVP Hack: 
	if ("." -eq $SqlInstance) {
		$SqlInstance = "dev.sqlserver.id";
	}
	#MVP Hack: 
	if ($null -eq $Credentials) {
		$password = ConvertTo-SecureString 'Pass@word1' -AsPlainText -Force
		$Credentials = New-Object System.Management.Automation.PSCredential('sa', $password);
	}
	
	$provider = $Framework;
	if ($provider -eq "AUTO") {
		$provider = Get-FrameworkProvider;
	}
	
	try {
		$conn = Get-ConnectionObject -Framework $provider;
		$conn.ConnectionString = Get-ConnectionString -Framework $provider -Server $SqlInstance -Database $Database -Credentials $Credentials -ConnectionString $ConnectionString;
		
		if ($ConnectionTimeout -gt 0) {
			$conn.ConnectionTimeout = $ConnectionTimeout;
		}
		
		$cmd = Get-CommandObject -Framework $provider;
		$cmd.Connection = $conn;
		$cmd.CommandText = $Query;
		
		if ($ConnectionTimeout -gt 0) {
			$cmd.CommandTimeout = $ConnectionTimeout;
		}
		
		$dataSet = New-Object System.Data.DataSet;
		$adapter = Get-DataAdapter $provider;
		
		$adapter.SelectCommand = $cmd;
	}
	catch {
		throw "CONFIG error: $_ "; #TODO: embellis this MVP implementation ... i.e., this error handling sucks... 
	}
	
	try {
		$conn.Open();
		$adapter.Fill($dataSet) | Out-Null; # TODO: I'm doing Out-Null to capture 'nocount off' (rowcount) kind of stuff. what about printed outputs? can i capture those? SHOULD I capture those? And, if I do... how do I return them to the user? 
		$conn.Close();
	}
	catch {
		# TODO: look at options for handling SQL errors ... i.e., silentlycontinue? output? or stop/throw?
		throw "OPERATION error: $_ "; #TODO: embellis this MVP implementation ... i.e., this error handling sucks... 
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