using System.Text.RegularExpressions;

namespace PSI.Models;

public class Command
{
    public CommandType CommandType { get; private set; }
    public string CommandText { get; private set; }
    public ResultType ResultType { get; private set; }

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

    public List<BatchContext> GetBatchedCommands()
    {
        var output = new List<BatchContext>();

        if (CommandType == CommandType.Command)
        {
            output.Add(new BatchContext(this.CommandType, this.ResultType, this.CommandText));
            return output;
        }

        if (Regex.IsMatch(this.CommandText, @"^\s*GO\s*", Global.MultiLineRegexOptions))
        {
            var splitter = new BatchSplitter(this.CommandText);
            foreach (var batch in splitter.SplitIntoBatches())
                output.Add(new BatchContext(this.CommandType, this.ResultType, batch));

            return output;
        }

        output.Add(new BatchContext(this.CommandType, this.ResultType, this.CommandText));
        return output;
    }
}

public class BatchContext
{
    public CommandType CommandType { get; private set; }
    public ResultType ResultType { get; private set; } 
    public BatchCommand BatchCommand { get; private set; }

    public BatchContext(CommandType commandType, ResultType resultType, string commandText)
    {
        this.CommandType = commandType;
        this.ResultType = resultType;
        this.BatchCommand = new BatchCommand(commandText);
    }

    public BatchContext(CommandType commandType, ResultType resultType, BatchCommand batchCommand)
    {
        this.CommandType = commandType;
        this.ResultType = resultType;
        this.BatchCommand = batchCommand;
    }
}

public class BatchSplitter(string command)
{
    private string _commandText = command;

    public List<BatchCommand> SplitIntoBatches()
    {
        var batchTerminators = new List<Tuple<int, int>>();
        var blockComments = new List<Tuple<int, int>>();
        var eolCommentTickLocations = new List<int>();
        var useDirectiveStarts = new List<int>();
        var strings = new List<Tuple<int, int>>();
        var usingChunks = new List<Tuple<string, int, int>>();
        var ignorableGoLocations = new List<int>();

        string sourceText = this._commandText;

        // For EOL Comments (--) with Ticks (') in them: replace the ticks with _ and 'remember' the location. 
        //      Otherwise, stray ticks will cause ugly issues with 'string' matching regexes.
        var regex = new Regex(@"(?<comment_tick>--[^\r]*')", Global.SingleLineRegexOptions);
        foreach (Match m in regex.Matches(this._commandText))
        {
            int commentStartLocation = m.Index;

            var subRegex = new Regex(@"'", Global.SingleLineRegexOptions);
            foreach(Match x in subRegex.Matches(m.Value))
                eolCommentTickLocations.Add(commentStartLocation + x.Index);
        }

        // REFACTOR: the code below (to identify USE xxx-> GO) ... is a sledge hammer. 
        //      needs some refactoring - i.e., probably makes sense to create some sort of 'split' by locations FUNC
        //      cuz I use it to splity by "USE xxxxx" and then DOWN at the bottom of this func ... to split by GO. 
        regex = new Regex(@"(?<using>(\s*USE\s*\[.{1,255}?\]\s*;*|\s*USE\s+[^\[\s]{1,255}))", Global.SingleLineRegexOptions);
        int useStart = 0;
        foreach (Match m in regex.Matches(this._commandText))
        {
            // NOTE: regex.Split() isn't working here:
            //      a) it captures leading whitespace (cuz of my regex)
            //      b) more importantly, it's capturing / splitting on the same 'match' > 1 time (consistently).
            //      which is why I'm brute-forcing things to a) get exact start location and b) only process each boundary 1x. 
            useStart = m.Index;

            string rawValue = m.Value;
            string value = rawValue.TrimStart();

            if (value.Length < rawValue.Length)
                useStart = useStart + (rawValue.Length - value.Length);

            useDirectiveStarts.Add(useStart);
        }

        int offsetStart = 0;
        foreach (var offset in useDirectiveStarts)
        {
            int offsetEnd = offset;
            usingChunks.Add(new Tuple<string, int, int>(this._commandText.Substring(offsetStart, offsetEnd - offsetStart), offsetStart, offsetEnd));
            offsetStart = offsetEnd;
        }

        if (offsetStart < this._commandText.Length)
            usingChunks.Add(new Tuple<string, int, int>(this._commandText.Substring(offsetStart, this._commandText.Length - offsetStart), offsetStart, this._commandText.Length));

        foreach (var usingChunk in usingChunks)
        {
            string usingText = usingChunk.Item1;

            regex = new Regex(@"(?<using>(\s*USE\s*\[.{1,255}?\]\s*;*|\s*USE\s+[^\[\s]{1,255}))", Global.SingleLineRegexOptions);
            var matches = regex.Matches(usingText);
            if (matches.Count > 0)
            {
                var useMatch = matches[0];
                var goRegex = new Regex(@"^\s*GO\s*", Global.MultiLineRegexOptions);
                var goMatches = goRegex.Matches(usingText);
                if (goMatches.Count > 0)
                {
                    var match = goMatches[0];
                    string useStatementToGoText = usingText.Substring(useMatch.Length, match.Index - useMatch.Length);

                    int goOffset = usingChunk.Item2 + match.Index;

                    // remove /*  comments */  & remove -- comments
                    var commentsRegex = new Regex(@"/\*.*?\*/", Global.SingleLineRegexOptions);
                    useStatementToGoText = commentsRegex.Replace(useStatementToGoText, "");

                    commentsRegex = new Regex(@"--[^\n\r]*", Global.SingleLineRegexOptions);
                    useStatementToGoText = commentsRegex.Replace(useStatementToGoText, "");

                    if(string.IsNullOrWhiteSpace(useStatementToGoText))
                        ignorableGoLocations.Add(goOffset);
                }
            }
        }

        foreach (int location in ignorableGoLocations)
        {
            // REFACTOR: this just feels dirty: 
            this._commandText = this._commandText.ReplaceAtIndex(location, ' ');
            this._commandText = this._commandText.ReplaceAtIndex(location + 1, ' ');
        }

        foreach (int position in eolCommentTickLocations)
            this._commandText = this._commandText.ReplaceAtIndex(position, '_');

        regex = new Regex(@"(?<comment>/\*.*?\*/)", Global.SingleLineRegexOptions);
        foreach (Match m in regex.Matches(this._commandText))
            blockComments.Add(new Tuple<int, int>(m.Index, m.Index + m.Length));

        regex = new Regex(@"(?<string>N?(\x27)((?!\1).|\1{2})*\1)", Global.SingleLineRegexOptions);
        foreach(Match m in regex.Matches(this._commandText))
            strings.Add(new Tuple<int, int>(m.Index, m.Index + m.Length));

        // UNDO ticks changed to _ (now that legit 'strings' are identified):
        foreach (int position in eolCommentTickLocations)
            this._commandText = this._commandText.ReplaceAtIndex(position, '\'');

        regex = new Regex(@"^\s*GO\s*", Global.MultiLineRegexOptions);  // !! MULTILINE !!
        foreach (Match m in regex.Matches(this._commandText))
        {
            if(IsTerminatorWithinStartEndLocations(m.Index, blockComments))
                continue;

            if(IsTerminatorWithinStartEndLocations(m.Index, strings))
                continue;

            // HACK: Until I can get my GO REGEX to stop matching GOTO (or anything else that is legit SQL, not in comments, at the start of the line, and starts with GO...):
            if (LooksLikeGoStatementButIsSomethingElse(m))
                continue;

            batchTerminators.Add(new Tuple<int, int>(m.Index, m.Length));
        }

        List<BatchCommand> output = new List<BatchCommand>();

        if(batchTerminators.Count == 0)
            output.Add(new BatchCommand(sourceText, -1, -1, this._commandText));
        else
        {
            int start = 0;
            foreach (var boundary in batchTerminators)
            {
                int end = boundary.Item1;

                output.Add(new BatchCommand(sourceText, start, end, this._commandText.Substring(start, end - start)));
                start = end + boundary.Item2; 
            }

            if(start < this._commandText.Length)
                output.Add(new BatchCommand(sourceText, start, this._commandText.Length, this._commandText.Substring(start, this._commandText.Length - start)));
        }

        return output;
    }

