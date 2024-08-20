namespace PSI.Models.Tests.unit_tests;

public class GoStatementTests
{
    [Test]
    public void GoHandlers_Match_Simple_Go_In_Multi_Line_Command()
    {
        string text = "SELECT @@SERVERNAME [server_name];\r\nGO";
        var sut = new Tokenizer(text);
        sut.Initialize();
        sut.Tokenize();

        Assert.That(sut.GoStatements.Count, Is.EqualTo(1));

        Assert.That(sut.GoStatements[0].StartIndex, Is.EqualTo(36));
        Assert.That(sut.GoStatements[0].EndIndex, Is.EqualTo(38));

        // sanity check: 
        string go = text.Substring(36, 2);
        StringAssert.AreEqualIgnoringCase(sut.GoStatements[0].Text, go);

        Assert.That(sut.GoStatements[0].GoCount, Is.EqualTo(0));
        StringAssert.AreEqualIgnoringCase(sut.GoStatements[0].Text, "GO");
    }

    [Test]
    public void GoHandlers_Correctly_Allow_Spaces_On_Newline_Before_Go()
    {
        var sut = new Tokenizer("SELECT @@SERVERNAME [server_name];\r\n   GO");
        sut.Initialize();
        sut.Tokenize();

        Assert.That(sut.GoStatements.Count, Is.EqualTo(1));

        StringAssert.AreEqualIgnoringCase(sut.GoStatements[0].Text, "   GO");
    }

    [Test]
    public void GoHandlers_Correctly_Allow_Spaces_On_Newline_After_Go()
    {
        var sut = new Tokenizer("SELECT @@SERVERNAME [server_name];\r\n   GO   ");
        sut.Initialize();
        sut.Tokenize();

        Assert.That(sut.GoStatements.Count, Is.EqualTo(1));
        StringAssert.AreEqualIgnoringCase(sut.GoStatements[0].Text, "   GO");
    }

    [Test]
    public void GoHandlers_Correctly_Allow_Tabs_On_Newline_Before_Go()
    {
        var sut = new Tokenizer("SELECT @@SERVERNAME [server_name];\r\n\t GO");
        sut.Initialize();
        sut.Tokenize();

        Assert.That(sut.GoStatements.Count, Is.EqualTo(1));

        StringAssert.AreEqualIgnoringCase(sut.GoStatements[0].Text, "\t GO");
    }

    [Test]
    public void GoHandlers_Correctly_Allow_Eol_Comments_After_Go()
    {
        var sut = new Tokenizer("SELECT @@SERVERNAME [server_name];\r\n  GO -- with some comment here...");
        sut.Initialize();
        sut.Tokenize();

        Assert.That(sut.GoStatements.Count, Is.EqualTo(1));

        StringAssert.AreEqualIgnoringCase(sut.GoStatements[0].Text, "  GO");
    }

    [Test]
    public void GoHandlers_Capture_Simple_Go_With_Numbers()
    {
        var sut = new Tokenizer("CHECKPOINT;\r\nGo   32 -- and a comment");
        sut.Initialize();
        sut.Tokenize();

        Assert.That(sut.GoStatements.Count, Is.EqualTo(1));

        StringAssert.AreEqualIgnoringCase(sut.GoStatements[0].Text, "Go   32");
        Assert.That(sut.GoStatements[0].GoCount, Is.EqualTo(32));
    }

    [Test]
    public void GoHandlers_Correctly_Allow_EolComments_Touching_Go()
    {
        var sut = new Tokenizer("SELECT @@SERVERNAME [server_name];\r\n  GO-- this comment is dumb - but legit");
        sut.Initialize();
        sut.Tokenize();

        Assert.That(sut.GoStatements.Count, Is.EqualTo(1));

        StringAssert.AreEqualIgnoringCase(sut.GoStatements[0].Text, "  GO");
    }

    [Test]
    public void GoHandlers_Correctly_Allow_Numbers_Touching_Go()
    {
        var sut = new Tokenizer("CHECKPOINT;\r\nGO3\r\nCHECKPOINT;\r\nGO2\r\nSELECT @@SERVERNAME\r\nGO");
        sut.Initialize();
        sut.Tokenize();

        Assert.That(sut.GoStatements.Count, Is.EqualTo(3));

        StringAssert.AreEqualIgnoringCase(sut.GoStatements[0].Text, "GO3");
        Assert.That(sut.GoStatements[0].GoCount, Is.EqualTo(3));

        StringAssert.AreEqualIgnoringCase(sut.GoStatements[1].Text, "GO2");
        Assert.That(sut.GoStatements[1].GoCount, Is.EqualTo(2));

        StringAssert.AreEqualIgnoringCase(sut.GoStatements[2].Text, "GO");
        Assert.That(sut.GoStatements[2].GoCount, Is.EqualTo(0));
    }

    [Test]
    public void GoHandlers_Ignore_Go_Statements_Within_Block_Comments()
    {
        var sut = new Tokenizer("/*\r\n\r\nSELECT @@SERVERNAME; \r\nGO \r\n\r\n*/\r\n\r\nSELECT @@VERSION;");
        sut.Initialize();
        sut.Tokenize();

        Assert.That(sut.GoStatements.Count, Is.EqualTo(0));
        Assert.That(sut.BlockComments.Count, Is.EqualTo(1));
    }

    [Test]
    public void GoHandlers_Ignore_Go_Statements_Within_Strings()
    {
        // still not sure why you'd put a "GO" inside of a 'string'... but... don't want it to cause problems IF someone does: 
        var sut = new Tokenizer("DECLARE @text nvarchar(MAX) = N'/*\r\n\r\nSELECT @@SERVERNAME; \r\nGO \r\n\r\n*/';\r\n\r\nSELECT @@VERSION;\r\nGO");

        sut.Initialize();
        sut.Tokenize();

        Assert.That(sut.GoStatements.Count, Is.EqualTo(1));
        Assert.That(sut.Strings.Count, Is.EqualTo(1));
    }

    // what other edge cases are there? 
}