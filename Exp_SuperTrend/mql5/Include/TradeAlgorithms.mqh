//+------------------------------------------------------------------+
//|                                        TradeAlgorithms.mqh      |
//|                           Optimized Trading Algorithms v2.0     |
//|                                  Performance Enhanced Library   |
//+------------------------------------------------------------------+
#property copyright "Optimized Trading Algorithms © 2025"
#property link      "https://www.mql5.com"
#property version   "2.00"

#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>

//+------------------------------------------------------------------+
//| Performance Optimization Constants                               |
//+------------------------------------------------------------------+
#define MAX_RETRY_ATTEMPTS 5
#define RETRY_DELAY_MS 100
#define CACHE_UPDATE_INTERVAL 5    // seconds
#define MAX_POSITIONS_CACHE 50

//+------------------------------------------------------------------+
//| Enhanced Enumerations                                            |
//+------------------------------------------------------------------+
enum MarginMode
{
   FREEMARGIN=0,     // MM from free margin on account
   BALANCE,          // MM from balance on account  
   LOSSFREEMARGIN,   // MM by losses from free margin on account
   LOSSBALANCE,      // MM by losses from balance on account
   LOT               // Fixed lot without changes
};

enum POSITION_STATE
{
   POSITION_UNKNOWN = 0,
   POSITION_OPENING = 1,
   POSITION_OPEN = 2,
   POSITION_MODIFYING = 3,
   POSITION_CLOSING = 4,
   POSITION_CLOSED = 5
};

//+------------------------------------------------------------------+
//| Performance Structures                                           |
//+------------------------------------------------------------------+
struct PositionCache
{
   ulong ticket;
   ENUM_POSITION_TYPE type;
   double volume;
   double openPrice;
   double stopLoss;
   double takeProfit;
   double currentPrice;
   double profit;
   datetime openTime;
   datetime lastUpdate;
   POSITION_STATE state;
   
   PositionCache() : ticket(0), type(POSITION_TYPE_BUY), volume(0), openPrice(0),
                    stopLoss(0), takeProfit(0), currentPrice(0), profit(0),
                    openTime(0), lastUpdate(0), state(POSITION_UNKNOWN) {}
};

struct TradeStatistics
{
   int totalTrades;
   int winningTrades;
   int losingTrades;
   double totalProfit;
   double totalLoss;
   double maxProfit;
   double maxLoss;
   double profitFactor;
   double winRate;
   datetime lastTradeTime;
   
   TradeStatistics() : totalTrades(0), winningTrades(0), losingTrades(0),
                      totalProfit(0), totalLoss(0), maxProfit(0), maxLoss(0),
                      profitFactor(0), winRate(0), lastTradeTime(0) {}
};

struct MarketInfo
{
   double bid;
   double ask;
   double spread;
   double point;
   int digits;
   double tickValue;
   double tickSize;
   datetime lastUpdate;
   
   MarketInfo() : bid(0), ask(0), spread(0), point(0), digits(0),
                 tickValue(0), tickSize(0), lastUpdate(0) {}
};

//+------------------------------------------------------------------+
//| Global Variables with Caching                                   |
//+------------------------------------------------------------------+
CTrade trade;
CSymbolInfo symbolInfo;
CPositionInfo positionInfo;

// Position caching for performance
PositionCache g_positionCache[];
int g_cacheSize = 0;
datetime g_lastCacheUpdate = 0;

// Market info caching
MarketInfo g_marketInfo;

// Trade statistics
TradeStatistics g_tradeStats;

// Error handling
static int g_lastError = 0;
static datetime g_lastErrorTime = 0;

//+------------------------------------------------------------------+
//| Performance Optimization Functions                               |
//+------------------------------------------------------------------+
void UpdateMarketInfoCache(string symbol)
{
   datetime currentTime = TimeCurrent();
   
   // Update cache every CACHE_UPDATE_INTERVAL seconds
   if(currentTime < g_marketInfo.lastUpdate + CACHE_UPDATE_INTERVAL)
      return;
   
   if(!symbolInfo.Name(symbol))
   {
      Print("ERROR: Failed to select symbol ", symbol);
      return;
   }
   
   g_marketInfo.bid = symbolInfo.Bid();
   g_marketInfo.ask = symbolInfo.Ask();
   g_marketInfo.spread = symbolInfo.Spread();
   g_marketInfo.point = symbolInfo.Point();
   g_marketInfo.digits = (int)symbolInfo.Digits();
   g_marketInfo.tickValue = symbolInfo.TradeTickValue();
   g_marketInfo.tickSize = symbolInfo.TradeTickSize();
   g_marketInfo.lastUpdate = currentTime;
}

