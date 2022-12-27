Set-StrictMode -Version 1.0;

<#

	Import-Module -Name "D:\Dropbox\Repositories\psi" -Force;
	
	$parameters = New-PsiParameterSet;
	#Add-PsiParameter -Direction Return;
	#Add-PsiParameter -Name "@JobName" -Type "Sysname" -Value "Fake Job";

	$query = "SELECT 
			ISNULL(MAX(s.[enabled]), 0) [enabled]
		FROM 
			msdb.dbo.sysjobs j 
			INNER JOIN msdb.dbo.[sysjobschedules] js ON [j].[job_id] = [js].[job_id]
			INNER JOIN msdb.dbo.[sysschedules] s ON [js].[schedule_id] = [s].[schedule_id]
		WHERE 
			j.[name] = @JobName; ";

	$query = "SELECT [name] FROM sys.databases WHERE [database_id] = @id";
	Add-PsiParameter -Direction Return;
	Add-PsiParameter -Name "id" -Type "Int" -Value 11;

$parameters;


	Invoke-PsiCommand -SqlInstance dev.sqlserver.id -Database msdb -Credentials (Get-Credential sa) -Query $query -Parameters $parameters -Provider SQLClient;
	

#>

$global:PsiParameterManager = [PSI.Models.ParameterSetManager]::Instance;
$global:PsiDefaultParameterSetName = "{DEFAULT}";
$global:PsiSizeableParameterTypes = @("char", "varchar", "Nchar", "Nvarchar", "binary", "varbinary", "datetime2");

filter New-PsiParameterSet {
	param (
		[string]$Name = $global:PsiDefaultParameterSetName
	);
	
	if ($global:PsiParameterManager.ParameterSets.ContainsKey($Name)) {
		if ($global:PsiDefaultParameterSetName -eq $Name) {
			throw "A DEFAULT PsiParameterSet already exists. To create a New or Additional ParameterSet, specify a name via the -Name parameter.";
		}
		else {
			throw "A PsiParameterSet with the name of [$Name] alrerady exists. Please specify a distinct -Name value for each ParameterSet.";
		}		
	}
	
	$global:PsiParameterManager.AddParameterSet($Name);
	return $global:PsiParameterManager.GetParameterSetByName($Name);
}

filter Get-PsiParameterSets {
	param (
		[switch]$NamesOnly = $false
	)
	
	if ($NamesOnly) {
		# return just the names
	}
	
	# Default to "the PowerShell way (i.e., objects vs string)" as output:
	return $global:PsiParameterManager.ParameterSets;
}

