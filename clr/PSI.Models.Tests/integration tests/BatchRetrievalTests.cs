namespace PSI.Models.Tests.integration_tests;

public class BatchRetrievalTests
{
    [Test]
    public void GetTokenizedBatches_Returns_Simple_Batches()
    {
        var sut = new Tokenizer(
            "SELECT TOP 200 * FROM sys.objects;\r\nGO\r\nUSE [admindb];\r\nGO\r\nSELECT * FROM dbo.[numbers];\r\nGO");
        sut.Initialize();
        sut.Tokenize();

        Assert.That(sut.GoStatements.Count, Is.EqualTo(3));

        var batches = sut.GetParsedBatches();
        Assert.That(batches.Count, Is.EqualTo(3));

        StringAssert.AreEqualIgnoringCase("SELECT TOP 200 * FROM sys.objects;", batches[0].BatchText);
        StringAssert.AreEqualIgnoringCase("USE [admindb];", batches[1].BatchText);
        StringAssert.AreEqualIgnoringCase("SELECT * FROM dbo.[numbers];", batches[2].BatchText);
    }

    [Test]
    public void GetTokenizedBatches_Returns_Trailing_Batches()
    {
        var text = "SELECT * FROM sys.server_principals;\r\nGO\r\n\r\nSELECT @@SERVERNAME [server_name];\r\nGO";
        var sut = new Tokenizer(text);
        sut.Initialize();
        sut.Tokenize();

        // Expect 2x GO statements, and 2x batches:
        Assert.That(sut.GoStatements.Count, Is.EqualTo(2));

        var batches = sut.GetParsedBatches();
        Assert.That(batches.Count, Is.EqualTo(2));

        StringAssert.AreEqualIgnoringCase(text, batches[0].TextSources.OriginalCommand);
        StringAssert.AreEqualIgnoringCase(text, batches[1].TextSources.OriginalCommand);

        StringAssert.AreEqualIgnoringCase("SELECT * FROM sys.server_principals;\r\nGO",
            batches[0].TextSources.OriginalBatch);
        StringAssert.AreEqualIgnoringCase("\r\n\r\nSELECT @@SERVERNAME [server_name];\r\nGO",
            batches[1].TextSources.OriginalBatch);

        // sanity check: 
        Assert.That(batches[0].StartIndex, Is.EqualTo(0));
        Assert.That(batches[0].EndIndex, Is.EqualTo(40));
        StringAssert.AreEqualIgnoringCase(text.Substring(0, 40 - 0), batches[0].TextSources.OriginalBatch);

        Assert.That(batches[1].StartIndex, Is.EqualTo(40));
        Assert.That(batches[1].EndIndex, Is.EqualTo(82));
        StringAssert.AreEqualIgnoringCase(text.Substring(40, 82 - 40), batches[1].TextSources.OriginalBatch);

        StringAssert.AreEqualIgnoringCase("SELECT * FROM sys.server_principals;", batches[0].BatchText);
        StringAssert.AreEqualIgnoringCase("SELECT @@SERVERNAME [server_name];", batches[1].BatchText);
    }

    [Test]
    public void GetTokenizedBatches_Returns_Source_Text()
    {
        string text =
            "SELECT TOP 200 * FROM sys.objects;\r\nGO\r\nUSE [admindb];\r\nGO\r\nSELECT * FROM dbo.[numbers];\r\nGO";
        var sut = new Tokenizer(text);
        sut.Initialize();
        sut.Tokenize();

        var batches = sut.GetParsedBatches();
        Assert.That(batches.Count, Is.EqualTo(3));

        StringAssert.AreEqualIgnoringCase(text, batches[0].TextSources.OriginalCommand);
        StringAssert.AreEqualIgnoringCase("SELECT TOP 200 * FROM sys.objects;\r\nGO",
            batches[0].TextSources.OriginalBatch);

        // sanity check: 
        Assert.That(batches[0].StartIndex, Is.EqualTo(0));
        Assert.That(batches[0].EndIndex, Is.EqualTo(38));

        StringAssert.AreEqualIgnoringCase(text.Substring(0, 38 - 0), batches[0].TextSources.OriginalBatch);

        // resume checks:
        StringAssert.AreEqualIgnoringCase(text, batches[1].TextSources.OriginalCommand);
        StringAssert.AreEqualIgnoringCase("\r\nUSE [admindb];\r\nGO", batches[1].TextSources.OriginalBatch);

        StringAssert.AreEqualIgnoringCase(text, batches[2].TextSources.OriginalCommand);
        StringAssert.AreEqualIgnoringCase("\r\nSELECT * FROM dbo.[numbers];\r\nGO",
            batches[2].TextSources.OriginalBatch);
    }

