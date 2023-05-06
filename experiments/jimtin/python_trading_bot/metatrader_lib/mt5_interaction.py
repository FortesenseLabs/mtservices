import MetaTrader5
import pandas
import datetime
import pytz

import exceptions


# Function to start Meta Trader 5 (MT5)
def start_mt5(username, password, server, path):
    """
    Initializes and logs into MT5
    :param username: 8 digit integer
    :param password: string
    :param server: string
    :param path: string
    :return: True if successful, Error if not
    """
    # Ensure that all variables are the correct type
    uname = int(username)  # Username must be an int
    pword = str(password)  # Password must be a string
    trading_server = str(server)  # Server must be a string
    filepath = str(path)  # Filepath must be a string

    # Attempt to start MT5
    try:
        metaTrader_init = MetaTrader5.initialize(login=uname, password=pword, server=trading_server, path=filepath)
    except Exception as e:
        print(f"Error initializing MetaTrader: {e}")
        raise exceptions.MetaTraderInitializeError

    # Attempt to login to MT5
    if not metaTrader_init:
        raise exceptions.MetaTraderInitializeError
    else:
        try:
            metaTrader_login = MetaTrader5.login(login=uname, password=pword, server=trading_server)
        except Exception as e:
            print(f"Error loging in to MetaTrader: {e}")
            raise exceptions.MetaTraderLoginError

    # Return True if initialization and login are successful
    if metaTrader_login:
        return True


# Function to initialize a symbol on MT5
def initialize_symbols(symbol_array):
    """
    Function to initialize a symbol on MT5. Note that different brokers have different symbols.
    To read more: https://trading-data-analysis.pro/everything-you-need-to-connect-your-python-trading-bot-to-metatrader-5-de0d8fb80053
    :param symbol_array: List of symbols to be initialized
    :return: True if all symbols enabled
    """
    # Get a list of all symbols supported in MT5
    all_symbols = MetaTrader5.symbols_get()
    # Create a list to store all the symbols
    symbol_names = []
    # Add the retrieved symbols to the list
    for symbol in all_symbols:
        symbol_names.append(symbol.name)

    # Check each provided symbol in symbol_array to ensure it exists
    for provided_symbol in symbol_array:
        if provided_symbol in symbol_names:
            # If it exists, enable
            if MetaTrader5.symbol_select(provided_symbol, True):
                pass
            else:
                # Print the outcome to screen. Custom Logging/Error Handling not yet created
                print(f"Error creating symbol {provided_symbol}. Symbol not enabled.")
                # Return a generic value error. Custom Error Handling not yet created.
                raise exceptions.MetaTraderSymbolUnableToBeEnabledError
        else:
            # Print the outcome to screen. Custom Logging/Error Handling not yet created
            print(f"Symbol {provided_symbol} does not exist in this MT5 implementation. Symbol not enabled.")
            # Return a generic syntax error. Custom Error Handling not yet enabled
            raise exceptions.MetaTraderSymbolDoesNotExistError
    # Return true if all symbols enabled
    return True


