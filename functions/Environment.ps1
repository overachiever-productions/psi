Set-StrictMode -Version 1.0;

function Get-FrameworkProvider {
	# TODO: Implement this. Right now it's a bare-bones implementation... 
	# 		as in, it doesn't account for Posh < 5.0... 
	
	$poshVersion = $PSVersionTable.PSVersion;
	if ($poshVersion.Major -ge 5) {
		return "ODBC";
	}
	
	# otherwise... MAYBE? pay attention to what OS we're talking about and spit out SQLClient as the default? 
	# 		though, honestly? Sqlclient is damned near the ONLY thing that'll work... 
	# 		so I probably don't need to load OS info at all, right? 
	
	throw "Not Implemented - but probably 'SQLClient'... ";
	
}