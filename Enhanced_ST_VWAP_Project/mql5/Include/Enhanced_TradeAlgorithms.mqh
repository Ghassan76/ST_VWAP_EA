//+------------------------------------------------------------------+
//|                                     Enhanced_TradeAlgorithms.mqh |
//|                   Enhanced Trading Algorithms for ST&VWAP System |
//|                                    Performance & Analytics v2.0   |
//+------------------------------------------------------------------+
#property copyright "Enhanced Trading Algorithms © 2025"
#property link      "https://www.mql5.com"
#property version   "2.00"

#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>

//+------------------------------------------------------------------+
//| Performance Optimization Constants                               |
//+------------------------------------------------------------------+
#define MAX_CACHED_POSITIONS 100
#define MEMORY_CLEANUP_INTERVAL 3600  // 1 hour
#define PERFORMANCE_BUFFER_SIZE 1000
#define MAX_HISTORY_RECORDS 10000

//+------------------------------------------------------------------+
//| Enumerations                                                     |
//+------------------------------------------------------------------+
enum MarginMode
{
   FREEMARGIN=0,     // MM from free margin on account
   BALANCE,          // MM from balance on account  
   LOSSFREEMARGIN,   // MM by losses from free margin on account
   LOSSBALANCE,      // MM by losses from balance on account
   LOT               // Fixed lot without changes
};

enum EA_STATE 
{ 
   ST_READY = 0, 
   ST_IN_TRADE, 
   ST_FROZEN, 
   ST_COOLDOWN, 
   ST_ARMING 
};

enum DIR 
{ 
   DIR_NONE = 0, 
   DIR_BUY = 1, 
   DIR_SELL = -1 
};

enum FREEZE_REASON 
{ 
   FREEZE_TRADE_CLOSE = 0, 
   FREEZE_DATA_MISSING, 
   FREEZE_MANUAL 
};

enum MARKET_STATE
{
   MARKET_UNKNOWN = 0,
   MARKET_TRENDING,
   MARKET_RANGING,
   MARKET_VOLATILE,
   MARKET_QUIET
};

//+------------------------------------------------------------------+
//| Enhanced Structures for Performance & Analytics                 |
//+------------------------------------------------------------------+
struct SessionTime
{
   bool   enabled;
   int    startHour;
   int    startMinute;
   int    endHour;
   int    endMinute;
   
   SessionTime() : enabled(false), startHour(0), startMinute(0), endHour(0), endMinute(0) {}
};

struct PositionTracker
{
   ulong ticket;
   int slModifications;
   int tpModifications;
   ulong lastTickTime;
   bool breakEvenExecuted;
   datetime entryTime;
   double entryPrice;
   double originalSL;
   double originalTP;
   double maxProfit;          // Track maximum profit reached
   double maxDrawdown;        // Track maximum drawdown
   double runningPnL;         // Current unrealized P&L
   
   PositionTracker() : ticket(0), slModifications(0), tpModifications(0), 
                      lastTickTime(0), breakEvenExecuted(false), entryTime(0),
                      entryPrice(0), originalSL(0), originalTP(0), maxProfit(0),
                      maxDrawdown(0), runningPnL(0) {}
};

struct TradeStats
{
   int totalTrades;
   int winTrades;
   int loseTrades;
   double totalProfit;
   double maxDrawdown;
   datetime lastTradeTime;
   double avgWinAmount;       // Average winning trade amount
   double avgLossAmount;      // Average losing trade amount
   double profitFactor;       // Gross profit / Gross loss
   double sharpeRatio;        // Risk-adjusted return measure
   double maxConsecutiveWins;
   double maxConsecutiveLosses;
   double currentStreak;      // Current win/loss streak
   
   TradeStats() : totalTrades(0), winTrades(0), loseTrades(0), 
                 totalProfit(0), maxDrawdown(0), lastTradeTime(0),
                 avgWinAmount(0), avgLossAmount(0), profitFactor(0),
                 sharpeRatio(0), maxConsecutiveWins(0), maxConsecutiveLosses(0),
                 currentStreak(0) {}
};