# Function to place a trade on MT5
def place_order(order_type, symbol, volume, stop_loss, take_profit, comment, direct=False, price=0):
    """
    Function to place a trade on MetaTrader 5 with option to check balance first
    :param order_type: String from options: SELL_STOP, BUY_STOP, SELL, BUY
    :param symbol: String
    :param volume: String or Float
    :param stop_loss: String or Float
    :param take_profit: String of Float
    :param comment: String
    :param direct: Bool, defaults to False
    :param price: String or Float, optional
    :return: Trade outcome or syntax error
    """

    # Set up the place order request
    request = {
        "symbol": symbol,
        "volume": volume,
        "sl": round(stop_loss, 3),
        "tp": round(take_profit, 3),
        "type_time": MetaTrader5.ORDER_TIME_GTC,
        "comment": comment
    }

    # Create the order type based upon provided values. This can be expanded for different order types as needed.
    if order_type == "SELL_STOP":
        request['type'] = MetaTrader5.ORDER_TYPE_SELL_STOP
        request['action'] = MetaTrader5.TRADE_ACTION_PENDING
        if price <= 0:
            raise exceptions.MetaTraderIncorrectStopPriceError
        else:
            request['price'] = round(price, 3)
            request['type_filling'] = MetaTrader5.ORDER_FILLING_RETURN
    elif order_type == "BUY_STOP":
        request['type'] = MetaTrader5.ORDER_TYPE_BUY_STOP
        request['action'] = MetaTrader5.TRADE_ACTION_PENDING
        if price <= 0:
            raise exceptions.MetaTraderIncorrectStopPriceError
        else:
            request['price'] = round(price, 3)
            request['type_filling'] = MetaTrader5.ORDER_FILLING_RETURN

    elif order_type == "SELL":
        request['type'] = MetaTrader5.ORDER_TYPE_SELL
        request['action'] = MetaTrader5.TRADE_ACTION_DEAL
        request['type_filling'] = MetaTrader5.ORDER_FILLING_IOC
    elif order_type == "BUY":
        request['type'] = MetaTrader5.ORDER_TYPE_BUY
        request['action'] = MetaTrader5.TRADE_ACTION_DEAL
        request['type_filling'] = MetaTrader5.ORDER_FILLING_IOC
    else:
        print("Choose a valid order type from SELL_STOP, BUY_STOP, SELL, BUY")
        raise SyntaxError

    if direct is True:
        # Send the order to MT5
        order_result = MetaTrader5.order_send(request)
        # Notify based on return outcomes
        if order_result[0] == 10009:
            # Print result
            # print(f"Order for {symbol} successful") # Enable if error checking order_result
            return order_result[2]
        elif order_result[0] == 10027:
            # Turn off autotrading
            print(f"Turn off Algo Trading on MT5 Terminal")
            raise exceptions.MetaTraderAlgoTradingNotDisabledError
        else:
            # Print result
            print(f"Error placing order. ErrorCode {order_result[0]}, Error Details: {order_result}")
            raise exceptions.MetaTraderOrderPlacingError

    else:
        # Check the order
        result = MetaTrader5.order_check(request)
        if result[0] == 0:
            # print("Balance Check Successful") # Enable to error check Balance Check
            # If order check is successful, place the order. Little bit of recursion for fun.
            place_order(
                order_type=order_type,
                symbol=symbol,
                volume=volume,
                price=price,
                stop_loss=stop_loss,
                take_profit=take_profit,
                comment=comment,
                direct=True
            )
        else:
            print(f"Order unsucessful. Details: {result}")
            raise exceptions.MetaTraderOrderCheckError

# Function to cancel an order
def cancel_order(order_number):
    """
    Function to cancel an order
    :param order_number: Int
    :return:
    """
    # Create the request
    request = {
        "action": MetaTrader5.TRADE_ACTION_REMOVE,
        "order": order_number,
        "comment": "Order Removed"
    }
    # Send order to MT5
    order_result = MetaTrader5.order_send(request)
    if order_result[0] == 10009:
        return True
    else:
        print(f"Error cancelling order. Details: {order_result}")
        raise exceptions.MetaTraderCancelOrderError


# Function to modify an open position
def modify_position(order_number, symbol, new_stop_loss, new_take_profit):
    """
    Function to modify a position
    :param order_number: Int
    :param symbol: String
    :param new_stop_loss: Float
    :param new_take_profit: Float
    :return: Boolean
    """
    # Create the request
    request = {
        "action": MetaTrader5.TRADE_ACTION_SLTP,
        "symbol": symbol,
        "sl": new_stop_loss,
        "tp": new_take_profit,
        "position": order_number
    }
    # Send order to MT5
    order_result = MetaTrader5.order_send(request)
    if order_result[0] == 10009:
        return True
    else:
        print(f"Error modifying position. Details: {order_result}")
        raise exceptions.MetaTraderModifyPositionError


