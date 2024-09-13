Set-StrictMode -Version 3.0;

<#
	
	Import-Module -Name "D:\Dropbox\Repositories\psi" -Force;


# $results += Execute-Batch -Framework $Framework -Batch $batch -Connection $batchConnection -Parameters $paramSet;

#>

function Execute-Batch {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[string]$Framework,
		[Parameter(Mandatory)]
		[PSI.Models.Connection]$Connection,
		[Parameter(Mandatory)]
		[PSI.Models.Batch]$Batch,
		[PSI.Models.OptionSet]$SetOptions = $null,
		[PSI.Models.ParameterSet]$Parameters = $null,
		[int]$BatchNumber
	);
	
	begin {
		$batchResult = [PSI.Models.BatchResult]::FromBatch($Batch);
		# TODO: bind other 'outputs' to  $batchResult (i.e., expand comments and handle this 'stuff')
	}
	
	process {
		try {
			$conn = Get-ConnectionObject -Framework $Framework -Connection $Connection -BatchResult $batchResult;
			
			$cmd = Get-CommandObject -Framework $Framework;
			$cmd.Connection = $conn;
			$cmd.CommandText = $Batch.BatchText;
			$cmd.CommandType = $Batch.CommandType;
			
			if ($Parameters) {
				Bind-Parameters -Framework $Framework -Command $cmd -Parameters $Parameters;
			}
			
			$dataSet = New-Object System.Data.DataSet;
			Add-Member -InputObject $batchResult -MemberType NoteProperty -Name DataSet -Value $dataSet -Force;  # this is ... kind of nuts. 
			
			$adapter = Get-DataAdapter $Framework -Command $cmd;
		}
		catch {
			#throw "SETUP ERROR: $_ => $($_.Exception.StackTrace)"; # TODO: https://overachieverllc.atlassian.net/browse/PSI-15
			throw $_;
		}
		
		# TODO: ... there's no 'finally' here that cleans up objects ... 
		
		try {
			$conn.Open();
			
			# DOH: right after the connection OPENS is a great time to execute SET options... BUT, that's too late in the pipeline... 
			# 		i.e., previous to this - in the pi
			# TODO: now that the connection is open (i.e., RIGHT after it opens) - fire off any $SetOptions that need 
			# 		to be executed - as name-value pairs (e.g., "ANSI_NULLS OFF, QUOTED_IDENTS ON, etc.") (and while the sample syntax
			# 			i just threw out is bogus, there are easy ways to combine set options... something that the dotNet OptionSet thingy
			#				can/will handle. )
			
			$adapter.Fill($dataSet) | Out-Null;
			
			$conn.Close();
		}
		catch {
			throw "EXECUTION ERROR: $_ "; # TODO: https://overachieverllc.atlassian.net/browse/PSI-15
		}
		finally {
			$conn.Close();
		}
	}
	
	end {
		return $batchResult;
	}
}