struct MarketConditions
{
   double volatility;         // ATR-based volatility measure
   double trendStrength;      // Trend strength indicator
   MARKET_STATE state;        // Current market state
   double spreadCost;         // Current spread cost
   double liquidity;          // Liquidity measure
   datetime lastUpdate;       // Last update time
   double momentum;           // Price momentum indicator
   
   MarketConditions() : volatility(0), trendStrength(0), state(MARKET_UNKNOWN),
                       spreadCost(0), liquidity(0), lastUpdate(0), momentum(0) {}
};

struct PerformanceMetrics
{
   double totalReturn;        // Total return percentage
   double annualizedReturn;   // Annualized return
   double volatilityIndex;    // Strategy volatility
   double maxDrawdownPercent; // Max drawdown as percentage
   double recoveryFactor;     // Total return / Max drawdown
   double calmarRatio;        // Annualized return / Max drawdown
   double sortinoRatio;       // Downside deviation adjusted return
   int tradesPerDay;          // Average trades per day
   double avgHoldingTime;     // Average holding time in hours
   datetime startTime;        // Strategy start time
   
   PerformanceMetrics() : totalReturn(0), annualizedReturn(0), volatilityIndex(0),
                         maxDrawdownPercent(0), recoveryFactor(0), calmarRatio(0),
                         sortinoRatio(0), tradesPerDay(0), avgHoldingTime(0), startTime(0) {}
};

//+------------------------------------------------------------------+
//| Memory Pool for Efficient Array Management                      |
//+------------------------------------------------------------------+
template<typename T>
class CMemoryPool
{
private:
   T m_pool[];
   bool m_used[];
   int m_size;
   int m_nextFree;
   
public:
   CMemoryPool(int size = PERFORMANCE_BUFFER_SIZE)
   {
      m_size = size;
      ArrayResize(m_pool, m_size);
      ArrayResize(m_used, m_size);
      ArrayInitialize(m_used, false);
      m_nextFree = 0;
   }
   
   int Allocate()
   {
      for(int i = m_nextFree; i < m_size; i++)
      {
         if(!m_used[i])
         {
            m_used[i] = true;
            m_nextFree = i + 1;
            return i;
         }
      }
      
      // Search from beginning if no free slot found
      for(int i = 0; i < m_nextFree; i++)
      {
         if(!m_used[i])
         {
            m_used[i] = true;
            m_nextFree = i + 1;
            return i;
         }
      }
      
      return -1; // Pool full
   }
   
   void Deallocate(int index)
   {
      if(index >= 0 && index < m_size)
      {
         m_used[index] = false;
         if(index < m_nextFree)
            m_nextFree = index;
      }
   }
   
   T* Get(int index)
   {
      if(index >= 0 && index < m_size && m_used[index])
         return &m_pool[index];
      return NULL;
   }
   
   void Clear()
   {
      ArrayInitialize(m_used, false);
      m_nextFree = 0;
   }
};

//+------------------------------------------------------------------+
//| Global Variables with Performance Optimization                  |
//+------------------------------------------------------------------+
CTrade         trade;
CSymbolInfo    symbolInfo;
CPositionInfo  positionInfo;
COrderInfo     orderInfo;

// Optimized position tracking with memory pool
CMemoryPool<PositionTracker> g_positionPool;
int g_activePositions[];
int g_positionCount = 0;

// Enhanced analytics structures
TradeStats g_tradeStats;
MarketConditions g_marketConditions;
PerformanceMetrics g_performanceMetrics;

// Caching variables for performance
static double g_cachedPrice = 0;
static datetime g_lastPriceUpdate = 0;
static double g_cachedSpread = 0;
static datetime g_lastSpreadUpdate = 0;
static datetime g_lastMemoryCleanup = 0;

