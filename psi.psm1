Set-StrictMode -Version 3.0;

# 1. Import CLR Objects:
. "$PSScriptRoot\psi.meta.ps1"
Import-PsiTypes;

# Import Funcs/etc. 
foreach ($file in (@(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'functions/*.ps1') -Recurse -ErrorAction Stop))) {
	try {
		. $file.FullName;
	}
	catch {
		throw "Unable to dot source PSI file: [$($file.FullName)]`rEXCEPTION: $_  `r$($_.ScriptStackTrace) ";
	}
}

# Export Psi Funcs:
Export-ModuleMember -Function *-Psi*;