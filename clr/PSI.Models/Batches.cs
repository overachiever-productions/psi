using System.Runtime.CompilerServices;

namespace PSI.Models;

public class Batch
{
    public CommandType CommandType { get; private set; }
    public ResultType ResultType { get; private set; }

    public string BatchText { get; private set; }

    public ParsedBatch ParsedBatch { get; private set; }

    public Batch(CommandType commandType, ResultType resultType, string batchText) : this(commandType, resultType, batchText, null) { }

    public Batch(CommandType commandType, ResultType resultType, string batchText, ParsedBatch parsedBatch)
    {
        this.CommandType = commandType;
        this.ResultType = resultType;
        this.BatchText = batchText;

        this.ParsedBatch = parsedBatch;
    }
}

public class BatchResult
{
    public CommandType CommandType { get; private set; }
    public ResultType ResultType { get; private set; }
    public bool AllowRowCounts { get; private set; } = false;

    // Results:
    public List<Tuple<string, DateTime>> RowCounts { get; private set; } = new List<Tuple<string, DateTime>>();
    public List<PrintedOutput> PrintedOutputs { get; private set; } = new List<PrintedOutput>();
    public List<Parameter> Parameters { get; private set; }
    public List<string> Messages { get; private set; } = new List<string>();
    // NOTE: The projection (3rd "P") - if there is one - is dynamically 'bolted on to' the BatchResult from within PowerShell. 

    public List<Parameter> OutputParameters
    {
        get
        {
            var outputable = ParameterDirection.Output | ParameterDirection.InputOutput | ParameterDirection.Return;
            return this.Parameters.Where(p => outputable.HasFlag(p.Direction)).ToList();
        }
    }

    public string TargetServer { get; private set; }
    public string TargetDatabase { get; private set; } 

    // TODO: Pull these from ... ParsedBatch.
    //public List<String> UsedDatabases { get; private set; } // fulfills the above
    public string Login { get; private set; }
    public string ApplicationName { get; private set; }

    public OptionSet Options { get; private set; }

    public int ConnectionTimeout { get; private set; }
    public int CommandTimeout { get; private set; }
    public int QueryTimeout { get; private set; }

    // TODO: 
    // Connection OPTIONS: MultiSubnet, Encrypt, TrustServerCert, AppIntent (readonly), etc... 

    public int BatchNumber { get; private set; }
    public DateTime? ExecutionStart { get; private set; }
    public DateTime? ExecutionEnd { get; private set; }

    public bool HasErrors
    {
        get
        {
            return this.PrintedOutputs.Any(x => x.IsError);
        }
    }

    public List<Error> Errors
    {
        get
        {
            List<Error> output = new List<Error>();

            if (this.HasErrors)
            {
                foreach (var printedOutput in this.PrintedOutputs.Where(x => x.IsError))
                    output.Add(printedOutput.ToError());
            }

            return output;
        }
    }

    public string BatchText { get; private set; }

    public ParsedBatch ParsedBatch { get; private set; }

    protected BatchResult(Batch batch, Connection connection, ParameterSet parameters, OptionSet options, int batchNumber, string userName)
    {
        this.CommandType = batch.CommandType;
        this.ResultType = batch.ResultType;

        if (batch.CommandType == CommandType.Text)
        {
            this.ParsedBatch = batch.ParsedBatch;
            this.BatchText = batch.ParsedBatch.BatchText;
        }
        else
            this.BatchText = batch.BatchText;

        this.Parameters = parameters.Parameters;

        this.TargetServer = connection.Server;
        this.TargetDatabase = connection.Database;

        if (connection.Credential == null)
            this.Login = userName;
        else 
            this.Login = connection.Credential.UserName;
        this.ApplicationName = connection.ApplicationName;
        this.BatchNumber = batchNumber;

        this.ConnectionTimeout = connection.ConnectionTimeout;
        this.CommandTimeout = connection.CommandTimeout;
        this.QueryTimeout = connection.QueryTimeout;

        this.Options = options;
    }

    public static BatchResult FromBatch(Batch batch, Connection connection, ParameterSet parameters, OptionSet options, int batchNumber, string userName)
    {
        return new BatchResult(batch, connection, parameters, options, batchNumber, userName);
    }

    public void AddPrintedOutput(PrintedOutput printedOutput)
    {
        this.PrintedOutputs.Add(printedOutput);
        this.Messages.Add($"Msg {printedOutput.ErrorNumber}, Level {printedOutput.Severity}, State {printedOutput.State}, Line {printedOutput.LineNumber}\r\n{printedOutput.Message}");
    }

    public void EnableRowCounts()
    {
        this.AllowRowCounts = true;
    }

    public void AddRowCount(string modified, DateTime timestamp)
    {
        if (this.AllowRowCounts)
        {
            this.RowCounts.Add(new Tuple<string, DateTime>(modified, timestamp));

            this.Messages.Add(modified);
        }
    }

    public void SetBatchExecutionStart()
    {
        this.ExecutionStart = DateTime.Now;
    }

    public void SetBatchExecutionEnd()
    {
        this.ExecutionEnd = DateTime.Now;

        if (this.Messages.Count == 0)
            // this mimics behavior of SSMS - which throws this text out IF there were no row-updates and no errors:
            this.Messages.Add("Commands completed successfully.");

    }
}

public class PrintedOutput(string message, int severity, int state, int errorNumber, int lineNumber)
{
    public string Message { get; private set; } = message;
    public int Severity { get; private set; } = severity;
    public int  State { get; private set; } = state;
    public int ErrorNumber { get; private set; } = errorNumber;
    public int LineNumber { get; private set; } = lineNumber;

    public bool IsError
    {
        get
        {
            return Severity > 11;
        }
    }

    public Error ToError()
    {
        return new Error(this.Message, this.Severity, this.State, this.ErrorNumber, this.LineNumber);
    }
}

// TODO: should probably shove this into its own .cs file... 
public class Error(string message, int severity, int state, int errorNumber, int lineNumber)
{
    public string Message { get; private set; } = message;
    public int Severity { get; private set; } = severity;
    public int State { get; private set; } = state;
    public int ErrorNumber { get; private set; } = errorNumber;
    public int LineNumber { get; private set; } = lineNumber;

    public string Summarize()
    {
        return $"Msg {this.ErrorNumber}, Level {this.Severity}, State {this.State}, Line {this.LineNumber}\r\n{this.Message}";
    }
}
