/// https://github.com/qdrant/fastembed
Class dc.musketeersbr.sqlembeddings.providers.FastEmbed Extends ProviderAbstract
{

/// Loads an ebedding model from the given model name.
/// 
/// @param modelName The name of the model to be loaded.
/// @return The loaded model as a %SYS.Python object.
ClassMethod ExecuteLoadModel(modelName As %String = "BAAI/bge-small-en-v1.5") As %SYS.Python [ Language = python ]
{
    from fastembed import TextEmbedding

    model = TextEmbedding(model_name=modelName)
    return model
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
ClassMethod ExecuteEmbeddings(data As %String, model As %SYS.Python) As %String [ Language = python, Private ]
{
    documents = [data]
    embeddings_list = list(model.embed(documents))[0]
    embeddings_list = [embedding.tolist() for embedding in embeddings_list]
    return str(embeddings_list)
}

}