void UpdatePositionCache(string symbol, ulong magicNumber = 0)
{
   datetime currentTime = TimeCurrent();
   
   // Update cache every few seconds for performance
   if(currentTime < g_lastCacheUpdate + 2)
      return;
   
   g_lastCacheUpdate = currentTime;
   g_cacheSize = 0;
   
   // Resize cache array if needed
   if(ArraySize(g_positionCache) < MAX_POSITIONS_CACHE)
      ArrayResize(g_positionCache, MAX_POSITIONS_CACHE);
   
   // Cache all relevant positions
   for(int i = 0; i < PositionsTotal() && g_cacheSize < MAX_POSITIONS_CACHE; i++)
   {
      if(positionInfo.SelectByIndex(i))
      {
         if(positionInfo.Symbol() == symbol && 
            (magicNumber == 0 || positionInfo.Magic() == magicNumber))
         {
            g_positionCache[g_cacheSize].ticket = positionInfo.Ticket();
            g_positionCache[g_cacheSize].type = (ENUM_POSITION_TYPE)positionInfo.PositionType();
            g_positionCache[g_cacheSize].volume = positionInfo.Volume();
            g_positionCache[g_cacheSize].openPrice = positionInfo.PriceOpen();
            g_positionCache[g_cacheSize].stopLoss = positionInfo.StopLoss();
            g_positionCache[g_cacheSize].takeProfit = positionInfo.TakeProfit();
            g_positionCache[g_cacheSize].currentPrice = positionInfo.PriceCurrent();
            g_positionCache[g_cacheSize].profit = positionInfo.Profit();
            g_positionCache[g_cacheSize].openTime = positionInfo.Time();
            g_positionCache[g_cacheSize].lastUpdate = currentTime;
            g_positionCache[g_cacheSize].state = POSITION_OPEN;
            
            g_cacheSize++;
         }
      }
   }
}

int FindCachedPosition(ENUM_POSITION_TYPE type, string symbol)
{
   for(int i = 0; i < g_cacheSize; i++)
   {
      if(g_positionCache[i].type == type)
         return i;
   }
   return -1;
}

bool HasOpenPosition(ENUM_POSITION_TYPE type, string symbol, ulong magicNumber = 0)
{
   UpdatePositionCache(symbol, magicNumber);
   return FindCachedPosition(type, symbol) >= 0;
}

//+------------------------------------------------------------------+
//| Enhanced Error Handling                                          |
//+------------------------------------------------------------------+
bool HandleTradeError(int errorCode, string operation)
{
   g_lastError = errorCode;
   g_lastErrorTime = TimeCurrent();
   
   switch(errorCode)
   {
      case TRADE_RETCODE_REQUOTE:
      case TRADE_RETCODE_PRICE_OFF:
      case TRADE_RETCODE_PRICE_CHANGED:
         Print("Retriable error in ", operation, ": ", errorCode, " - Will retry");
         return true; // Retriable error
         
      case TRADE_RETCODE_INVALID_STOPS:
         Print("Invalid stops in ", operation, ": ", errorCode);
         return false;
         
      case TRADE_RETCODE_NO_MONEY:
         Print("Insufficient funds for ", operation, ": ", errorCode);
         return false;
         
      case TRADE_RETCODE_MARKET_CLOSED:
         Print("Market closed for ", operation, ": ", errorCode);
         return false;
         
      case TRADE_RETCODE_DONE:
      case TRADE_RETCODE_DONE_PARTIAL:
         return false; // Success, no retry needed
         
      default:
         Print("Trade error in ", operation, ": ", errorCode);
         return false;
   }
}

