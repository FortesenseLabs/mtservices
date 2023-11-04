//+------------------------------------------------------------------+
//|                 WiseFinanceSocketServer                           |
//|              Copyright 2023, Fortesense Labs.                     |
//|              https://www.wisefinance.com                           |
//+------------------------------------------------------------------+
// Reference:
// - https://github.com/ejtraderLabs/Metatrader5-Docker
// - https://www.mql5.com/en/code/280
// - ejTrader

#property copyright "Copyright 2023, Fortesense Labs."
#property link "https://www.wisefinance.com"
#property version "0.10"
#property description "Wise Finance Socket Server History Info Processor"

#include <wisefinanceMT/SocketServer.mqh>
#include <wiseFinanceMT/Utils.mqh>

//+------------------------------------------------------------------+
//| Push historical data to socket                                   |
//+------------------------------------------------------------------+
bool PushHistoricalData(ClientSocket &client, CJAVal &jdata)
{
  string t = jdata.Serialize();

  client.responseData = t;
  SocketSend(client);
  return true;
}

//+------------------------------------------------------------------+
// Function to handle tick data (eg. writing to a CSV file)          |
//+------------------------------------------------------------------+
void HandleTickData(ClientSocket &client, RequestData &rdata)
{
  CJAVal data, d, msg;
  MqlTick tickArray[];

  string fileName = rdata.symbol + "-" + rdata.chartTimeFrame + "-TICK.csv";
  string directoryName = "Data";
  string outputFile = directoryName + "\\" + fileName;

  // ... Retrieve fromDate, toDate, and tick data
  ENUM_TIMEFRAMES period = GetTimeframe(rdata.chartTimeFrame);
  datetime fromDate = rdata.fromDate;
  datetime toDate = rdata.toDate;

  int tickCount = 0;
  ulong fromDateM = StringToTime(fromDate);
  ulong toDateM = StringToTime(toDate);

  tickCount = CopyTicksRange(rdata.symbol, tickArray, COPY_TICKS_ALL, 1000 * (ulong)fromDateM, 1000 * (ulong)toDateM);
  if (tickCount < 0)
  {
    mControl.mSetUserError(65541, GetErrorID(65541));
  }

  CheckError(client, __FUNCTION__);
  Print("Preparing data of ", tickCount, " ticks for ", rdata.symbol);

  int file_handle = FileOpen(outputFile, FILE_WRITE | FILE_CSV);
  if (file_handle != INVALID_HANDLE)
  {
    msg["status"] = (string)msCONNECTED;
    msg["type"] = (string)mtNORMAL;
    msg["data"] = StringFormat("Writing to: %s\\%s", TerminalInfoString(TERMINAL_DATA_PATH), outputFile);
    if (liveStream)
    {
      client.responseData = msg.Serialize();
      SocketSend(client);
    }

    ActionDoneOrError(client, ERR_SUCCESS, __FUNCTION__, "ERR_SUCCESS");

    // Inform client that file is avalable for writing
    PrintFormat("%s file is available for writing", fileName);
    PrintFormat("File path: %s\\Files\\", TerminalInfoString(TERMINAL_DATA_PATH));

    // Write data to the CSV file
    for (int i = 0; i < tickCount; i++)
    {
      FileWrite(file_handle, tickArray[i].time_msc, ",", tickArray[i].bid, ",", tickArray[i].ask);

      msg["status"] = (string)msCONNECTED;
      msg["type"] = (string)mtFLUSH;
      msg["data"] = (string)tickArray[i].time_msc;
      if (liveStream)
      {
        client.responseData = msg.Serialize();
        SocketSend(client);
      }
    }
    FileClose(file_handle);
    PrintFormat("Data is written, %s file is closed", fileName);

    msg["status"] = (string)msDISCONNECTED;
    msg["type"] = (string)mtNORMAL;
    msg["data"] = (string)StringFormat("Writing to: %s\\%s", outputFile, " is finished");
    if (liveStream)
    {
      client.responseData = msg.Serialize();
      SocketSend(client);
    }
  }
  else
  {
    mControl.mSetUserError(65542, GetErrorID(65542));
    CheckError(client, __FUNCTION__);
  }

  // ... Send response to the client
}

//+------------------------------------------------------------------+
// Function to handle non-tick data (e.g. write to a CSV file)       |
//+------------------------------------------------------------------+
void HandleNonTickData(ClientSocket &client, RequestData &rdata)
{
  CJAVal c, d;
  MqlRates r[];
  int spread[];

  string fileName = rdata.symbol + "-" + rdata.chartTimeFrame + ".csv";
  string directoryName = "Data";
  string outputFile = directoryName + "\\" + fileName;

  // ... Retrieve fromDate, toDate, and OHLCV data
  int barCount;

  ENUM_TIMEFRAMES period = GetTimeframe(rdata.chartTimeFrame);
  datetime fromDate = rdata.fromDate;
  datetime toDate = rdata.toDate;

  barCount = CopyRates(rdata.symbol, period, fromDate, toDate, r);
  if (CopySpread(rdata.symbol, period, fromDate, toDate, spread) != 1)
  {
    mControl.mSetUserError(65541, GetErrorID(65541));
  }

  Print("Preparing tick data of ", barCount, " ticks for ", rdata.symbol);
  int file_handle = FileOpen(outputFile, FILE_WRITE | FILE_CSV);
  if (file_handle != INVALID_HANDLE)
  {
    ActionDoneOrError(client, ERR_SUCCESS, __FUNCTION__, "ERR_SUCCESS");

    PrintFormat("%s file is available for writing", outputFile);
    PrintFormat("File path: %s\\Files\\", TerminalInfoString(TERMINAL_DATA_PATH));

    // Write data to the CSV file
    for (int i = 0; i < barCount; i++)
    {
      FileWrite(file_handle, r[i].time, ",", r[i].open, ",", r[i].high, ",", r[i].low, ",", r[i].close, ",", r[i].tick_volume, spread[i]);
    }

    FileClose(file_handle);
    PrintFormat("Data is written, %s file is closed", outputFile);
  }
  else
  {
    mControl.mSetUserError(65542, GetErrorID(65542));
    CheckError(client, __FUNCTION__);
  }

  // ... Send response to the client
}

