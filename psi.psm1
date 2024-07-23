Set-StrictMode -Version 3.0;

# 1. Import CLR Types: 
[string]$ScriptRoot = $PSScriptRoot;
	
$classFiles = @(
	"$ScriptRoot\clr\PSI.Models\Usings.cs"
	"$ScriptRoot\clr\PSI.Models\Extensions.cs"
	"$ScriptRoot\clr\PSI.Models\Global.cs"
	"$ScriptRoot\clr\PSI.Models\Enums.cs"
	"$ScriptRoot\clr\PSI.Models\Connection.cs"
	"$ScriptRoot\clr\PSI.Models\Command.cs"
	"$ScriptRoot\clr\PSI.Models\Parameter.cs"
	"$ScriptRoot\clr\PSI.Models\ParameterSet.cs"
	"$ScriptRoot\clr\PSI.Models\ParameterSetManager.cs"
	"$ScriptRoot\clr\PSI.Models\PsiMapper.cs"
);
	
Add-Type -Path $classFiles;

# 2. Internal Funcs:
foreach ($file in (@(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'internal/*.ps1') -Recurse -ErrorAction Stop))) {
	try {
		. $file.FullName;
	}
	catch {
		throw "Unable to dot source INTERNAL PSI file: [$($file.FullName)]`rEXCEPTION: $_  `r$($_.ScriptStackTrace) ";
	}
}

# 3. Public Funcs: 
foreach ($file in (@(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'public/*.ps1') -Recurse -ErrorAction Stop))) {
	try {
		. $file.FullName;
	}
	catch {
		throw "Unable to dot source PUBLIC PSI file: [$($file.FullName)]`rEXCEPTION: $_  `r$($_.ScriptStackTrace) ";
	}
}

# 4. Export Public Funcs and Aliases: 
Export-ModuleMember -Function *-Psi*;