    [Test]
    public void GetTokenizedBatches_Splits_Correctly_Without_A_Terminating_Go_Statement()
    {
        var text = "SELECT @@SERVERNAME [server_name];\r\nGO\r\nUSE admindb;\r\nSELECT TOP 200 * FROM dbo.number;\r\n";
        var sut = new Tokenizer(text);
        sut.Initialize();
        sut.Tokenize();

        // EXPECT only 1x "GO", but 2x full-on batches:
        Assert.That(sut.GoStatements.Count, Is.EqualTo(1));
        var batches = sut.GetParsedBatches(true);
        Assert.That(batches.Count, Is.EqualTo(2));

        StringAssert.AreEqualIgnoringCase(text, batches[0].TextSources.OriginalCommand);
        StringAssert.AreEqualIgnoringCase("SELECT @@SERVERNAME [server_name];\r\nGO",
            batches[0].TextSources.OriginalBatch);
        StringAssert.AreEqualIgnoringCase("SELECT @@SERVERNAME [server_name];", batches[0].BatchText);


        StringAssert.AreEqualIgnoringCase(text, batches[1].TextSources.OriginalCommand);
        StringAssert.AreEqualIgnoringCase("\r\nUSE admindb;\r\nSELECT TOP 200 * FROM dbo.number;\r\n",
            batches[1].TextSources.OriginalBatch);
        StringAssert.AreEqualIgnoringCase("USE admindb;\r\nSELECT TOP 200 * FROM dbo.number;", batches[1].BatchText);
    }

    [Test]
    public void GetTokenizedBatches_Processes_Comments_Without_Problems()
    {
        var sut = new Tokenizer("USE [admindb];-- even a comment\r\nGO\r\nSELECT * FROM dbo.[numbers];\r\nGO");
        sut.Initialize();
        sut.Tokenize();

        Assert.That(sut.GoStatements.Count, Is.EqualTo(2));

        var batches = sut.GetParsedBatches(true);
        Assert.That(batches.Count, Is.EqualTo(1));
        StringAssert.AreEqualIgnoringCase("USE [admindb];-- even a comment\r\n  \r\nSELECT * FROM dbo.[numbers];",
            batches[0].BatchText);
    }

    [Test]
    public void GetTokenizedBatches_Returns_Comments_As_Collection()
    {
        var text = "USE [admindb]; -- comment here\r\nGO\r\nSELECT * FROM dbo.[numbers];\r\nGO";
        var sut = new Tokenizer(text);
        sut.Initialize();
        sut.Tokenize();

        Assert.That(sut.GoStatements.Count, Is.EqualTo(2));
        var batches = sut.GetParsedBatches(true);
        Assert.That(batches.Count, Is.EqualTo(1));

        Assert.That(batches[0].Comments.Count, Is.EqualTo(1));

        // sanity check vs new offsets/indexes: 
        Assert.That(batches[0].Comments[0].StartIndex, Is.EqualTo(15));
        Assert.That(batches[0].Comments[0].EndIndex, Is.EqualTo(30));

        StringAssert.AreEqualIgnoringCase("-- comment here", batches[0].Comments[0].Text);
    }

    [Test]
    public void GetTokenizedBatches_Returns_BlockComments_As_Collection()
    {
        var text = "/* Some \r\n multi-line comments with a \r\n\r\nUSE [master]\r\nGO\r\n\r\n nested inside*/USE [admindb]; /* more\r\ncomments\r\nhere*/\r\nGO\r\nSELECT * FROM dbo.[numbers];\r\nGO";
        var sut = new Tokenizer(text);
        sut.Initialize();
        sut.Tokenize();

        Assert.That(sut.GoStatements.Count, Is.EqualTo(2));

        var batches = sut.GetParsedBatches(true);
        Assert.That(batches.Count, Is.EqualTo(1));

        Assert.That(batches[0].BlockComments.Count, Is.EqualTo(2));

        // sanity check
        Assert.That(batches[0].BlockComments[0].StartIndex, Is.EqualTo(0));
        Assert.That(batches[0].BlockComments[0].EndIndex, Is.EqualTo(78));

        StringAssert.AreEqualIgnoringCase("/* Some \r\n multi-line comments with a \r\n\r\nUSE [master]\r\nGO\r\n\r\n nested inside*/", text.Substring(0, 78 - 0));
        StringAssert.AreEqualIgnoringCase("/* Some \r\n multi-line comments with a \r\n\r\nUSE [master]\r\nGO\r\n\r\n nested inside*/", batches[0].BlockComments[0].Text);

        StringAssert.AreEqualIgnoringCase("/* more\r\ncomments\r\nhere*/", batches[0].BlockComments[1].Text);
    }

