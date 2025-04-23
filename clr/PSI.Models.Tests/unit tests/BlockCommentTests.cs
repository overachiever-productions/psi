namespace PSI.Models.Tests.unit_tests;

public class BlockCommentTests
{
    [Test]
    public void BlockCommentHandlers_Match_Simple_Single_Line_BlockComment()
    {
        string text = "SELECT @@SERVERNAME [server_name] /* some comments */\r\rGO";
        var sut = new Tokenizer(text);
        sut.Initialize();
        sut.Tokenize();

        Assert.That(sut.BlockComments.Count, Is.EqualTo(1));
        Assert.That(sut.BlockComments[0].StartIndex, Is.EqualTo(34));
        Assert.That(sut.BlockComments[0].EndIndex, Is.EqualTo(53));

        // sanity check: 
        string comment = text.Substring(34, 53 - 34);
        StringAssert.AreEqualIgnoringCase(sut.BlockComments[0].Text, comment);


        StringAssert.AreEqualIgnoringCase("/* some comments */", sut.BlockComments[0].Text);
    }

    [Test]
    public void BlockCommentHandlers_Match_Simple_Comments_Across_Multiple_Lines()
    {
        var sut = new Tokenizer("   /* comments */ SELECT TOP 200\r\n    /*firstname */ last_name   \r\n FROM\r\n/*oldTable*/NewTable;");
        sut.Initialize();
        sut.Tokenize();

        Assert.That(sut.BlockComments.Count, Is.EqualTo(3));

        StringAssert.AreEqualIgnoringCase("/* comments */", sut.BlockComments[0].Text);
        StringAssert.AreEqualIgnoringCase("/*firstname */", sut.BlockComments[1].Text);
        StringAssert.AreEqualIgnoringCase("/*oldTable*/", sut.BlockComments[2].Text);
    }

    [Test]
    public void BlockCommentHandlers_Ignore_Stray_Asterixes()
    {
        var sut = new Tokenizer("/* SELECT * FROM blah;*/\r\nSELECT TOP 200 * FROM blah;");
        sut.Initialize();
        sut.Tokenize();

        Assert.That(sut.BlockComments.Count, Is.EqualTo(1));
        StringAssert.AreEqualIgnoringCase("/* SELECT * FROM blah;*/", sut.BlockComments[0].Text);
    }

    [Test]
    public void BlockCommentHandlers_Ignore_Stray_Slashes()
    {
        var sut = new Tokenizer("\t/* xx /* nested with / and another //// */ */\r\nSELECT @@SERVERNAME [server_name];");
        sut.Initialize();
        sut.Tokenize();

        Assert.That(sut.BlockComments.Count, Is.EqualTo(1));
        StringAssert.AreEqualIgnoringCase("/* xx /* nested with / and another //// */ */", sut.BlockComments[0].Text);
    }

    [Test]
    public void BlockCommentHandlers_Can_Handle_Simple_Nested_BlockComments()
    {
        var sut = new Tokenizer("\t/* xx /* nest */ */\r\nSELECT @@SERVERNAME [server_name];");
        sut.Initialize();
        sut.Tokenize();

        Assert.That(sut.BlockComments.Count, Is.EqualTo(1));

        StringAssert.AreEqualIgnoringCase("/* xx /* nest */ */", sut.BlockComments[0].Text);
    }

    [Test]
    public void BlockCommentHandlers_Can_Handle_Multiple_Nested_BlockComments()
    {
        var sut = new Tokenizer("\t/* comment /* sub-comment1 /* sub-comment2 */ */ */\r\nSELECT @@SERVERNAME [server_name];\t/* multi\r\nline block /* sub\r\n comment */\r\n*/");
        sut.Initialize();
        sut.Tokenize();

        Assert.That(sut.BlockComments.Count, Is.EqualTo(2));
        StringAssert.AreEqualIgnoringCase("/* comment /* sub-comment1 /* sub-comment2 */ */ */", sut.BlockComments[0].Text);
        StringAssert.AreEqualIgnoringCase("/* multi\r\nline block /* sub\r\n comment */\r\n*/", sut.BlockComments[1].Text);
    }

    [Test]
    public void BlockCommentHandlers_Can_Handle_Adjacent_Nested_Terminators()
    {
        // just a sanity check to make sure code doesn't choke on "*/*/" etc... 
        var sut = new Tokenizer("\t/* xx /* nest /* nest 2 */*/*/\r\n\tSELECT @@SERVERNAME [server_name];");
        sut.Initialize();
        sut.Tokenize();

        Assert.That(sut.BlockComments.Count, Is.EqualTo(1));
    }

    [Test]
    public void BlockCommentHandlers_Throw_On_Non_Completed_BlockComments()
    {
        var sut = new Tokenizer("/* this comment is not even close to valid\r\nSELECT TOP 200 * FROM something;");
        sut.Initialize();
        Assert.Throws<SyntaxException>(sut.Tokenize);
    }

    [Test]
    public void BlockCommentHandlers_Throw_On_Incomplete_Nested_BlockComments()
    {
        var sut = new Tokenizer("\t/* xx /* nest (but no-nested-close) */ \r\nSELECT @@SERVERNAME [server_name];");
        sut.Initialize();
        Assert.Throws<SyntaxException>(sut.Tokenize);
    }

    // nesting that doesn't correctly terminate some of the internal /* 

    // need to test the case of double and triple nesting of end comments
    // e.g., "/*  /* comments */*/ 
    // and   "/*   /*   /*   dsaklfjlds */*/*/"


}