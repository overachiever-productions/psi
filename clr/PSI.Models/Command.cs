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
        var output = new List<Batch>();

        if (CommandType == CommandType.Command)
        {
            output.Add(new Batch(this.CommandType, this.ResultType, this.CommandText));
            return output;
        }

        var tokenizer = new Tokenizer(this.CommandText);
        tokenizer.Initialize();
        tokenizer.Tokenize();
        foreach (var parsedBatch in tokenizer.GetParsedBatches(true))
            output.Add(new Batch(this.CommandType, this.ResultType, parsedBatch.BatchText, parsedBatch));

        return output;
    }
}