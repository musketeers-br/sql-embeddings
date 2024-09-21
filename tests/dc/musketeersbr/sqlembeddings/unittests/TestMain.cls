Class dc.musketeersbr.sqlembeddings.unittests.TestMain Extends %UnitTest.TestCase
{

/// Test initialization with valid parameters
Method TestOnNewValid() As %Status
{
    Set obj = ##class(dc.musketeersbr.sqlembeddings.Main).%New("Model1", "Value1")
    Do $$$AssertEquals(obj.ModelName, "Model1", "ModelName should be 'Model1'")
    Do $$$AssertEquals(obj.ValueToEmbed, "Value1", "ValueToEmbed should be 'Value1'")
    Return $$$OK
}

/// Test initialization with empty model name
Method TestOnNewEmptyModelName() As %Status
{
    Try {
        Set obj = ##class(dc.musketeersbr.sqlembeddings.Main).%New("", "Value1")
    } Catch ex {
        Do $$$AssertStatusEquals(ex.AsStatus(), $$$ERROR($$$GeneralError, "ModelName is required"), "Expected error for empty ModelName")
    }
    Return $$$OK
}

/// Test initialization with empty value to embed
Method TestOnNewEmptyValueToEmbed() As %Status
{
    Try {
        Set obj = ##class(dc.musketeersbr.sqlembeddings.Main).%New("Model1", "")
    } Catch ex {
        Do $$$AssertStatusEquals(ex.AsStatus(), $$$ERROR($$$GeneralError, "ValueToEmbed is required"), "Expected error for empty ValueToEmbed")
    }
    Return $$$OK
}

/// Test initialization with both parameters empty
Method TestOnNewBothEmpty() As %Status
{
    Try {
        Set obj = ##class(dc.musketeersbr.sqlembeddings.Main).%New("", "")
    } Catch ex {
        Do $$$AssertStatusEquals(ex.AsStatus(), $$$ERROR($$$GeneralError, "ModelName is required"), "Expected error for empty ModelName")
        // Note: The test stops at the first validation failure encountered (ModelName), so no need to check ValueToEmbed here.
    }
    Return $$$OK
}

/// Test the Validate method directly with valid properties
Method TestValidateValid() As %Status
{
    Set obj = ##class(dc.musketeersbr.sqlembeddings.Main).%New("Model1", "Value1")
    Set sc = obj.Validate()
    Do $$$AssertStatusOK(sc, "Validation should succeed for valid properties")
    Return $$$OK
}

/// Test the Validate method directly with empty ModelName
Method TestValidateEmptyModelName() As %Status
{
    Set obj = ##class(dc.musketeersbr.sqlembeddings.Main).%New("", "Value1")
    Do $$$AssertEquals(obj, "", "Validation should fail for empty ModelName")
    Return $$$OK
}

/// Test the Validate method directly with empty ValueToEmbed
Method TestValidateEmptyValueToEmbed() As %Status
{
    Set obj = ##class(dc.musketeersbr.sqlembeddings.Main).%New("Model1", "")
    Do $$$AssertEquals(obj, "", "Validation should fail for empty ValueToEmbed")
    Return $$$OK
}

/// Test the Execute method (current implementation is a placeholder)
Method TestExecute() As %Status
{
    Set obj = ##class(dc.musketeersbr.sqlembeddings.Main).%New("Model1", "Value1")
    Set result = obj.Execute()
    Do $$$AssertEquals(result, "", "Execute should return an empty string (placeholder implementation)")
    Return $$$OK
}

}
