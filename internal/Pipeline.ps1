Set-StrictMode -Version 3.0;

<#
	
	Import-Module -Name "D:\Dropbox\Repositories\psi" -Force;

#>


function Invoke-DatabaseCommand {
	[CmdletBinding()]
	param (
		[string]$Command = $null,
		[string]$SprocName = $null,  # one or the other - i.e., either a command or ... a sproc-name.
		[string]$CommandType,			# same-ish as the above - i.e., dictates what we're using and ... should match
		[PSI.Models.ParameterSet]$Parameters = $null,
		[string]$ConnectionString,
		[int]$ConnectionTimeout = -1,
		[int]$CommandTimeout = -1,
		[int]$QueryTimeout = -1,
		[string]$ApplicationName,
		[string]$Framework,
		
		# not sure how to handle these... 
		[switch]$ReadOnly = $false,
		[switch]$Encrypt = $true,
		[switch]$TrustServerCert = $true
#		[switch]$AsDataSet = $false,
#		[switch]$AsDataTable = $false,
#		[switch]$AsDataRow = $false,
#		[switch]$AsScalar = $false,
#		[switch]$AsNonQuery = $false,
#		[switch]$AsJson = $false,
#		[switch]$AsXml = $false
	);
	
	begin {
		# validations / etc. 
	}
	
	process {
		try {
			$conn = Get-ConnectionObject -Framework $provider;
			# TODO: https://overachieverllc.atlassian.net/browse/PSI-23 
			$conn.ConnectionString = Get-ConnectionString -Framework $provider -Server $SqlInstance -Database $Database -SqlCredential $SqlCredential -ConnectionString $ConnectionString;
			
			if ($ConnectionTimeout -gt 0) {
				$conn.ConnectionTimeout = $ConnectionTimeout;
			}
			
			$cmd = Get-CommandObject -Framework $provider;
			$cmd.Connection = $conn;
			$cmd.CommandText = $Query;
			$cmd.CommandType = $CommandType;
			
			if ($CommandTimeout -gt 0) {
				$cmd.CommandTimeout = $CommandTimeout;
			}
			
			if (-not ([string]::IsNullOrEmpty($ParameterString))) {
				if ($Parameters) {
					throw "Invalid Arguments. Only -Parameters OR -ParameterString can be used - not BOTH.";
				}
				
				$Parameters = Expand-SerializedParameters -Parameters $ParameterString;
			}
			
			if ($Parameters) {
				Bind-Parameters -Framework $provider -Command $cmd -Parameters $Parameters;
			}
			
			# MKC: Hmm. What IF I created a PsiDataSet - which 'derived from' System.Data.DataSet and which had a few extra 'goodies' or details
			# 		such as: .SourceCommand, .ServerName(beingExecutedAgainst), .PrintedOutput, .ParameterOutputs ... 
			# 			at that point, I'd then have ... everything I need for a given 'result'/operation against the server
			# 				and would JUST need to figure out a way of 'chunking' the $Query being passed in (i.e., split against GO (#) ... and then
			# 				wire up some sort of collection/container of these objects? )
			$dataSet = New-Object System.Data.DataSet;
			$adapter = Get-DataAdapter $provider;
			
			$adapter.SelectCommand = $cmd;
		}
		catch {
			# TODO: https://overachieverllc.atlassian.net/browse/PSI-15
			throw "SETUP ERROR: $_ => $($_.Exception.StackTrace)";
			
			# TODO: ... there's no 'finally' here that cleans up objects ... 
		}
		
		try {
			$conn.Open();
			# TODO: https://overachieverllc.atlassian.net/browse/PSI-20 
			$adapter.Fill($dataSet) | Out-Null;
			$conn.Close();
		}
		catch {
			# TODO: https://overachieverllc.atlassian.net/browse/PSI-15
			throw "EXECUTION ERROR: $_ ";
		}
		finally {
			$conn.Close();
		}
		
		# Processing of outputs is a BIT complex. But the best way to tackle that is to:
		# 	1. Check for any EXPLICIT -AsXXX output types first (going 'up' from smallest/least output type to largest output type)
		# 	2. Once those EXPLICIT options are handled, try going 'down' from largest to smallest to return whatever makes the most SENSE. 
		if ($AsNonQuery) {
			return;
		}
		
		if ($AsScalar -or $AsJson -or $AsXml) {
			# convert if/as needed... otherwise ... output.
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
		
		$row = $table.Rows[0];
		if ($row.Columns.Count -gt 1) {
			return $row; # multiple columns - return the entire row.
		}
		
		# There are 3x options for returning scalar values:
		# 		a. Return the WHOLE ROW (even if it's just a single column-wide). This is what Invoke-SqlCmd does. 
		# 		b. Create a custom PSObject with column-name and value results. CAN'T see ANY benefit to this over a data-row.
		# 		c. No context info - just the scalar result itself (i.e., not the column-name - just the 'scalar value itself - fully isolated')/
		# For now, Invoke-PsiCommand will leverage option A. 
		return $row; # option C would be $row[0].	
		
		
	}
	
	end {
		
	}
}