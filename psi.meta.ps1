Set-StrictMode -Version 1.0;

function Import-PsiTypes {
	param (
		[string]$ScriptRoot = $PSScriptRoot
	);
	
	$classFiles = @(
		"$ScriptRoot\clr\PSI.Models\Enums\PDirection.cs"
		"$ScriptRoot\clr\PSI.Models\Enums\PsiType.cs"
		"$ScriptRoot\clr\PSI.Models\Parameter.cs"
		"$ScriptRoot\clr\PSI.Models\ParameterSet.cs"
		"$ScriptRoot\clr\PSI.Models\ParameterSetManager.cs"
		"$ScriptRoot\clr\PSI.Models\Mapper.cs"
	);
	
	Add-Type -Path $classFiles;
}