//+------------------------------------------------------------------+
//| Function to retrieve and send tick data                          |
//+------------------------------------------------------------------+
void RetrieveAndSendTickData(ClientSocket &client, RequestData &rdata)
{
  CJAVal data, d;
  MqlTick tickArray[];

  ENUM_TIMEFRAMES period = GetTimeframe(rdata.chartTimeFrame);
  datetime fromDate = rdata.fromDate;
  datetime toDate = rdata.toDate;

  // ... Retrieve fromDate, toDate, and tick data
  int tickCount = 0;
  ulong fromDateM = StringToTime(fromDate);
  ulong toDateM = StringToTime(toDate);

  tickCount = CopyTicksRange(rdata.symbol, tickArray, COPY_TICKS_ALL, 1000 * (ulong)fromDateM, 1000 * (ulong)toDateM);
  Print("Preparing tick data of ", tickCount, " ticks for ", rdata.symbol);
  if (tickCount > 0)
  {
    for (int i = 0; i < tickCount; i++)
    {
      data[i][0] = (long)tickArray[i].time_msc;
      data[i][1] = (double)tickArray[i].bid;
      data[i][2] = (double)tickArray[i].ask;
    }
    d["data"].Set(data);
  }
  else
  {
    d["data"].Add(data);
  }
  Print("Finished preparing tick data");

  d["symbol"] = rdata.symbol;
  d["timeframe"] = rdata.chartTimeFrame;

  // ... Prepare data and send to the client
  PushHistoricalData(client, d);
}

//+------------------------------------------------------------------+
//| Function to retrieve and send non-tick data                      |
//+------------------------------------------------------------------+
void RetrieveAndSendNonTickData(ClientSocket &client, RequestData &rdata)
{
  CJAVal c, d;
  MqlRates r[];
  int spread[];
  int barCount = 0;

  // ... Retrieve fromDate, toDate, and OHLCV data
  ENUM_TIMEFRAMES period = GetTimeframe(rdata.chartTimeFrame);
  datetime fromDate = rdata.fromDate;
  datetime toDate = rdata.toDate;

  barCount = CopyRates(rdata.symbol, period, fromDate, toDate, r);
  if (CopySpread(rdata.symbol, period, fromDate, toDate, spread) != 1)
  { /*mControl.Check();*/
  }

  if (barCount)
  {
    for (int i = 0; i < barCount; i++)
    {
      c[i][0] = (long)r[i].time;
      c[i][1] = (double)r[i].open;
      c[i][2] = (double)r[i].high;
      c[i][3] = (double)r[i].low;
      c[i][4] = (double)r[i].close;
      c[i][5] = (double)r[i].tick_volume;
      c[i][6] = (double)r[i].real_volume;
      c[i][7] = (int)spread[i];
    }
    d["data"].Set(c);
  }
  else
  {
    d["data"].Add(c);
  }

  d["symbol"] = rdata.symbol;
  d["timeframe"] = rdata.chartTimeFrame;

  // ... Prepare data and send to the client
  PushHistoricalData(client, d);
}

//+------------------------------------------------------------------+
//| Function to handle trade data                                    |
//+------------------------------------------------------------------+
void HandleTradeData(ClientSocket &client)
{
  CDealInfo tradeInfo;
  CJAVal trades, data;

  if (HistorySelect(0, TimeCurrent()))
  {
    // Get total deals in history
    int total = HistoryDealsTotal();
    ulong ticket; // deal ticket

    for (int i = 0; i < total; i++)
    {
      if ((ticket = HistoryDealGetTicket(i)) > 0)
      {
        tradeInfo.Ticket(ticket);
        data["ticket"] = (long)tradeInfo.Ticket();
        data["time"] = (long)tradeInfo.Time();
        data["price"] = (double)tradeInfo.Price();
        data["volume"] = (double)tradeInfo.Volume();
        data["symbol"] = (string)tradeInfo.Symbol();
        data["type"] = (string)tradeInfo.TypeDescription();
        data["entry"] = (long)tradeInfo.Entry();
        data["profit"] = (double)tradeInfo.Profit();

        trades["trades"].Add(data);
      }
    }
  }
  else
  {
    trades["trades"].Add(data);
  }

  // Serialize and send trade data to the client
  string t = trades.Serialize();

  client.responseData = t;
  SocketSend(client);
}

//+------------------------------------------------------------------+
//| Validate history info data request                               |
//+------------------------------------------------------------------+
bool ValidateHistoryInfoRequest(RequestData &rdata)
{
  bool valid = true;

  // List of fields to validate
  string fieldsToValidate[] = {
      "actionType",
      "symbol",
      "chartTimeFrame",
      "fromDate"};

  for (int i = 0; i < ArraySize(fieldsToValidate); i++)
  {
    string fieldName = fieldsToValidate[i];
    string value = GetStructFieldValue(rdata, fieldName);

    if (value == NULL)
    {
      Print("Error: Field '" + fieldName + "' is NULL in the request.");
      valid = false;
      break;
    }
  }

  return valid;
}