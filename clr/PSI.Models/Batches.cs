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
    // NOTE: The projection (3rd "P") - if there is one - is dynamically 'bolted on to' the BatchResult from within PowerShell. 

    public List<Parameter> OutputParameters
    {
        get
        {
            var outputable = ParameterDirection.Output | ParameterDirection.InputOutput | ParameterDirection.Return;
            return this.Parameters.Where(p => outputable.HasFlag(p.Direction)).ToList();
        }
    }

    /*
    
         TODO: other objects like: 
           .Parameters - i.e., inputs. 
           . Connection info? i.e., might as well BIND that to this object (i.e., the 'batch') as it'll be part of the output, right?
               specifically, i want server and ... username (windows or sql).
           .Return Params
           .Projection / Output
           .Printed Text or whatever...
           .Full-on errors. 
           .start/end .ExecutionTime
           .etc. 
           .TargetDatabases - which'll be ... lazy-loaded via a func against the original batch thingy? (if so, then I have to pass that in).
                     so, yeah, maybe just have the .TargetDatabases (List<string>) prop... be implemented here (lazy-loaded) and ... NOT in the 'parser'.

    FROM POWERSHELL (i.e., other crap I had down as potential ideas of .properties to 'shove' in here:
		# NOTE ... $batchResult is where I'm going to bind things like the connection-details
       # 			such as ... 
       #					.server, .user, etc.   (conn Properties)
       # 				.parameters (including outputs) (parameters)
       # 				. SetOptions ... 
       # 				.dataset 
       # 				.printed (collection of strings/printed outputs... )
       # 				.result-type
       
       
       # OTHER THINGS to bundle (i.e.., early/previous notes):
       # 	new CommandThingy - with following Props: 
       # 		.ConnectionString 
       # 		. 	Database (or is that part of the above - think it's both ... i.e., want to know which DB we connected against for history - but conn-string needs to be done/complete)
       # 		. 	Server (yeah, same as above)
       # 		. 	Framework (ditto - needs to be part of connstring - but also want to track it)
       # 		. 	AppName (ditto)
       # 		. 	Command - but this'll be per each GO-d block... 
       # 		. 	Command-type 
       # 		. 	Encrypt/Read-Only (AG)/TrustServer - i.e., these are all details. 
       # 		. 	SET options and other conn-string details. (like arithabort, ansi_nulls, etc)
       # 	so... use a .Connection object - with all of the props above - and ... .GetConnectionString() as a serialization func (that can't be leaked/output)
       # 		.ResultType (as x, y, or z - but only 1 option)
       # 		.Timeouts
       # 		. 	Connection (this'll have to be copied to .Connection object)
       # 		. 	Command  which is either a sproc name or a Batch/ParsedBatch... 
       # 		.  


     
     */

    public bool HasErrors
    {
        get
        {
            return this.PrintedOutputs.Any(x => x.IsError);
        }
    }

    public string BatchText { get; private set; }

    public ParsedBatch ParsedBatch { get; private set; }

    protected BatchResult(Batch batch, ParameterSet parameters)
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
    }

    public static BatchResult FromBatch(Batch batch, ParameterSet parameters)
    {
        return new BatchResult(batch, parameters);
    }

    public void AddPrintedOutput(PrintedOutput printedOutput)
    {
        this.PrintedOutputs.Add(printedOutput);
    }

    public void EnableRowCounts()
    {
        this.AllowRowCounts = true;
    }

    public void AddRowCount(string modified, DateTime timestamp)
    {
        if (this.AllowRowCounts)
            this.RowCounts.Add(new Tuple<string, DateTime>(modified, timestamp));
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
}