function Add-PsiParameter {
	param (
		[string]$Name = $null,
		[ValidateSet("char", "varchar", "varcharMAX", "Nchar", "Nvarchar", "NvarcharMAX", "binary", "varbinary", "varbinaryMAX",
			"tinyint", "smallint", "int", "bigint", "decimal", "numeric", "smallmoney", "money", "float", "date", "time",
			"smalldatetime", "datetime", "datetime2", "datetimeoffset", "uniqueidentifier", "image", "text", "Ntext", "sqlvariant",
			"geometry", "geography", "timestamp", "xml", "sysname"
		)]
		[string]$Type = $null,		
		[object]$Value = $null,
		[int]$Size = $null,
		[ValidateSet("Input", "InputOutput", "Output", "Return")]
		[string]$Direction = $null,
		[int]$Scale = $null,
		[int]$Precision = $null,
		[string]$SetName = $global:PsiDefaultParameterSetName
	);
	
	$pDirection = [PSI.Models.PDirection]::NotSet;
	if (-not ([string]::IsNullOrEmpty($Direction))) {
		try {
			$pDirection = [PSI.Models.Mapper]::GetPDirection($Direction);
		}
		catch {
			throw "Exception Parsing Enum value of [$Direction] to PsiEnum of PDirection: $_ ";
		}
	}
	
	$pType = [PSI.Models.PsiType]::NotSet;
	if (-not ([string]::IsNullOrEmpty($Type))) {
		try {
			$pType = [PSI.Models.Mapper]::GetPsiType($Type);
		}
		catch {
			throw "Exception Parsing Enum value of [$Type] to PsiEnum of PsiType: $_ ";
		}
	}
	
	if ($Direction) {
		if ($pDirection -eq [PSI.Models.PDirection]::Return) {
			# By CONVENTION, @ReturnValue is the $Name most commonly used by ADO.NET and so on - so, default to conventions if no explicit values.
			if ([string]::IsNullOrEmpty($Name)) {
				$Name = "@ReturnValue";
			}
			
			if ([PSI.Models.PsiType]::NotSet -eq $pType) {
				$pType = [PSI.Models.PsiType]::Int;
			}
		}
	}
	
	if ($Precision -or $Scale) {
		if ($Type -notin @("decimal", "numeric")) {
			throw "-Precision and -Scale may ONLY be set for decimal and numeric types.";
		}
		
		if(-not($Precision -and $Scale)) {
			throw "Both -Precision and -Scale are required for decimal and numeric types.";
		}
	}
	
	if ($Size) {
		# Syntactic-Sugar: Folks with .NET background might $Size -1 to achieve MAX versions. That's fine (not ideal, but fine). Just re-map for them. 
		if ((-1 -eq $Size) -and ($Type -in @("char", "varchar", "Nchar", "Nvarchar", "binary", "varbinary"))) {
			$Type = $Type + "MAX";
			$Size = $null;
		}
		else {
			if ($Type -like "*MAX") {
				throw "The -Size paramter can NOT be used with the [$Type] data type. Leave -Size empty or `$null.";
			}
			
			if ($Size -lt 0) {
				throw "The -Size parameter must be > 0. Use the <dataType>MAX data-type for (MAX) variants.";
			}
			
			if ($Type -notin $global:PsiSizeableParameterTypes) {
				throw "The [$Type] can not be given a -Size parameter. Only strings (char/nchar), variable-strings (varX), binary/var-binary, and datetime2 may be sized.";
			}
		}
	}
	
	if (-not ([string]::IsNullOrEmpty($Name))) {
		if (-not ($Name.StartsWith("@"))) {
			$Name = "@" + $Name;
		}
	}
	else {
		if ($pDirection -ne [PSI.Models.PDirection]::Return) {
			throw "only return params can NOT have a name...";
		}
	}
	
	# NOTE: Do NOT check for ($null -eq $Value). Params can/might be NULL. That'll be 'sorted out' at run-time of the command itself.
	
	$parameter = New-Object PSI.Models.Parameter($Name, $pType, $pDirection, $Value, $Size, $Precision, $Scale);
	$global:PsiParameterManager.AddParameterToSet($SetName, $parameter);
}

function Add-PsiMaxUnicodeStringParamter {
	
}

# alias as ... Add-PsiStringParameter
function Add-PsiUnicodeStringParameter {
	
}

function Add-PsiSmallDateTimeParameter {
	
}

