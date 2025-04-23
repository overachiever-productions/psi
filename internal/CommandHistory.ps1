
function Add-ResultsToCommandHistory {
	param (
		# TODO: figure out what other kinds of signature/details I need from the invoked-command itself... 
		[PSI.Models.BatchResult[]]$Results
	);
	
	# TODO: Implement this. 
	# And... NOTE that 'history' will NOT be a mere Collection of Psi.Models.BatchResult. 
	# 	it'll be a COLLECTION of a COLLECTION of Psi.Models.BatchResult. 
	# 		or, in other words, each time Invoke-PsiCommand is invoked, I'll add a new 'entry' 
	# 		into the 'outer'/main (history) collection. Which'll, in turn, be a COLLECTION of 1 or more results 
	# 			where the results could be errors, success, multiple batches... whatever. 
}
