namespace PSI.Models;

public class CrLfInitializer : ITokenInitializer
{
    public bool Handles(char character)
    {
        return (character == 13 || character == 10);
    }

    public void Process(ITokenizer tokenizer, StringReader reader, char currentChar)
    {
        if (tokenizer.NewLineStatus.HasFlag(NewLineStatus.CrFoundWaitingOnLf))
            return;

        if (13 == (int)currentChar && 10 == reader.Peek())
        {
            tokenizer.NewLineStatus = NewLineStatus.CrFoundWaitingOnLf;

            var finalizer = new NewLineFinalizer();
            tokenizer.EnlistFinalizer(finalizer);
            return;
        }

        // if still here, then 10 or 13 (by self). SKIP finalizer and spin up new line NOW. 
        tokenizer.AddCodeLineFromCurrentLocation();
    }
}

public class NewLineFinalizer : ITokenFinalizer
{
    public bool WatchesFor(char character)
    {
        return character == 10;
    }

    public void Process(ITokenizer tokenizer, StringReader reader, char currentChar)
    {
        tokenizer.AddCodeLineFromCurrentLocation();
        tokenizer.MarkFinalizerForRemoval(this);
    }

    public void ProcessRemoval(ITokenizer tokenizer)
    {
        tokenizer.NewLineStatus = NewLineStatus.None;
    }

    public void Terminate(ITokenizer tokenizer)
    {

    }
}

public class StringInitializer : ITokenInitializer
{
    public bool Handles(char character)
    {
        return character == 39;
    }

    public void Process(ITokenizer tokenizer, StringReader reader, char currentChar)
    {
        if (tokenizer.StringStatus.HasFlag(StringStatus.InString))
            return;

        if (tokenizer.CommentStatus.HasFlag(CommentStatus.InComment))
            return; // ticks / strings after -- (when not in strings already) ... don't count - e.g., ignore "-- it's fun" and "-- 'string'"... 

        tokenizer.StringStatus = StringStatus.InString;

        bool isUnicode = false;
        int stringStart = tokenizer.CurrentIndex;
        if (78 == (int)tokenizer.CharacterBuffer.Peek())
        {
            isUnicode = true;
            stringStart--;
        }

        var finalizer = new StringFinalizer(stringStart, isUnicode);
        tokenizer.EnlistFinalizer(finalizer);
    }
}

public class StringFinalizer : ITokenFinalizer
{
    private int _nestingDepth = 0;
    private int _stringStart = 0;
    private bool _isUnicode = false;

    public StringFinalizer(int stringStart, bool isUnicode)
    {
        this._stringStart = stringStart;
        this._isUnicode = isUnicode;
    }

    public bool WatchesFor(char character)
    {
        return character == 39;
    }

    public void Process(ITokenizer tokenizer, StringReader reader, char currentChar)
    {
        if (39 == reader.Peek())
        {
            tokenizer.StringStatus |= StringStatus.EscapingOrNesting;
            this._nestingDepth++;

            return;
        }

        if (0 == this._nestingDepth)
        {
            string text = tokenizer.RawText.Substring(this._stringStart, tokenizer.CurrentIndex - this._stringStart + 1);
            var codeString = new CodeString(this._stringStart, tokenizer.CurrentIndex, text, this._isUnicode);

            tokenizer.Strings.Add(codeString); // feels dirty to add this directly... but maybe ... meh?

            tokenizer.MarkFinalizerForRemoval(this);
        }
        else
            this._nestingDepth--;
    }

    public void ProcessRemoval(ITokenizer tokenizer)
    {
        tokenizer.StringStatus = StringStatus.None;
    }

    public void Terminate(ITokenizer tokenizer)
    {
        if (tokenizer.StringStatus.HasFlag(StringStatus.InString))
            throw new SyntaxException($"Syntax Error. String starting at position {this._stringStart} is not closed.");
    }
}