<# 
	Disclaimer about VERSIONING HELL. 
	What I WANTED to do: 
		Have 3x overloads in C# (i.e., in the Mapper.cs file) that looked like: 
			- public static void LoadParameters(SqlCommand command, ParameterSet parameters){}
			- public static void LoadParameters(OdbcCommand command, ParameterSet parameters){}
			- public static void LoadParameters(OleDbCommand command, ParameterSet parameters){}

		and then, from PsiCommand - just call: [PSI.Models.Mapper].LoadParameters($cmd, $Parameters). 
		TYPE detection would have 'routed' to the proper command and ... i'd have some wire-up operations/glue to go through
			in a fully type-safe environment... 

	What HAPPENED: 
		1. I had to add NUGET packages for System.Data.SqlClient|Odbc|OleDb to my .NET project. (no biggie)
		2. I got this bit of happiness when trying to Add-Type against my dot-included .cs files: 
				The type name 'OdbcCommand' could not be found in the namespace 'System.Data.Odbc'. 
					This type has been forwarded to assembly 'System.Data.Odbc, Version=0.0.0.0, Culture=neutral, PublicKeyToken=cc7b13ffcd2ddd51' 
					Consider adding a reference to that assembly.         

		Or, in other words, to get my 'type-routing' fun to work ...  I would have had to import THOSE specific references. 
			Which... yeah - could work. 
				BUT, then I'd be TYING this implementation to HARD-CODED versions of System.Data.xxxx functionality. 
			Which... would be DUMB cuz... I've ALREADY got access to all 3x implementations via PowerShell (i.e., whatever I'm 'sitting on' to write this code). 
				AND, those implementations 'go with' whatever PoshFramework this code is running on. 

			So, short of figuring out how to ... redirect the C# compiler part of Posh to "Hey, use the versions of SqlClient, ODBC, and OLEDB you already have loaded" ... 
				the easier option, sigh, was to do all of said mapping in .... Posh.

#>
filter Bind-Parameters {
	param (
		[ValidateSet("ODBC", "OLEDB", "SQLClient")]
		[Parameter(Mandatory)]
		[string]$Framework,
		[Parameter(Mandatory)]
		[object]$Command,
		[Parameter(Mandatory)]
		[PSI.Models.ParameterSet]$Parameters
	);
	
	# Jackpot: These are the core docs I need: https://learn.microsoft.com/en-us/dotnet/framework/data/adonet/configuring-parameters-and-parameter-data-types
	
	switch ($Framework) {
		"ODBC"	 {
			foreach ($parameter in $Parameters.Parameters) {
				Bind-OdbcParameter -Command $Command -Parameter $parameter;
				
				# ODBC doesn't allow @namedParams (in the Command itself) for TEXT operations:
				# 	fodder: 
				# 		https://stackoverflow.com/questions/1535994/asp-net-odbc-query-with-parameters
				# 		https://stackoverflow.com/questions/32196416/select-query-does-not-work-with-parameters-using-parameters-addwithvalue
				if ("Text" -eq $Command.CommandType) {
					$cmd.CommandText = $cmd.CommandText.replace($parameter.Name, '?');
				}
			}
		}
		"OLEDB" {
			foreach ($parameter in $Parameters.Parameters) {
				Bind-OleDbParameter -Command $Command -Parameter $parameter;
			}
		}
		"SQLClient" {
			foreach ($parameter in $Parameters.Parameters) {
				Bind-SqlClientParameter -Command $Command -Parameter $parameter;
			}
		}
		default {
			throw "Invalid -Framework. The Framework [$Framework] is not recognized.";
		}
	}
}

