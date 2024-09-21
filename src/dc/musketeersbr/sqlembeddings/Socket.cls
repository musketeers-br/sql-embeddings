/// Handle a client/server interface for run embeddings models.
/// Create to handle slow imports as described in https://stackoverflow.com/a/78053521
Class dc.musketeersbr.sqlembeddings.Socket Extends %RegisteredObject
{

/// Start the embeddings services server on the given port.
/// 
/// This method starts a new process running the server on the given port.
/// The server will listen for incoming connections and process any requests
/// it receives.
/// 
/// @param pPort The port number to listen on.
ClassMethod StartServer(pPort As %Integer)
{
    Do ..StartServerPy(pPort)
}

/// Start the embeddings services server in the background on the given port.
/// This method forks a new process to run the server and returns the process ID.
/// @param pPort The port number to listen on.
/// @return The process ID of the server process.
ClassMethod StartServerBackground(pPort As %Integer) As %Integer [ Private ]
{
    Job ..StartServer(pPort)
    Set pID = $ZCHILD
    Return pID
}

/// Loads an ebedding model from the given model name.
/// 
/// @param modelName The name of the model to be loaded.
/// @return The loaded model as a %SYS.Python object.
ClassMethod LoadEmbeddingModelPy(modelName As %String) As %SYS.Python [ Language = python ]
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
ClassMethod ExecuteEmbeddingsPy(data As %String, model As %SYS.Python) [ Language = python, Private ]
{
    embeddings = model.encode(data.decode('utf-8'))
    embeddings_list = [str(embedding.tolist()) for embedding in embeddings]
    return str(embeddings_list).encode('utf-8')
}

/// Starts a server in Python to handle incoming connections and generate embeddings using a specified model.
/// The server listens on the specified port and responds to incoming connections by generating embeddings
/// for the received string using the specified model.
/// 
/// This is the actual embeddings server implementation in Python using its socket library.
/// 
/// @param port The port number to listen on.
ClassMethod StartServerPy(port As %Integer) [ Language = python, Private ]
{
    import socket
    import signal
    import sys
    import iris

    def signal_handler(sig, frame):
        """
        Signal handler to shut down the server gracefully when a signal is received.

        :param sig: The signal number.
        :param frame: The current stack frame.
        :return: None
        """
        print("\nServer shutting down gracefully...")
        server_socket.close()
        sys.exit(0)

    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)

    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.bind(('localhost', port))
    server_socket.listen(5)
    #; server_socket.timeout(10)

    error_msg = ""
    try:
        # todo: import the model from parameter
        model = iris.cls("dc.musketeersbr.sqlembeddings.Socket").LoadEmbeddingModelPy('all-MiniLM-L6-v2')
    except Exception as e:
        error_msg = f"Error loading model: {e}"
        model = None

    print(f"Server listening on port {port}...")

    try:
        while True:
            client_socket, addr = server_socket.accept()
            print(f"Connection from {addr}")

            # if there was an error loading the model, send an error message
            if error_msg != "":
                client_socket.sendall(error_msg.encode('utf-8'))
            else:
                data = client_socket.recv(99999)
                if data:
                    print(f"Received: {data.decode('utf-8')}")
                    embeddings_string = iris.cls("dc.musketeersbr.sqlembeddings.Socket").ExecuteEmbeddingsPy(data, model)
                    client_socket.sendall(embeddings_string)
            client_socket.close()

    except Exception as e:
        print(f"Error: {e}")

    finally:
        server_socket.close()
        print("Server closed.")
}

/// Starts a client to connect to the embeddings services server and send a message.
/// 
/// This method starts a new client process to connect to the server at the given
/// host and port, and sends the given message to the server.
/// The method returns the response from the server as a string.
/// 
/// @param pServer The host name or IP address of the server.
/// @param pPort The port number of the server.
/// @param pMessage The message to be sent to the server.
/// @return The response from the server as a string.
ClassMethod StartClient(pMessage As %String, pServer As %String = "localhost", pPort As %Integer = "") As %String
{
    Set embeddings = ..StartClientPy(pMessage, pServer, pPort)
    Return embeddings
}

