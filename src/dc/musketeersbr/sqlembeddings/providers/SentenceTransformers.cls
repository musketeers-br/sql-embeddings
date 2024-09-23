Class dc.musketeersbr.sqlembeddings.providers.SentenceTransformers Extends ProviderAbstract
{

/// Loads an ebedding model from the given model name.
/// 
/// @param modelName The name of the model to be loaded.
/// @return The loaded model as a %SYS.Python object.
ClassMethod LoadEmbeddingModel(modelName As %String) As %SYS.Python [ Language = python ]
{
    import sentence_transformers

    model = sentence_transformers.SentenceTransformer(modelName)
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
ClassMethod ExecuteEmbeddings(data As %String, model As %SYS.Python) As %String [ Language = python ]
{
    embeddings = model.encode(data)
    embeddings_list = [str(embedding.tolist()) for embedding in embeddings]
    return str(embeddings_list)
}

}
