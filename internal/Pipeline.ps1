Set-StrictMode -Version 3.0;

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
		$currentUserName = $env:USERNAME;
		if ((Get-CimInstance Win32_ComputerSystem).Domain -ne "WORKGROUP") {
				$currentUserName = "$($env:USERDOMAIN )\$($currentUserName)";
		}
		
		$batchResult = [PSI.Models.BatchResult]::FromBatch($Batch, $Connection, $Parameters, $SetOptions, $BatchNumber, $currentUserName);
	}
	
	process {
		try {
			$conn = Get-ConnectionObject -Framework $Framework -Connection $Connection -BatchResult $batchResult;
			
			$cmd = Get-CommandObject -Framework $Framework -BatchResult $batchResult;
			$cmd.Connection = $conn;
			$cmd.CommandText = $Batch.BatchText;
			$cmd.CommandType = ("Text" -eq $Batch.CommandType) ? $Batch.CommandType : ("StoredProcedure");
			
			if ($Parameters) {
				Bind-Parameters -Framework $Framework -Command $cmd -Parameters $Parameters;
			}
			
			$dataSet = New-Object System.Data.DataSet;
			Add-Member -InputObject $batchResult -MemberType NoteProperty -Name DataSet -Value $dataSet -Force;  # this is ... kind of nuts. 
			
			$adapter = Get-DataAdapter $Framework -Command $cmd;
		}
		catch {
			throw "CONNECTION ERROR: $_ `r`n`t=> $($_.Exception.StackTrace)"; # TODO: https://overachieverllc.atlassian.net/browse/PSI-15
		}
		# TODO: ... there's no 'finally' here that cleans up objects ... i.e., in case of ERRORs. 
		
		try {
			$batchResult.SetBatchExecutionStart();
			$conn.Open();
			
			# TODO: If -AsNonQuery ... then DON'T wire up an adapter ... and just run as $cmd.ExecuteNonQuery();
			# 			not a HUGE priority - cuz, I'm CAPTURING/HANDLING this down in the results processing 'section' by simply NOT 
			# 			doing anything with the DATATABLE ... (i.e., discarding it).
			
			# DOH: right after the connection OPENS is a great time to execute SET options... BUT, that's too late in the pipeline... 
			# 		i.e., previous to this - in the pi
			# TODO: now that the connection is open (i.e., RIGHT after it opens) - fire off any $SetOptions that need 
			# 		to be executed - as name-value pairs (e.g., "ANSI_NULLS OFF, QUOTED_IDENTS ON, etc.") (and while the sample syntax
			# 			i just threw out is bogus, there are easy ways to combine set options... something that the dotNet OptionSet thingy
			#				can/will handle. )
			
			$batchResult.EnableRowCounts();
			$adapter.Fill($dataSet) | Out-Null;
			
			if ($batchResult.OutputParameters.Count -gt 0) {
				Bind-OutputParameterValues -BatchResult $batchResult -Command $cmd;
			}
			
			$conn.Close();
			
		}
		catch {
			throw "EXECUTION ERROR: $_ `r`n`t=> $($_.Exception.StackTrace)"; # TODO: https://overachieverllc.atlassian.net/browse/PSI-15
		}
		finally {
			$conn.Close();
			$batchResult.SetBatchExecutionEnd();
			# and... I should be doing .Dispose here too, right - on $conn, $cmd, and ... $adapter - i.e., check to see if ALL of them are present, open, etc. and ... do the WHOLE 9 yards in terms of cleanup. 
		}
	}
	
	end {
		return $batchResult;
	}
}