    [Test]
    public void GetTokenizedBatches_Remove_UseOnly_Does_Not_Break_Normal_Batches()
    {
        var sut = new Tokenizer("SELECT @@SERVERNAME [server_name];\r\nGO\r\nUSE admindb;\r\nSELECT TOP 200 * FROM dbo.number;\r\nGO");
        sut.Initialize();
        sut.Tokenize();

        Assert.That(sut.GoStatements.Count, Is.EqualTo(2));

        var batches = sut.GetParsedBatches(true);
        Assert.That(batches.Count, Is.EqualTo(2));

        StringAssert.AreEqualIgnoringCase("SELECT @@SERVERNAME [server_name];", batches[0].BatchText);
        StringAssert.AreEqualIgnoringCase("USE admindb;\r\nSELECT TOP 200 * FROM dbo.number;", batches[1].BatchText);
    }

    [Test]
    public void GetTokenizedBatches_Handles_Multiple_UseOnly_Batches_And_Comments()
    {
        var text = "SELECT @@SERVERNAME [server];\r\nGO\r\n\r\nUSE [admindb]; -- comment here\r\nGO\r\nSELECT * FROM dbo.[numbers];\r\nGO\r\n USE master;\r\nGO\r\nSELECT TOP 200 * FROM sys.objects\r\nWHERE something = 2;";
        var sut = new Tokenizer(text);
        sut.Initialize();
        sut.Tokenize();

        var batches = sut.GetParsedBatches(true);
        Assert.That(batches.Count, Is.EqualTo(3));

        StringAssert.AreEqualIgnoringCase("SELECT @@SERVERNAME [server];", batches[0].BatchText);
        StringAssert.AreEqualIgnoringCase("USE [admindb]; -- comment here\r\n  \r\nSELECT * FROM dbo.[numbers];", batches[1].BatchText);
        StringAssert.AreEqualIgnoringCase("USE master;\r\n  \r\nSELECT TOP 200 * FROM sys.objects\r\nWHERE something = 2;", batches[2].BatchText);
    }

    [Test]
    public void GetTokenizedBatches_Does_Not_Lose_UseXxx_Go_At_Script_End()
    {
        var text = "USE [master];\r\nGO\r\nSELECT @@SERVERNAME;\r\nGO\r\nUSE [admindb];\r\nGO\r\n";
        var sut = new Tokenizer(text);
        sut.Initialize();
        sut.Tokenize();

        var batches = sut.GetParsedBatches(true);
        Assert.That(batches.Count, Is.EqualTo(2));

        StringAssert.AreEqualIgnoringCase("USE [master];\r\n  \r\nSELECT @@SERVERNAME;", batches[0].BatchText);
        StringAssert.AreEqualIgnoringCase("USE [admindb];", batches[1].BatchText); // technically a 'useless' batch ... but, it was a useless command too... 

        // sanity check (on offsets)
        Assert.That(batches[0].StartIndex, Is.EqualTo(0));
        Assert.That(batches[0].EndIndex, Is.EqualTo(41));
        StringAssert.AreEqualIgnoringCase(text.Substring(0, 41).Replace("GO", "  "), "USE [master];\r\n  \r\nSELECT @@SERVERNAME;\r\n");

        Assert.That(batches[1].StartIndex, Is.EqualTo(43));
        Assert.That(batches[1].EndIndex, Is.EqualTo(63));

        // TODO: this is technically a bit off... i.e., i THINK this should start at ... USE instead of \r\n
        StringAssert.AreEqualIgnoringCase(text.Substring(43, 63 - 43).Replace("GO", "  "), "\r\nUSE [admindb];\r\n  ");
    }

    [Test]
    public void GetTokenizedBatches_Removes_Blank_Batches()
    {
        // actual lines from tSQLt.database.sql - i.e., 2x 'bogus' GO statements. 
        var sut = new Tokenizer("DECLARE @Msg NVARCHAR(MAX);SELECT @Msg = 'Installed at '+CONVERT(NVARCHAR,GETDATE(),121);RAISERROR(@Msg,0,1);\r\nGO\r\n\r\n\r\nGO\r\n\r\n\r\n\r\nGO\r\n\r\nIF EXISTS (SELECT 1 FROM sys.assemblies WHERE name = 'tSQLtCLR')\r\n    DROP ASSEMBLY tSQLtCLR;\r\nGO");
        sut.Initialize();
        sut.Tokenize();

        var batches = sut.GetParsedBatches(true);
        Assert.That(batches.Count, Is.EqualTo(2));
    }
}