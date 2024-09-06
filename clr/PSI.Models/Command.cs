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