namespace PSI.Models.Tests.unit_tests;

public class StringTests
{
    [Test]
    public void StringHandlers_Identify_Very_Simple_String()
    {
        var sut = new Tokenizer("This has a 'string' in it.");
        sut.Initialize();
        sut.Tokenize();

        Assert.That(sut.CodeLines.Count, Is.EqualTo(1));

        Assert.That(sut.Strings.Count, Is.EqualTo(1));
        Assert.That(sut.Strings[0].StartIndex, Is.EqualTo(11));
        Assert.That(sut.Strings[0].EndIndex, Is.EqualTo(18));

        StringAssert.AreEqualIgnoringCase("'string'", sut.Strings[0].Text);
    }

    [Test]
    public void StringHandlers_Identify_Ascii_String_As_Ascii()
    {
        var sut = new Tokenizer("This is 'ascii'.");
        sut.Initialize();
        sut.Tokenize();

        Assert.That(sut.Strings.Count, Is.EqualTo(1));
        Assert.That(sut.Strings[0].IsUnicode, Is.False);
    }

    [Test]
    public void StringHandlers_Identify_Unicode_String_As_Unicode()
    {
        var sut = new Tokenizer("This is not N'ascii'.");
        sut.Initialize();
        sut.Tokenize();

        Assert.That(sut.Strings.Count, Is.EqualTo(1));
        Assert.That(sut.Strings[0].IsUnicode, Is.True);
    }

    [Test]
    public void StringHandlers_Identify_Strings_Spanning_Multiple_Lines()
    {
        var sut = new Tokenizer("SELECT 'This \r\nstring spans\r\nmultiple lines' [test_case];");
        sut.Initialize();
        sut.Tokenize();

        Assert.That(sut.Strings.Count, Is.EqualTo(1));
        Assert.That(sut.Strings[0].IsUnicode, Is.False);

        StringAssert.AreEqualIgnoringCase("'This \r\nstring spans\r\nmultiple lines'", sut.Strings[0].Text);
    }

    [Test]
    public void StringHandlers_Identify_Multiple_Strings_In_Single_Line()
    {
        var sut = new Tokenizer("SELECT 'Simple String' as [test1], N'unicode' [test2];");
        sut.Initialize();
        sut.Tokenize();

        Assert.That(sut.Strings.Count, Is.EqualTo(2));
    }

    [Test]
    public void StringHandlers_Identify_Multiple_Strings_Across_Many_Lines()
    {
        var sut = new Tokenizer("SELECT 'This \r\nstring spans\r\nmultiple lines' [test_case], N'And another string\r\ntoo' [test_case2], N'test 3' [single_line_test];");
        sut.Initialize();
        sut.Tokenize();

        Assert.That(sut.Strings.Count, Is.EqualTo(3));
        Assert.That(sut.Strings[0].IsUnicode, Is.False);
        Assert.That(sut.Strings[1].IsUnicode, Is.True);
        Assert.That(sut.Strings[2].IsUnicode, Is.True);

        StringAssert.AreEqualIgnoringCase("'This \r\nstring spans\r\nmultiple lines'", sut.Strings[0].Text);
        StringAssert.AreEqualIgnoringCase("N'And another string\r\ntoo'", sut.Strings[1].Text);
        StringAssert.AreEqualIgnoringCase("N'test 3'", sut.Strings[2].Text);
    }

    [Test]
    public void StringHandlers_Identify_Strings_At_End_Of_Text()
    {
        var sut = new Tokenizer("SELECT 'this is a simple string.'");
        sut.Initialize();
        sut.Tokenize();

        Assert.That(sut.Strings.Count, Is.EqualTo(1));
        StringAssert.AreEqualIgnoringCase("'this is a simple string.'", sut.Strings[0].Text);
    }

    [Test]
    public void StringHandlers_Can_Handle_Simple_Escaped_Tick()
    {
        var sut = new Tokenizer("SELECT 'There''s a tick in here.'");
        sut.Initialize();
        sut.Tokenize();

        Assert.That(sut.Strings.Count, Is.EqualTo(1));
        StringAssert.AreEqualIgnoringCase("'There''s a tick in here.'", sut.Strings[0].Text);
    }

    [Test]
    public void StringHandlers_Can_Handle_Escaped_Strings()
    {
        var sut = new Tokenizer("SELECT 'This has a ''nested string'' in it.'");
        sut.Initialize();
        sut.Tokenize();

        Assert.That(sut.Strings.Count, Is.EqualTo(1));
        StringAssert.AreEqualIgnoringCase("'This has a ''nested string'' in it.'", sut.Strings[0].Text);
    }

    [Test]
    public void StringHandlers_Can_Handle_Nesting_And_Other_Strings()
    {
        var sut = new Tokenizer("SELECT 'This \r\nstring spans\r\nmultiple lines' [test_case], N'So does this string but ''with\r\nnested'' ticks' [test_case2], N'test 3' [single_line_test];");
        sut.Initialize();
        sut.Tokenize();

        Assert.That(sut.Strings.Count, Is.EqualTo(3));

        StringAssert.AreEqualIgnoringCase("'This \r\nstring spans\r\nmultiple lines'", sut.Strings[0].Text);
        StringAssert.AreEqualIgnoringCase("N'So does this string but ''with\r\nnested'' ticks'", sut.Strings[1].Text);
        StringAssert.AreEqualIgnoringCase("N'test 3'", sut.Strings[2].Text);
    }

    [Test]
    public void StringHandlers_Throw_Exception_On_Non_Completed_String()
    {
        var sut = new Tokenizer("SELECT 'This has a bad string in it");
        sut.Initialize();

        Assert.Throws<SyntaxException>(sut.Tokenize);
    }


    // with -- and 'string' in the comments. but ... don't break the line. 
    //          i.e., think it's as simple as adding a new EolCommentStatus ... and IF tokenizer.EolStatus <> None ... then ignore... 

    // with the OTHER scenario I had a problem with (that caused this shit-show detour in the first place).
}