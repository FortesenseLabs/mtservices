class TimeFrames:
    TIMEFRAME_M1 = "M1"
    TIMEFRAME_M5 = "M5"
    TIMEFRAME_M15 = "M15"
    TIMEFRAME_M30 = "M30"
    TIMEFRAME_H1 = "H1"
    TIMEFRAME_H4 = "H4"
    TIMEFRAME_D1 = "D1"
    TIMEFRAME_W1 = "W1"
    TIMEFRAME_MN = "MN"


        # self.ORDER_TYPES = {
        #     'BUY': self.ORDER_TYPE_BUY,
        #     'SELL': self.ORDER_TYPE_SELL,
        #     'BUY_LIMIT': self.ORDER_TYPE_BUY_LIMIT,
        #     'SELL_LIMIT': self.ORDER_TYPE_SELL_LIMIT,
        #     'BUY_STOP': self.ORDER_TYPE_BUY_STOP,
        #     'SELL_STOP': self.ORDER_TYPE_SELL_STOP,
        #     'BUY_STOP_LIMIT': self.ORDER_TYPE_BUY_STOP_LIMIT,
        #     'SELL_STOP_LIMIT': self.ORDER_TYPE_SELL_STOP_LIMIT,
        #     'CLOSE_BY': self.ORDER_TYPE_CLOSE_BY,
        # }
    

        # self.TRADE_REQUEST_ACTIONS = {
        #     # Place an order for an instant deal with the specified parameters (set a market order)
        #     'DEAL': self.TRADE_ACTION_DEAL,
        #     # Place an order for performing a deal at specified conditions (pending order)
        #     'PENDING': self.TRADE_ACTION_PENDING,
        #     # Change open position Stop Loss and Take Profit
        #     'SLTP': self.TRADE_ACTION_SLTP,
        #     # Change parameters of the previously placed trading order
        #     'MODIFY': self.TRADE_ACTION_MODIFY,
        #     # Remove previously placed pending order
        #     'REMOVE': self.TRADE_ACTION_REMOVE,
        #     # Close a position by an opposite one
        #     'CLOSE_BY': self.TRADE_ACTION_CLOSE_BY,
        # }

        # self.ORDER_TYPE_FILLING = {
        #     'FOK': self.ORDER_FILLING_FOK,
        #     'IOC': self.ORDER_FILLING_IOC,
        #     'RETURN': self.ORDER_FILLING_RETURN
        # }

        # self.ORDER_TYPE_TIME = {
        #     # The order stays in the queue until it is manually canceled
        #     'GTC': self.ORDER_TIME_GTC,
        #     # The order is active only during the current trading day
        #     'DAY': self.ORDER_TIME_DAY,
        #     # The order is active until the specified date
        #     'SPECIFIED': self.ORDER_TIME_SPECIFIED,
        #     # The order is active until 23:59:59 of the specified day. If this time appears to be out of a trading session, the expiration is processed at the nearest trading time.
        #     'SPECIFIED_DAY': self.ORDER_TIME_SPECIFIED_DAY
        # }


# from sqlalchemy import Column, Float, Integer, String, DateTime
# from sqlalchemy.ext.declarative import declarative_base

# Base = declarative_base()

# class TableName(Base):
#     __tablename__ = 'table_name'

#     id = Column(Integer, primary_key=True)
#     current_datetime = Column(DateTime)
#     symbol = Column(String)
#     time_frame = Column(String)
#     time = Column(String)
#     open = Column(Float)
#     high = Column(Float)
#     low = Column(Float)
#     close = Column(Float)
#     tick_volume = Column(Integer)