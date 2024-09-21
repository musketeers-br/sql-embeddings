Class dc.musketeersbr.sqlembeddings.providers.ProviderAbstract Extends %RegisteredObject
{

/// Loads an ebedding model from the given model name.
/// 
/// @param modelName The name of the model to be loaded.
/// @return The loaded model as a %SYS.Python object.
ClassMethod LoadEmbeddingModel(modelName As %String) As %SYS.Python [ Abstract, Language = python ]
{
}

/// Executes the embeddings using the given model and data.
/// 
/// This method is a wrapper around the Hugging Face Transformers library and
/// is used to execute the embeddings using the given model and data.
/// 
/// Args:
///     data (str): The data to be embedded.
///     model: The model to be used for embeddings.
/// 
/// Returns:
///     str: The embeddings as a string.
ClassMethod ExecuteEmbeddings(data As %String, model As %SYS.Python) As %String [ Abstract, Language = python, Private ]
{
}

}
