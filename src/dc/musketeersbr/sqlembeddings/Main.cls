Class dc.musketeersbr.sqlembeddings.Main Extends %RegisteredObject
{

/// Property to store the model name.
Property ModelName As %String;

/// Property to store the value that needs to be embedded.
Property ValueToEmbed As %String;

/// Method to initialize the object with the provided model name and value to embed.
/// This method ensures that both properties are set and validated.
/// @param modelName The name of the model to be used.
/// @param valueToEmbed The value to be embedded.
/// @return Status of the operation (success or error).
Method %OnNew(valueToEmbed = "", modelName As %String = "") As %Status [ Private, ServerOnly = 1 ]
{
    Set ..ModelName = modelName
    Set ..ValueToEmbed = valueToEmbed

    // Call the validation method to ensure all properties are properly set
    Set sc = ..%OnValidateObject()
    If $$$ISERR(sc) {
        // Throw an exception if validation fails
        Throw ##class(%Exception.StatusException).CreateFromStatus(sc)
    }
    Return $$$OK
}

/// This method is called by the %Save() method to validate the object before saving it.
/// It checks that the ModelName and ValueToEmbed properties are not empty and that the ValueToEmbed property is a string.
/// If any of these conditions are not met, it sets the appropriate error message and returns an error status.
/// 
/// This method is private and should not be called directly.
/// 
/// @return %Status - The status of the validation. If the validation fails, this will contain an error message.
Method %OnValidateObject() As %Status [ Private, ServerOnly = 1 ]
{
    Set sc = ..Validate()
    Return sc
}

/// Method to validate that all required properties are set.
/// @return Status of the validation (success or error).
Method Validate() As %Status
{
    // Check if ModelName is not empty
    If ..ModelName = "" {
        Return $$$ERROR($$$GeneralError, "ModelName is required")
    }
    // Check if ValueToEmbed is not empty
    If ..ValueToEmbed = "" {
        Return $$$ERROR($$$GeneralError, "ValueToEmbed is required")
    }
    Return $$$OK
}

/// Placeholder method for executing an action with the embedded value.
/// Currently returns an empty vector.
/// @return An empty vector.
Method Execute() As %Vector
{
    Return ..GetEmbeddings(..ValueToEmbed)
}

/// Gets the embeddings for the given sentences using the socket client.
/// 
/// @param sentences The sentences to be embedded.
/// @return A vector of doubles representing the embeddings.
ClassMethod GetEmbeddings(sentences) As %Vector
{
    Set response = ##class(dc.musketeersbr.sqlembeddings.Socket).StartClient(sentences)
    /// Replace single quotes with nothing (todo: find out how to get only numbers)
    Set response = $REPLACE(response, "'", "")

    Set json = {}.%FromJSON(response)
    Set len = json.%Size()
    For i = 1:1:len {
        Set $vector(vector, i, "double") = json.%Get(i)
    }

    Return vector
}

}