EA_STATE g_eaState = ST_READY;
datetime g_lastStateChange = 0;
datetime g_freezeUntil = 0;
datetime g_cooldownUntil = 0;

//+------------------------------------------------------------------+
//| Performance-Optimized Utility Functions                         |
//+------------------------------------------------------------------+
string GV(const string tag, const ulong mag) 
{ 
   return _Symbol + "_" + tag + "_" + (string)mag; 
}

void GlobalVariableDel_(const string symbol)
{
   string prefix = symbol + "_";
   for(int i = GlobalVariablesTotal() - 1; i >= 0; i--)
   {
      string name = GlobalVariableName(i);
      if(StringFind(name, prefix) == 0)
         GlobalVariableDel(name);
   }
}

// Optimized price retrieval with caching
double GetCachedPrice(bool forceUpdate = false)
{
   datetime currentTime = TimeCurrent();
   if(forceUpdate || currentTime > g_lastPriceUpdate + 1) // Cache for 1 second
   {
      g_cachedPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      g_lastPriceUpdate = currentTime;
   }
   return g_cachedPrice;
}

// Optimized spread retrieval with caching
double GetCachedSpread(bool forceUpdate = false)
{
   datetime currentTime = TimeCurrent();
   if(forceUpdate || currentTime > g_lastSpreadUpdate + 5) // Cache for 5 seconds
   {
      g_cachedSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
      g_lastSpreadUpdate = currentTime;
   }
   return g_cachedSpread;
}

// Memory cleanup function
void PerformMemoryCleanup()
{
   datetime currentTime = TimeCurrent();
   if(currentTime > g_lastMemoryCleanup + MEMORY_CLEANUP_INTERVAL)
   {
      // Clean up closed positions
      for(int i = g_positionCount - 1; i >= 0; i--)
      {
         PositionTracker* tracker = g_positionPool.Get(g_activePositions[i]);
         if(tracker != NULL && !PositionSelectByTicket(tracker.ticket))
         {
            g_positionPool.Deallocate(g_activePositions[i]);
            // Remove from active array
            for(int j = i; j < g_positionCount - 1; j++)
            {
               g_activePositions[j] = g_activePositions[j + 1];
            }
            g_positionCount--;
         }
      }
      
      g_lastMemoryCleanup = currentTime;
   }
}

//+------------------------------------------------------------------+
//| Enhanced Market Analysis Functions                               |
//+------------------------------------------------------------------+
void UpdateMarketConditions()
{
   double atr = iATR(_Symbol, PERIOD_M15, 14);
   double currentAtr[];
   if(CopyBuffer(atr, 0, 0, 1, currentAtr) > 0)
   {
      g_marketConditions.volatility = currentAtr[0];
   }
   
   // Calculate trend strength using price momentum
   double price = GetCachedPrice();
   double priceChange = price - g_cachedPrice;
   g_marketConditions.momentum = priceChange / _Point;
   
   // Update spread cost
   g_marketConditions.spreadCost = GetCachedSpread() * _Point;
   
   // Determine market state based on volatility and momentum
   if(g_marketConditions.volatility > 0)
   {
      double avgVolatility = g_marketConditions.volatility * 1.5; // Threshold multiplier
      
      if(MathAbs(g_marketConditions.momentum) > avgVolatility)
      {
         g_marketConditions.state = MARKET_TRENDING;
         g_marketConditions.trendStrength = MathAbs(g_marketConditions.momentum) / avgVolatility;
      }
      else if(g_marketConditions.volatility > avgVolatility * 0.8)
      {
         g_marketConditions.state = MARKET_VOLATILE;
         g_marketConditions.trendStrength = 0.5;
      }
      else if(g_marketConditions.volatility < avgVolatility * 0.3)
      {
         g_marketConditions.state = MARKET_QUIET;
         g_marketConditions.trendStrength = 0.1;
      }
      else
      {
         g_marketConditions.state = MARKET_RANGING;
         g_marketConditions.trendStrength = 0.3;
      }
   }
   
   g_marketConditions.lastUpdate = TimeCurrent();
   
   IndicatorRelease(atr);
}

