 [![Gitter](https://img.shields.io/badge/Available%20on-Intersystems%20Open%20Exchange-00b2a9.svg)](https://openexchange.intersystems.com/package/sql-embedding)
 [![Quality Gate Status](https://community.objectscriptquality.com/api/project_badges/measure?project=intersystems_iris_community%2Fsql-embedding&metric=alert_status)](https://community.objectscriptquality.com/dashboard?id=intersystems_iris_community%2Fsql-embedding)
 [![Reliability Rating](https://community.objectscriptquality.com/api/project_badges/measure?project=intersystems_iris_community%2Fsql-embedding&metric=reliability_rating)](https://community.objectscriptquality.com/dashboard?id=intersystems_iris_community%2Fsql-embedding)

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

## Installation 

### Setting an API key

If you're planning to use an online embeddings service, you'll need an API key. Currently, the project supports OpenAI's Embeddings service.

[Obtain your OpenAI API key by creating an account on their platform](https://openai.com/).

#### Configuring Environment Variables:

Environment variables are used to store sensitive information like API keys and tokens. These variables need to be set before building the Docker image.

There are two ways to configure these variables:

When launching the Docker container, you can set the `OPENAI_KEY` the environment variables on a dotenv file using the -e flag:

```bash
# OpenAI API key
export OPENAI_KEY=$OPENAI_KEY
```

### Supported embedding models

Currently, the project supports the following embeddings models/services, here called providers:

| Provider ID | Provider information |
|-------------|----------------------|
| fastembed | [FastEmbed](https://fastembed.com/) |
| openai | [OpenAI](https://openai.com/) |
| sentence_transformers | [SentenceTransformers](https://www.sbert.net/) |

By default, the project will use FastEmbed embeddings model. It's free and you don't need an API key to use it.

### Docker

For your convenience, the project uses [Docker Compose](https://docs.docker.com/compose/) to build and run the containers. Note that in the case of SentenceTransformers, you'll need to install the SentenceTransformers library manually, since this library is big and takes a long time to install making the build process slow.

Clone/git pull the repo into any local directory

```
$ git clone https://github.com/musketeers-br/sql-embeddings
```

Open the terminal in this directory and run:

```
$ docker-compose build

$ docker-compose up -d
```

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

## Usage

```sql
dc.embedding('<text>', '<provider>/<modelName>')
```

## Example
To get started, you can use the following SQL query to generate an embedding for the word 'test':

```sql
-- using the default embedding provider/model to get the embeddings vector
select dc.embedding('test')

-- table with two vector columns to store the embeddings
-- pay attention to the vectors dimensions, they must be the same as the model used
create table testvector(
    document varchar(1024),             -- the text to be embedded
    embFastEmbed vector(double, 384),   -- store fastembed embeddings
    embOpenAI vector(double, 1536)      -- store openai embeddings
)

insert into testvector (
    document, 
    embFastEmbed, 
    embOpenAI
) values (
    'my text', 
    -- get the fastembed embeddings using the BAAI/bge-small-en-v1.5 model
    dc.embedding('my text', 'fastembed/BAAI/bge-small-en-v1.5'), 
    -- get the openai embeddings using the text-embedding-3-small model
    dc.embedding('my text', 'openai/text-embedding-3-small')
)

-- show the results
select * from testvector
```

> Note that the first execution will take a few seconds to generate the embeddings since the libraries not loaded yet. The subsequent executions will be much faster.

# Dream team

* [José Roberto Pereira](https://community.intersystems.com/user/jos%C3%A9-roberto-pereira-0)
* [Henry Pereira](https://community.intersystems.com/user/henry-pereira)
* [Henrique Dias](https://community.intersystems.com/user/henrique-dias-2)