ClassMethod StartClientPy(message As %String, server As %String = "localhost", port As %Integer = "") As %String [ Language = python ]
{
    import socket
    import os
    import signal
    import sys
    import time
    import iris

    def signal_handler(sig, frame):
        """
        Signal handler to catch SIGINT and SIGTERM and perform a clean shutdown.

        :param sig: The signal number that was received.
        :param frame: The current stack frame.
        """
        print("\nClient shutting down gracefully...")
        client_socket.close()
        sys.exit(0)

    def get_available_port():
        """
        Finds an available port on localhost.

        Uses the socket module to create a socket, bind it to localhost with port 0,
        and then retrieve the port number that the operating system assigned.

        :return: The port number that is available.
        """
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.bind(('', 0))
        available_port = s.getsockname()[1]
        s.close()
        print(f"Available port: {available_port}")
        return available_port

    def check_if_server_is_down(server, port):
        """
        Checks if the server is down by attempting a connection to the given server and port.

        Args:
            server (str): The server host name or IP address.
            port (int): The port number.

        Returns:
            bool: True if the server is down, False otherwise.
        """
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(5)
        result = sock.connect_ex((server, port))
        print(f"Server is down on port {port}: {result != 0}")
        return result != 0

    def kill_server():
        """
        Kill the current server process.

        This method attempts to kill the current server process by sending a
        SIGINT signal to the process with the ID stored in the
        `dc.musketeersbr.sqlembeddings.Socket` class. If the process does not
        exist, this method will do nothing.

        Returns:
            None
        """
        pid = iris.cls("dc.musketeersbr.sqlembeddings.Socket").GetCurrentProcessID()
        try:
            os.kill(pid, signal.SIGINT)
        except:
            pass

    """
    Starts a new server in the background on the given port.

    If there is already a server running, it will be killed first.

    :param port: The port to start the server on.
    :return: None
    """
    def start_new_server(port):
        curr_port = iris.cls("dc.musketeersbr.sqlembeddings.Socket").GetCurrentPort()
        curr_pid = iris.cls("dc.musketeersbr.sqlembeddings.Socket").GetCurrentProcessID()
        if curr_pid:
            print(f"Killing server on port {curr_port} and pid {curr_pid}...")
            kill_server()

        print(f"Starting a new server on port {port}...")
        pid = iris.cls("dc.musketeersbr.sqlembeddings.Socket").StartServerBackground(port)
        iris.cls("dc.musketeersbr.sqlembeddings.Socket").SaveCurrentProcessID(pid)
        iris.cls("dc.musketeersbr.sqlembeddings.Socket").SaveCurrentPort(port)

        for i in range(60):
            print(f"Waiting for server to start on port {port}...")
            if not check_if_server_is_down(server, port):
                print(f"Server on port {port} is up.")
                break
            time.sleep(1)

    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)

    client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    #; client_socket.settimeout(10)

    try:
        if str(port) == '':
            print("No port specified, using current port...")
            port = iris.cls("dc.musketeersbr.sqlembeddings.Socket").GetCurrentPort()
            print(f"Current port: {port}")

        if str(port) == '':
            print("No port specified, using default port...")
            port = get_available_port()
            print(f"Selected port: {port}")

        print("Starting the client on port " + str(port) + "...")

        if check_if_server_is_down(server, port):
            start_new_server(port)

        client_socket.connect((server, port))
        client_socket.sendall(message.encode('utf-8'))
        data = client_socket.recv(999999).decode('utf-8')

        # check if the server response is about an error
        if "Error" in data:
            # raise an exception with the error message
            raise Exception(data)

        return data

    except ConnectionRefusedError:
        print("[Error] Connection refused: Server may be down or not accepting connections.")
        start_new_server(port)
        return iris.cls("dc.musketeersbr.sqlembeddings.Socket").StartClientPy(message, server, port)

    finally:
        client_socket.close()
}

/// Saves the current port number to the IRIS temporary storage.
/// @param pPort The current port number.
ClassMethod SaveCurrentPort(pPort As %Integer)
{
    Set ^IRIS.Temp("MusketeersBR","SQLEMBEDDINGS","PORT") = pPort
}

/// Retrieves the current port number from the IRIS temporary storage.
/// @return The current port number.
ClassMethod GetCurrentPort() As %Integer
{
    Return $GET(^IRIS.Temp("MusketeersBR","SQLEMBEDDINGS","PORT"))
}

/// Saves the current process ID to the IRIS temporary storage.
/// @param pProcessID The current process ID.
ClassMethod SaveCurrentProcessID(pProcessID As %Integer)
{
    Set ^IRIS.Temp("MusketeersBR","SQLEMBEDDINGS","PROCESSID") = pProcessID
}

/// Retrieves the current process ID from the IRIS temporary storage.
/// @return The current process ID.
ClassMethod GetCurrentProcessID() As %Integer
{
    Return $GET(^IRIS.Temp("MusketeersBR","SQLEMBEDDINGS","PROCESSID"))
}

}