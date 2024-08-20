namespace PSI.Models;

public enum TokenType
{
    BlockComment,
    EolComment,
    String,
    GoStatement //, 
    //Identifier,
    //QuotedIdentifier, 
    //TempObjectIdentifier,  // # or ## 
    //Parameter, 
    //SystemVariable, // i.e., @@xx
    //Operator, 
    //Literal (number)
    //etc...
}

[Flags]
public enum NewLineStatus
{
    None = 0,
    CrFoundWaitingOnLf = 1
}

[Flags]
public enum StringStatus
{
    None = 0,
    InString = 1,
    EscapingOrNesting = 2
}

[Flags]
public enum CommentStatus
{
    None = 0,
    InComment = 1
}

[Flags]
public enum BlockCommentStatus
{
    None = 0,
    SlashFoundWaitingOnStar = 1,
    InComment = 2,
    Nested = 4,
    NestedStarFoundWaitingOnNestedBackslash = 8
}

public class CharacterBuffer
{
    private readonly List<char> _buffer;

    public int Limit { get; private set; }

    public CharacterBuffer(int limit)
    {
        this._buffer = new List<char>();
        this._buffer.Capacity = limit;
    }

    public void Add(char character)
    {
        this._buffer.Add(character);
        this._buffer.TrimExcess();
    }

    public char Peek()
    {
        return this._buffer[^1];
    }
}

public interface ITokenInitializer
{
    bool Handles(char character);
    void Process(ITokenizer tokenizer, StringReader reader, char currentChar);
}

public interface ITokenFinalizer
{
    bool WatchesFor(char character);
    void Process(ITokenizer tokenizer, StringReader reader, char currentChar);
    void ProcessRemoval(ITokenizer tokenizer);
    void Terminate(ITokenizer tokenizer);
}

public interface ICodeLine
{
    int LineNumber { get; }
    string LineText { get; }
    int StartOffset { get; }
    int EndOffset { get; }

    void SetLineNumber(int lineNumber);
}

public class CodeLine(string lineText, int startOffset, int endOffset) : ICodeLine
{
    public int LineNumber { get; private set; }
    public string LineText { get; private set; } = lineText;
    public int StartOffset { get; private set; } = startOffset;
    public int EndOffset { get; private set; } = endOffset;

    public void SetLineNumber(int lineNumber)
    {
        this.LineNumber = lineNumber;
    }
}

public interface IToken
{
    TokenType TokenType { get; }
    int StartIndex { get; }
    int EndIndex { get; }
    string Text { get; }
}

public class CodeString(int start, int end, string text, bool isUnicode) : IToken
{
    public TokenType TokenType { get; } = TokenType.String;
    public int StartIndex { get; } = start;
    public int EndIndex { get; } = end;
    public string Text { get; } = text;
    public bool IsUnicode { get; } = isUnicode;
}

public class GoStatement(int startIndex, int endIndex, string text, int goCount) : IToken
{
    public TokenType TokenType { get; } = TokenType.GoStatement;
    public int StartIndex { get; } = startIndex;
    public int EndIndex { get; } = endIndex;
    public string Text { get; } = text;
    public int GoCount { get; } = goCount;
}

public class BlockComment(int startIndex, int endIndex, string text) : IToken
{
    public TokenType TokenType { get; } = TokenType.BlockComment;
    public int StartIndex { get; } = startIndex;
    public int EndIndex { get; } = endIndex;
    public string Text { get; } = text;
}

public class Comment(int startIndex, int endIndex, string text) : IToken
{
    public TokenType TokenType { get; } = TokenType.EolComment;
    public int StartIndex { get; } = startIndex;
    public int EndIndex { get; } = endIndex;
    public string Text { get; } = text;
}

public class UseDirective(string text)
{
    // should I also pass in locations? ... if so, they need to be relative to the ... batch not the original document, right? 
    // and... i guess if I pass in "uSe xyz ... -- comments or whatever ... " then I can parse that crap out of the text parameter and ... 
    //  turn that into a db name via regex... 

    // which means that I should have a: 
    public string TargetDatabase { get; } = text; // TODO: just assigning this ... here to avoid breaking the build from within PowerShell. 
}

public class TextSources(string originalCommand, string originalBatch)
{
    public string OriginalCommand { get; } = originalCommand;
    public string OriginalBatch { get; } = originalBatch;
}

public class ParsedBatch(int start, int end, string text, TextSources sources)
{
    public int StartIndex { get; } = start;
    public int EndIndex { get; } = end;
    public string BatchText { get; } = text;
    public TextSources TextSources { get; set; } = sources;

    public GoStatement GoStatement { get; internal set; }

    public List<Comment> Comments { get; internal set; }
    public List<BlockComment> BlockComments { get; internal set; }

    public List<UseDirective> UseDirectives
    {
        get
        {
            throw new NotImplementedException();
        }
    }
}

public interface ITokenizer
{
    string RawText { get; }
    int CurrentIndex { get; }
    NewLineStatus NewLineStatus { get; set; }
    StringStatus StringStatus { get; set; }
    BlockCommentStatus BlockCommentStatus { get; set; }
    CommentStatus CommentStatus { get; set; }