public class GoInitializer : ITokenInitializer
{
    public bool Handles(char character)
    {
        // G or g ... i.e., needs to be case-insensitive:
        return (character == 103 || character == 71);
    }

    public void Process(ITokenizer tokenizer, StringReader reader, char currentChar)
    {
        if (tokenizer.BlockCommentStatus.HasFlag(BlockCommentStatus.InComment))
            return;

        if (tokenizer.StringStatus.HasFlag(StringStatus.InString))
            return;

        if (111 == reader.Peek() || 79 == reader.Peek())
        {
            var currentCodeLine = tokenizer.GetCurrentLineFromCurrentLocation();

            string textBeforeGo = currentCodeLine.LineText.Substring(0,
                currentCodeLine.LineText.IndexOf("go", StringComparison.CurrentCultureIgnoreCase));

            if (string.IsNullOrWhiteSpace(textBeforeGo))
                tokenizer.EnlistFinalizer(new GoFinalizer(tokenizer.CurrentIndex, currentCodeLine));
        }
    }
}

public class GoFinalizer(int goStart, CodeLine currentLine) : ITokenFinalizer
{
    private int _goStart = goStart;
    private CodeLine _currentLine = currentLine;

    public bool WatchesFor(char character)
    {
        return (character == 111 || character == 79);
    }

    public void Process(ITokenizer tokenizer, StringReader reader, char currentChar)
    {
        // legal characters following "GO" are: <whitespace>, digits (e.g., GO12), or "--" (i.e., "GO--this is legit - even if it's lame)). 
        int goTextEnd = this._currentLine.LineText.IndexOf("go", StringComparison.InvariantCultureIgnoreCase) + 2;
        string textAfterGo = this._currentLine.LineText.Substring(goTextEnd, this._currentLine.LineText.Length - goTextEnd);

        var regex = new Regex(@"--[^\r\n]*", Global.SingleLineRegexOptions);
        textAfterGo = regex.Replace(textAfterGo, "");

        char charImmediatelyAfterGo = (char)reader.Peek();

        string goText = this._currentLine.LineText.Substring(0, goTextEnd);
        int goNumber = 0;
        GoStatement goStatement = null;

        // check for most common scenario: whitespace OR end-of-string/file/etc.
        if (string.IsNullOrWhiteSpace(charImmediatelyAfterGo.ToString()) || (65535 == (int)charImmediatelyAfterGo))
        {
            regex = new Regex(@"\s*(?<number>[0-9]+)", Global.SingleLineRegexOptions);
            Match m = regex.Match(textAfterGo);
            if (m.Success)
            {
                string number = m.Groups["number"].Value;
                int index = this._currentLine.LineText.IndexOf(number, StringComparison.InvariantCultureIgnoreCase);

                goText = this._currentLine.LineText.Substring(0, index + number.Length);
                goNumber = int.Parse(number);
            }

            goStatement = new GoStatement(this._goStart, this._goStart + goText.Length, goText, goNumber);
        }

        // now ... check for eol comments - e.g., "GO--and this is an ugly comment in a stupid spot right up next to the GO".
        if ((int)charImmediatelyAfterGo == 45)
        {
            if (string.IsNullOrWhiteSpace(textAfterGo))
                goStatement = new GoStatement(this._goStart, tokenizer.CurrentIndex, goText, 0);
        }

        // check for GO### - which is legit (e.g., GO3)
        if ((int)charImmediatelyAfterGo is >= 48 and <= 57)
        {
            regex = new Regex(@"\s*(?<number>[0-9]+)", Global.SingleLineRegexOptions);
            Match m = regex.Match(textAfterGo);
            if (m.Success)
            {
                string number = m.Groups["number"].Value;
                int index = this._currentLine.LineText.IndexOf(number, StringComparison.InvariantCultureIgnoreCase);

                goText = this._currentLine.LineText.Substring(0, index + number.Length);
                goNumber = int.Parse(number);
            }

            goStatement = new GoStatement(this._goStart, this._goStart + goText.Length, goText, goNumber);
        }

        if ((int)charImmediatelyAfterGo == 59)
        {
            // 59 = ";"
            throw new Exception("this is illegal. not sure I should care - but... this isn't valid SQL... ");
        }

        if (goStatement != null)
            tokenizer.GoStatements.Add(goStatement);

        // even IF we didn't find a legit go-statement, we're past "G + O" so... time to bail/unlist:
        tokenizer.MarkFinalizerForRemoval(this);
    }

