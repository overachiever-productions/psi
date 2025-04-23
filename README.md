# psi - PowerShell Sql Interface

## Tentative Roadmap
- 0.1 - Initial Release - Proof of Concept (with some hard-coded functionality in play).
- 0.2 - Introduction of Sprocs - specifically: parameters. 
- 0.3 - Error Handling + Connectivity Functionality.
- 0.4 - Custom Output Formatting (errors, printed outputs, parameters, row-counts, etc)
- 0.5 - JSON/XML + Auto-Output & CommandResults-Functionality Optimized.
- 0.6 - Unit and Integration Tests
- 0.7 - Documentation.
- 0.8 - Build Framework.
- 0.9 - MVP Complete.
- 1.0 - Initial Release. 

It's still very EARLY in dev cycle for PSI ... so the above may change. 

## Known Issues
Psi is VERY much a beta - and super rough around the edges. It works (I'm integrating it into some production-level projects to help keep 'shaping' the APIs and interactions against real-world projects), but don't expect the 'rough edges' to be smoothed out until around v0.7 or so. 

## Why YET ANOTHER Invoke-SqlCmd replacement/implementation?
3 Main Reasons: 
- `Invoke-SqlCmd` is great. But it also ships in a module/package that weighs in at over 23MB. You might not want all of those dependencies, attack-vectors, and 'bloat' to MERELY 'command-line' your way through operations with SQL Server. 
- `Invoke-SqlCmd` PRETENDS to implement parameters. As in, the way it tackles parameterization is both odd (conceptually) and 100% prone to SQL Injection. 
- Intelligent batch splitting. Psi's batch splitting is more robust than a mere split on "GO" - meaning that it can/will ignore `GO` statements that appear within `/* comments */` or even within `'ticks'` (though, any dynamic T-SQL with `GO` in it will automatically, obviously, fail as `GO` is a batch-terminator and not, technically, part of the T-SQL language specification.)