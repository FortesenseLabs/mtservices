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

#include <wiseFinanceMT/HistoryInfo.mqh>
#include <wiseFinanceMT/TradeRequest.mqh>
#include <wisefinanceMT/SocketServer.mqh>
// #include <wiseFinanceMT/Utils.mqh>

//+------------------------------------------------------------------+
//| Reconfigure the script params                                    |
//+------------------------------------------------------------------+
void ScriptConfiguration(ClientSocket &client, RequestData &rdata)
{
  string symbol = rdata.symbol;
  string chartTimeFrame = rdata.chartTimeFrame;

  ArrayResize(symbolSubscriptions, symbolSubscriptionCount + 1);
  symbolSubscriptions[symbolSubscriptionCount].symbol = symbol;
  symbolSubscriptions[symbolSubscriptionCount].chartTimeFrame = chartTimeFrame;
  // to initialze with value 0 skips the first price
  symbolSubscriptions[symbolSubscriptionCount].lastBar = 0;
  symbolSubscriptionCount++;

  CJAVal info;

  info["error"] = false;
  info["done"] = true;
  string t = info.Serialize();

  client.responseData = t;
  ServerSocketSend(client);
}

//+------------------------------------------------------------------+
//| Account information                                              |
//+------------------------------------------------------------------+
void GetAccountInfo(ClientSocket &client)
{
  CJAVal info;

  info["error"] = false;
  info["broker"] = AccountInfoString(ACCOUNT_COMPANY);
  info["currency"] = AccountInfoString(ACCOUNT_CURRENCY);
  info["server"] = AccountInfoString(ACCOUNT_SERVER);
  info["trading_allowed"] = TerminalInfoInteger(TERMINAL_TRADE_ALLOWED);
  info["bot_trading"] = AccountInfoInteger(ACCOUNT_TRADE_EXPERT);
  info["balance"] = AccountInfoDouble(ACCOUNT_BALANCE);
  info["equity"] = AccountInfoDouble(ACCOUNT_EQUITY);
  info["margin"] = AccountInfoDouble(ACCOUNT_MARGIN);
  info["margin_free"] = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
  info["margin_level"] = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
  info["time"] = string(tm); // sending time for localtime dataframe

  string t = info.Serialize();

  client.responseData = t;
  ServerSocketSend(client);
}

//+------------------------------------------------------------------+
//| Balance information                                              |
//+------------------------------------------------------------------+
void GetBalanceInfo(ClientSocket &client)
{
  CJAVal info;
  info["balance"] = AccountInfoDouble(ACCOUNT_BALANCE);
  info["equity"] = AccountInfoDouble(ACCOUNT_EQUITY);
  info["margin"] = AccountInfoDouble(ACCOUNT_MARGIN);
  info["margin_free"] = AccountInfoDouble(ACCOUNT_MARGIN_FREE);

  string t = info.Serialize();

  client.responseData = t;
  ServerSocketSend(client);
}

//+------------------------------------------------------------------+
//| Clear symbol subscriptions and indicators                        |
//+------------------------------------------------------------------+
void ResetSubscriptionsAndIndicators(ClientSocket &client)
{
  ArrayFree(symbolSubscriptions);
  symbolSubscriptionCount = 0;

  bool error = false;
  /*
  if(ArraySize(symbolSubscriptions)!=0 || ArraySize(indicators)!=0 || ArraySize(chartWindows)!=0 || error){
    // Set to only Alert. Fails too often, this happens when i.e. the backtrader script gets aborted unexpectedly
    mControl.Check();
    mControl.mSetUserError(65540, GetErrorID(65540));
    CheckError(client, __FUNCTION__);
  }
  */
  ActionDoneOrError(client, ERR_SUCCESS, __FUNCTION__, "ERR_SUCCESS");
}

//+------------------------------------------------------------------+
//| Fetch positions information                                      |
//+------------------------------------------------------------------+
void GetPositions(ClientSocket &client)
{
  CPositionInfo mPosition;
  CJAVal data, position;

  // Get positions
  int positionsTotal = PositionsTotal();
  // Create empty array if no positions
  if (!positionsTotal)
    data["positions"].Add(position);
  // Go through positions in a loop
  for (int i = 0; i < positionsTotal; i++)
  {
    mControl.mResetLastError();

    if (mPosition.Select(PositionGetSymbol(i)))
    {
      position["id"] = PositionGetInteger(POSITION_IDENTIFIER);
      position["magic"] = PositionGetInteger(POSITION_MAGIC);
      position["symbol"] = PositionGetString(POSITION_SYMBOL);
      position["type"] = EnumToString(ENUM_POSITION_TYPE(PositionGetInteger(POSITION_TYPE)));
      position["time_setup"] = PositionGetInteger(POSITION_TIME);
      position["open"] = PositionGetDouble(POSITION_PRICE_OPEN);
      position["stoploss"] = PositionGetDouble(POSITION_SL);
      position["takeprofit"] = PositionGetDouble(POSITION_TP);
      position["volume"] = PositionGetDouble(POSITION_VOLUME);

      data["error"] = (bool)false;
      data["positions"].Add(position);
    }
    CheckError(client, __FUNCTION__);
  }

  string t = data.Serialize();
  client.responseData = t;
  ServerSocketSend(client);
}