//+------------------------------------------------------------------+
//| Enhanced Performance Metrics Calculation                        |
//+------------------------------------------------------------------+
void CalculatePerformanceMetrics()
{
   if(g_performanceMetrics.startTime == 0)
      g_performanceMetrics.startTime = TimeCurrent();
   
   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   double initialBalance = AccountInfoDouble(ACCOUNT_BALANCE) - g_tradeStats.totalProfit;
   
   if(initialBalance > 0)
   {
      g_performanceMetrics.totalReturn = (g_tradeStats.totalProfit / initialBalance) * 100.0;
      
      // Calculate annualized return
      datetime currentTime = TimeCurrent();
      double daysPassed = (currentTime - g_performanceMetrics.startTime) / 86400.0;
      if(daysPassed > 0)
      {
         g_performanceMetrics.annualizedReturn = (g_performanceMetrics.totalReturn / daysPassed) * 365.0;
         g_performanceMetrics.tradesPerDay = g_tradeStats.totalTrades / daysPassed;
      }
   }
   
   // Calculate advanced ratios
   if(g_tradeStats.maxDrawdown > 0)
   {
      g_performanceMetrics.maxDrawdownPercent = (g_tradeStats.maxDrawdown / initialBalance) * 100.0;
      g_performanceMetrics.recoveryFactor = g_performanceMetrics.totalReturn / g_performanceMetrics.maxDrawdownPercent;
      
      if(g_performanceMetrics.maxDrawdownPercent > 0)
         g_performanceMetrics.calmarRatio = g_performanceMetrics.annualizedReturn / g_performanceMetrics.maxDrawdownPercent;
   }
   
   // Calculate profit factor
   double grossProfit = g_tradeStats.avgWinAmount * g_tradeStats.winTrades;
   double grossLoss = MathAbs(g_tradeStats.avgLossAmount * g_tradeStats.loseTrades);
   
   if(grossLoss > 0)
      g_tradeStats.profitFactor = grossProfit / grossLoss;
}

//+------------------------------------------------------------------+
//| State Management Functions                                       |
//+------------------------------------------------------------------+
void SetEAState(EA_STATE newState, FREEZE_REASON reason = FREEZE_TRADE_CLOSE)
{
   if(g_eaState != newState)
   {
      g_eaState = newState;
      g_lastStateChange = TimeCurrent();
      
      string stateText = EnumToString(newState);
      Print("EA State changed to: ", stateText);
      
      if(newState == ST_FROZEN)
      {
         g_freezeUntil = TimeCurrent() + 15 * 60; // 15 minutes freeze
         string reasonText = EnumToString(reason);
         Print("EA Frozen due to: ", reasonText);
      }
      else if(newState == ST_COOLDOWN)
      {
         g_cooldownUntil = TimeCurrent() + 5 * 60; // 5 minutes cooldown
      }
   }
}

EA_STATE GetEAState()
{
   // Check if freeze/cooldown period has expired
   datetime current = TimeCurrent();
   
   if(g_eaState == ST_FROZEN && current >= g_freezeUntil)
   {
      SetEAState(ST_READY);
   }
   else if(g_eaState == ST_COOLDOWN && current >= g_cooldownUntil)
   {
      SetEAState(ST_READY);
   }
   
   return g_eaState;
}

bool IsEAReadyToTrade()
{
   return GetEAState() == ST_READY;
}

//+------------------------------------------------------------------+
//| Enhanced Position Tracking Functions                            |
//+------------------------------------------------------------------+
int FindPositionTrackerIndex(ulong ticket)
{
   for(int i = 0; i < g_positionCount; i++)
   {
      PositionTracker* tracker = g_positionPool.Get(g_activePositions[i]);
      if(tracker != NULL && tracker.ticket == ticket)
         return i;
   }
   return -1;
}

