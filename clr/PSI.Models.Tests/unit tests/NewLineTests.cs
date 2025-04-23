namespace PSI.Models.Tests.unit_tests;

public class NewLineTests
{
    #region Test Strings
    private readonly string SUPER_SIMPLE_MULTI_LINE_STRING = @"New
Line.";

    private readonly string SIMPLE_MULTI_LINE_STRING_WITH_CRLF_TERMINATOR = @"New
Line.
";

    #endregion

    [Test]
    public void NewLineHandlers_Split_String_By_CrLf()
    {
        var sut = new Tokenizer(SUPER_SIMPLE_MULTI_LINE_STRING);
        sut.Initialize();

        sut.Tokenize();

        Assert.That(sut.CodeLines.Count, Is.EqualTo(2));

        Assert.That(sut.CodeLines[0].LineNumber == 0);
        StringAssert.AreEqualIgnoringCase("New\r\n", sut.CodeLines[0].LineText);

        Assert.That(sut.CodeLines[1].LineNumber == 1);
        StringAssert.AreEqualIgnoringCase("Line.", sut.CodeLines[1].LineText);
    }

    [Test]
    public void NewLineHandlers_Do_Not_Add_Extra_Blank_Lines_At_EoString()
    {
        var sut = new Tokenizer(SIMPLE_MULTI_LINE_STRING_WITH_CRLF_TERMINATOR);
        sut.Initialize();

        sut.Tokenize();

        // should be 3x lines - cuz that's how many there are (NOT 4 lines - i.e., the 'native' CRLF + a bogus/terminator from code/processing.
        Assert.That(sut.CodeLines.Count, Is.EqualTo(3));

        StringAssert.AreEqualIgnoringCase("", sut.CodeLines[2].LineText);
    }

    [Test]
    public void NewLineHandlers_Split_On_LineFeed_Only()
    {
        var sut = new Tokenizer("This is a\nterrible newline (in windows)\r\n.");
        sut.Initialize();

        sut.Tokenize();

        Assert.That(sut.CodeLines.Count, Is.EqualTo(3));

        StringAssert.AreEqualIgnoringCase("This is a\n", sut.CodeLines[0].LineText);
        StringAssert.AreEqualIgnoringCase("terrible newline (in windows)\r\n", sut.CodeLines[1].LineText);
        StringAssert.AreEqualIgnoringCase(".", sut.CodeLines[2].LineText);
    }

    [Test]
    public void NewLineHandlers_Split_On_CarriageReturn_Only()
    {
        var sut = new Tokenizer("This is a\rterrible newline (in windows)\r\n.");
        sut.Initialize();

        sut.Tokenize();

        Assert.That(sut.CodeLines.Count, Is.EqualTo(3));

        StringAssert.AreEqualIgnoringCase("This is a\r", sut.CodeLines[0].LineText);
        StringAssert.AreEqualIgnoringCase("terrible newline (in windows)\r\n", sut.CodeLines[1].LineText);
        StringAssert.AreEqualIgnoringCase(".", sut.CodeLines[2].LineText);
    }
}