filter Bind-OdbcParameter {
	param (
		[Parameter(Mandatory)]
		[System.Data.Odbc.OdbcCommand]$Command,
		[Parameter(Mandatory)]
		[PSI.Models.Parameter]$Parameter
	);
	
#	if ("Return" -eq $Parameter.Direction) {
#		# not sure what to do here or... if this EVEN 'needs' any special handling. 
#		throw "RETURN PARAM binding not implemented yet. Not sure it even needs anything speciall... but, wahtever... "
#	}
	
	if ($Parameter.Direction -notin @("Input", "InputOutput", "Output", "Return")) {
		throw "Psi Framwork Error. Invalid PsiParameter Direction Specified.";
	}
	
	$direction = ConvertTo-SystemParameterDirection -Direction $Parameter.Direction;
	[int]$size = $null;
	[int]$precision = $null;
	[int]$scale = $null;
	
	switch ($Parameter.Type) {
		"NotSet" {
			throw "Psi Framwork Error. PsiType has not been correctly set.";
		}
		{ $_ -in @("Bit", "TinyInt", "SmallInt", "Int", "BigInt", "Date", "Time", "SmallDateTime", "DateTime", "UniqueIdentifier") } {
			# straight 'port'/crossover of type: 
			$type = [System.Data.Odbc.OdbcType]([Enum]::Parse([System.Data.Odbc.OdbcType], $Parameter.Type, $true));
		}
		{ $_ -in @("Char", "Varchar", "NChar", "NVarchar", "Binary", "Varbinary") } {
			$type = [System.Data.Odbc.OdbcType]([Enum]::Parse([System.Data.Odbc.OdbcType], $Parameter.Type, $true));
			$size = $Parameter.Size;
		}
		{ $_ -in @("VarcharMax", "NVarcharMax", "VarbinaryMax") } {
			$type = [System.Data.Odbc.OdbcType]([Enum]::Parse([System.Data.Odbc.OdbcType], $Parameter.Type, $true));
			$size = -1;
		}
		{ $_ -in @("Decimal", "Numeric") } {
			$type = [System.Data.Odbc.OdbcType]([Enum]::Parse([System.Data.Odbc.OdbcType], $Parameter.Type, $true));
			$precision = $Parameter.Precision;
			$scale = $Parameter.Scale;
		}
		{ $_ -in @("Image", "Text", "NText") } {
			# TODO: may end up wanting to emit warnings about these being deprecated within SQL Server? 
			$type = [System.Data.Odbc.OdbcType]([Enum]::Parse([System.Data.Odbc.OdbcType], $Parameter.Type, $true));
		}
		"Sysname" {
			$type = [System.Data.Odbc.OdbcType]::NVarChar;
			$size = 256;
		}
		"SmallMoney" {
			# TODO: hmmm
		}
		"Money" {
			# TODO: hmmm
		}
		"Float" {
			# TODO: verifi that this is correct:
			$type = [System.Data.Odbc.OdbcType]::Double;
		}
		"Real" {
			# TODO: group with others that make sense... 
			$type = [System.Data.Odbc.OdbcType]::Real;
		}
		
		"DateTime2" {
			# Fodder: https://learn.microsoft.com/en-us/sql/relational-databases/native-client-odbc-date-time/enhanced-date-and-time-type-behavior-with-previous-sql-server-versions-odbc?view=sql-server-ver16 
			# Fodder: https://stackoverflow.com/questions/1334143/datetime2-vs-datetime-in-sql-server 
			# TODO: need to figure out how to specify this... 
			$type = [System.Data.Odbc.OdbcType]::DateTime;
		}
		"DateTimeOffset" {
			# TODO: need to figure out how to specify this... 
		}


		"SqlVariant" {
			# TODO: figure out if I can support this or not. or ... even want to. 
		}
		"Geometry" {
			# Probably CAN'T Support. Given that MS doesn't support it ... not sure how I can get their DRIVER to support it. 
			# 	instead, think i just need to provide info about work-arounds for this.
		}
		"Geography" {
			# ditto. 
		}
		"TimeStamp" {
			# yeah... ODBC.TimeStamp = SQL_BINARY stream... don't think i want to use this.. 
			$type = [System.Data.Odbc.OdbcType]::Timestamp; 
		}
		"Xml" {
			#$p = New-OdbcParameter -Name $Parameter.Name -Type  -Direction $direction;
		}
		default {
			throw "not valid PsiType... no mapping could be made.";
		}
	}
	
	$added = New-Object System.Data.Odbc.OdbcParameter($Parameter.Name, $type);
	$added.Direction = $direction;
	
	if ($Parameter.Value) {
		$added.Value = $Parameter.Value;
	}
	
	if ($size) {
		$added.Size = $size;
	}
	
	if ($precision) {
		$added.Precision = $precision;
		$added.Scale = $scale;
	}
	
	$Command.Parameters.Add($added) | Out-Null;
}

