//+------------------------------------------------------------------+
//|                                     Enhanced_TradeAlgorithms.mqh |
//|                   Enhanced Trading Algorithms for ST&VWAP System |
//+------------------------------------------------------------------+
#property copyright "Enhanced Trading Algorithms © 2025"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>

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

//+------------------------------------------------------------------+
//| Structures                                                       |
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
   
   PositionTracker() : ticket(0), slModifications(0), tpModifications(0), 
                      lastTickTime(0), breakEvenExecuted(false), entryTime(0),
                      entryPrice(0), originalSL(0), originalTP(0) {}
};

struct TradeStats
{
   int totalTrades;
   int winTrades;
   int loseTrades;
   double totalProfit;
   double maxDrawdown;
   datetime lastTradeTime;
   
   TradeStats() : totalTrades(0), winTrades(0), loseTrades(0), 
                 totalProfit(0), maxDrawdown(0), lastTradeTime(0) {}
};

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
CTrade         trade;
CSymbolInfo    symbolInfo;
CPositionInfo  positionInfo;
COrderInfo     orderInfo;

PositionTracker g_positionTrackers[];
TradeStats g_tradeStats;
EA_STATE g_eaState = ST_READY;
datetime g_lastStateChange = 0;
datetime g_freezeUntil = 0;
datetime g_cooldownUntil = 0;

//+------------------------------------------------------------------+
//| Global Variable Helper Functions                                 |
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
//| Position Tracking Functions                                      |
//+------------------------------------------------------------------+
int FindPositionTrackerIndex(ulong ticket)
{
   for(int i = 0; i < ArraySize(g_positionTrackers); i++)
   {
      if(g_positionTrackers[i].ticket == ticket)
         return i;
   }
   return -1;
}

void AddPositionTracker(ulong ticket, double entryPrice, double sl, double tp)
{
   int size = ArraySize(g_positionTrackers);
   ArrayResize(g_positionTrackers, size + 1);
   
   g_positionTrackers[size].ticket = ticket;
   g_positionTrackers[size].entryTime = TimeCurrent();
   g_positionTrackers[size].entryPrice = entryPrice;
   g_positionTrackers[size].originalSL = sl;
   g_positionTrackers[size].originalTP = tp;
   g_positionTrackers[size].slModifications = 0;
   g_positionTrackers[size].tpModifications = 0;
   g_positionTrackers[size].breakEvenExecuted = false;
   g_positionTrackers[size].lastTickTime = GetTickCount();
}

void RemovePositionTracker(ulong ticket)
{
   int index = FindPositionTrackerIndex(ticket);
   if(index >= 0)
   {
      int size = ArraySize(g_positionTrackers);
      for(int i = index; i < size - 1; i++)
      {
         g_positionTrackers[i] = g_positionTrackers[i + 1];
      }
      ArrayResize(g_positionTrackers, size - 1);
   }
}

//+------------------------------------------------------------------+
//| Lot Size Calculation Functions                                   |
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
         margin = AccountInfoDouble(ACCOUNT_FREEMARGIN);
         lot = NormalizeDouble(margin * MM / 100000, 2);
         break;
         
      case BALANCE:
         margin = AccountInfoDouble(ACCOUNT_BALANCE);
         lot = NormalizeDouble(margin * MM / 100000, 2);
         break;
         
      case LOSSFREEMARGIN:
         margin = AccountInfoDouble(ACCOUNT_FREEMARGIN);
         lot = NormalizeDouble(margin * MM / 50000, 2);
         break;
         
      case LOSSBALANCE:
         margin = AccountInfoDouble(ACCOUNT_BALANCE);
         lot = NormalizeDouble(margin * MM / 50000, 2);
         break;
         
      case LOT:
      default:
         lot = MM;
         break;
   }
   
   // Normalize lot size according to symbol specifications
   double minLot = symbolInfo.LotsMin();
   double maxLot = symbolInfo.LotsMax();
   double lotStep = symbolInfo.LotsStep();
   
   if(lot < minLot) lot = minLot;
   if(lot > maxLot) lot = maxLot;
   
   lot = NormalizeDouble(lot / lotStep, 0) * lotStep;
   
   return lot;
}