    public void ProcessRemoval(ITokenizer tokenizer)
    {

    }

    public void Terminate(ITokenizer tokenizer)
    {

    }
}

public class BlockCommentInitializer : ITokenInitializer
{
    public bool Handles(char character)
    {
        // "/" 
        return character == 47;
    }

    public void Process(ITokenizer tokenizer, StringReader reader, char currentChar)
    {
        int nextChar = reader.Peek();

        if (tokenizer.BlockCommentStatus.HasFlag(BlockCommentStatus.NestedStarFoundWaitingOnNestedBackslash))
        {
            tokenizer.BlockCommentNestingLevel--;
            if (tokenizer.BlockCommentNestingLevel == 0)
                tokenizer.BlockCommentStatus = BlockCommentStatus.InComment;

            return;
        }

        if (tokenizer.BlockCommentStatus.HasFlag(BlockCommentStatus.InComment))
            return;

        if (42 == nextChar)
        {
            tokenizer.BlockCommentStatus = BlockCommentStatus.SlashFoundWaitingOnStar;
            var finalizer = new BlockCommentFiller(tokenizer.CurrentIndex);
            tokenizer.EnlistFinalizer(finalizer);
        }
    }
}

public class BlockCommentFiller(int commentStart) : ITokenFinalizer
{
    private int _commentStart = commentStart;

    public bool WatchesFor(char character)
    {
        return character == 42;
    }

    public void Process(ITokenizer tokenizer, StringReader reader, char currentChar)
    {
        int nextChar = reader.Peek();
        char previousChar = tokenizer.CharacterBuffer.Peek();

        // Scenario A: We've just hit the first "*" after the very first "/" - i.e.,. we're now 'in the comment'.
        if (tokenizer.CurrentIndex - this._commentStart == 1)
        {
            tokenizer.BlockCommentStatus = BlockCommentStatus.InComment; // no longer STARTING a comment
            return;
        }

        // Scenario B: We're NOT nested, we've just hit a "*", and the very next char is a "/" - in which case, we're wrapping up a /* comment */
        if (!tokenizer.BlockCommentStatus.HasFlag(BlockCommentStatus.Nested))
        {
            if (47 == nextChar)
            {
                // Remove self, but add a 'true' finalizer into the mix: 
                tokenizer.MarkFinalizerForRemoval(this);
                // and, note, a 'real' finalizer is added in this object's ProcessRemoval 'event'.
            }
        }

        // Scenario C: we're hitting a "*" and the immediate next char is a "/" but we're nested. 
        // WARN: order of operations are critical (i.e., Scenario C has to be processed before Scenario D). (or C will need more logic)
        if (47 == nextChar)
        {
            // this 'tells' the initializer to handle the "/" in a nested "*/" ... which'll then decrement nesting count.
            tokenizer.BlockCommentStatus |= BlockCommentStatus.NestedStarFoundWaitingOnNestedBackslash;
            return;
        }

        // Scenario D: we're on a "*" - and previous char was a "/" - but we're no longer at start - i.e., we've just started NESTING. 
        if (47 == previousChar)
        {
            tokenizer.BlockCommentStatus |= BlockCommentStatus.Nested;
            tokenizer.BlockCommentNestingLevel++;

            return;
        }

        // Scenario E: Just a 'stray' * - e.g. "/* SELECT * FROM blah - but commented out  ... */" 
        // nothing - we're fine. 
    }