//+------------------------------------------------------------------+
//| Enhanced Lot Size Calculation                                    |
//+------------------------------------------------------------------+
double GetLot(double MM, MarginMode MMMode, string symbol)
{
   UpdateMarketInfoCache(symbol);
   
   if(g_marketInfo.point <= 0 || g_marketInfo.tickValue <= 0)
   {
      Print("WARNING: Invalid market info, using default lot size");
      return 0.1;
   }
   
   double lot = 0.1;
   double margin = 0;
   
   switch(MMMode)
   {
      case FREEMARGIN:
         margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
         if(margin > 0)
            lot = NormalizeDouble(margin * MM / 100000, 2);
         break;
         
      case BALANCE:
         margin = AccountInfoDouble(ACCOUNT_BALANCE);
         if(margin > 0)
            lot = NormalizeDouble(margin * MM / 100000, 2);
         break;
         
      case LOSSFREEMARGIN:
         margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
         if(margin > 0)
         {
            double riskAmount = margin * MM / 100.0;
            lot = NormalizeDouble(riskAmount / 1000, 2); // Simplified risk calculation
         }
         break;
         
      case LOSSBALANCE:
         margin = AccountInfoDouble(ACCOUNT_BALANCE);
         if(margin > 0)
         {
            double riskAmount = margin * MM / 100.0;
            lot = NormalizeDouble(riskAmount / 1000, 2); // Simplified risk calculation
         }
         break;
         
      case LOT:
      default:
         lot = MM;
         break;
   }
   
   // Validate lot size against symbol specifications
   if(!symbolInfo.Name(symbol))
      return 0.1;
   
   double minLot = symbolInfo.LotsMin();
   double maxLot = symbolInfo.LotsMax();
   double stepLot = symbolInfo.LotsStep();
   
   if(stepLot > 0)
      lot = MathFloor(lot / stepLot) * stepLot;
   
   lot = MathMax(minLot, MathMin(maxLot, lot));
   
   return NormalizeDouble(lot, 2);
}

//+------------------------------------------------------------------+
//| Enhanced Position Opening Functions                              |
//+------------------------------------------------------------------+
bool BuyPositionOpen(bool Signal, string Symb, datetime SignalTime, 
                     double MM, MarginMode MMMode, int Deviation, 
                     int StopLoss, int TakeProfit, ulong MagicNumber = 0)
{
   if(!Signal)
      return false;
   
   // Check if position already exists
   if(HasOpenPosition(POSITION_TYPE_BUY, Symb, MagicNumber))
   {
      if(MagicNumber > 0)
         Print("BUY position already exists for ", Symb, " with Magic: ", MagicNumber);
      return false;
   }
   
   UpdateMarketInfoCache(Symb);
   
   double lot = GetLot(MM, MMMode, Symb);
   if(lot <= 0)
   {
      Print("ERROR: Invalid lot size calculated: ", lot);
      return false;
   }
   
   double price = g_marketInfo.ask;
   if(price <= 0)
   {
      Print("ERROR: Invalid ask price: ", price);
      return false;
   }
   
   // Calculate SL and TP with validation
   double sl = 0, tp = 0;
   if(StopLoss > 0)
   {
      sl = price - StopLoss * g_marketInfo.point;
      sl = NormalizeDouble(sl, g_marketInfo.digits);
   }
   
   if(TakeProfit > 0)
   {
      tp = price + TakeProfit * g_marketInfo.point;
      tp = NormalizeDouble(tp, g_marketInfo.digits);
   }
   
   // Validate stop levels
   if(!ValidateStopLevels(Symb, price, sl, tp, true))
      return false;
   
   // Configure trade object
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(Deviation);
   
   // Execute trade with retry logic
   bool result = false;
   for(int attempt = 1; attempt <= MAX_RETRY_ATTEMPTS; attempt++)
   {
      result = trade.Buy(lot, Symb, price, sl, tp);
      
      if(result)
      {
         ulong ticket = trade.ResultOrder();
         Print("BUY position opened successfully - Ticket: ", ticket, 
               " Lot: ", lot, " Price: ", price, " SL: ", sl, " TP: ", tp);
         
         // Update trade statistics
         UpdateTradeStatistics(true, 0); // Position opened
         
         // Invalidate position cache
         g_lastCacheUpdate = 0;
         return true;
      }
      
      int errorCode = trade.ResultRetcode();
      if(!HandleTradeError(errorCode, "BuyPositionOpen"))
         break;
      
      if(attempt < MAX_RETRY_ATTEMPTS)
      {
         Sleep(RETRY_DELAY_MS);
         // Update price for retry
         UpdateMarketInfoCache(Symb);
         price = g_marketInfo.ask;
      }
   }
   
   Print("Failed to open BUY position after ", MAX_RETRY_ATTEMPTS, " attempts. Last error: ", trade.ResultRetcode());
   return false;
}

