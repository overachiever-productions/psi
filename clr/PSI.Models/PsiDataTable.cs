using System.Data;

namespace PSI.Models
{
    // NOTE: this was me playing around with the IDEA Of potentially 'deriving from System.Data.DataTable' to 
    //  'decorate' it with a few additiona fields/props - so that I could have properties like
    //          .ExecutedAgainst(ServerName)
    //          .(Return)Parameters
    //          .Printed(output)
    //          .OriginalStatement (the statement run against the DB, etc.)
    // BUT:
    //  the system.Data.DataTable object is effing ginormous:
    //          https://learn.microsoft.com/en-us/dotnet/api/system.data.datatable?view=net-8.0

    // So, I think I want an extension method of System.Data.DataTable
    //          .ToPsiDataTable(this system.data.datatable input)
    //          that spits out 
    //          a. any fields/details I need from System.Data.DataTable
    //          b. any of these 'extra' fields I want. 
    //      i.e., I don't want/need the 'bloat/complexity' of EVERYTHING that's in a data-table. 
    //      i just want a) a multi-dimensional 'array' of data that I can To-JSON or to-XML or output, etc. 
    //          and b) printed messages and so on.

    // Otherwise, 
    //  it looks like I can get 'printed' results BACK from my SQL connection via the Connection.InfoMessage event
    //              https://learn.microsoft.com/en-us/dotnet/api/system.data.sqlclient.sqlconnection.infomessage?view=netframework-4.8.1
    //   there's a decent-ish amount of fodder on this: 
    //              https://stackoverflow.com/questions/28537767/capture-sql-print-output-in-net-while-the-sql-is-running
    //              https://stackoverflow.com/questions/5749826/need-to-get-the-sql-server-print-value-in-c-sharp
    //              https://stackoverflow.com/questions/1880471/capture-stored-procedure-print-output-in-net

    // There's ALSO this post, which covers how to - apparently - pull 'row count' info from the COMMAND object itself:
    //      https://stackoverflow.com/questions/27993049/retrieve-record-counts-from-multiple-statements 
    //          NOTE: there are a number of notes in the ANSWER for this one - looks like this stuff is a BIT complicated... 

    // ONLY
    //          all of those are for the SqlConnection object. 
    //          I need these for ... different/newer/updated drivers - ODBC and OLEDB. 
    //              
    //      ah. good. Here's the ODBCConnection Object (doc) - and it HAS a the .InfoMessage event:
    //          https://learn.microsoft.com/en-us/dotnet/api/system.data.odbc.odbcconnection?view=net-8.0   
    //      ditto for the OLEDBConnection object: 
    //          https://learn.microsoft.com/en-us/dotnet/api/system.data.oledb.oledbconnection?view=net-8.0
    //      AND YEAH:
    //          SQLConnection supports it - but only on .NET 4.8.x 
    //              at least according to the docs: 
    //              https://learn.microsoft.com/en-us/dotnet/api/system.data.sqlclient.sqlconnection?view=netframework-4.8.1
    //          actually, I guess (duh) that 4.8.x is the latest version of 'old' .NET FRAMEWORK, whereas 8.x is the newest version of .NET
    //          so, I guess that both of those are ... viable. 
    //      which means that one of the things I need to try/check
    //          is to see if .NET 8 is on-box and/or if .NET Framework 4.8.x is on-box 
    //              which'll determine which drivers/'platform' can be used. 
    //          shouldn't be hard. 
    //          

    // ALSO, importantly, here's a bunch of interesting documentation for ADO.NET - which appears to cover .NET Framework 4.8.x and .NET 8.x
    //          https://learn.microsoft.com/en-us/dotnet/framework/data/adonet/ 




    public class PsiDataTable : DataTable
    {
        public List<string> PrintResults { get; }

        public PsiDataTable()
        {
            this.PrintResults = new List<string>();
        }

        public void AddPrintResult(string printResult)
        {
            this.PrintResults.Add(printResult);
        }
    }
}