void AddPositionTracker(ulong ticket, double entryPrice, double sl, double tp)
{
   int poolIndex = g_positionPool.Allocate();
   if(poolIndex >= 0)
   {
      PositionTracker* tracker = g_positionPool.Get(poolIndex);
      if(tracker != NULL)
      {
         tracker.ticket = ticket;
         tracker.entryTime = TimeCurrent();
         tracker.entryPrice = entryPrice;
         tracker.originalSL = sl;
         tracker.originalTP = tp;
         tracker.slModifications = 0;
         tracker.tpModifications = 0;
         tracker.breakEvenExecuted = false;
         tracker.lastTickTime = GetTickCount();
         tracker.maxProfit = 0;
         tracker.maxDrawdown = 0;
         tracker.runningPnL = 0;
         
         // Add to active positions array
         if(g_positionCount < MAX_CACHED_POSITIONS)
         {
            g_activePositions[g_positionCount] = poolIndex;
            g_positionCount++;
         }
      }
   }
}

void RemovePositionTracker(ulong ticket)
{
   int index = FindPositionTrackerIndex(ticket);
   if(index >= 0)
   {
      // Update trade statistics before removing
      PositionTracker* tracker = g_positionPool.Get(g_activePositions[index]);
      if(tracker != NULL)
      {
         UpdateTradeStats(tracker.runningPnL);
      }
      
      g_positionPool.Deallocate(g_activePositions[index]);
      
      // Remove from active array
      for(int i = index; i < g_positionCount - 1; i++)
      {
         g_activePositions[i] = g_activePositions[i + 1];
      }
      g_positionCount--;
   }
}

void UpdatePositionMetrics(ulong ticket)
{
   int index = FindPositionTrackerIndex(ticket);
   if(index >= 0)
   {
      PositionTracker* tracker = g_positionPool.Get(g_activePositions[index]);
      if(tracker != NULL && PositionSelectByTicket(ticket))
      {
         double currentPnL = PositionGetDouble(POSITION_PROFIT);
         tracker.runningPnL = currentPnL;
         
         if(currentPnL > tracker.maxProfit)
            tracker.maxProfit = currentPnL;
         
         if(currentPnL < 0 && MathAbs(currentPnL) > tracker.maxDrawdown)
            tracker.maxDrawdown = MathAbs(currentPnL);
      }
   }
}

//+------------------------------------------------------------------+
//| Enhanced Trade Statistics                                        |
//+------------------------------------------------------------------+
void UpdateTradeStats(double profit)
{
   g_tradeStats.totalTrades++;
   g_tradeStats.totalProfit += profit;
   g_tradeStats.lastTradeTime = TimeCurrent();
   
   if(profit > 0)
   {
      g_tradeStats.winTrades++;
      g_tradeStats.avgWinAmount = ((g_tradeStats.avgWinAmount * (g_tradeStats.winTrades - 1)) + profit) / g_tradeStats.winTrades;
      
      if(g_tradeStats.currentStreak >= 0)
         g_tradeStats.currentStreak++;
      else
         g_tradeStats.currentStreak = 1;
      
      if(g_tradeStats.currentStreak > g_tradeStats.maxConsecutiveWins)
         g_tradeStats.maxConsecutiveWins = g_tradeStats.currentStreak;
   }
   else
   {
      g_tradeStats.loseTrades++;
      g_tradeStats.avgLossAmount = ((g_tradeStats.avgLossAmount * (g_tradeStats.loseTrades - 1)) + profit) / g_tradeStats.loseTrades;
      
      if(g_tradeStats.currentStreak <= 0)
         g_tradeStats.currentStreak--;
      else
         g_tradeStats.currentStreak = -1;
      
      if(MathAbs(g_tradeStats.currentStreak) > g_tradeStats.maxConsecutiveLosses)
         g_tradeStats.maxConsecutiveLosses = MathAbs(g_tradeStats.currentStreak);
   }
   
   // Update maximum drawdown
   if(g_tradeStats.totalProfit < 0 && MathAbs(g_tradeStats.totalProfit) > g_tradeStats.maxDrawdown)
      g_tradeStats.maxDrawdown = MathAbs(g_tradeStats.totalProfit);
   
   // Recalculate performance metrics
   CalculatePerformanceMetrics();
}