bool SellPositionOpen(bool Signal, string Symb, datetime SignalTime, 
                      double MM, MarginMode MMMode, int Deviation, 
                      int StopLoss, int TakeProfit, ulong MagicNumber = 0)
{
   if(!Signal)
      return false;
   
   // Check if position already exists
   if(HasOpenPosition(POSITION_TYPE_SELL, Symb, MagicNumber))
   {
      if(MagicNumber > 0)
         Print("SELL position already exists for ", Symb, " with Magic: ", MagicNumber);
      return false;
   }
   
   UpdateMarketInfoCache(Symb);
   
   double lot = GetLot(MM, MMMode, Symb);
   if(lot <= 0)
   {
      Print("ERROR: Invalid lot size calculated: ", lot);
      return false;
   }
   
   double price = g_marketInfo.bid;
   if(price <= 0)
   {
      Print("ERROR: Invalid bid price: ", price);
      return false;
   }
   
   // Calculate SL and TP with validation
   double sl = 0, tp = 0;
   if(StopLoss > 0)
   {
      sl = price + StopLoss * g_marketInfo.point;
      sl = NormalizeDouble(sl, g_marketInfo.digits);
   }
   
   if(TakeProfit > 0)
   {
      tp = price - TakeProfit * g_marketInfo.point;
      tp = NormalizeDouble(tp, g_marketInfo.digits);
   }
   
   // Validate stop levels
   if(!ValidateStopLevels(Symb, price, sl, tp, false))
      return false;
   
   // Configure trade object
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(Deviation);
   
   // Execute trade with retry logic
   bool result = false;
   for(int attempt = 1; attempt <= MAX_RETRY_ATTEMPTS; attempt++)
   {
      result = trade.Sell(lot, Symb, price, sl, tp);
      
      if(result)
      {
         ulong ticket = trade.ResultOrder();
         Print("SELL position opened successfully - Ticket: ", ticket, 
               " Lot: ", lot, " Price: ", price, " SL: ", sl, " TP: ", tp);
         
         // Update trade statistics
         UpdateTradeStatistics(true, 0); // Position opened
         
         // Invalidate position cache
         g_lastCacheUpdate = 0;
         return true;
      }
      
      int errorCode = trade.ResultRetcode();
      if(!HandleTradeError(errorCode, "SellPositionOpen"))
         break;
      
      if(attempt < MAX_RETRY_ATTEMPTS)
      {
         Sleep(RETRY_DELAY_MS);
         // Update price for retry
         UpdateMarketInfoCache(Symb);
         price = g_marketInfo.bid;
      }
   }
   
   Print("Failed to open SELL position after ", MAX_RETRY_ATTEMPTS, " attempts. Last error: ", trade.ResultRetcode());
   return false;
}

//+------------------------------------------------------------------+
//| Enhanced Position Closing Functions                              |
//+------------------------------------------------------------------+
bool BuyPositionClose(bool Signal, string Symb, int Deviation, ulong MagicNumber = 0)
{
   if(!Signal)
      return false;
   
   UpdatePositionCache(Symb, MagicNumber);
   
   // Find BUY position in cache
   int cacheIndex = FindCachedPosition(POSITION_TYPE_BUY, Symb);
   if(cacheIndex < 0)
      return false; // No BUY position found
   
   ulong ticket = g_positionCache[cacheIndex].ticket;
   double profit = g_positionCache[cacheIndex].profit;
   
   // Configure trade object
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(Deviation);
   
   // Execute close with retry logic
   bool result = false;
   for(int attempt = 1; attempt <= MAX_RETRY_ATTEMPTS; attempt++)
   {
      result = trade.PositionClose(ticket);
      
      if(result)
      {
         Print("BUY position closed successfully - Ticket: ", ticket, " Profit: ", DoubleToString(profit, 2));
         
         // Update trade statistics
         UpdateTradeStatistics(false, profit); // Position closed
         
         // Invalidate position cache
         g_lastCacheUpdate = 0;
         return true;
      }
      
      int errorCode = trade.ResultRetcode();
      if(!HandleTradeError(errorCode, "BuyPositionClose"))
         break;
      
      if(attempt < MAX_RETRY_ATTEMPTS)
         Sleep(RETRY_DELAY_MS);
   }
   
   Print("Failed to close BUY position after ", MAX_RETRY_ATTEMPTS, " attempts. Last error: ", trade.ResultRetcode());
   return false;
}

