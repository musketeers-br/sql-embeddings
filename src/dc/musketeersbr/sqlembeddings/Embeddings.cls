Class dc.musketeersbr.sqlembeddings.Embeddings Extends %RegisteredObject
{

ClassMethod GetEmbeddingsProvider(providerName As %String) As %String
{
    If providerName = "sentence_transformers" {
        Return "dc.musketeersbr.sqlembeddings.providers.SentenceTransformers"
    } ElseIf providerName = "fastembed" {
        Return "dc.musketeersbr.sqlembeddings.providers.FastEmbed"
    } ElseIf providerName = "openai" {
        Return "dc.musketeersbr.sqlembeddings.providers.OpenAI"
    } ElseIf providerName = "langchain" {
        Return "dc.musketeersbr.sqlembeddings.providers.FakeEmbeddings"
    } Else {
        Throw ##class(%Exception.General).%New("Invalid provider name")
    }
}

}
