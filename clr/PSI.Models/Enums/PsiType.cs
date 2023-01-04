namespace PSI.Models
{
    // Fodder: https://learn.microsoft.com/en-us/dotnet/api/system.data.sqldbtype?view=net-7.0
    public enum PsiType
    {
        NotSet, // NOTE: This option is exposed to PowerShell (it's not in the ValidateSet(list)).
        Char,
        Varchar,
        VarcharMax,
        NChar,
        NVarchar,
        NVarcharMax,
        Binary,
        Varbinary,
        VarbinaryMax,
        TinyInt,
        SmallInt,
        Bit,
        Int,
        BigInt,
        Decimal,
        Numeric, // same as decimal 
        SmallMoney,
        Money,
        Float,
        Real,  
        Date,
        Time,
        SmallDateTime,
        DateTime,
        DateTime2,
        DateTimeOffset,
        UniqueIdentifier,
        Image,
        Text,
        NText,
        SqlVariant,
        Geometry,
        Geography,
        TimeStamp, // probably not? but ... meh. maybe.
        Xml,
        Sysname
    }
}
