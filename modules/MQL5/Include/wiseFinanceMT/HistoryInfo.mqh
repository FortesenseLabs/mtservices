//+------------------------------------------------------------------+
//|                 WiseFinanceSocketServer                           |
//|              Copyright 2023, Fortesense Labs.                     |
//|              https://www.wisefinance.com                           |
//+------------------------------------------------------------------+
// Reference:
// - https://github.com/ejtraderLabs/Metatrader5-Docker
// - https://www.mql5.com/en/code/280
// - https://www.mql5.com/en/docs/convert/stringtotime
// - https://www.mql5.com/en/docs/basis/types/integer/datetime
// - ejTrader

#property copyright "Copyright 2023, Fortesense Labs."
#property link "https://www.wisefinance.com"
#property version "0.10"
#property description "Wise Finance Socket Server History Info Processor"

#include <wisefinanceMT/sockets/SocketServer.mqh>
#include <wiseFinanceMT/Utils.mqh>

//+------------------------------------------------------------------+
//| Push historical data to socket                                   |
//+------------------------------------------------------------------+
bool PushHistoricalData(ClientSocket &client, CJAVal &jdata)
{
  string t = jdata.Serialize();

  client.responseData = t;
  ServerSocketSend(client);
  return true;
}

//+------------------------------------------------------------------+
//| Function to retrieve and send tick data                          |
//+------------------------------------------------------------------+
void RetrieveAndSendTickData(ClientSocket &client, string symbol, string chartTimeFrame, datetime fromDate, datetime toDate)
{
  Print("RetrieveAndSendTickData()");

  CJAVal data;
  string tick;
  MqlTick tickArray[];

  // Retrieve fromDate, toDate, and tick data
  ENUM_TIMEFRAMES period = GetTimeframe(chartTimeFrame);

  // Calculate the difference in seconds between fromDate and toDate
  // int diffInSeconds = MathAbs(TimeSeconds(toDate - fromDate));

  // // Check if the difference is more than 5 years (5 * 365 * 24 * 60 * 60 seconds)
  // // 12hrs => 12 * 60 * 60
  // if (diffInSeconds > 12 * 60 * 60)
  // {
  //   // Adjust toDate to be 5 years after fromDate
  //   toDate = TimeAdd(fromDate, PERIOD_YEARS, 5);
  // }

  int tickCount = 0;
  ulong fromDateM = StringToTime(fromDate);
  ulong toDateM = StringToTime(toDate);

  tickCount = CopyTicksRange(symbol, tickArray, COPY_TICKS_ALL, 1000 * (ulong)fromDateM, 1000 * (ulong)toDateM);
  if (tickCount <= 0)
  {
    data["error"] = (bool)false;
    // data["ticks"].Add(tick);
    data["ticks"] = tick;
  }

  for (int i = 0; i < tickCount; i++)
  {
    tick = tickArray[i].time_msc + "||" + tickArray[i].bid + "||" + tickArray[i].ask;

    data["ticks"].Add(tick);

    Print("Tick: ", tick);

    // Error handling
    CheckError(client, __FUNCTION__);
  }

  data["error"] = (bool)false;
  // PushHistoricalData(client, data);
  string msg = data.Serialize();
  client.responseData = msg;
  ServerSocketSend(client);
}

//+------------------------------------------------------------------+
//| Function to retrieve and send non-tick data (bar data)           |
//+------------------------------------------------------------------+
void RetrieveAndSendNonTickData(ClientSocket &client, string symbol, string chartTimeFrame, datetime fromDate, datetime toDate)
{
  CJAVal data;
  string c;
  MqlRates r[];
  int spread[];
  int barCount = 0;

  // Retrieve fromDate, toDate, and OHLCV data
  ENUM_TIMEFRAMES period = GetTimeframe(chartTimeFrame);

  barCount = CopyRates(symbol, period, fromDate, toDate, r);
  if (CopySpread(symbol, period, fromDate, toDate, spread) != 1)
  { /*mControl.Check();*/
    mControl.mSetUserError(65541, GetErrorID(65541));
  }

  if (barCount)
  {
    for (int i = 0; i < barCount; i++)
    {
      c = r[i].time + "||" + r[i].open + "||" + r[i].high + "||" + r[i].low + "||" + r[i].close + "||" + r[i].tick_volume + "||" + r[i].real_volume + "||" + spread[i];

      data["rates"].Add(c);

      Print("Rate: ", c);
    }

    // data["data"].Set(c);
  }
  else
  {
    data["data"].Add(c);
  }

  data["symbol"] = symbol;
  data["timeframe"] = chartTimeFrame;
  data["error"] = (bool)false;

  // ... Prepare data and send to the client
  // PushHistoricalData(client, data);
  string msg = data.Serialize();
  client.responseData = msg;
  ServerSocketSend(client);
}

//+------------------------------------------------------------------+
//| Function to handle trade data                                    |
//+------------------------------------------------------------------+
void HandleTradeData(ClientSocket &client)
{
  CDealInfo tradeInfo;
  CJAVal trades;
  string data;

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

        data = tradeInfo.Ticket() + "||" + tradeInfo.Time() + "||" + tradeInfo.Price() + "||" + tradeInfo.Volume() + "||" + tradeInfo.Symbol() + "||" + tradeInfo.TypeDescription() + "||" + tradeInfo.Entry() + "||" + tradeInfo.Profit();

        Print("Trade: ", data);

        trades["trades"].Add(data);
      }
    }
  }
  else
  {
    trades["trades"].Add(data);
  }

  trades["error"] = (bool)false;

  // Serialize and send trade data to the client
  string t = trades.Serialize();
  client.responseData = t;
  ServerSocketSend(client);
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