# Function to retrieve all open orders from MT5
def get_open_orders():
    """
    Function to retrieve a list of open orders from MetaTrader 5
    :return: List of open orders
    """
    orders = MetaTrader5.orders_get()
    order_array = []
    for order in orders:
        order_array.append(order[0])
    return order_array


# Function to retrieve all open positions
def get_open_positions():
    """
    Function to retrieve a list of open orders from MetaTrader 5
    :return: list of positions
    """
    # Get position objects
    positions = MetaTrader5.positions_get()
    # Return position objects
    return positions


# Function to close an open position
def close_position(order_number, symbol, volume, order_type, price, comment):
    """
    Function to close an open position from MetaTrader 5
    :param order_number: int
    :return: Boolean
    """
    # Create the request
    request = {
        'action': MetaTrader5.TRADE_ACTION_DEAL,
        'symbol': symbol,
        'volume': volume,
        'position': order_number,
        'price': price,
        'type_time': MetaTrader5.ORDER_TIME_GTC,
        'type_filling': MetaTrader5.ORDER_FILLING_IOC,
        'comment': comment
    }

    if order_type == "SELL":
        request['type'] = MetaTrader5.ORDER_TYPE_SELL
    elif order_type == "BUY":
        request['type'] = MetaTrader5.ORDER_TYPE_BUY
    else:
        print(f"Incorrect syntax for position close {order_type}")
        raise SyntaxError

    # Place the order
    result = MetaTrader5.order_send(request)
    if result[0] == 10009:
        return True
    else:
        print(f"Error closing position. Details: {result}")
        raise exceptions.MetaTraderClosePositionError


# Function to convert a timeframe string in MetaTrader 5 friendly format
def set_query_timeframe(timeframe):
    # Implement a Pseudo Switch statement. Note that Python 3.10 implements match / case but have kept it this way for
    # backwards integration
    if timeframe == "M1":
        return MetaTrader5.TIMEFRAME_M1
    elif timeframe == "M2":
        return MetaTrader5.TIMEFRAME_M2
    elif timeframe == "M3":
        return MetaTrader5.TIMEFRAME_M3
    elif timeframe == "M4":
        return MetaTrader5.TIMEFRAME_M4
    elif timeframe == "M5":
        return MetaTrader5.TIMEFRAME_M5
    elif timeframe == "M6":
        return MetaTrader5.TIMEFRAME_M6
    elif timeframe == "M10":
        return MetaTrader5.TIMEFRAME_M10
    elif timeframe == "M12":
        return MetaTrader5.TIMEFRAME_M12
    elif timeframe == "M15":
        return MetaTrader5.TIMEFRAME_M15
    elif timeframe == "M20":
        return MetaTrader5.TIMEFRAME_M20
    elif timeframe == "M30":
        return MetaTrader5.TIMEFRAME_M30
    elif timeframe == "H1":
        return MetaTrader5.TIMEFRAME_H1
    elif timeframe == "H2":
        return MetaTrader5.TIMEFRAME_H2
    elif timeframe == "H3":
        return MetaTrader5.TIMEFRAME_H3
    elif timeframe == "H4":
        return MetaTrader5.TIMEFRAME_H4
    elif timeframe == "H6":
        return MetaTrader5.TIMEFRAME_H6
    elif timeframe == "H8":
        return MetaTrader5.TIMEFRAME_H8
    elif timeframe == "H12":
        return MetaTrader5.TIMEFRAME_H12
    elif timeframe == "D1":
        return MetaTrader5.TIMEFRAME_D1
    elif timeframe == "W1":
        return MetaTrader5.TIMEFRAME_W1
    elif timeframe == "MN1":
        return MetaTrader5.TIMEFRAME_MN1
    else:
        print(f"Incorrect timeframe provided. {timeframe}")
        raise ValueError


