 [![Gitter](https://img.shields.io/badge/Available%20on-Intersystems%20Open%20Exchange-00b2a9.svg)](https://openexchange.intersystems.com/package/sql-embedding)
 [![Quality Gate Status](https://community.objectscriptquality.com/api/project_badges/measure?project=intersystems_iris_community__sql-embeddings&metric=alert_status)](https://community.objectscriptquality.com/dashboard?id=intersystems_iris_community__sql-embeddings&metric=alert_status)
 [![Reliability Rating](https://community.objectscriptquality.com/api/project_badges/measure?project=intersystems_iris_community__sql-embeddings&metric=reliability_rating)](https://community.objectscriptquality.com/dashboard?id=intersystems_iris_community__sql-embeddings&metric=reliability_rating)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat&logo=AdGuard)](LICENSE)

# SQL-Embedding

## Motivation
*SQL-Embedding* is a versatile solution that simplifies the process of creating and utilizing embeddings for vector search directly within SQL queries. By providing a unified interface, you can seamlessly access a wide range of embedding models, enabling efficient and effective vector search operations.

### Key Features
* Simplified Embedding Creation: Easily generate embeddings from your data within SQL queries.
* Diverse Model Support: Access a variety of embedding models to suit your specific needs.
* Efficient Vector Search: Perform fast and accurate vector searches directly in your SQL database.

## Prerequisites

Make sure you have [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) and [Docker desktop](https://www.docker.com/products/docker-desktop) installed.

## Online demo

> **Note, due instability reasons when downloading models that we can't figure out why, some models are disabled by default. Thus, only the model langchain/fake-provider is available in the demo.** Our apologies for this.

To access the demo, go to [SQL Portal](https://sql-embeddings.demo.community.intersystems.com/csp/sys/exp/%25CSP.UI.Portal.SQL.Home.zen?$NAMESPACE=IRISAPP).

Then use the following SQL query to generate an embedding for the word 'test':

```sql
select dc.embedding('test', 'langchain/fake-provider')
```

```sql
-- table with two vector columns to store the embeddings
-- pay attention to the vectors dimensions, they must be the same as the model used
create table testtable(
    document varchar(1024),         -- the text to be embedded
    embeddings vector(double, 384)  -- store fastembed embeddings using its model bge-small-en-v1.5
)
```

```sql
insert into testtable (
    document, 
    embeddings
) values (
    'my text', 
    dc.embedding('my text', 'langchain/fake-provider')
)
```

```sql
-- show the results
select * from testtable
```

```sql
-- using VECTOR_DOT_PRODUCT function on the generated embeddings and ad-hoc embeddings
select 
    VECTOR_DOT_PRODUCT(
        embeddings, 
        dc.embedding('my text', 'langchain/fake-provider')
    )  
from testtable
```

## Installation 

### Setting an API key

If you're planning to use an online embeddings service, you'll need an API key. Currently, the project supports OpenAI's Embeddings service.

[Obtain your OpenAI API key by creating an account on their platform](https://openai.com/).

#### Configuring Environment Variables:

Environment variables are used to store sensitive information like API keys and tokens. These variables need to be set before building the Docker image.

There are two ways to configure these variables:

When launching the Docker container, you can set the `OPENAI_API_KEY` the environment variables on a dotenv file using the -e flag:

```bash
# OpenAI API key
export OPENAI_API_KEY=$OPENAI_API_KEY
```

### Supported embedding models

Currently, the project supports the following embeddings models/services, here called providers:

| Provider ID | Provider supported models |
|-------------|----------------------|
| fastembed | [FastEmbed](https://qdrant.github.io/fastembed/examples/Supported_Models/#supported-text-embedding-models) |
| openai | [OpenAI](https://platform.openai.com/docs/models/embeddings) |
| sentence_transformers | [Sentence Transformers](https://sbert.net/docs/sentence_transformer/pretrained_models.html#original-models) |
| langchain | [Langchain (just fake emebeddings for testing purposes)](https://python.langchain.com/docs/integrations/text_embedding/fake/) |

By default, the project will use FastEmbed embeddings model. It's free and you don't need an API key to use it.

### IPM

Open IRIS installation with IPM client installed. Call in any namespace:

```objectscript
USER>zpm "install sql-embeddings"

```

Or call the following for installing programmatically:

```objectscript
set sc=$zpm("install sql-embeddings")
```

Note that you'll need to install the libraries manually. If you don't, you'll get an error when you try to use the `dc.embedding` function.

To use custom models like spaCy, run the following commands in the IRIS terminal:

```bash
$ docker-compose exec iris iris session iris -U IRISAPP
```

Execute the commands to install spaCy and download the specified model:

```objectscript
USER> !pip3 install spacy
USER> !pip3 install https://github.com/explosion/spacy-models/releases/download/en_core_web_md-3.7.1/en_core_web_md-3.7.1-py3-none-any.whl
```

### Docker

For your convenience, the project uses [Docker Compose](https://docs.docker.com/compose/) to build and run the containers.

Note that in the case of SentenceTransformers, you'll need to install the SentenceTransformers library manually, since this library is big and takes a long time to install making the build process slow.

Clone/git pull the repo into any local directory

```
$ git clone https://github.com/musketeers-br/sql-embeddings
```

Open the terminal in this directory and run:

```
$ docker-compose build

$ docker-compose up -d
```

## Usage

```sql
dc.embedding('<text>', '<provider>/<modelName>')
```

## Examples
To get started, you can use the following SQL query to generate an embedding for the word 'test':

```sql
-- using the default embedding provider/model to get the embeddings vector
select dc.embedding('test')
```

The following a more complex examples that creates a table to store the embeddings, generate and insert embeddings, query the table and show the results and get the similarity between 'my text' and 'lorem ipsum': 

```sql
-- table with two vector columns to store the embeddings
-- pay attention to the vectors dimensions, they must be the same as the model used
create table testvector(
    document varchar(1024),                     -- the text to be embedded
    embFastEmbedModel1 vector(double, 384),     -- store fastembed embeddings using its model bge-small-en-v1.5
    embFastEmbedModel2 vector(double, 384),     -- store fastembed embeddings using its model jina-embeddings-v2-small-en
    embOpenAI vector(double, 1536)              -- store openai embeddings
)
```

```sql
insert into testvector (
    document, 
    embFastEmbedModel1, 
    embFastEmbedModel2, 
    embOpenAI
) values (
    'my text', 
    -- get the fastembed embeddings using the BAAI/bge-small-en-v1.5 model
    dc.embedding('my text', 'fastembed/BAAI/bge-small-en-v1.5'), 
    -- get the fastembed embeddings using another model (jinaai/jina-embeddings-v2-small-en)
    dc.embedding('my text', 'fastembed/jinaai/jina-embeddings-v2-small-en'),
    -- get the openai embeddings using the text-embedding-3-small model
    dc.embedding('my text', 'openai/text-embedding-3-small')
)
```

```sql
-- show the results
select * from testvector
```

```sql
-- show the similarity between 'my text' and 'lorem ipsum'
select 
    VECTOR_DOT_PRODUCT(
        embFastEmbedModel1, 
        dc.embedding('my text', 'fastembed/BAAI/bge-small-en-v1.5')
    ) "Similariy between 'my text' and itself", 
    VECTOR_DOT_PRODUCT(
        embFastEmbedModel1, 
        dc.embedding('lorem ipsum', 'fastembed/BAAI/bge-small-en-v1.5')
    ) "Similariy between the 'my text' and 'lorem ipsum'" 
from testvector
```

> Note that the first execution of each model will take a few seconds to generate the embeddings since the libraries not loaded yet. The subsequent executions will be much faster.

# Dream team

* [José Roberto Pereira](https://community.intersystems.com/user/jos%C3%A9-roberto-pereira-0)
* [Henry Pereira](https://community.intersystems.com/user/henry-pereira)
* [Henrique Dias](https://community.intersystems.com/user/henrique-dias-2)
