Set-StrictMode -Version 3.0;

<#

	Import-Module -Name "D:\Dropbox\Repositories\psi" -Force;
	
	$parameters = New-PsiParameterSet;  # REFACTOR: $parameters = New-Parameters or New-PsiParameters ... 
#	#Add-PsiParameter -Direction Return;   # REFACTOR: Add-Parameter or Add-PsiParameter
#	#Add-PsiParameter -Name "@JobName" -Type "Sysname" -Value "Fake Job";
#
#	$query = "SELECT 
#			ISNULL(MAX(s.[enabled]), 0) [enabled]
#		FROM 
#			msdb.dbo.sysjobs j 
#			INNER JOIN msdb.dbo.[sysjobschedules] js ON [j].[job_id] = [js].[job_id]
#			INNER JOIN msdb.dbo.[sysschedules] s ON [js].[schedule_id] = [s].[schedule_id]
#		WHERE 
#			j.[name] = @JobName; ";

	$query = "SELECT [name] FROM sys.databases WHERE [database_id] = @id";
	#Add-PsiParameter -Direction Return;
	Add-PsiParameter -Name "id" -Type "Int" -Value 11;

#$parameters;

	Invoke-PsiCommand -SqlInstance dev.sqlserver.id -Database msdb -SqlCredential (Get-Credential sa) -Query $query -Parameters $parameters;
	

#>

$global:PsiDefaultParameterSetName = "_DEFAULT";
$global:PsiParameterManager = [PSI.Models.ParameterSetManager]::Instance;
$global:PsiSizeableParameterTypes = @("char", "varchar", "Nchar", "Nvarchar", "binary", "varbinary", "datetime2");