# Function to query previous candlestick data from MT5
def query_historic_data(symbol, timeframe, number_of_candles):
    # Convert the timeframe into an MT5 friendly format
    mt5_timeframe = set_query_timeframe(timeframe)
    # Retrieve data from MT5
    rates = MetaTrader5.copy_rates_from_pos(symbol, mt5_timeframe, 1, number_of_candles)
    return rates


# Function to retrieve latest tick for a symbol
def retrieve_latest_tick(symbol):
    """
    Function to retrieve the latest tick for a symbol
    :param symbol: String
    :return: Dictionary object
    """
    # Retrieve the tick information
    tick = MetaTrader5.symbol_info_tick(symbol)._asdict()
    spread = tick['ask'] - tick['bid']
    tick['spread'] = spread
    return tick


# Function to retrieve ticks from a time range
def retrieve_tick_time_range(start_time_utc, finish_time_utc, symbol, dataframe=False):
    # Set option in MT5 terminal for Unlimited bars
    # Check time format of start time
    if type(start_time_utc) != datetime.datetime:
        print(f"Time range tick start time is in incorrect format")
        raise ValueError
    # Check time format of finish time
    if type(finish_time_utc) != datetime.datetime:
        print(f"Time range tick finish time is in incorrect format")
        raise ValueError
    # Retrieve ticks
    ticks = MetaTrader5.copy_ticks_range(symbol, start_time_utc, finish_time_utc, MetaTrader5.COPY_TICKS_INFO)
    # Convert into dataframe only if Dataframe set to True
    if dataframe:
        # Convert into a dataframe
        ticks_data_frame = pandas.DataFrame(ticks)
        # Add spread
        ticks_data_frame['spread'] = ticks_data_frame['ask'] - ticks_data_frame['bid']
        # Add symbol
        ticks_data_frame['symbol'] = symbol
        # Format integers into signed integers (postgres doesn't support unsigned int)
        ticks_data_frame['time'] = ticks_data_frame['time'].astype('int64')
        ticks_data_frame['volume'] = ticks_data_frame['volume'].astype('int64')
        ticks_data_frame['time_msc'] = ticks_data_frame['time_msc'].astype('int64')
        return ticks_data_frame
    return ticks


# Function to retrieve candlestick data for a specified time range
def retrieve_candlestick_data_range(start_time_utc, finish_time_utc, symbol, timeframe, dataframe=False):
    # Set option in MT5 terminal for Unlimited bars
    # Check time format of start time
    if type(start_time_utc) != datetime.datetime:
        print(f"Time range tick start time is in incorrect format")
        raise ValueError
    # Check time format of finish time
    if type(finish_time_utc) != datetime.datetime:
        print(f"Time range tick finish time is in incorrect format")
        raise ValueError
    # Convert the timeframe into MT5 compatible format
    timeframe_value = set_query_timeframe(timeframe)
    # Retrieve the data
    candlestick_data = MetaTrader5.copy_rates_range(symbol, timeframe_value, start_time_utc, finish_time_utc)
    if dataframe:
        # Convert to a dataframe
        candlestick_dataframe = pandas.DataFrame(candlestick_data)
        # Add in symbol and timeframe columns
        candlestick_dataframe['symbol'] = symbol
        candlestick_dataframe['timeframe'] = timeframe
        # Convert integers into signed integers (postgres doesn't support unsigned int)
        candlestick_dataframe['time'] = candlestick_dataframe['time'].astype('int64')
        candlestick_dataframe['tick_volume'] = candlestick_dataframe['tick_volume'].astype('float64')
        candlestick_dataframe['spread'] = candlestick_dataframe['spread'].astype('int64')
        candlestick_dataframe['real_volume'] = candlestick_dataframe['real_volume'].astype('int64')
        # Return completed dataframe
        return candlestick_dataframe
    else:
        return candlestick_data


