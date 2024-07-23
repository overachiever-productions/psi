Set-StrictMode -Version 3.0;

filter Has-Value {
	param (
		[Parameter(Position = 0)]
		[string]$Value
	);
	
	return (-not ([string]::IsNullOrWhiteSpace($Value)));
}

#filter Is-Array {
#	param (
#		[object]$Value
#	);
#	
#	# sigh. this is effing useless. e.g., if(Is-Array "some string") ... yields true. cuz, "some string" is an array of strings when evaluated here. 
#	return $Value -is [array];	
#}

filter Array-IsPopulated {
	param (
		[object[]]$Value
	);
	
	try {
		return $Value.Count -ge 1;
	}
	catch {
		return $false;
	}
}

filter Is-Scalar {
	param (
		[object[]]$Value
	);
	
	if (-not (Is-Array $Value)) {
		return $true;  # arguably, if $Value isn't an array, then... it's scalar.
	}
	
	if ($Value.Count -eq 1) {
		return $true;
	}
	
	return $false;
}