    private bool IsTerminatorWithinStartEndLocations(int index, List<Tuple<int, int>> locations)
    {
        return locations.Any(x => index >= x.Item1 && index < x.Item2);
    }

    private bool LooksLikeGoStatementButIsSomethingElse(Match m)
    {
        // insanely enough, the chars that can legally follow "GO" are: "[EOF]", "[EOL]" (CR or LF), "/s" (whitespace), "--(comments)", "/* .... comments ... etc". 

        int matchStartIndex = m.Index;
        int goStartIndex = matchStartIndex + (m.Value.Length - m.Value.TrimStart().Length);
        if (goStartIndex + 2 >= this._commandText.Length)
            return false; // end of line.

        if (goStartIndex + 3 >= this._commandText.Length)
            return false; // also at end of line.

        var characterRightAfterGo = this._commandText.Substring(goStartIndex + 2, 1);
        if (string.IsNullOrWhiteSpace(characterRightAfterGo))
            return false; // whitepsace or whatever... but it's "GO" with a boundary after it... 

        // at this point, the ONLY other scenario that's (LEGALLY) possible (i.e., valid) is something like "GO/*this is a comment..." or "GO--comment here too". 
        //  so: 
        if (goStartIndex + 4 >= this._commandText.Length)
            return false;

        var charsAfterGo = this._commandText.Substring(goStartIndex + 2, 2);
        if (charsAfterGo == "--" || charsAfterGo == "/*")
            return false; // i.e., looks like a GO and IS a GO (not something else). It's just that it's followed REALLY CLOSELY by legit/allowed comments. 

        return true;
    }
}

// REFACTOR: BatchCommandText or possibly just CommandText (which'll make Command.CommandText odd - but maybe not. it's the text from PSI. everything 'after' is text for the DB).
public class BatchCommand
{
    public string SourceText { get; private set; }
    public string SourceBatch { get; private set; }
    public string BatchText { get; private set; }

    public BatchCommand(string sourceText, int offsetStart, int offsetEnd, string batchText)
    {
        this.SourceText = sourceText;
        this.BatchText = batchText;

        if (offsetStart > -1)
            this.SourceBatch = this.SourceText.Substring(offsetStart, offsetEnd - offsetStart);
        else
            this.SourceBatch = sourceText;
    }

    public BatchCommand(string sourceText)
    {
        this.SourceText = sourceText;
        this.SourceBatch = sourceText;
        this.BatchText = sourceText;
    }

    //regex = new Regex(@"(?<using>(\s*USE\s*\[.{1,255}?\]\s*;*|\s*USE\s+[^\[\s]{1,255}))", Global.SingleLineRegexOptions);
    //    foreach (Match m in regex.Matches(this._commandText))
    //    {
    //    var targetDB = m.Groups["using"].Value;
    //}

}