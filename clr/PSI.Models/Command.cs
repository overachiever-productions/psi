namespace PSI.Models;

public class Command
{
    public CommandType CommandType { get; private set; }
    public ResultType ResultType { get; private set; }
    public string CommandText { get; private set; }

    protected Command(CommandType commandType, string commandText, ResultType resultType)
    {
        this.CommandType = commandType;
        this.CommandText = commandText;
        this.ResultType = resultType;
    }

    public static Command ForSproc(string sprocName, ResultType resultType)
    {
        return new Command(CommandType.Command, sprocName, resultType);
    }

    public static Command FromQuery(string query, ResultType resultType)
    {
        return new Command(CommandType.Text, query, resultType);
    }

    public List<Batch> GetBatches()
    {
        if (CommandType == CommandType.Command)
            return [new Batch(this.CommandType, this.ResultType, this.CommandText)];

        var output = new List<Batch>();

        var tokenizer = new Tokenizer(this.CommandText);
        tokenizer.Initialize();
        tokenizer.Tokenize();
        foreach (var batch in tokenizer.GetParsedBatches(true))
            output.Add(new Batch(this.CommandType, this.ResultType, batch.BatchText, batch));

        return output;
    }
}

public class Batch
{
    public CommandType CommandType { get; private set; }
    public ResultType ResultType { get; private set; }

    public string BatchText { get; private set; }
    public string OriginalCommand { get; private set; } 
    public string OriginalBatch { get; private set; }


    // Expose Parsed Batch as an object ? 
    //      if so, then ... remove .OriginalCommand and .OriginalBatch
    //      or... 'proxy'/bubble-them-up as new properties - 
    //      e.g., do I need to add: 
    //          .Comments / .BlockComments / .Strings / etc.? 


    // TODO: other objects like: 
    //  .Return Params
    //  .Projection / Output
    //  .Printed Text or whatever...
    //  .Full-on errors. 
    //  .start/end .ExecutionTime
    //  .etc. 
    //  .TargetDatabases - which'll be ... lazy-loaded via a func against the original batch thingy? (if so, then I have to pass that in).
    //              so, yeah, maybe just have the .TargetDatabases (List<string>) prop... be implemented here (lazy-loaded) and ... NOT in the 'parser'.

    public Batch(CommandType commandType, ResultType resultType, string batchText) : this (commandType, resultType, batchText, null) { }

    public Batch(CommandType commandType, ResultType resultType, string batchText, ParsedBatch parsedBatch)
    {
        this.CommandType = commandType;
        this.ResultType = resultType;
        this.BatchText = batchText;

        if (parsedBatch != null)
        {
            this.OriginalCommand = parsedBatch.TextSources.OriginalCommand;
            this.OriginalBatch = parsedBatch.TextSources.OriginalBatch;
        }
    }
}