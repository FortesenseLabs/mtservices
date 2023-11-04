
//+------------------------------------------------------------------+
#property copyright "ejtrader"
#property link "https://github.com/ejtraderLabs/MQL5-ejtraderMT"

#include <wisefinanceMT/Socketlib.mqh>
#include <wiseFinanceMT/Json.mqh>

struct ClientSocket
{
  SOCKET64 socket;
  string requestData;
  string responseData;
};

struct RequestData
{
  string action;
  string actionType;
  string symbol;
  string chartTimeFrame;
  datetime fromDate;
  datetime toDate;
  //
  ulong id;
  string magic;
  double volume;
  double price;
  double stoploss;
  double takeprofit;
  int expiration;
  double deviation;
  string comment;
  string chartId;
  string indicatorChartId;
  string chartIndicatorSubWindow;
  string style;
};

enum msgStatus
{
  msCONNECTED,
  msDISCONNECTED,
};

enum msgType
{
  mtNORMAL,
  mtFLUSH,
};

// Sockets
SOCKET64 serverSocket = INVALID_SOCKET64;
ClientSocket clients[1024];
char SOCKET_BUFFER[8192]; // Adjust the buffer size as needed (4096)

//+------------------------------------------------------------------+
//| Send Socket response                                               |
//+------------------------------------------------------------------+
int SocketSend(ClientSocket &client)
{
  uchar response[];
  int len = StringToCharArray(client.responseData, response) - 1;
  if (len < 0)
    return 0;

  // TODO: examine thoroughly
  // Send the HTTP response back to the client
  return send(client.socket, response, ArraySize(response), 0);
}

//+------------------------------------------------------------------+
//| Read Socket request                                                |
//+------------------------------------------------------------------+
ClientSocket SocketRecv(ClientSocket &client)
{
  if (client.socket != INVALID_SOCKET64)
  {
    int request_len = recv(client.socket, SOCKET_BUFFER, sizeof(SOCKET_BUFFER), 0);

    if (request_len > 0)
    {
      uchar data[];
      ArrayCopy(data, SOCKET_BUFFER, ArraySize(data), 0, request_len);
      client.requestData = CharArrayToString(data);
      // Process received data here
      // Print("Received Data: ", client.requestData);
    }
    else if (request_len == 0)
    {
      // The client has disconnected
      closesocket(client.socket);
      client.socket = INVALID_SOCKET64;
    }
    else
    {
      // An error occurred
      int err = WSAGetLastError();
      if (err != WSAEWOULDBLOCK)
      {
        Print("recv failed with error: %d\n", err);
        closesocket(client.socket);
        client.socket = INVALID_SOCKET64;
      }
    }
  }

  return client;
}

//+------------------------------------------------------------------+
//| StartServer                                                        |
//+------------------------------------------------------------------+
void StartServer(string addr, ushort port)
{
  // Initialize the library
  char wsaData[];
  ArrayResize(wsaData, sizeof(WSAData));
  int res = WSAStartup(MAKEWORD(2, 2), wsaData);
  if (res != 0)
  {
    Print("-WSAStartup failed error: " + string(res));
    return;
  }

  // Create a socket
  serverSocket = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
  if (serverSocket == INVALID_SOCKET64)
  {
    Print("-Create failed error: " + WSAErrorDescript(WSAGetLastError()));
    CloseServer();
    return;
  }

  // Bind to address and port
  Print("Trying to bind " + addr + ":" + string(port));

  char ch[];
  StringToCharArray(addr, ch);
  sockaddr_in addrin;
  addrin.sin_family = AF_INET;
  addrin.sin_addr.u.S_addr = inet_addr(ch);
  addrin.sin_port = htons(port);
  ref_sockaddr ref;
  ref.in = addrin;
  if (bind(serverSocket, ref.ref, sizeof(addrin)) == SOCKET_ERROR)
  {
    int err = WSAGetLastError();
    if (err != WSAEISCONN)
    {
      Print("-Connect failed error: " + WSAErrorDescript(err) + ". Cleanup socket");
      CloseServer();
      return;
    }
  }

  // Set to non-blocking mode
  int non_block = 1;
  res = ioctlsocket(serverSocket, (int)FIONBIO, non_block);
  if (res != NO_ERROR)
  {
    Print("ioctlsocket failed error: " + string(res));
    CloseServer();
    return;
  }

  // Listen on the port and accept client connections
  if (listen(serverSocket, SOMAXCONN) == SOCKET_ERROR)
  {
    Print("Listen failed with error: ", WSAErrorDescript(WSAGetLastError()));
    CloseServer();
    return;
  }

  Print("Server started successfully");
}

