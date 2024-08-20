namespace PSI.Models;

public enum CommandType
{
    Command, 
    Text
}

public enum FrameworkType
{
    NotSet,
    SqlClient,
    OleDb,
    Odbc
}

public enum ResultType
{
    NotSet, 
    PsiObject, 
    Xml, 
    Json, 
    DataSet, 
    DataTable, 
    DataRow,
    Scalar
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

public enum ParameterDirection
{
    NotSet, 
    Input,
    InputOutput,
    Output,
    Return
}