bool SellPositionClose(bool Signal, string Symb, int Deviation, ulong MagicNumber = 0)
{
   if(!Signal)
      return false;
   
   UpdatePositionCache(Symb, MagicNumber);
   
   // Find SELL position in cache
   int cacheIndex = FindCachedPosition(POSITION_TYPE_SELL, Symb);
   if(cacheIndex < 0)
      return false; // No SELL position found
   
   ulong ticket = g_positionCache[cacheIndex].ticket;
   double profit = g_positionCache[cacheIndex].profit;
   
   // Configure trade object
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(Deviation);
   
   // Execute close with retry logic
   bool result = false;
   for(int attempt = 1; attempt <= MAX_RETRY_ATTEMPTS; attempt++)
   {
      result = trade.PositionClose(ticket);
      
      if(result)
      {
         Print("SELL position closed successfully - Ticket: ", ticket, " Profit: ", DoubleToString(profit, 2));
         
         // Update trade statistics
         UpdateTradeStatistics(false, profit); // Position closed
         
         // Invalidate position cache
         g_lastCacheUpdate = 0;
         return true;
      }
      
      int errorCode = trade.ResultRetcode();
      if(!HandleTradeError(errorCode, "SellPositionClose"))
         break;
      
      if(attempt < MAX_RETRY_ATTEMPTS)
         Sleep(RETRY_DELAY_MS);
   }
   
   Print("Failed to close SELL position after ", MAX_RETRY_ATTEMPTS, " attempts. Last error: ", trade.ResultRetcode());
   return false;
}

