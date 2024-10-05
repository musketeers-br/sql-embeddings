# Perfomance test

The following notebooks were adapted from https://github.com/intersystems-community/iris-vector-search/blob/main/demo/sql_demo.ipynb and aims to test performance on bulk insert operations. The notebook [sql_demo](./sql_demo.ipynb#Elapsed-time) uses Python directly to get all embeddings and then store them in IRIS. The notebook [sql_demo_dc_embedding](./sql_demo_dc_embedding.ipynb#Elapsed-time) uses the SQL function `dc_embedding()` to get the embeddings directly in SQL.

Each of these notebooks calculate the elapsed time of the whole bulk insert operation. The amount of time spent is diplayed at the end of each notebook.

As you can see, the function `dc.embedding()` is slower than the Python direct usage approach.