filter Bind-OleDbParameter {
	param (
		[Parameter(Mandatory)]
		[System.Data.Oledb.OleDbCommand]$Command,
		[Parameter(Mandatory)]
		[PSI.Models.Parameter]$Parameter
	);
	
	if ("Return" -eq $Parameter.Direction) {
		# not sure what to do here or... if this EVEN 'needs' any special handling. 
		throw "RETURN PARAM binding not implemented yet. Not sure it even needs anything speciall... but, wahtever... "
	}
	
	if ($Parameter.Direction -notin @("Input", "InputOutput", "Output", "Return")) {
		throw "Psi Framwork Error. Invalid PsiParameter Direction Specified.";
	}
	
	$direction = ConvertTo-SystemParameterDirection -Direction $Parameter.Direction;
	[int]$size = $null;
	[int]$precision = $null;
	[int]$scale = $null;
	
	switch ($Parameter.Type) {
		"NotSet" {
			throw "Psi Framwork Error. PsiType has not been correctly set.";
		}
		"Char" {
			$type = [System.Data.OleDb.OleDbType]::Char;
		}
		"Varchar" {
			$type = [System.Data.OleDb.OleDbType]::VarChar;
		}
		"VarcharMax" {
			$type = [System.Data.OleDb.OleDbType]::LongVarChar;
		}
		"NChar" {
			$type = [System.Data.OleDb.OleDbType]::WChar;
		}
		"NVarchar" {
			$type = [System.Data.OleDb.OleDbType]::VarWChar;
		}
		"NVarcharMax" {
			$type = [System.Data.OleDb.OleDbType]::LongVarWChar;
		}
		"Binary" {
			$type = [System.Data.OleDb.OleDbType]::Binary;
		}
		"Varbinary" {
			$type = [System.Data.OleDb.OleDbType]::VarBinary;
		}
		"VarbinaryMax" {
			$type = [System.Data.OleDb.OleDbType]::LongVarBinary;
		}
		"Bit" {
			$type = [System.Data.OleDb.OleDbType]::Boolean;
		}
		"TinyInt" {
			$type = [System.Data.OleDb.OleDbType]::TinyInt;
		}
		"SmallInt" {
			$type = [System.Data.OleDb.OleDbType]::SmallInt;
		}
		"Int" {
			$type = [System.Data.OleDb.OleDbType]::Integer;
		}
		"BigInt" {
			$type = [System.Data.OleDb.OleDbType]::BigInt;
		}
		"Decimal" {
			$type = [System.Data.OleDb.OleDbType]::Decimal;
		}
		"Numeric" {
			$type = [System.Data.OleDb.OleDbType]::Numeric;
		}
		"SmallMoney" {
		}
		"Money" {
			$type = [System.Data.OleDb.OleDbType]::Currency;
		}
		"Float" {
		}
		"Date" {
			$type = [System.Data.OleDb.OleDbType]::DBDate;
		}
		"Time" {
			$type = [System.Data.OleDb.OleDbType]::DBTime;
		}
		"SmallDateTime" {
			# hmmm... 
			$type = [System.Data.OleDb.OleDbType]::DBTimeStamp;
		}
		"DateTime" {
			# hmmmm... 
			$type = [System.Data.OleDb.OleDbType]::DBTimeStamp;
		}
		"DateTime2" {
			# hmmm.
			$type = [System.Data.OleDb.OleDbType]::DBTimeStamp;
		}
		"DateTimeOffset" {
		}
		"UniqueIdentifier" {
			$type = [System.Data.OleDb.OleDbType]::Guid;
		}
		"Image" {
			#hmmmm.
		}
		"Text" {
			#hmmmm.
		}
		"NText" {
			#hmmmm.
		}
		"SqlVariant" {
			# TODO: test this out... 
			$type = [System.Data.OleDb.OleDbType]::Variant;
		}
		"Geometry" {
		}
		"Geography" {
		}
		"TimeStamp" {
		}
		"Xml" {
		}
		"Sysname" {
			$type = [System.Data.OleDb.OleDbType]::VarWChar;
			$size = 256;
		}
		default {
			throw "not valid PsiType... no mapping could be made.";
		}
	}
	
	$added = New-Object System.Data.OleDb.OleDbParameter($Parameter.Name, $type);
	$added.Direction = $direction;
	
	if ($Parameter.Value) {
		$added.Value = $Parameter.Value;
	}
	
	if ($size) {
		$added.Size = $size;
	}
	
	if ($precision) {
		$added.Precision = $precision;
		$added.Scale = $scale;
	}
	
	$Command.Parameters.Add($added) | Out-Null;
}

