# psi - PowerShell Sql Interface

## Tentative Roadmap
- 0.1 - Initial Release - Proof of Concept (with some hard-coded functionality in play).
- 0.2 - Introduction of Sprocs - specifically: parameters. 
- 0.3 - ConnectionString Builders + Error Handling Complete.
- 0.4 - MVP Complete. 
- 0.5 - T-SQL Template Support/Functionality + JSON/XML Support Finalized. 
- 0.6 - Perf-Tuning and API Fixes/Tuning (Refactoring).
- 0.8 - Documentation
- 0.9 - ? 
- 1.0 - Initial Release. 

It's still very EARLY in dev cycle for PSI ... so the above may change. 

## Why YET ANOTHER Invoke-SqlCmd replacement/implementation?
3 Main Reasons: 
- `Invoke-SqlCmd` is great. But it also ships in a module/package that weighs in at over 23MB. You might not want all of those dependencies, attack-vectors, and 'bloat' to MERELY 'command-line' your way through operations with SQL Server. 
- `Invoke-SqlCmd` PRETENDS to implement parameters. As in, the way it tackles parameterization is both odd (conceptually) and 100% prone to SQL Injection. 
- `Invoke-SqlCmd` and most of the other replacements out there use SqlClient libraries/providers to access SQL Server. SqlClient has been deprecated for eons now. psi provides support for SqlClient, ODBC (drivers), and OLEDB (provider) - and defaults to ODBC (making it more cross-platform friendly).