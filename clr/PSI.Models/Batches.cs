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