filter Bind-SqlClientParameter {
	param (
		[Parameter(Mandatory)]
		[System.Data.SqlClient.SqlCommand]$Command,
		[Parameter(Mandatory)]
		[PSI.Models.Parameter]$Parameter
	);
	
	if ("Return" -eq $Parameter.Direction) {
		# not sure what to do here or... if this EVEN 'needs' any special handling. 
		throw "RETURN PARAM binding not implemented yet. Not sure it even needs anything speciall... but, wahtever... "
	}
	
	if ($Parameter.Direction -notin @("Input", "InputOutput", "Output", "Return")) {
		throw "Psi Framwork Error. Invalid PsiParameter Direction Specified.";
	}
	
	$direction = ConvertTo-SystemParameterDirection -Direction $Parameter.Direction;
	[int]$size = $null;
	[int]$precision = $null;
	[int]$scale = $null;
	
	switch ($Parameter.Type) {
		"NotSet" {
			throw "Psi Framwork Error.";
		}
		"Char" {
			$type = [System.Data.SqlDbType]::Char;
		}
		"Varchar" {
			$type = [System.Data.SqlDbType]::VarChar;
		}
		"VarcharMax" {
			$type = [System.Data.SqlDbType]::VarChar;
			$size = -1;
		}
		"NChar" {
			$type = [System.Data.SqlDbType]::NChar;
		}
		"NVarchar" {
			$type = [System.Data.SqlDbType]::NVarChar;
		}
		"NVarcharMax" {
			$type = [System.Data.SqlDbType]::NVarChar;
			$size = -1;
		}
		"Binary" {
			$type = [System.Data.SqlDbType]::Binary;
		}
		"Varbinary" {
			$type = [System.Data.SqlDbType]::VarBinary;
		}
		"VarbinaryMax" {
			$type = [System.Data.SqlDbType]::VarBinary;
			$size = -1;
		}
		"Bit" {
			$type = [System.Data.SqlDbType]::Bit;
		}
		"TinyInt" {
			$type = [System.Data.SqlDbType]::TinyInt;
		}
		"SmallInt" {
			$type = [System.Data.SqlDbType]::SmallInt;
		}
		"Int" {
			$type = [System.Data.SqlDbType]::Int;
		}
		"BigInt" {
			$type = [System.Data.SqlDbType]::BigInt;
		}
		"Decimal" {
			$type = [System.Data.SqlDbType]::Decimal;
		}
		"Numeric" {
			# hmmm. No explicit mapping. Decimal should be JUST FINE in this SPECIFIC case. 
			$type = [System.Data.SqlDbType]::Decimal;
		}
		"SmallMoney" {
			$type = [System.Data.SqlDbType]::SmallMoney;
		}
		"Money" {
			$type = [System.Data.SqlDbType]::Money;
		}
		"Float" {
			$type = [System.Data.SqlDbType]::Float;
		}
		"Date" {
			$type = [System.Data.SqlDbType]::Date;
		}
		"Time" {
			$type = [System.Data.SqlDbType]::Time;
		}
		"SmallDateTime" {
			$type = [System.Data.SqlDbType]::SmallDateTime;
		}
		"DateTime" {
			$type = [System.Data.SqlDbType]::DateTime;
		}
		"DateTime2" {
			$type = [System.Data.SqlDbType]::DateTime2;
			$size = $Parameter.Size;
		}
		"DateTimeOffset" {
			$type = [System.Data.SqlDbType]::DateTimeOffset;
		}
		"UniqueIdentifier" {
			$type = [System.Data.SqlDbType]::UniqueIdentifier;
		}
		"Image" {
			$type = [System.Data.SqlDbType]::Image;
		}
		"Text" {
			$type = [System.Data.SqlDbType]::Text;
		}
		"NText" {
			$type = [System.Data.SqlDbType]::NText;
		}
		"SqlVariant" {
			$type = [System.Data.SqlDbType]::Variant;
		}
		"Geometry" {
			# hmmmm?
			$type = [System.Data.SqlDbType]::Structured;
		}
		"Geography" {
			# hmmmm?
			$type = [System.Data.SqlDbType]::Structured;
		}
		"TimeStamp" {
			$type = [System.Data.SqlDbType]::Timestamp;
		}
		"Xml" {
			# interesting... 
			$type = [System.Data.SqlDbType]::Xml;
		}
		"Sysname" {
			$type = [System.Data.SqlDbType]::NVarChar;
			$size = 256;
		}
		default {
			throw "not valid PsiType... no mapping could be made.";
		}
	}
	
	$added = New-Object System.Data.SqlClient.SqlParameter($Parameter.Name, $type);
	$added.Direction = $direction;
	
	if ($Parameter.Value) {
		$added.Value = $Parameter.Value;
	}
	
	if ($size) {
		$added.Size = $size;
	}
	
	if ($precision) {
		$added.Precision = $precision;
		$added.Scale = $scale;
	}
	
	$Command.Parameters.Add($added) | Out-Null;
}