    public void ProcessRemoval(ITokenizer tokenizer)
    {
        tokenizer.EnlistFinalizer(new BlockCommentFinalizer(this._commentStart));
    }

    public void Terminate(ITokenizer tokenizer)
    {
        if (tokenizer.BlockCommentNestingLevel > 0)
            throw new SyntaxException($"Syntax Error. Block-Comment (with nested block-comments) starting at position {this._commentStart} is not closed.");

        if (tokenizer.BlockCommentStatus.HasFlag(BlockCommentStatus.InComment))
            throw new SyntaxException($"Syntax Error. Block-Comment starting at position {this._commentStart} is not closed.");
    }
}

// 3x 'handlers' allow watching for FINAL "/" in "/* comments */" without triggering a NEW comment or problems with nesting.
public class BlockCommentFinalizer(int commentStart) : ITokenFinalizer
{
    private int _commentStart = commentStart;

    public bool WatchesFor(char character)
    {
        // "/" 
        return character == 47;
    }

    public void Process(ITokenizer tokenizer, StringReader reader, char currentChar)
    {
        string commentText = tokenizer.RawText.Substring(this._commentStart, tokenizer.CurrentIndex - this._commentStart + 1);

        tokenizer.BlockComments.Add(new BlockComment(this._commentStart, tokenizer.CurrentIndex + 1, commentText));
        tokenizer.BlockCommentStatus = BlockCommentStatus.None;
        tokenizer.MarkFinalizerForRemoval(this);
    }

    public void ProcessRemoval(ITokenizer tokenizer)
    {

    }

    public void Terminate(ITokenizer tokenizer)
    {

    }
}

public class CommentInitializer : ITokenInitializer
{
    public bool Handles(char character)
    {
        return character == '-';
    }

    public void Process(ITokenizer tokenizer, StringReader reader, char currentChar)
    {
        if (tokenizer.StringStatus.HasFlag(StringStatus.InString) || tokenizer.BlockCommentStatus.HasFlag(BlockCommentStatus.InComment))
            return;

        if (tokenizer.CommentStatus.HasFlag(CommentStatus.InComment))
            return; // likewise, if we're already in a -- comment and there are additional --'s (flowerpots, lines, etc.) ... we're good.


        if (45 == reader.Peek())
        {
            tokenizer.CommentStatus = CommentStatus.InComment;  // now just watch for EOL... 
            tokenizer.EnlistFinalizer(new CommentFinalizer(tokenizer.CurrentIndex));
        }
    }
}

public class CommentFinalizer(int commentStart) : ITokenFinalizer
{
    private int _commentStart = commentStart;

    public bool WatchesFor(char character)
    {
        // need to watch for both 13 and 10 (i.e., in case of 'bad' newlines):
        return (character == 13 || character == 10);
    }

    public void Process(ITokenizer tokenizer, StringReader reader, char currentChar)
    {
        // as soon as we hit CR, CRLF, or LF ... we're done... 
        var commentText = tokenizer.RawText.Substring(this._commentStart, tokenizer.CurrentIndex - this._commentStart);
        tokenizer.Comments.Add(new Comment(this._commentStart, tokenizer.CurrentIndex, commentText));

        tokenizer.CommentStatus = CommentStatus.None;
        tokenizer.MarkFinalizerForRemoval(this);
    }

    public void ProcessRemoval(ITokenizer tokenizer) { }

    public void Terminate(ITokenizer tokenizer)
    {
        // if there isn't a CR, CRLF, or LF at the END of a string ... and we were in -- a comment, need to wrap up. 
        if (tokenizer.CommentStatus.HasFlag(CommentStatus.InComment))
        {
            var commentText = tokenizer.RawText.Substring(this._commentStart, tokenizer.CurrentIndex - this._commentStart);
            tokenizer.Comments.Add(new Comment(this._commentStart, tokenizer.CurrentIndex, commentText));
        }
    }
}