    void EnlistInitializer(ITokenInitializer initializer);
    void EnlistFinalizer(ITokenFinalizer finalizer);
    void MarkFinalizerForRemoval(ITokenFinalizer finalizer);

    CharacterBuffer CharacterBuffer { get; }

    List<ICodeLine> CodeLines { get; }
    List<CodeString> Strings { get; }
    List<GoStatement> GoStatements { get; } // and/or should i have .Batches?
    List<BlockComment> BlockComments { get; }
    List<Comment> Comments { get; }
    int BlockCommentNestingLevel { get; set; }

    void Initialize();
    void Tokenize();

    List<ParsedBatch> GetParsedBatches(bool ignoreGoInUseOnlyBatches);

    void AddCodeLineFromCurrentLocation();

    int GetCurrentLineStartOffset();
    CodeLine GetCurrentLineFromCurrentLocation();
}

// vNEXT: might make more sense to pass in a STREAM (or similar abstraction) vs a string?
public class Tokenizer(string rawText) : ITokenizer
{
    private List<ITokenInitializer> _tokenInitializers = new List<ITokenInitializer>();
    private List<ITokenFinalizer> _tokenFinalizers = new List<ITokenFinalizer>();
    private List<ITokenFinalizer> _finalizersToRemove = new List<ITokenFinalizer>();
    private Stack<int> _newlineIndexes = new Stack<int>();
    private int _lineNumber = 0;

    public NewLineStatus NewLineStatus { get; set; }
    public StringStatus StringStatus { get; set; } = StringStatus.None;
    public BlockCommentStatus BlockCommentStatus { get; set; } = BlockCommentStatus.None;
    public CommentStatus CommentStatus { get; set; } = CommentStatus.None;

    public CharacterBuffer CharacterBuffer { get; set; } = new(10);
    public List<ICodeLine> CodeLines { get; internal set; } = new();
    public List<CodeString> Strings { get; internal set; } = new();
    public List<GoStatement> GoStatements { get; internal set; } = new();
    public List<BlockComment> BlockComments { get; internal set; } = new();
    public List<Comment> Comments { get; internal set; } = new();
    public int BlockCommentNestingLevel { get; set; }

    public string RawText { get; private set; } = rawText;
    public int CurrentIndex { get; private set; } = -1;

    public void EnlistInitializer(ITokenInitializer initializer)
    {
        this._tokenInitializers.Add(initializer);
    }

    public void EnlistFinalizer(ITokenFinalizer finalizer)
    {
        this._tokenFinalizers.Add(finalizer);
    }

    public void MarkFinalizerForRemoval(ITokenFinalizer finalizer)
    {
        this._finalizersToRemove.Add(finalizer);
    }

    public int GetCurrentLineStartOffset()
    {
        return this._newlineIndexes.Peek();
    }

    public CodeLine GetCurrentLineFromCurrentLocation()
    {
        int start = this.GetCurrentLineStartOffset();

        char[] chars = { '\r', '\n' };
        int end = this.RawText.IndexOfAny(chars, start);
        if (end == -1)
            end = this.RawText.Length;

        string currentLine = this.RawText.Substring(start, end - start);

        return new CodeLine(currentLine, start, end);
    }

    public void Initialize()
    {
        this.EnlistInitializer(new CrLfInitializer());
        this.EnlistInitializer(new StringInitializer());
        this.EnlistInitializer(new GoInitializer());
        this.EnlistInitializer(new BlockCommentInitializer());
        this.EnlistInitializer(new CommentInitializer());
    }

    public void Tokenize()
    {
        int readValue;
        this.CurrentIndex = 0;
        this._newlineIndexes.Push(0);

        using StringReader sr = new StringReader(this.RawText);
        while ((readValue = sr.Read()) != -1)
        {
            char current = (char)readValue;

            foreach (var finalizer in this._tokenFinalizers)
            {
                if (finalizer.WatchesFor(current))
                    finalizer.Process(this, sr, current);
            }

            foreach (var initializer in this._tokenInitializers)
            {
                if (initializer.Handles(current))
                    initializer.Process(this, sr, current);
            }

            foreach (var finalizer in this._finalizersToRemove)
            {
                finalizer.ProcessRemoval(this);
                if (this._tokenFinalizers.Contains(finalizer))
                    this._tokenFinalizers.Remove(finalizer);

                this._finalizersToRemove = new List<ITokenFinalizer>();
            }

            this.CharacterBuffer.Add(current);
            this.CurrentIndex++;
        }

        // finalizers get one last chance to terminate any non-completed (i.e., 'open') tokens:
        foreach (var finalizer in this._tokenFinalizers)
            finalizer.Terminate(this);

        int lastNewLineStart = this.GetCurrentLineStartOffset();
        if (this.CurrentIndex - lastNewLineStart > -1)
            this.AddCodeLineFromCurrentLocation();
    }