filter New-PsiParameterSet {
	param (
		[string]$Name = $global:PsiDefaultParameterSetName,
		[switch]$OverwriteExisting = $true
	);
	
	if ($OverwriteExisting) {
		$global:PsiParameterManager.RemoveParameterSet($Name);
	}
	
	if ($global:PsiParameterManager.ParameterSets.ContainsKey($Name)) {
		if ($global:PsiDefaultParameterSetName -eq $Name) {
			throw "A DEFAULT PsiParameterSet already exists. To create an additional ParameterSet, specify a name via the -Name parameter.";
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
					 "bit", "tinyint", "smallint", "int", "bigint", "decimal", "numeric", "smallmoney", "money", "float", "real", "date", "time",
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
	
	$pDirection = [PSI.Models.ParameterDirection]::NotSet;
	if (-not ([string]::IsNullOrEmpty($Direction))) {
		try {
			$pDirection = [PSI.Models.PsiMapper]::GetPDirection($Direction);
		}
		catch {
			throw "Invalid Direction [$Direction]. Error: $_ ";
		}
	}
	
	$pType = [PSI.Models.DataType]::NotSet;
	if (-not ([string]::IsNullOrEmpty($Type))) {
		try {
			$pType = [PSI.Models.PsiMapper]::GetPsiType($Type);
		}
		catch {
			throw "Exception Parsing Enum value of [$Type] to PsiEnum of PsiType: $_ ";
		}
	}
	
	if ($Direction) {
		if ($pDirection -eq [PSI.Models.ParameterDirection]::Return) {
			if ([string]::IsNullOrEmpty($Name)) {
				# By CONVENTION, @ReturnValue is the $Name most commonly used by ADO.NET and so on - so, default to conventions if no explicit values.
				$Name = "@ReturnValue";
			}
			
			if ([PSI.Models.DataType]::NotSet -eq $pType) {
				$pType = [PSI.Models.DataType]::Int;
			}
		}
	}
	
	if ($Precision -or $Scale) {
		if ($Type -notin @("decimal", "numeric")) {
			throw "-Precision and -Scale may ONLY be set for decimal and numeric types.";
		}
		
		if (-not ($Precision -and $Scale)) {
			throw "Both -Precision and -Scale are required for decimal and numeric types.";
		}
	}
	
	if ($Size) {
		# Syntactic-Sugar: Folks with .NET background might $Size -1 to achieve MAX versions. That's fine (not ideal, but fine). Just re-map for them. 
		if ((-1 -eq $Size) -and ($Type -in @("char", "varchar", "nchar", "nvarchar", "binary", "varbinary"))) {
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
		# actually, think i'll just force RETURN params to have @ReturnValue as the name, right?
		if ($pDirection -ne [PSI.Models.ParameterDirection]::Return) {
			throw "only return params can NOT have a name...";
		}
	}
	
	# NOTE: Do NOT check for ($null -eq $Value). Params CAN be NULL.
	
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

filter Expand-SerializedParameters {
	param (
		[Parameter(Mandatory)]
		[string]$Parameters,
		[string]$Name = $global:PsiDefaultParameterSetName
	);
	
	return [Psi.Models.ParameterSet]::ParameterSetFromSerializedInput($Parameters, $Name);
}

filter Bind-Parameters {
	param (
		[ValidateSet("System", "Microsoft")]
		[Parameter(Mandatory)]
		[string]$Framework,
		[Parameter(Mandatory)]
		[object]$Command,
		[Parameter(Mandatory)]
		[PSI.Models.ParameterSet]$Parameters
	);
	
	switch ($Framework) {
		"System" {
			foreach ($parameter in $Parameters.Parameters) {
				Bind-SqlClientParameter -Command $Command -Parameter $parameter;
			}
		}
		default {
			throw "System.Data.SqlClient is currently the ONLY supported -Provider.";
		}
	}
}

filter Bind-OutputParameterValues {
	param (
		[PSI.Models.BatchResult]$BatchResult,
		$Command
	);
	
	foreach ($outputParam in $BatchResult.OutputParameters) {
		
		$cmdParameter = $Command.Parameters | Where-Object { $_.ParameterName -eq $outputParam.Name };
		
		if ($cmdParameter) {
			$outputParam.BindOutputParameter($cmdParameter.Value);
		}
	}
}

filter Bind-SqlClientParameter {
	param (
		[Parameter(Mandatory)]
		[System.Data.SqlClient.SqlCommand]$Command,
		[Parameter(Mandatory)]
		[PSI.Models.Parameter]$Parameter
	);
	
	if ("Return" -eq $Parameter.Direction) {
		# see https://overachieverllc.atlassian.net/browse/PSI-5 
		if ("Text" -eq $Command.CommandType) {
			throw "RETURN Parameter Types are NOT supported for Text operations.";
		}
	}
	
	if ($Parameter.Direction -notin @("Input", "InputOutput", "Output", "Return")) {
		throw "Psi Framwork Error. Invalid PsiParameter Direction Specified.";
	}
	
	$direction = ConvertTo-SystemParameterDirection -Direction $Parameter.Direction;
	[int]$size = $null;
	[int]$precision = $null;
	[int]$scale = $null;
	
	# https://learn.microsoft.com/en-us/dotnet/framework/data/adonet/configuring-parameters-and-parameter-data-types 
	switch ($Parameter.DataType) {
		{ $_ -in @("Bit", "TinyInt", "SmallInt", "Int", "BigInt", "SmallMoney", "Money", "Float", "Real", "Date", "Time", "SmallDateTime", "DateTime", "DateTimeOffset", "UniqueIdentifier") } {
			$type = [System.Data.SqlDbType]([Enum]::Parse([System.Data.SqlDbType], $Parameter.DataType, $true));
		}
		{ $_ -in @("Char", "Varchar", "NChar", "NVarchar", "Binary", "Varbinary", "DateTime2") } {
			$type = [System.Data.SqlDbType]([Enum]::Parse([System.Data.SqlDbType], $Parameter.DataType, $true));
			$size = $Parameter.Size;
		}
		{ $_ -in @("VarcharMax", "NVarcharMax", "VarbinaryMax")	} {
			$type = [System.Data.SqlDbType]([Enum]::Parse([System.Data.SqlDbType], $Parameter.DataType, $true));
			$size = -1;
		}
		{ $_ -in @("Decimal", "Numeric") } {
			$type = [System.Data.SqlDbType]::Decimal;
			$precision = $Parameter.Precision;
			$scale = $Parameter.Scale;
		}
		"Sysname" {
			$type = [System.Data.SqlDbType]::NVarChar;
			$size = 256;
		}
		{ $_ -in @("Image", "Text", "NText", "SqlVariant", "Geometry", "Geography", "TimeStamp", "Xml") } {
			$type = [System.Data.SqlDbType]([Enum]::Parse([System.Data.SqlDbType], $Parameter.DataType, $true));
		}
		"NotSet" {
			throw "Psi Framwork Error.";
		}
		default {
			throw "not valid PsiType... no mapping could be made.";
		}
	}
	
	$added = New-Object System.Data.SqlClient.SqlParameter($Parameter.Name, $type);
	$added.Direction = $direction;
	
	
	# WARNING: NEED to check data-type for BITs here - otherwise if($Parameter.Value) can equate to if($false) (when Bit value = $false)
	if (("Bit" -eq $Parameter.DataType) -or ($Parameter.Value)) {
		$added.Value = $Parameter.Value;
	}
	else {
		if ($direction -notin @("Output", "Return")) {
			$added.Value = [System.DBNull];
		}
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
		[PSI.Models.ParameterDirection]$Direction
	);
	
	# TODO: this is a LOT of code to allow for "Return" vs "ReturnValue" (i.e., that's the ONLY diff after removing OLEDB/ODBC)
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