namespace PSI.Models
{
    public enum PDirection
    {
        NotSet, // NOTE: This option is NOT exposed to PowerShell (it's not in the ValidateSet(list)).
        Input,
        InputOutput,
        Output,
        Return
    }
}