    public List<ParsedBatch> GetParsedBatches(bool ignoreGoInUseOnlyBatches = false)
    {
        List<ParsedBatch> output = new List<ParsedBatch>();

        int previousStart = 0;
        foreach (var go in this.GoStatements)
        {
            int end = go.EndIndex - previousStart - go.Text.Length;

            string batchText = this.RawText.Substring(previousStart, end).Trim();

            var sources = new TextSources(this.RawText, this.RawText.Substring(previousStart, (end + go.Text.Length)));
            var batch = new ParsedBatch(previousStart, go.EndIndex, batchText, sources);
            batch.GoStatement = go;
            output.Add(batch);

            previousStart = go.StartIndex + go.Text.Length;
        }

        if (previousStart < this.RawText.Length)
        {
            var batchText = this.RawText.Substring(previousStart, this.RawText.Length - previousStart).Trim();

            var sources = new TextSources(this.RawText, this.RawText.Substring(previousStart, this.RawText.Length - previousStart));
            var batch = new ParsedBatch(previousStart, this.RawText.Length, batchText, sources);
            output.Add(batch);
        }

        if (ignoreGoInUseOnlyBatches)
        {
            var modifiedBatches = new List<ParsedBatch>();
            previousStart = 0;
            var sourceText = this.RawText;

            foreach (var batch in output)
            {
                var text = batch.BatchText;

                int goLength = 0;
                if (batch.GoStatement != null)
                {
                    goLength = batch.GoStatement.Text.Length;

                    var regex = new Regex(@"(?<using>(\s*USE\s*\[.{1,255}?\]\s*;*|\s*USE\s+[^\[\s]{1,255}))", Global.SingleLineRegexOptions);
                    if (regex.IsMatch(text))
                    {
                        text = regex.Replace(text, "");

                        regex = new Regex(@"(?<comment>/\*.*?\*/)", Global.SingleLineRegexOptions);
                        text = regex.Replace(text, "");
                        regex = new Regex(@"--[^\r\n]*", Global.SingleLineRegexOptions);
                        text = regex.Replace(text, "");

                        if (string.IsNullOrWhiteSpace(text))
                        {
                            sourceText = sourceText.ReplaceAtIndex(batch.GoStatement.StartIndex, ' ');
                            sourceText = sourceText.ReplaceAtIndex(batch.GoStatement.StartIndex + 1, ' ');

                            // NOTE: there's an edge case where "USE xxx\r\nGO" are the LAST lines in a script. And, if so, the "GO" will end
                            // up being removed AND we'll get a final/terminating batch of "USE xxx" - with nothing else. That's ... fine at 
                            // this point. But may be something where I want to 'collapse' that final batch 'up into' the previous batch. 
                            // if so: a) if batchNumber (i.e., here, right now) == output.Count - 1. b) create a new batch with END offsets = batch.BatchText.Length
                            //      and c) make sure that applies to the batch-text as well... then, d) pop/remove last ParsedBatch from modifiedBatches and replace with ... newly created.
                            continue;
                        }
                    }
                }

                var newBatch = new ParsedBatch(previousStart, batch.EndIndex - goLength, sourceText.Substring(previousStart, batch.EndIndex - previousStart - goLength).Trim(), batch.TextSources);

                modifiedBatches.Add(newBatch);
                previousStart = batch.EndIndex;
            }

            output = modifiedBatches;
        }

        foreach (var batch in output)
        {
            batch.Comments = this.GetCommentsForBatch(batch.StartIndex, batch.EndIndex);
            batch.BlockComments = this.GetBlockCommentsForBatch(batch.StartIndex, batch.EndIndex);
        }

        // !!!! TODO: 
        //  after handling all bits of various formatting (well, except for the whole USE xxxx and GO replacement there)... 
        //      make sure that if a go.GoCount > 1 ... that ... I end up adding in a GO multiple times.... 

        return output;
    }

    public void AddCodeLineFromCurrentLocation()
    {
        int lineStart = this.GetCurrentLineStartOffset();
        int lineEnd = this.CurrentIndex + 1;
        if (lineEnd > this.RawText.Length)
            lineEnd = this.RawText.Length;

        string lineText = this.RawText.Substring(lineStart, lineEnd - lineStart);
        var codeLine = new CodeLine(lineText, lineStart, this.CurrentIndex + 1);

        codeLine.SetLineNumber(this._lineNumber);
        this.CodeLines.Add(codeLine);
        this._lineNumber++;

        this._newlineIndexes.Push(this.CurrentIndex + 1);
    }

    private List<Comment> GetCommentsForBatch(int startIndex, int endIndex)
    {
        var output = new List<Comment>();
        foreach (var comment in this.Comments)
        {
            if (comment.StartIndex >= startIndex && comment.EndIndex <= endIndex)
                output.Add(new Comment(comment.StartIndex - startIndex, comment.EndIndex - startIndex, comment.Text));
        }

        return output;
    }

    private List<BlockComment> GetBlockCommentsForBatch(int startIndex, int endIndex)
    {
        var output = new List<BlockComment>();
        foreach (var comment in this.BlockComments)
        {
            if (comment.StartIndex >= startIndex && comment.EndIndex <= endIndex)
                output.Add(new BlockComment(comment.StartIndex - startIndex, comment.EndIndex - startIndex, comment.Text));
        }

        return output;
    }
}