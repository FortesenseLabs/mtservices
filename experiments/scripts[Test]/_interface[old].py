

# # https://www.mql5.com/en/docs/python_metatrader5
# # https://github.com/Quantreo/MetaTrader-5-AUTOMATED-TRADING-using-Python
# class MetaTraderInterface:
#     def __init__(self, login: str = "", password: str = "", server: str = "", terminal_path: str = r"C:/Metatrader5/terminal64.exe", files_path: str = "", portable: bool = True):
      
#         self.logger = mt5.get_logger(path_to_logfile='./logs/mt5_log.log',
#                                      loglevel=logging.INFO, time_utc=True)
        
#         # path=r'C:/root/Metatrader5/terminal64.exe',
#         #'OctaFX-Demo', # 'Deriv-Demo',
#         # financial => 21193089 | synthetic => 30565290
#         self.mt5_connected = mt5.connected(
#             path=terminal_path, 
#             portable=portable,
#             server=server, 
#             login=login, 
#             password=password,
#             timeout=5000,
#             logger=self.logger,  # default is None
#             ensure_trade_enabled=True,  # default is False
#             enable_real_trading=False,  # default is False
#             raise_on_errors=True,  # default is False
#             return_as_dict=False,  # default is False
#             return_as_native_python_objects=False,  # default is False
#         )

#     def start(self):
#         """
#             Start App
#         """
#         with self.mt5_connected as conn:
#             try:
#                 # Display data on the MetaTrader 5 package
#                 print("MetaTrader5 package author: ", mt5.__author__)
#                 print("MetaTrader5 package version: ", mt5.__version__)
#                 #
#                 symbols_obj = Symbols(mt5)
#                 sym_name = "Crash 1000 Index"  # "Crash 1000 Index", "EURUSD"
#                 sym_info = symbols_obj.get_symbol_info(sym_name)
#                 print(sym_info)
#                 # if sym_info != None:
#                 # rates = Rates(mt5)
#                 # print(symbols_obj.get_symbol_info_tick(sym_name))
#                 # print(rates.get_rates(symbol_pair=sym_name))

#                 #
#                 # print(AccountInfo(mt5).get_account_info())
#                 # print(AccountInfo(mt5).get_terminal_info())
#                 # print(Order(mt5).calc_order_margin())
#                 # print(Order(mt5).calc_order_profit())
#                 # print(Order(mt5).get_orders_history(group='*GBP*'))
#                 # print(Order(mt5).get_deals_history())
#                 #
#                 # TradingManager()
#                 # asyncio.run()
#                 # asyncio.create_task()
#                 # trading_manager = TradingManager(mt5)
#                 # trading_manager.main_task()
#                 # asyncio.create_task(trading_manager.main_task())
#                 # loop = asyncio.get_event_loop()
#                 # loop.run_forever()
#                 # asyncio.run(trading_manager.main_task())
#                 # loop = asyncio.get_event_loop()
#                 # loop.create_task(trading_manager.main_task())
#                 # try:
#                 #     loop.run_forever()  # Blocking. Run until stop() is called
#                 # except KeyboardInterrupt:
#                 #     print(f"KeyboardInterrupt.")

#             except mt5.MT5Error as e:
#                 print(f"Error = {e}")

#         return None


# #
# #  TODO: Work on symbol pairs with less than 0.01 points like  Crash 1000 Index, BTCUSD
# #  Error => INVALID_STOPS
# # cannot process or correctly calculate the stop_loss
# # https://www.mql5.com/en/forum/285056
# # https://www.mql5.com/en/forum/348327
# # https://www.forexfactory.com/thread/557391-invalid-stops-when-placing-an-order
# # https://support.axi.com/hc/en-us/articles/4403609910041-What-is-an-Invalid-Stop-Loss-SL-or-Take-Profit-TP-
# #
# # MetaTrader5 package author:  {'pymt5adapter': 'nicholishen', 'MetaTrader5': 'MetaQuotes Ltd.'}
# # MetaTrader5 package version:  {'pymt5adapter': '0.4.4', 'MetaTrader5': '5.0.43'}
# # Error = FAIL: Terminal: Call failed
# #
# # .py", line 137, in __enter__
# # pymt5adapter.core.MT5Error: INTERNAL_FAIL_TIMEOUT: IPC timeout
# #
# #
# # https://app.metaapi.cloud/accounts/add
# # https://github.com/agiliumtrade-ai
# # https://www.schwab.com/learn/story/3-order-types-market-limit-and-stop-orders
# # https://www.mql5.com/en/docs/integration/python_metatrader5/mt5positionsget_py
# # https://github.com/nicholishen/pymt5adapter
# #
# #
# # Error = INVALID_PARAMS: Invalid "sl" argument({'action': 1, 'volume': 0.5, 'type': 0, 'price': 1248.93554, 'sl': 1248, 'tp': None, 'deviation': 5, 'magic': 234000, 'comment': 'python script open'},){}
# #
# #
# # Solution to StopLoss => price + 5<any int or float>
# #
# #