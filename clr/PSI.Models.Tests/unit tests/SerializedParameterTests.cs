namespace PSI.Models.Tests.unit_tests;

public class SerializedParameterTests
{
    [Test]
    public void Simple_Parameter_String_Is_Split_On_At_Sign()
    {
        var serialized = "@p1 int = 12, @p2 sysname = 'the big brown bear', @p12 varchar(50) = 'this is ascii text vs unicode'";
        var sut = ParameterSet.ParameterSetFromSerializedInput(serialized, "_DEFAULT");

        Assert.That(sut.Parameters.Count, Is.EqualTo(3));
    }

    [Test]
    public void Simple_Parameter_String_Correctly_Maps_Parameter_Name()
    {
        var serialized = "@p1 int = 12, @p2 sysname = 'the big brown bear', @p12 varchar(50) = 'this is ascii text vs unicode'";
        var sut = ParameterSet.ParameterSetFromSerializedInput(serialized, "_DEFAULT");

        Assert.That(sut.Parameters.Count, Is.EqualTo(3));

        StringAssert.AreEqualIgnoringCase("@p1", sut.Parameters[0].Name);
        StringAssert.AreEqualIgnoringCase("@p2", sut.Parameters[1].Name);
        StringAssert.AreEqualIgnoringCase("@p12", sut.Parameters[2].Name);
    }

    [Test]
    public void Simple_Parameter_String_Correctly_Maps_Parameter_Types()
    {
        var serialized = "@p1 int = 12, @p2 sysname = 'the big brown bear', @p12 varchar(50) = 'this is ascii text vs unicode'";
        var sut = ParameterSet.ParameterSetFromSerializedInput(serialized, "_DEFAULT");

        Assert.That(sut.Parameters.Count, Is.EqualTo(3));

        Assert.That(sut.Parameters[0].DataType, Is.EqualTo(DataType.Int));
        Assert.That(sut.Parameters[1].DataType, Is.EqualTo(DataType.Sysname));
        Assert.That(sut.Parameters[2].DataType, Is.EqualTo(DataType.Varchar));
    }

    [Test]
    public void Simple_Parameter_String_Correctly_Maps_Parameter_Sizes()
    {
        var serialized = "@p1 int = 12, @p2 sysname = 'the big brown bear', @p12 varchar(50) = 'this is ascii text vs unicode'";
        var sut = ParameterSet.ParameterSetFromSerializedInput(serialized, "_DEFAULT");

        Assert.That(sut.Parameters.Count, Is.EqualTo(3));
        Assert.That(sut.Parameters[2].Size, Is.EqualTo(50));
    }

    [Test]
    public void Simple_Parameter_String_Correctly_Maps_Parameter_Values()
    {
        var serialized = "@p1 int = 12, @p2 sysname = 'the big brown bear', @p12 varchar(50) = 'this is ascii text vs unicode'";
        var sut = ParameterSet.ParameterSetFromSerializedInput(serialized, "_DEFAULT");

        Assert.That(sut.Parameters.Count, Is.EqualTo(3));

        Assert.That(sut.Parameters[0].Value, Is.EqualTo(12));
        StringAssert.AreEqualIgnoringCase("'the big brown bear'", sut.Parameters[1].Value.ToString());
        StringAssert.AreEqualIgnoringCase("'this is ascii text vs unicode'", sut.Parameters[2].Value.ToString());
    }

    // next: 
    //  @ within 'strings' is ignored (Doesn't split into a different spot). 
    //  strings can be ESCAPED - e.g., @p3 sysname = 'that''s what I said!' - should be fine. 
    //  strings can be nested - e.g., @p3 sysname = 'this is ''tricky'' and stuff' - should be fine. 

    // OUTPUTs i.e., make sure I can detect OUTPUT and INPUT/OUTPUT. 
    // RETURN. Make sure I can detect/map RETURN params.
}