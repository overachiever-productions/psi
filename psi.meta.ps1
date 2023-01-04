Set-StrictMode -Version 1.0;

# WARN: don't call this Import-PsiTypes (which'd make sense) ... cuz... that'll EXPORT the method.
function Import-Types {
	param (
		[string]$ScriptRoot = $PSScriptRoot
	);
	
	$classFiles = @(
		"$ScriptRoot\clr\PSI.Models\Enums\PDirection.cs"
		"$ScriptRoot\clr\PSI.Models\Enums\PsiType.cs"
		"$ScriptRoot\clr\PSI.Models\Parameter.cs"
		"$ScriptRoot\clr\PSI.Models\ParameterSet.cs"
		"$ScriptRoot\clr\PSI.Models\ParameterSetManager.cs"
		"$ScriptRoot\clr\PSI.Models\PsiMapper.cs"
	);
	
	Add-Type -Path $classFiles;
}