//+------------------------------------------------------------------+
//| Lot Size Calculation Functions (Optimized)                      |
//+------------------------------------------------------------------+
double GetLot(double MM, MarginMode MMMode, string symbol)
{
   if(!symbolInfo.Name(symbol))
      return 0.1;
      
   double lot = 0.1;
   double margin = 0;
   
   switch(MMMode)
   {
      case FREEMARGIN:
         margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
         lot = NormalizeDouble(margin * MM / 100000, 2);
         break;
         
      case BALANCE:
         margin = AccountInfoDouble(ACCOUNT_BALANCE);
         lot = NormalizeDouble(margin * MM / 100000, 2);
         break;
         
      case LOSSFREEMARGIN:
         margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
         lot = NormalizeDouble(margin * MM / 100000, 2);
         break;
         
      case LOSSBALANCE:
         margin = AccountInfoDouble(ACCOUNT_BALANCE);
         lot = NormalizeDouble(margin * MM / 100000, 2);
         break;
         
      case LOT:
      default:
         lot = MM;
         break;
   }
   
   // Validate lot size
   double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   double stepLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   
   if(stepLot > 0)
   {
      lot = MathFloor(lot / stepLot) * stepLot;
   }
   
   lot = MathMax(minLot, MathMin(maxLot, lot));
   
   return lot;
}

//+------------------------------------------------------------------+
//| Session Time Management (Optimized)                             |
//+------------------------------------------------------------------+
bool IsInSession(const SessionTime &session, datetime time)
{
   if(!session.enabled)
      return false;
      
   MqlDateTime timeStruct;
   TimeToStruct(time, timeStruct);
   
   int currentMinutes = timeStruct.hour * 60 + timeStruct.min;
   int sessionStart = session.startHour * 60 + session.startMinute;
   int sessionEnd = session.endHour * 60 + session.endMinute;
   
   if(sessionStart <= sessionEnd)
   {
      return (currentMinutes >= sessionStart && currentMinutes <= sessionEnd);
   }
   else // Overnight session
   {
      return (currentMinutes >= sessionStart || currentMinutes <= sessionEnd);
   }
}

//+------------------------------------------------------------------+
//| Enhanced Position Management Functions                           |
//+------------------------------------------------------------------+
bool BuyPositionOpen(bool Signal, const string Symb, datetime SignalTime, 
                     double MM, MarginMode MMMode, int Deviation, 
                     int StopLoss, int TakeProfit, ulong MagicNumber = 0)
{
   if(!Signal) return false;
   
   double lot = GetLot(MM, MMMode, Symb);
   if(lot <= 0) return false;
   
   double price = SymbolInfoDouble(Symb, SYMBOL_ASK);
   if(price <= 0) return false;
   
   double sl = (StopLoss > 0) ? price - StopLoss * SymbolInfoDouble(Symb, SYMBOL_POINT) : 0;
   double tp = (TakeProfit > 0) ? price + TakeProfit * SymbolInfoDouble(Symb, SYMBOL_POINT) : 0;
   
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(Deviation);
   
   bool result = trade.Buy(lot, Symb, price, sl, tp);
   
   if(result)
   {
      ulong ticket = trade.ResultOrder();
      AddPositionTracker(ticket, price, sl, tp);
      
      Print("BUY position opened: Ticket=", ticket, " Lot=", lot, " Price=", price);
   }
   else
   {
      Print("BUY position failed: ", trade.ResultComment());
   }
   
   return result;
}

