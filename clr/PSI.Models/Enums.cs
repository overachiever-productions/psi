namespace PSI.Models;

public enum CommandType
{
    Command, 
    Text
}

public enum FrameworkType
{
    NotSet,
    System,
    Microsoft
}

public enum ResultType
{
    NotSet, 
    PsiObject, 
    MessagesOnly,
    Xml, 
    Json, 
    DataSet, 
    DataTable, 
    DataRow,
    Scalar, 
    NonQuery
}

// Fodder: https://learn.microsoft.com/en-us/dotnet/api/system.data.sqldbtype?view=net-8.0
public enum DataType
{
    NotSet, 
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

[Flags]
public enum ParameterDirection
{
    NotSet = 0, 
    Input = 1,
    Output = 2,
    InputOutput = 4,
    Return = 8
}