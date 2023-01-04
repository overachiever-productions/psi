#  CHANGE LOG

## [0.1.x] - 2022-12-22 - Initial Checkin
Proof of Concept. No Release. 

## [0.2.0] - 2023-01-04

### Known Issues
- This is still in an incredibly early ALPHA state. 
- Core functionality works ... to some degree. 
- OLEDB probably doesn't work with Parameters. 
- And Parameter mapping/data-types (via explicit vs inline params) are going to be hit or miss. 

### Added
- Full-Fledged Parameters Functionality (i.e., strongly-typed (abstracted) parameters/parameter-sets).
- Inline Parameters (similar to how `sp_executesql` allows for parameter declarations) - via `-ParameterString` argument. 
- Changelog added to project. 