bool SellPositionOpen(bool Signal, const string Symb, datetime SignalTime, 
                      double MM, MarginMode MMMode, int Deviation, 
                      int StopLoss, int TakeProfit, ulong MagicNumber = 0)
{
   if(!Signal) return false;
   
   double lot = GetLot(MM, MMMode, Symb);
   if(lot <= 0) return false;
   
   double price = SymbolInfoDouble(Symb, SYMBOL_BID);
   if(price <= 0) return false;
   
   double sl = (StopLoss > 0) ? price + StopLoss * SymbolInfoDouble(Symb, SYMBOL_POINT) : 0;
   double tp = (TakeProfit > 0) ? price - TakeProfit * SymbolInfoDouble(Symb, SYMBOL_POINT) : 0;
   
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(Deviation);
   
   bool result = trade.Sell(lot, Symb, price, sl, tp);
   
   if(result)
   {
      ulong ticket = trade.ResultOrder();
      AddPositionTracker(ticket, price, sl, tp);
      
      Print("SELL position opened: Ticket=", ticket, " Lot=", lot, " Price=", price);
   }
   else
   {
      Print("SELL position failed: ", trade.ResultComment());
   }
   
   return result;
}

bool BuyPositionClose(bool Signal, const string Symb, int Deviation, ulong MagicNumber = 0)
{
   if(!Signal) return false;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(positionInfo.SelectByIndex(i))
      {
         if(positionInfo.Symbol() == Symb && 
            positionInfo.Magic() == MagicNumber &&
            positionInfo.PositionType() == POSITION_TYPE_BUY)
         {
            trade.SetExpertMagicNumber(MagicNumber);
            trade.SetDeviationInPoints(Deviation);
            
            bool result = trade.PositionClose(positionInfo.Ticket());
            
            if(result)
            {
               RemovePositionTracker(positionInfo.Ticket());
               Print("BUY position closed: Ticket=", positionInfo.Ticket());
            }
            
            return result;
         }
      }
   }
   
   return false;
}