//+------------------------------------------------------------------+
//| CloseServer                                                        |
//+------------------------------------------------------------------+
void CloseServer()
{
  // Close all client sockets
  for (int i = 0; i < ArraySize(clients); i++)
  {
    if (clients[i].socket != INVALID_SOCKET64)
    {
      // Reset
      ResetSubscriptionsAndIndicators(clients[i]);

      closesocket(clients[i].socket);
      clients[i].socket = INVALID_SOCKET64;
    }
  }

  // Close the server socket
  if (serverSocket != INVALID_SOCKET64)
  {
    closesocket(serverSocket);
    serverSocket = INVALID_SOCKET64;
  }

  // Clean up Winsock
  WSACleanup();
}

//+------------------------------------------------------------------+
//| AcceptClients                                                        |
//+------------------------------------------------------------------+
void AcceptClients()
{
  if (serverSocket == INVALID_SOCKET64)
  {
    return;
  }

  // Accept any new incoming connections
  SOCKET64 client = INVALID_SOCKET64;

  ref_sockaddr ch;
  int len = sizeof(ref_sockaddr);
  client = accept(serverSocket, ch.ref, len);
  if (client != INVALID_SOCKET64)
  {
    // Add the new client socket to the list of clients
    for (int i = 0; i < ArraySize(clients); i++)
    {
      if (clients[i].socket == INVALID_SOCKET64)
      {
        clients[i].socket = client;
        clients[i] = SocketRecv(clients[i]);
        break;
      }
    }
  }

  // Check for data from any of the clients
  for (int i = 0; i < ArraySize(clients); i++)
  {
    if (clients[i].socket != INVALID_SOCKET64)
    {
      clients[i] = SocketRecv(clients[i]);
      ProcessClientRequest(clients[i]);
    }
  }

  Print("Waiting for Connections!!!");
}

//+------------------------------------------------------------------+
//| Process Client Request and Respond                                |
//+------------------------------------------------------------------+
void ProcessClientRequest(ClientSocket &client)
{
  // char buffer[SOCK_BUF];
  // int bytesRead = recv(clientSocket, buffer, sizeof(buffer), 0);
  // client = SocketRecv(client);

  if (client.socket <= 0)
  {
    // Error or connection closed
    closesocket(client.socket);
    return;
  }

  RequestHandler(client);
}

//+------------------------------------------------------------------+
//| Action confirmation                                              |
//+------------------------------------------------------------------+
void ActionDoneOrError(ClientSocket &client, int lastError, string funcName, string desc)
{

  CJAVal conf;

  conf["error"] = (bool)true;
  if (lastError == 0)
    conf["error"] = (bool)false;

  conf["lastError"] = (string)lastError;
  conf["description"] = (string)desc;
  conf["function"] = (string)funcName;

  string t = conf.Serialize();
  client.responseData = t;
  SocketSend(client);
}

//+------------------------------------------------------------------+
//| parse request data, convert into struct                          |
//+------------------------------------------------------------------+
RequestData ParseRequestData(ClientSocket &client)
{
  Print("Request Data: ", client.requestData);

  CJAVal dataObject;

  if (StringLen(client.requestData) > 0 && !dataObject.Deserialize(client.requestData))
  {
    Print("Failed to deserialize request command");
    mControl.mSetUserError(65537, GetErrorID(65537));
    CheckError(client, __FUNCTION__);
  }

  RequestData reqData;

  // Validate
  if (dataObject["toDate"].ToInt() != NULL)
  {
    datetime toDate = (datetime)dataObject["toDate"].ToInt();
  }

  datetime fromDate = (datetime)dataObject["fromDate"].ToInt();
  datetime toDate = TimeCurrent();

  // Unwrap remaining request data
  reqData.action = (string)dataObject["action"].ToStr();
  reqData.actionType = (string)dataObject["actionType"].ToStr();
  reqData.symbol = (string)dataObject["symbol"].ToStr();
  reqData.chartTimeFrame = (string)dataObject["chartTimeFrame"].ToStr();
  reqData.fromDate = fromDate;
  reqData.toDate = toDate;

  // Set optional request data to empty strings
  reqData.id = (ulong)dataObject["id"].ToStr(); // .ToInt()
  reqData.magic = (string)dataObject["magic"].ToStr();
  reqData.volume = (double)dataObject["volume"].ToDbl();
  reqData.price = (double)NormalizeDouble(dataObject["price"].ToDbl(), _Digits);
  reqData.stoploss = (double)dataObject["stoploss"].ToDbl();
  reqData.takeprofit = (double)dataObject["takeprofit"].ToDbl();
  reqData.expiration = (int)dataObject["expiration"].ToInt();
  reqData.deviation = (double)dataObject["deviation"].ToDbl();
  reqData.comment = (string)dataObject["comment"].ToStr();
  reqData.chartId = "";
  reqData.indicatorChartId = "";
  reqData.chartIndicatorSubWindow = "";
  reqData.style = "";

  return reqData;
}