//+------------------------------------------------------------------+
//| Position Validation Functions                                    |
//+------------------------------------------------------------------+
bool ValidateStopLevels(string symbol, double price, double sl, double tp, bool isBuy)
{
   if(!symbolInfo.Name(symbol))
      return false;
   
   int stopsLevel = (int)symbolInfo.StopsLevel();
   double minDistance = stopsLevel * symbolInfo.Point();
   
   if(stopsLevel > 0)
   {
      if(isBuy)
      {
         if(sl > 0 && (price - sl) < minDistance)
         {
            Print("WARNING: SL too close to price. Required distance: ", minDistance);
            return false;
         }
         
         if(tp > 0 && (tp - price) < minDistance)
         {
            Print("WARNING: TP too close to price. Required distance: ", minDistance);
            return false;
         }
      }
      else // Sell
      {
         if(sl > 0 && (sl - price) < minDistance)
         {
            Print("WARNING: SL too close to price. Required distance: ", minDistance);
            return false;
         }
         
         if(tp > 0 && (price - tp) < minDistance)
         {
            Print("WARNING: TP too close to price. Required distance: ", minDistance);
            return false;
         }
      }
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Trade Statistics Functions                                       |
//+------------------------------------------------------------------+
void UpdateTradeStatistics(bool isOpening, double profit)
{
   if(isOpening)
   {
      // Position opened
      g_tradeStats.lastTradeTime = TimeCurrent();
   }
   else
   {
      // Position closed
      g_tradeStats.totalTrades++;
      
      if(profit > 0)
      {
         g_tradeStats.winningTrades++;
         g_tradeStats.totalProfit += profit;
         
         if(profit > g_tradeStats.maxProfit)
            g_tradeStats.maxProfit = profit;
      }
      else if(profit < 0)
      {
         g_tradeStats.losingTrades++;
         g_tradeStats.totalLoss += MathAbs(profit);
         
         if(MathAbs(profit) > g_tradeStats.maxLoss)
            g_tradeStats.maxLoss = MathAbs(profit);
      }
      
      // Calculate derived statistics
      if(g_tradeStats.totalTrades > 0)
      {
         g_tradeStats.winRate = ((double)g_tradeStats.winningTrades / g_tradeStats.totalTrades) * 100.0;
      }
      
      if(g_tradeStats.totalLoss > 0)
      {
         g_tradeStats.profitFactor = g_tradeStats.totalProfit / g_tradeStats.totalLoss;
      }
      
      g_tradeStats.lastTradeTime = TimeCurrent();
   }
}

void PrintTradeStatistics()
{
   Print("=== Trade Statistics ===");
   Print("Total Trades: ", g_tradeStats.totalTrades);
   Print("Winning Trades: ", g_tradeStats.winningTrades);
   Print("Losing Trades: ", g_tradeStats.losingTrades);
   Print("Win Rate: ", DoubleToString(g_tradeStats.winRate, 2), "%");
   Print("Total Profit: ", DoubleToString(g_tradeStats.totalProfit, 2));
   Print("Total Loss: ", DoubleToString(g_tradeStats.totalLoss, 2));
   Print("Net Profit: ", DoubleToString(g_tradeStats.totalProfit - g_tradeStats.totalLoss, 2));
   Print("Profit Factor: ", DoubleToString(g_tradeStats.profitFactor, 2));
   Print("Max Profit: ", DoubleToString(g_tradeStats.maxProfit, 2));
   Print("Max Loss: ", DoubleToString(g_tradeStats.maxLoss, 2));
   Print("Last Trade: ", TimeToString(g_tradeStats.lastTradeTime));
   Print("=======================");
}

//+------------------------------------------------------------------+
//| Utility Functions                                                |
//+------------------------------------------------------------------+
void GlobalVariableDel_(string symbol)
{
   string prefix = symbol + "_";
   for(int i = GlobalVariablesTotal() - 1; i >= 0; i--)
   {
      string name = GlobalVariableName(i);
      if(StringFind(name, prefix) == 0)
         GlobalVariableDel(name);
   }
}

void LoadHistory(datetime time, string symbol, ENUM_TIMEFRAMES timeframe)
{
   // Improved history loading with error checking
   datetime serverTime = TimeCurrent();
   datetime fromTime = time > 0 ? time : serverTime - PeriodSeconds(timeframe) * 1000;
   
   int bars = Bars(symbol, timeframe, fromTime, serverTime);
   if(bars < 100) // Ensure minimum history
   {
      int attempts = 0;
      while(bars < 100 && attempts < 10)
      {
         Sleep(100);
         bars = Bars(symbol, timeframe, fromTime, serverTime);
         attempts++;
      }
      
      if(bars < 100)
         Print("WARNING: Limited history available: ", bars, " bars");
   }
}

//+------------------------------------------------------------------+
//| New Bar Detection Class                                          |
//+------------------------------------------------------------------+
class CIsNewBar
{
private:
   datetime m_lastbar_time;
   string   m_symbol;
   ENUM_TIMEFRAMES m_timeframe;

public:
   CIsNewBar() : m_lastbar_time(0), m_symbol(""), m_timeframe(PERIOD_CURRENT) {}
   
   bool IsNewBar(string symbol, ENUM_TIMEFRAMES timeframe)
   {
      if(m_symbol != symbol || m_timeframe != timeframe)
      {
         m_symbol = symbol;
         m_timeframe = timeframe;
         m_lastbar_time = 0; // Reset for new symbol/timeframe
      }
      
      datetime current_time = iTime(symbol, timeframe, 0);
      
      if(current_time > m_lastbar_time)
      {
         m_lastbar_time = current_time;
         return true;
      }
      
      return false;
   }
   
   void Reset()
   {
      m_lastbar_time = 0;
   }
};

//+------------------------------------------------------------------+
//| Performance Monitoring                                           |
//+------------------------------------------------------------------+
void PrintPerformanceSummary()
{
   Print("=== Performance Summary ===");
   Print("Position Cache Size: ", g_cacheSize);
   Print("Last Cache Update: ", TimeToString(g_lastCacheUpdate));
   Print("Market Info Last Update: ", TimeToString(g_marketInfo.lastUpdate));
   Print("Current Spread: ", DoubleToString(g_marketInfo.spread, 1), " points");
   Print("Last Error: ", g_lastError, " at ", TimeToString(g_lastErrorTime));
   
   // Print trade statistics
   PrintTradeStatistics();
   
   Print("=========================");
}

//+------------------------------------------------------------------+
//| Initialization and Cleanup                                       |
//+------------------------------------------------------------------+
void InitializeTradeAlgorithms(string symbol)
{
   // Initialize caches
   ArrayResize(g_positionCache, MAX_POSITIONS_CACHE);
   g_cacheSize = 0;
   g_lastCacheUpdate = 0;
   
   // Initialize market info
   UpdateMarketInfoCache(symbol);
   
   // Initialize statistics
   ZeroMemory(g_tradeStats);
   
   // Reset error tracking
   g_lastError = 0;
   g_lastErrorTime = 0;
   
   Print("Trade algorithms initialized for ", symbol);
}

void CleanupTradeAlgorithms()
{
   // Print final statistics
   PrintPerformanceSummary();
   
   // Clear caches
   ArrayResize(g_positionCache, 0);
   g_cacheSize = 0;
   
   Print("Trade algorithms cleanup completed");
}

//+------------------------------------------------------------------+