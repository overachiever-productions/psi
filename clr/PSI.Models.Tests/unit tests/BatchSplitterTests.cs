using NuGet.Frameworks;

namespace PSI.Models.Tests.unit_tests;

public class BatchSplitterTests
{
	#region Test Strings
	public const string TEST_CASE_WITH_GO_IN_COMMENTS = @"/*
	SAMPLE header comments with a 
	GO 
	on a new line... 

*/

IF EXISTS(SELECT NULL FROM someTable WHERE something = N'Something Else') BEGIN
    SELECT N'Here is a 
GO  -- but do NOT break here - cuz in a string
But it is in comments';  -- and there's a GO in the 'string' as well. 
END;
GO -- break here


IF OBJECT_ID('dbo.settings','U') IS NULL BEGIN
	PRINT 'doing stuff here.';	
  END;
ELSE BEGIN 
	IF NOT EXISTS (SELECT NULL FROM sys.columns WHERE [object_id] = OBJECT_ID('dbo.settings') AND [name] = N'setting_id') BEGIN 
		BEGIN TRAN
			PRINT 'more stuff';
		COMMIT;

        IF OBJECT_ID(N'tempdb..#settings') IS NOT NULL 
            DROP TABLE [#settings];
	END;
END;
GO  -- and here (but... yeah)";

    public const string USE_XX_WITH_GO_ON_NEXT_LINE = @"  
USE [admindb];
GO

SELECT COUNT(*) FROM [someTable];
GO";

    public const string MULTIPLE_USE_XXX_IN_SINGLE_COMMAND = @"USE [admindb];   /* multi line comment here - to make sure that multi-line comments
can
and will
be ignored */
GO

IF OBJECT_ID(N'abc', N'U') IS NULL BEGIN 
    CREATE TABLE abc (id int);
END; 
GO

USE [admindb];  -- comment here - just for fun. 
GO 

IF OBJECT_ID(N'xyz', N'U') IS NULL BEGIN 
    CREATE TABLE xyz (id int);
END;
GO";

    public const string TWO_BATCHES_WITH_A_GOTO_DIRECTIVE = @"SELECT 'the comments after the GO below represent LEGAL syntax' [statement];
GO -- these comments are FINE / LEGAL. 


GOTO NextThingy;

NextThingy:
SELECT 'The GO below does not have ANY chars after it not even CRLF';
GO";
    #endregion

    [Test]
    public void BatchSplitter_Ignores_GO_In_BlockComments()
    {
        var command = TEST_CASE_WITH_GO_IN_COMMENTS;

        var sut = new BatchSplitter(command);
        var output = sut.SplitIntoBatches();

		Assert.That(output.Count, Is.EqualTo(3));

		StringAssert.StartsWith(@"/*", output[0].BatchText);
		StringAssert.StartsWith(@"-- break here", output[1].BatchText);
		StringAssert.AreEqualIgnoringCase(@"-- and here (but... yeah)", output[2].BatchText);
    }

    [Test]
    public void BatchSplitter_Replaces_Single_GO_Following_Use_XX_Directive()
    {
        var command = USE_XX_WITH_GO_ON_NEXT_LINE;

        var sut = new BatchSplitter(command);
        var output = sut.SplitIntoBatches();

        Assert.That(output.Count, Is.EqualTo(1));  // expect that we replaced the first GO.
    }

    [Test]
    public void BatchSplitter_Replaces_Multiple_GOs_Following_USE_Directives()
    {
        var command = MULTIPLE_USE_XXX_IN_SINGLE_COMMAND;

        var sut = new BatchSplitter(command);
        var output = sut.SplitIntoBatches();

        Assert.That(output.Count, Is.EqualTo(2));
    }

    [Test]
    public void BatchSplitter_Does_Not_Split_On_Goto_Syntax()
    {
        var command = TWO_BATCHES_WITH_A_GOTO_DIRECTIVE;

        var sut = new BatchSplitter(command);
        var output = sut.SplitIntoBatches();

        Assert.That(output.Count, Is.EqualTo(2));
    }
}