//+------------------------------------------------------------------+
//| Fetch orders information                                         |
//+------------------------------------------------------------------+
void GetOrders(ClientSocket &client)
{
  mControl.mResetLastError();

  COrderInfo mOrder;
  CJAVal data, order;

  // Get orders
  if (HistorySelect(0, TimeCurrent()))
  {
    int ordersTotal = OrdersTotal();
    // Create empty array if no orders
    if (!ordersTotal)
    {
      data["error"] = (bool)false;
      data["orders"].Add(order);
    }

    for (int i = 0; i < ordersTotal; i++)
    {
      if (mOrder.Select(OrderGetTicket(i)))
      {
        order["id"] = (string)mOrder.Ticket();
        order["magic"] = OrderGetInteger(ORDER_MAGIC);
        order["symbol"] = OrderGetString(ORDER_SYMBOL);
        order["type"] = EnumToString(ENUM_ORDER_TYPE(OrderGetInteger(ORDER_TYPE)));
        order["time_setup"] = OrderGetInteger(ORDER_TIME_SETUP);
        order["open"] = OrderGetDouble(ORDER_PRICE_OPEN);
        order["stoploss"] = OrderGetDouble(ORDER_SL);
        order["takeprofit"] = OrderGetDouble(ORDER_TP);
        order["volume"] = OrderGetDouble(ORDER_VOLUME_INITIAL);

        data["error"] = (bool)false;
        data["orders"].Add(order);
      }
      // Error handling
      CheckError(client, __FUNCTION__);
    }
  }

  string t = data.Serialize();
  client.responseData = t;
  ServerSocketSend(client);
}

//+------------------------------------------------------------------+
//| Get historical data                                              |
//+------------------------------------------------------------------+
void HistoryInfo(ClientSocket &client, RequestData &rdata)
{
  if (rdata.actionType == "WRITE")
  {
    if (rdata.chartTimeFrame == "TICK")
    {
      HandleTickData(client, rdata);
    }
    else
    {
      HandleNonTickData(client, rdata);
    }
  }
  else if (rdata.actionType == "DATA")
  {
    if (rdata.chartTimeFrame == "TICK")
    {
      RetrieveAndSendTickData(client, rdata);
    }
    else
    {
      RetrieveAndSendNonTickData(client, rdata);
    }
  }
  else if (rdata.actionType == "TRADES")
  {
    HandleTradeData(client);
  }
  else
  {
    mControl.mSetUserError(65538, GetErrorID(65538));
    CheckError(client, __FUNCTION__);
  }
}

//+------------------------------------------------------------------+
//| Trading request                                                   |
//+------------------------------------------------------------------+
void TradingRequest(ClientSocket &client, RequestData &rdata)
{
  TradingModule(client, rdata);
}

//+------------------------------------------------------------------+
//| Get Tick                                                       |
//+------------------------------------------------------------------+
void GetTick(ClientSocket &client)
{
  // GET request handling code here
  // send an appropriate response back to the client
  string symbol = "Step Index";

  MqlTick tick;

  ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT;

  if (SymbolInfoTick(symbol, tick))
  {
    CJAVal Data;
    Data[0] = (string)tick.time_msc;
    Data[1] = (double)tick.bid;
    Data[2] = (double)tick.ask;

    CJAVal tickData;
    tickData["symbol"] = symbol;
    tickData["timeframe"] = TimeframeToString(timeframe);
    tickData["tick"].Set(Data);

    CJAVal jsonData;
    jsonData["event"] = "tick";
    jsonData["data"].Set(tickData);

    string jsonStr = jsonData.Serialize();
    // InformServerSocket(liveSocket, "/api/price/stream/tick", jsonStr, "TICK");
    client.responseData = jsonStr;
    ServerSocketSend(client);

    Print("[TICK] Sent Tick Data for ", symbol, " (", timeframe, ")");
    // Debug
    if (debug)
    {
      Print("New event on symbol: ", symbol);
      Print("data: ", jsonStr);
      // Sleep(1000);
    }
  }
  else
  {
    Print("Failed to get tick data for ", symbol, " (", timeframe, ")");
  }
}
