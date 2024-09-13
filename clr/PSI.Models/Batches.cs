namespace PSI.Models;

public class Batch
{
    public CommandType CommandType { get; private set; }
    public ResultType ResultType { get; private set; }

    public string BatchText { get; private set; }

    public ParsedBatch ParsedBatch { get; private set; }


    // TODO: other objects like: 
    //  .Parameters - i.e., inputs. 
    //  . Connection info? i.e., might as well BIND that to this object (i.e., the 'batch') as it'll be part of the output, right?
    //      specifically, i want server and ... username (windows or sql).
    //  .Return Params
    //  .Projection / Output
    //  .Printed Text or whatever...
    //  .Full-on errors. 
    //  .start/end .ExecutionTime
    //  .etc. 
    //  .TargetDatabases - which'll be ... lazy-loaded via a func against the original batch thingy? (if so, then I have to pass that in).
    //              so, yeah, maybe just have the .TargetDatabases (List<string>) prop... be implemented here (lazy-loaded) and ... NOT in the 'parser'.


    /*
    
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

    // Results:
    public List<string> PrintedOutputs { get; private set; } = new List<string>();
    // Parameters (Outputs)
    // Projection (DataSet)


    public string BatchText { get; private set; }

    public ParsedBatch ParsedBatch { get; private set; }

    protected BatchResult(Batch batch)
    {
        this.CommandType = batch.CommandType;
        this.ResultType = batch.ResultType;
        this.ParsedBatch = batch.ParsedBatch;

        this.BatchText = batch.ParsedBatch.BatchText;
    }

    public static BatchResult FromBatch(Batch batch)
    {
        return new BatchResult(batch);
    }

    public void AddResultText(string text)
    {
        this.PrintedOutputs.Add(text);
    }
}