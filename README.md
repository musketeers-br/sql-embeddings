 [![Gitter](https://img.shields.io/badge/Available%20on-Intersystems%20Open%20Exchange-00b2a9.svg)](https://openexchange.intersystems.com/package/sql-embedding)
 [![Quality Gate Status](https://community.objectscriptquality.com/api/project_badges/measure?project=intersystems_iris_community%2Fsql-embedding&metric=alert_status)](https://community.objectscriptquality.com/dashboard?id=intersystems_iris_community%2Fsql-embedding)
 [![Reliability Rating](https://community.objectscriptquality.com/api/project_badges/measure?project=intersystems_iris_community%2Fsql-embedding&metric=reliability_rating)](https://community.objectscriptquality.com/dashboard?id=intersystems_iris_community%2Fsql-embedding)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat&logo=AdGuard)](LICENSE)

# SQL-Embedding

## Motivation
*SQL-Embedding* allows you to utilize a variety of pre-trained language models to enhance vector search and create embeddings.

## Prerequisites

Make sure you have [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) and [Docker desktop](https://www.docker.com/products/docker-desktop) installed.

## Installation 

### Setting a LLM API key

To utilize the Large Language Model (LLM) service, you'll need an API key. Currently, the project supports OpenAI's LLM service.

[Obtain your OpenAI API key by creating an account on their platform](https://openai.com/).

#### Configuring Environment Variables:

Environment variables are used to store sensitive information like API keys and tokens. These variables need to be set before building the Docker image.

There are two ways to configure these variables:

When launching the Docker container, you can set the `OPENAI_KEY` the environment variables on a dotenv file using the -e flag:

```bash
# OpenAI API key
export OPENAI_KEY=$OPENAI_KEY
```

### Docker

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

## Example
To get started, you can use the following SQL query to generate an embedding for the word 'test':

```sql
select dc.embedding('test')

# Dream team

* [José Roberto Pereira](https://community.intersystems.com/user/jos%C3%A9-roberto-pereira-0)
* [Henry Pereira](https://community.intersystems.com/user/henry-pereira)
* [Henrique Dias](https://community.intersystems.com/user/henrique-dias-2)