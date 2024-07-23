namespace PSI.Models.Tests.unit_tests;

public class CommandTests
{
    #region Test Strings

    public const string SIMPLE_OPERATION_WITH_NO_GO_STATEMENTS = @"IF EXISTS(SELECT NULL FROM someTable WHERE something = N'Something Else') BEGIN
    PRINT 'doing stuff';
END;

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
END;";

    public const string SIMPLE_OPERATION_WITH_GO_AT_END = @"IF EXISTS(SELECT NULL FROM someTable WHERE something = N'Something Else') BEGIN
    PRINT 'doing stuff';
END;

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
GO";

    public const string SIMPLE_STATEMENT_WITH_TWO_BATCHES = @"IF EXISTS(SELECT NULL FROM someTable WHERE something = N'Something Else') BEGIN
    SELECT N'Here is a 
go
But it is in comments';  -- and there's a GO in the 'string' as well. 
END;
GO


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
GO";
    #endregion

    [Test]
    public void Command_Does_Not_Split_Batches_Without_GO_Statements()
    {
        var commandText = SIMPLE_OPERATION_WITH_NO_GO_STATEMENTS;

        var sut = Command.FromQuery(commandText, ResultType.PsiObject);
        var batches = sut.GetBatchedCommands();

        Assert.That(batches.Count, Is.EqualTo(1));
    }

    [Test]
    public void Command_Removes_Final_GO_Statement_In_Query()
    {
        var commandText = SIMPLE_OPERATION_WITH_GO_AT_END;

        var sut = Command.FromQuery(commandText, ResultType.PsiObject);
        var batches = sut.GetBatchedCommands();

        Assert.That(batches.Count, Is.EqualTo(1));
        StringAssert.DoesNotEndWith(@"GO", batches[0].BatchCommand.BatchText);
    }

    [Test]
    public void Command_Splits_Batches_On_GO_Statements()
    {
        var commandText = SIMPLE_STATEMENT_WITH_TWO_BATCHES;

        var sut = Command.FromQuery(commandText, ResultType.PsiObject);
        var batches = sut.GetBatchedCommands();

        Assert.That(batches.Count, Is.EqualTo(2));
    }
}