filter ConvertTo-SystemParameterDirection {
	param (
		[Parameter(Mandatory)]
		[PSI.Models.PDirection]$Direction
	);
	
	switch ($Direction) {
		"NotSet" {
			throw "Psi Framework Error.";
		}
		"Input" {
			return [System.Data.ParameterDirection]::Input;
		}
		"InputOutput" {
			return [System.Data.ParameterDirection]::InputOutput;
		}
		"Output" {
			return [System.Data.ParameterDirection]::Output;
		}
		"Return" {
			return [System.Data.ParameterDirection]::ReturnValue;
		}
		default {
			throw "Invalid Parameter Direction specified.";
		}
	}
}

#filter Get-OdbcType {
#	param (
#		[PSI.Models.PsiType]$Type
#	);
#	
#	switch ($Type) {
#		"NotSet" {
#			throw "Psi Framwork Error.";
#		}
#		"Char" {
#		}
#		"Varchar" {
#		}
#		"VarcharMax" {
#		}
#		"NChar" {
#		}
#		"NVarchar" {
#		}
#		"NVarcharMax" {
#		}
#		"Binary" {
#		}
#		"Varbinary" {
#		}
#		"VarbinaryMax" {
#		}
# 		"Bit" {
#		}
#		"TinyInt" {
#		}
#		"SmallInt" {
#		}
#		"Int" {
#		}
#		"BigInt" {
#		}
#		"Decimal" {
#		}
#		"Numeric" {
#		}
#		"SmallMoney" {
#		}
#		"Money" {
#		}
#		"Float" {
#		}
#		"Date" {
#		}
#		"Time" {
#		}
#		"SmallDateTime" {
#		}
#		"DateTime" {
#		}
#		"DateTime2" {
#		}
#		"DateTimeOffset" {
#		}
#		"UniqueIdentifier" {
#		}
#		"Image" {
#		}
#		"Text" {
#		}
#		"NText" {
#		}
#		"SqlVariant" {
#		}
#		"Geometry" {
#		}
#		"Geography" {
#		}
#		"TimeStamp" {
#		}
#		"Xml" {
#		}
#		"Sysname" {
#			# hmmm... so... do i modify the .Size via this func as well? think i should... 
#			# or... I could do the $Command.Add... right friggin here... in which case... i don't need to have a separate func... i.e., roll this up into the 'caller'?
#			return [System.Data.Odbc.OdbcType]::NVarChar;
#		}
#		default {
#			throw "not valid PsiType... no mapping could be made.";
#		}
#	}
#}