bool SellPositionClose(bool Signal, const string Symb, int Deviation, ulong MagicNumber = 0)
{
   if(!Signal) return false;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(positionInfo.SelectByIndex(i))
      {
         if(positionInfo.Symbol() == Symb && 
            positionInfo.Magic() == MagicNumber &&
            positionInfo.PositionType() == POSITION_TYPE_SELL)
         {
            trade.SetExpertMagicNumber(MagicNumber);
            trade.SetDeviationInPoints(Deviation);
            
            bool result = trade.PositionClose(positionInfo.Ticket());
            
            if(result)
            {
               RemovePositionTracker(positionInfo.Ticket());
               Print("SELL position closed: Ticket=", positionInfo.Ticket());
            }
            
            return result;
         }
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Enhanced Break-Even Processing                                   |
//+------------------------------------------------------------------+
void ProcessBreakEven(double profitPercent, double offsetPercent)
{
   for(int i = 0; i < g_positionCount; i++)
   {
      PositionTracker* tracker = g_positionPool.Get(g_activePositions[i]);
      if(tracker == NULL || tracker.breakEvenExecuted) continue;
      
      if(!PositionSelectByTicket(tracker.ticket)) continue;
      
      double currentPrice = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ?
                           SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                           SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      
      double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double takeProfit = PositionGetDouble(POSITION_TP);
      
      if(takeProfit <= 0) continue;
      
      bool isBuy = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
      double profitDistance = isBuy ? (takeProfit - entryPrice) : (entryPrice - takeProfit);
      double currentProfit = isBuy ? (currentPrice - entryPrice) : (entryPrice - currentPrice);
      
      if(profitDistance > 0 && (currentProfit / profitDistance) >= (profitPercent / 100.0))
      {
         double newSL = entryPrice + (isBuy ? 1 : -1) * (offsetPercent / 100.0) * profitDistance;
         
         trade.PositionModify(tracker.ticket, newSL, takeProfit);
         tracker.breakEvenExecuted = true;
         
         Print("Break-even executed for ticket: ", tracker.ticket, " New SL: ", newSL);
      }
      
      // Update position metrics
      UpdatePositionMetrics(tracker.ticket);
   }
}

//+------------------------------------------------------------------+
//| Performance Monitoring and Cleanup                              |
//+------------------------------------------------------------------+
void PerformanceUpdate()
{
   // Update market conditions
   UpdateMarketConditions();
   
   // Update position metrics for all active positions
   for(int i = 0; i < g_positionCount; i++)
   {
      PositionTracker* tracker = g_positionPool.Get(g_activePositions[i]);
      if(tracker != NULL)
      {
         UpdatePositionMetrics(tracker.ticket);
      }
   }
   
   // Perform memory cleanup if needed
   PerformMemoryCleanup();
   
   // Calculate performance metrics
   CalculatePerformanceMetrics();
}

//+------------------------------------------------------------------+
//| Initialization and Cleanup Functions                            |
//+------------------------------------------------------------------+
void InitializeEnhancedAlgorithms()
{
   // Initialize memory pools
   ArrayResize(g_activePositions, MAX_CACHED_POSITIONS);
   g_positionCount = 0;
   
   // Initialize performance metrics
   g_performanceMetrics.startTime = TimeCurrent();
   
   // Cache initial values
   GetCachedPrice(true);
   GetCachedSpread(true);
   
   Print("Enhanced Trade Algorithms initialized successfully");
}

void CleanupEnhancedAlgorithms()
{
   // Clear memory pools
   g_positionPool.Clear();
   g_positionCount = 0;
   
   // Clean up global variables
   GlobalVariableDel_(_Symbol);
   
   Print("Enhanced Trade Algorithms cleaned up");
}

//+------------------------------------------------------------------+
//| Advanced Analytics Export Functions                              |
//+------------------------------------------------------------------+
string GetPerformanceReport()
{
   string report = "=== ENHANCED PERFORMANCE REPORT ===\n";
   report += StringFormat("Total Trades: %d\n", g_tradeStats.totalTrades);
   report += StringFormat("Win Rate: %.1f%%\n", g_tradeStats.totalTrades > 0 ? (double)g_tradeStats.winTrades / g_tradeStats.totalTrades * 100 : 0);
   report += StringFormat("Profit Factor: %.2f\n", g_tradeStats.profitFactor);
   report += StringFormat("Total Return: %.2f%%\n", g_performanceMetrics.totalReturn);
   report += StringFormat("Annualized Return: %.2f%%\n", g_performanceMetrics.annualizedReturn);
   report += StringFormat("Max Drawdown: %.2f%%\n", g_performanceMetrics.maxDrawdownPercent);
   report += StringFormat("Calmar Ratio: %.2f\n", g_performanceMetrics.calmarRatio);
   report += StringFormat("Recovery Factor: %.2f\n", g_performanceMetrics.recoveryFactor);
   report += StringFormat("Avg Win: %.2f\n", g_tradeStats.avgWinAmount);
   report += StringFormat("Avg Loss: %.2f\n", g_tradeStats.avgLossAmount);
   report += StringFormat("Max Consecutive Wins: %.0f\n", g_tradeStats.maxConsecutiveWins);
   report += StringFormat("Max Consecutive Losses: %.0f\n", g_tradeStats.maxConsecutiveLosses);
   report += StringFormat("Current Streak: %.0f\n", g_tradeStats.currentStreak);
   report += StringFormat("Market State: %s\n", EnumToString(g_marketConditions.state));
   report += StringFormat("Trend Strength: %.2f\n", g_marketConditions.trendStrength);
   report += StringFormat("Volatility: %.5f\n", g_marketConditions.volatility);
   report += "=== END REPORT ===\n";
   
   return report;
}

//+------------------------------------------------------------------+