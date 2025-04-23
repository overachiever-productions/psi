namespace PSI.Models.Tests.unit_tests;

public class CommentTests
{
    [Test]
    public void CommentHandlers_Capture_Simple_End_Of_Line_Comments()
    {
        var text = "SELECT 42 [answer]; -- witty comment here.\r\n";
        var sut = new Tokenizer(text);
        sut.Initialize();
        sut.Tokenize();

        Assert.That(sut.Comments.Count, Is.EqualTo(1));
        // NOTE: EOL comments do NOT include the CR, CRLF, or LF of at the 'end' of the line. Just the text.
        StringAssert.AreEqualIgnoringCase("-- witty comment here.", sut.Comments[0].Text);

        Assert.That(sut.Comments[0].StartIndex, Is.EqualTo(20));
        Assert.That(sut.Comments[0].EndIndex, Is.EqualTo(42));

        // sanity check: 
        string comment = text.Substring(20, 42 - 20);
        StringAssert.AreEqualIgnoringCase(sut.Comments[0].Text, comment);
    }

    [Test]
    public void CommentHandlers_Can_Handle_Comments_At_End_Of_String()
    {
        var sut = new Tokenizer("SELECT 42 [answer]; -- comment text");
        sut.Initialize();
        sut.Tokenize();

        Assert.That(sut.Comments.Count, Is.EqualTo(1));
    }

    [Test]
    public void CommentHandlers_Can_Capture_Multiple_Comments()
    {
        var sut = new Tokenizer("SELECT TOP 200 -- name, last_name\r\nfirst_name, last_name -- FROM users\r\nFROM dbo.super_users\r\n-- WHERE is_super_user = 1\r\nWHERE is_active = 1;");
        sut.Initialize();
        sut.Tokenize();

        Assert.That(sut.Comments.Count, Is.EqualTo(3));

        StringAssert.AreEqualIgnoringCase("-- name, last_name", sut.Comments[0].Text);
        StringAssert.AreEqualIgnoringCase("-- FROM users", sut.Comments[1].Text);
        StringAssert.AreEqualIgnoringCase("-- WHERE is_super_user = 1", sut.Comments[2].Text);
    }

    [Test]
    public void CommentHandlers_Can_Handle_CR_Only_NewLines()
    {
        var sut = new Tokenizer("SELECT @@SERVERNAME; -- comment here\rSELECT @@VERSION;");
        sut.Initialize();
        sut.Tokenize();

        Assert.That(sut.Comments.Count, Is.EqualTo(1));
        StringAssert.AreEqualIgnoringCase("-- comment here", sut.Comments[0].Text);
    }

    [Test]
    public void CommentHandlers_Can_Handle_LF_Only_NewLines()
    {
        var sut = new Tokenizer("SELECT @@SERVERNAME; -- comment here\nSELECT @@VERSION;");
        sut.Initialize();
        sut.Tokenize();

        Assert.That(sut.Comments.Count, Is.EqualTo(1));
        StringAssert.AreEqualIgnoringCase("-- comment here", sut.Comments[0].Text);
    }

    [Test]
    public void CommentHandlers_Treat_Dashed_Lines_As_Single_Comment()
    {
        var sut = new Tokenizer("----------------------\r\n-- Flower Pot!\r\n-------------------------------");
        sut.Initialize();
        sut.Tokenize();

        Assert.That(sut.Comments.Count, Is.EqualTo(3));

        StringAssert.AreEqualIgnoringCase("-- Flower Pot!", sut.Comments[1].Text);
    }
}