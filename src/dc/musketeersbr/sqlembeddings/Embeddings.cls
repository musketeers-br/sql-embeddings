Class dc.musketeersbr.sqlembeddings.Embeddings Extends %RegisteredObject
{

ClassMethod GetEmbeddingsProvider(providerName As %String) As %String
{
    Do ##class(dc.musketeersbr.sqlembeddings.Logger).Debug("GetEmbeddingsProvider: "_providerName)
    If providerName = "sentence_transformers" {
        Return "dc.musketeersbr.sqlembeddings.providers.SentenceTransformers"
    } ElseIf providerName = "fastembed" {
        Return "dc.musketeersbr.sqlembeddings.providers.FastEmbed"
    } ElseIf providerName = "openai" {
        Return "dc.musketeersbr.sqlembeddings.providers.OpenAI"
    } ElseIf providerName = "langchain" {
        Return "dc.musketeersbr.sqlembeddings.providers.FakeEmbeddings"
    } ElseIf providerName = "spacy" {
        Return "dc.musketeersbr.sqlembeddings.providers.SpaCy"
    } Else {
        Throw ##class(%Exception.General).%New("Invalid provider name")
    }
}

}