//+------------------------------------------------------------------+
//| Order Management Functions                                       |
//+------------------------------------------------------------------+
bool BuyPositionOpen(bool signal, string symbol, datetime signalTime, 
                    double MM, MarginMode MMMode, int deviation, 
                    int stopLoss, int takeProfit, ulong magicNumber = 0)
{
   if(!signal || !IsEAReadyToTrade()) return false;
   
   if(!symbolInfo.Name(symbol))
   {
      Print("Error: Invalid symbol ", symbol);
      return false;
   }
   
   double lot = GetLot(MM, MMMode, symbol);
   if(lot <= 0)
   {
      Print("Error: Invalid lot size calculated");
      return false;
   }
   
   double price = symbolInfo.Ask();
   double sl = (stopLoss > 0) ? price - stopLoss * symbolInfo.Point() : 0;
   double tp = (takeProfit > 0) ? price + takeProfit * symbolInfo.Point() : 0;
   
   trade.SetExpertMagicNumber(magicNumber);
   trade.SetDeviationInPoints(deviation);
   
   if(trade.Buy(lot, symbol, price, sl, tp, "ST_VWAP Buy"))
   {
      ulong ticket = trade.ResultOrder();
      AddPositionTracker(ticket, price, sl, tp);
      SetEAState(ST_IN_TRADE);
      
      g_tradeStats.totalTrades++;
      g_tradeStats.lastTradeTime = TimeCurrent();
      
      Print("BUY position opened: Ticket=", ticket, ", Lot=", lot, ", Price=", price);
      return true;
   }
   else
   {
      Print("Error opening BUY position: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
      return false;
   }
}

bool SellPositionOpen(bool signal, string symbol, datetime signalTime,
                     double MM, MarginMode MMMode, int deviation,
                     int stopLoss, int takeProfit, ulong magicNumber = 0)
{
   if(!signal || !IsEAReadyToTrade()) return false;
   
   if(!symbolInfo.Name(symbol))
   {
      Print("Error: Invalid symbol ", symbol);
      return false;
   }
   
   double lot = GetLot(MM, MMMode, symbol);
   if(lot <= 0)
   {
      Print("Error: Invalid lot size calculated");
      return false;
   }
   
   double price = symbolInfo.Bid();
   double sl = (stopLoss > 0) ? price + stopLoss * symbolInfo.Point() : 0;
   double tp = (takeProfit > 0) ? price - takeProfit * symbolInfo.Point() : 0;
   
   trade.SetExpertMagicNumber(magicNumber);
   trade.SetDeviationInPoints(deviation);
   
   if(trade.Sell(lot, symbol, price, sl, tp, "ST_VWAP Sell"))
   {
      ulong ticket = trade.ResultOrder();
      AddPositionTracker(ticket, price, sl, tp);
      SetEAState(ST_IN_TRADE);
      
      g_tradeStats.totalTrades++;
      g_tradeStats.lastTradeTime = TimeCurrent();
      
      Print("SELL position opened: Ticket=", ticket, ", Lot=", lot, ", Price=", price);
      return true;
   }
   else
   {
      Print("Error opening SELL position: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
      return false;
   }
}

bool BuyPositionClose(bool signal, string symbol, int deviation, ulong magicNumber = 0)
{
   if(!signal) return false;
   
   trade.SetExpertMagicNumber(magicNumber);
   trade.SetDeviationInPoints(deviation);
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(positionInfo.SelectByIndex(i))
      {
         if(positionInfo.Symbol() == symbol && 
            positionInfo.PositionType() == POSITION_TYPE_BUY &&
            (magicNumber == 0 || positionInfo.Magic() == magicNumber))
         {
            ulong ticket = positionInfo.Ticket();
            if(trade.PositionClose(ticket))
            {
               RemovePositionTracker(ticket);
               UpdateTradeStats(positionInfo.Profit());
               SetEAState(ST_COOLDOWN);
               
               Print("BUY position closed: Ticket=", ticket, ", Profit=", positionInfo.Profit());
               return true;
            }
         }
      }
   }
   return false;
}

bool SellPositionClose(bool signal, string symbol, int deviation, ulong magicNumber = 0)
{
   if(!signal) return false;
   
   trade.SetExpertMagicNumber(magicNumber);
   trade.SetDeviationInPoints(deviation);
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(positionInfo.SelectByIndex(i))
      {
         if(positionInfo.Symbol() == symbol && 
            positionInfo.PositionType() == POSITION_TYPE_SELL &&
            (magicNumber == 0 || positionInfo.Magic() == magicNumber))
         {
            ulong ticket = positionInfo.Ticket();
            if(trade.PositionClose(ticket))
            {
               RemovePositionTracker(ticket);
               UpdateTradeStats(positionInfo.Profit());
               SetEAState(ST_COOLDOWN);
               
               Print("SELL position closed: Ticket=", ticket, ", Profit=", positionInfo.Profit());
               return true;
            }
         }
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Advanced Position Management Functions                           |
//+------------------------------------------------------------------+
void UpdateTradeStats(double profit)
{
   g_tradeStats.totalProfit += profit;
   
   if(profit > 0)
      g_tradeStats.winTrades++;
   else if(profit < 0)
      g_tradeStats.loseTrades++;
      
   // Update max drawdown
   if(profit < 0 && MathAbs(profit) > g_tradeStats.maxDrawdown)
      g_tradeStats.maxDrawdown = MathAbs(profit);
}

bool ModifyPosition(ulong ticket, double newSL, double newTP, int maxSLMods = -1, int maxTPMods = -1)
{
   if(!positionInfo.SelectByTicket(ticket))
      return false;
      
   int trackerIndex = FindPositionTrackerIndex(ticket);
   if(trackerIndex < 0)
      return false;
      
   // Check modification limits
   if(maxSLMods > 0 && g_positionTrackers[trackerIndex].slModifications >= maxSLMods)
   {
      Print("SL modification limit reached for ticket ", ticket);
      return false;
   }
   
   if(maxTPMods > 0 && g_positionTrackers[trackerIndex].tpModifications >= maxTPMods)
   {
      Print("TP modification limit reached for ticket ", ticket);
      return false;
   }
   
   // Check minimum interval between modifications
   ulong currentTick = GetTickCount();
   if(currentTick - g_positionTrackers[trackerIndex].lastTickTime < 1000) // 1 second minimum
      return false;
   
   if(trade.PositionModify(ticket, newSL, newTP))
   {
      // Update modification counters
      double currentSL = positionInfo.StopLoss();
      double currentTP = positionInfo.TakeProfit();
      
      if(MathAbs(newSL - currentSL) > symbolInfo.Point())
         g_positionTrackers[trackerIndex].slModifications++;
         
      if(MathAbs(newTP - currentTP) > symbolInfo.Point())
         g_positionTrackers[trackerIndex].tpModifications++;
         
      g_positionTrackers[trackerIndex].lastTickTime = currentTick;
      
      Print("Position modified: Ticket=", ticket, ", New SL=", newSL, ", New TP=", newTP);
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Break-Even and Trailing Functions                               |
//+------------------------------------------------------------------+
void ProcessBreakEven(double breakEvenPercent, double beSLPercent)
{
   for(int i = 0; i < ArraySize(g_positionTrackers); i++)
   {
      ulong ticket = g_positionTrackers[i].ticket;
      
      if(g_positionTrackers[i].breakEvenExecuted)
         continue;
         
      if(!positionInfo.SelectByTicket(ticket))
         continue;
         
      double entryPrice = g_positionTrackers[i].entryPrice;
      double originalTP = g_positionTrackers[i].originalTP;
      double currentPrice = (positionInfo.PositionType() == POSITION_TYPE_BUY) ? 
                           symbolInfo.Bid() : symbolInfo.Ask();
      
      // Calculate profit percentage
      double tpDistance = MathAbs(originalTP - entryPrice);
      double currentProfit = 0;
      
      if(positionInfo.PositionType() == POSITION_TYPE_BUY)
         currentProfit = currentPrice - entryPrice;
      else
         currentProfit = entryPrice - currentPrice;
         
      double profitPercent = (tpDistance > 0) ? (currentProfit / tpDistance) * 100 : 0;
      
      if(profitPercent >= breakEvenPercent)
      {
         double newSL = entryPrice + (currentProfit * beSLPercent / 100);
         
         if(positionInfo.PositionType() == POSITION_TYPE_SELL)
            newSL = entryPrice - (currentProfit * beSLPercent / 100);
            
         if(ModifyPosition(ticket, newSL, positionInfo.TakeProfit()))
         {
            g_positionTrackers[i].breakEvenExecuted = true;
            Print("Break-even executed for ticket ", ticket, ", New SL: ", newSL);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Session Management Functions                                     |
//+------------------------------------------------------------------+
bool IsInSession(SessionTime &session, datetime time)
{
   if(!session.enabled)
      return false;
      
   MqlDateTime timeStruct;
   TimeToStruct(time, timeStruct);
   
   int currentMinutes = timeStruct.hour * 60 + timeStruct.min;
   int startMinutes = session.startHour * 60 + session.startMinute;
   int endMinutes = session.endHour * 60 + session.endMinute;
   
   if(startMinutes <= endMinutes)
   {
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
   }
   else // Overnight session
   {
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
   }
}

bool IsInAnySession(SessionTime &sessions[], datetime time)
{
   for(int i = 0; i < ArraySize(sessions); i++)
   {
      if(IsInSession(sessions[i], time))
         return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Utility Functions                                               |
//+------------------------------------------------------------------+
void LoadHistory(datetime startTime, string symbol, ENUM_TIMEFRAMES timeframe)
{
   int bars = iBars(symbol, timeframe);
   datetime time[];
   
   if(CopyTime(symbol, timeframe, startTime, TimeCurrent(), time) > 0)
   {
      Print("History loaded successfully for ", symbol, " ", EnumToString(timeframe));
   }
}

class CIsNewBar
{
private:
   datetime m_lastBarTime;
   string   m_symbol;
   ENUM_TIMEFRAMES m_timeframe;
   
public:
   CIsNewBar() : m_lastBarTime(0) {}
   
   bool IsNewBar(string symbol, ENUM_TIMEFRAMES timeframe)
   {
      datetime currentBarTime = iTime(symbol, timeframe, 0);
      
      if(m_symbol != symbol || m_timeframe != timeframe)
      {
         m_symbol = symbol;
         m_timeframe = timeframe;
         m_lastBarTime = currentBarTime;
         return false;
      }
      
      if(currentBarTime != m_lastBarTime)
      {
         m_lastBarTime = currentBarTime;
         return true;
      }
      
      return false;
   }
};