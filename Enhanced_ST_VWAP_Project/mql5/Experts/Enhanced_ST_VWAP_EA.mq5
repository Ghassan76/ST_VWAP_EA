//+------------------------------------------------------------------+
//|                                        Enhanced_ST_VWAP_EA.mq5 |
//|              Enhanced SuperTrend & VWAP Expert Advisor System  |
//+------------------------------------------------------------------+
#property copyright "Enhanced ST&VWAP Expert Advisor © 2025"
#property link      "https://www.mql5.com"
#property version   "5.00"
#property description "Enhanced EA combining SuperTrend & VWAP with advanced features"

//+------------------------------------------------------------------+
//| Include Files                                                    |
//+------------------------------------------------------------------+
#include <Enhanced_TradeAlgorithms.mqh>

//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+
// General Settings
input ulong   MagicNumber                 = 567890;
input bool    VerboseLogs                 = true;      // Verbose logging mode
input bool    EnableEntry                 = true;      // Master enable switch
input bool    EnableBuy                   = true;      // Allow long trades
input bool    EnableSell                  = true;      // Allow short trades

// Time and Day Filters
input group "=== TIME AND DAY FILTERS ==="
input bool    UseTimeFilter               = true;
input int     BeginHour                   = 15;
input int     BeginMinute                 = 0;
input int     EndHour                     = 22;
input int     EndMinute                   = 59;
input bool    TradeSun                    = false;
input bool    TradeMon                    = true;
input bool    TradeTue                    = true;
input bool    TradeWed                    = true;
input bool    TradeThu                    = true;
input bool    TradeFri                    = true;
input bool    TradeSat                    = false;

// Multiple Trading Sessions
input group "=== MULTIPLE TRADING SESSIONS ==="
input bool    Session1_Enable             = false;
input int     Session1_StartHour          = 9;
input int     Session1_StartMinute        = 0;
input int     Session1_EndHour            = 12;
input int     Session1_EndMinute          = 0;

input bool    Session2_Enable             = false;
input int     Session2_StartHour          = 13;
input int     Session2_StartMinute        = 0;
input int     Session2_EndHour            = 17;
input int     Session2_EndMinute          = 0;

input bool    Session3_Enable             = false;
input int     Session3_StartHour          = 20;
input int     Session3_StartMinute        = 0;
input int     Session3_EndHour            = 23;
input int     Session3_EndMinute          = 0;

input bool    Session4_Enable             = false;
input int     Session4_StartHour          = 0;
input int     Session4_StartMinute        = 0;
input int     Session4_EndHour            = 6;
input int     Session4_EndMinute          = 0;

// Market Conditions
input group "=== MARKET CONDITIONS ==="
input int     MaxSpreadPts                = 140;

// Position Sizing
input group "=== POSITION SIZING ==="
input bool    DynamicLots                 = false;
input double  RiskPct                     = 1.0;
input double  FixedLot                    = 2.00;
input int     SlippagePts                 = 30;        // Order slippage

// Stop Loss & Take Profit
input group "=== STOP LOSS & TAKE PROFIT ==="
input bool    UseMoneyTargets             = false;
input double  MoneySLAmount               = 50.0;
input double  MoneyTPAmount               = 100.0;
input double  PointsSL                    = 10000;
input double  PointsTP                    = 10000;

// Enhanced State Management
input group "=== STATE MANAGEMENT ==="
input int     FreezeDurationMinutes       = 15;        // Freeze duration after issues
input int     PostTradeCooldownMin        = 5;         // Cooldown after trade close
input bool    FreezeOnDataMissing         = true;      // Freeze on missing data

// Enhanced Smart Trailing with Break-Even
input group "=== ENHANCED SMART TRAILING ==="
input bool    EnableBreakEven             = true;      // Enable break-even functionality
input bool    EnableSmartTrailing         = true;      // Enable smart trailing functionality
input double  BreakEvenPercent            = 49.0;      // Profit % to trigger break-even
input double  BESLPctOfTP                 = 1.0;       // Break-even SL offset as % of TP span
input double  TrailStartPercent           = 50.0;      // Profit % to start trailing
input int     TrailingSLStepPoints        = 1000;      // Step size for SL trailing (points)
input int     TrailingTPStepPoints        = 1000;      // Step size for TP trailing (points)
input int     TriggerDistancePoints       = 1000;      // Minimum distance to trigger trailing
input int     CheckIntervalSec            = 0;         // Timer interval for trailing checks
input int     MinIntervalMS               = 0;         // Minimum interval between modifications

// Modification Limits
input group "=== MODIFICATION LIMITS ==="
input int     MaxSLModifications          = 5;         // Max SL changes per position (-1 = unlimited)
input int     MaxTPModifications          = 3;         // Max TP changes per position (-1 = unlimited)
input bool    LogModificationLimits       = true;      // Log when limits are reached

// Daily Risk Management
input group "=== DAILY RISK MANAGEMENT ==="
input bool    EnableMaxTradesPerDay       = false;
input int     MaxTradesPerDay             = 10;
input bool    EnableProfitCap             = false;
input double  DailyProfitTarget           = 100.0;
input bool    EnableLossLimit             = false;
input double  DailyLossLimit              = 200.0;

// SuperTrend & VWAP Indicator Parameters
input group "=== SUPERTREND & VWAP PARAMETERS ==="
input ENUM_TIMEFRAMES InpIndTimeframe     = PERIOD_H1; // Indicator timeframe
input int     ATRPeriod                   = 22;        // ATR period for SuperTrend
input double  STMultiplier                = 3.0;       // SuperTrend multiplier
input ENUM_APPLIED_PRICE SourcePrice      = PRICE_MEDIAN; // Price for SuperTrend calculation
input bool    TakeWicksIntoAccount        = true;      // Consider wicks in calculation
input bool    EnableVWAPFilter            = true;      // Enable VWAP filtering
input ENUM_APPLIED_PRICE VWAPPriceMethod  = PRICE_TYPICAL; // VWAP calculation price
input double  MinVolumeThreshold          = 1.0;       // Minimum volume for VWAP
input bool    ResetVWAPDaily              = true;      // Reset VWAP daily
input uint    SignalBar                   = 1;         // Bar number for signal

// Signal Filtering
input group "=== SIGNAL FILTERING ==="
input bool    FilterSignalsOnClose        = true;      // Only take signals on bar close
input bool    RequireVWAPConfirmation     = true;      // Require VWAP confirmation for signals
input double  MinPointsFromVWAP           = 50.0;      // Minimum distance from VWAP in points

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
int TimeShiftSec;
int STVWAPHandle;
int min_rates_total;

SessionTime g_sessions[4];
TradeStats g_dailyStats;
datetime g_lastDayReset = 0;

// Signal tracking variables
static bool Recount = true;
static bool BUY_Open = false, BUY_Close = false;
static bool SELL_Open = false, SELL_Close = false;
static datetime UpSignalTime, DnSignalTime;
static CIsNewBar NB;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialize trading algorithms
    trade.SetExpertMagicNumber(MagicNumber);
    
    // Get handle for Enhanced ST&VWAP indicator
    STVWAPHandle = iCustom(_Symbol, InpIndTimeframe, "Enhanced_ST_VWAP_Indicator",
                          ATRPeriod, STMultiplier, SourcePrice, TakeWicksIntoAccount,
                          VWAPPriceMethod, MinVolumeThreshold, ResetVWAPDaily,
                          EnableVWAPFilter, true); // ShowVWAPLine = true
    
    if(STVWAPHandle == INVALID_HANDLE)
    {
        Print("Failed to get Enhanced ST&VWAP indicator handle");
        return(INIT_FAILED);
    }
    
    // Initialize timeframe shift in seconds
    TimeShiftSec = PeriodSeconds(InpIndTimeframe);
    
    // Initialize minimum rates required
    min_rates_total = int(ATRPeriod + SignalBar + 10);
    
    // Initialize trading sessions
    InitializeSessions();
    
    // Initialize daily statistics
    ResetDailyStats();
    
    // Set EA state to ready
    SetEAState(ST_READY);
    
    // Print initialization info
    if(VerboseLogs)
    {
        Print("Enhanced ST&VWAP EA initialized successfully");
        Print("Magic Number: ", MagicNumber);
        Print("Symbol: ", _Symbol);
        Print("Timeframe: ", EnumToString(InpIndTimeframe));
        Print("ATR Period: ", ATRPeriod, ", Multiplier: ", STMultiplier);
        Print("VWAP Filter: ", EnableVWAPFilter ? "Enabled" : "Disabled");
        Print("Risk Management: ", DynamicLots ? "Dynamic (" + DoubleToString(RiskPct, 1) + "%)" : "Fixed (" + DoubleToString(FixedLot, 2) + " lots)");
    }
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Clean up global variables
    GlobalVariableDel_(_Symbol);
    
    // Release indicator handle
    if(STVWAPHandle != INVALID_HANDLE)
        IndicatorRelease(STVWAPHandle);
    
    if(VerboseLogs)
    {
        Print("Enhanced ST&VWAP EA deinitialized. Reason: ", reason);
        PrintDailyStats();
    }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Check if EA is ready to trade
    if(!IsEAReadyToTrade())
        return;
    
    // Check daily statistics reset
    CheckDailyReset();
    
    // Check daily risk limits
    if(!CheckDailyLimits())
        return;
    
    // Check market conditions
    if(!CheckMarketConditions())
        return;
    
    // Check time filters
    if(!CheckTimeFilters())
        return;
    
    // Check indicator data availability
    if(BarsCalculated(STVWAPHandle) < min_rates_total)
    {
        if(FreezeOnDataMissing)
            SetEAState(ST_FROZEN, FREEZE_DATA_MISSING);
        return;
    }
    
    // Load history for proper indicator calculation
    LoadHistory(TimeCurrent() - PeriodSeconds(InpIndTimeframe) - 1, _Symbol, InpIndTimeframe);
    
    // Process trading signals
    ProcessTradingSignals();
    
    // Process advanced position management
    if(EnableBreakEven)
        ProcessBreakEven(BreakEvenPercent, BESLPctOfTP);
    
    // Process smart trailing (if implemented)
    if(EnableSmartTrailing)
        ProcessSmartTrailing();
}

//+------------------------------------------------------------------+
//| Initialize trading sessions                                      |
//+------------------------------------------------------------------+
void InitializeSessions()
{
    g_sessions[0].enabled = Session1_Enable;
    g_sessions[0].startHour = Session1_StartHour;
    g_sessions[0].startMinute = Session1_StartMinute;
    g_sessions[0].endHour = Session1_EndHour;
    g_sessions[0].endMinute = Session1_EndMinute;
    
    g_sessions[1].enabled = Session2_Enable;
    g_sessions[1].startHour = Session2_StartHour;
    g_sessions[1].startMinute = Session2_StartMinute;
    g_sessions[1].endHour = Session2_EndHour;
    g_sessions[1].endMinute = Session2_EndMinute;
    
    g_sessions[2].enabled = Session3_Enable;
    g_sessions[2].startHour = Session3_StartHour;
    g_sessions[2].startMinute = Session3_StartMinute;
    g_sessions[2].endHour = Session3_EndHour;
    g_sessions[2].endMinute = Session3_EndMinute;
    
    g_sessions[3].enabled = Session4_Enable;
    g_sessions[3].startHour = Session4_StartHour;
    g_sessions[3].startMinute = Session4_StartMinute;
    g_sessions[3].endHour = Session4_EndHour;
    g_sessions[3].endMinute = Session4_EndMinute;
}

//+------------------------------------------------------------------+
//| Process trading signals                                          |
//+------------------------------------------------------------------+
void ProcessTradingSignals()
{
    // Check for new bar or force recount
    if(!SignalBar || NB.IsNewBar(_Symbol, InpIndTimeframe) || Recount)
    {
        // Reset signal flags
        BUY_Open = false;
        SELL_Open = false;
        BUY_Close = false;
        SELL_Close = false;
        Recount = false;
        
        // Get SuperTrend signals (buffers 2 and 3 contain buy/sell signals)
        double BuySignal[1], SellSignal[1];
        double SuperTrend[1], VWAP[1];
        
        // Copy signal buffers from Enhanced ST&VWAP indicator
        if(CopyBuffer(STVWAPHandle, 2, SignalBar, 1, BuySignal) <= 0) {Recount = true; return;}
        if(CopyBuffer(STVWAPHandle, 3, SignalBar, 1, SellSignal) <= 0) {Recount = true; return;}
        
        // Copy SuperTrend and VWAP values for additional filtering
        if(CopyBuffer(STVWAPHandle, 0, SignalBar, 1, SuperTrend) <= 0) {Recount = true; return;}
        if(CopyBuffer(STVWAPHandle, 2, SignalBar, 1, VWAP) <= 0) {Recount = true; return;} // VWAP is buffer 2
        
        datetime signalTime = iTime(_Symbol, InpIndTimeframe, SignalBar);
        double currentPrice = iClose(_Symbol, InpIndTimeframe, SignalBar);
        
        // Process buy signals
        if(BuySignal[0] != 0 && BuySignal[0] != EMPTY_VALUE)
        {
            bool vwapOK = !RequireVWAPConfirmation || 
                         (VWAP[0] != 0 && VWAP[0] != EMPTY_VALUE && 
                          MathAbs(currentPrice - VWAP[0]) >= MinPointsFromVWAP * _Point);
            
            if(vwapOK)
            {
                if(EnableBuy && EnableEntry) 
                    BUY_Open = true;
                if(EnableSell) 
                    SELL_Close = true;
                    
                UpSignalTime = signalTime + TimeShiftSec;
                
                if(VerboseLogs)
                    Print("BUY signal detected at ", TimeToString(signalTime), ", Price: ", DoubleToString(currentPrice, _Digits));
            }
        }
        
        // Process sell signals  
        if(SellSignal[0] != 0 && SellSignal[0] != EMPTY_VALUE)
        {
            bool vwapOK = !RequireVWAPConfirmation || 
                         (VWAP[0] != 0 && VWAP[0] != EMPTY_VALUE && 
                          MathAbs(currentPrice - VWAP[0]) >= MinPointsFromVWAP * _Point);
            
            if(vwapOK)
            {
                if(EnableSell && EnableEntry) 
                    SELL_Open = true;
                if(EnableBuy) 
                    BUY_Close = true;
                    
                DnSignalTime = signalTime + TimeShiftSec;
                
                if(VerboseLogs)
                    Print("SELL signal detected at ", TimeToString(signalTime), ", Price: ", DoubleToString(currentPrice, _Digits));
            }
        }
        
        // Additional trend confirmation using SuperTrend direction
        if(BUY_Open || SELL_Open)
        {
            double STDirection[1];
            if(CopyBuffer(STVWAPHandle, 3, SignalBar, 1, STDirection) > 0) // Direction buffer
            {
                if(BUY_Open && STDirection[0] <= 0) // SuperTrend not bullish
                {
                    BUY_Open = false;
                    if(VerboseLogs) Print("BUY signal rejected - SuperTrend not bullish");
                }
                
                if(SELL_Open && STDirection[0] >= 0) // SuperTrend not bearish
                {
                    SELL_Open = false;
                    if(VerboseLogs) Print("SELL signal rejected - SuperTrend not bearish");
                }
            }
        }
    }
    
    // Execute trading operations
    ExecuteTrades();
}

//+------------------------------------------------------------------+
//| Execute trades based on signals                                  |
//+------------------------------------------------------------------+
void ExecuteTrades()
{
    double lotSize = DynamicLots ? CalculateDynamicLot() : FixedLot;
    MarginMode mmMode = DynamicLots ? FREEMARGIN : LOT;
    
    // Close positions first
    if(BUY_Close)
        SellPositionClose(true, _Symbol, SlippagePts, MagicNumber);
        
    if(SELL_Close)
        BuyPositionClose(true, _Symbol, SlippagePts, MagicNumber);
    
    // Open new positions
    if(BUY_Open && CheckPositionLimits())
    {
        int sl = UseMoneyTargets ? CalculatePointsFromMoney(MoneySLAmount, true) : (int)PointsSL;
        int tp = UseMoneyTargets ? CalculatePointsFromMoney(MoneyTPAmount, false) : (int)PointsTP;
        
        if(BuyPositionOpen(true, _Symbol, UpSignalTime, lotSize, mmMode, SlippagePts, sl, tp, MagicNumber))
        {
            g_dailyStats.totalTrades++;
            if(VerboseLogs) Print("BUY position opened successfully");
        }
    }
    
    if(SELL_Open && CheckPositionLimits())
    {
        int sl = UseMoneyTargets ? CalculatePointsFromMoney(MoneySLAmount, true) : (int)PointsSL;
        int tp = UseMoneyTargets ? CalculatePointsFromMoney(MoneyTPAmount, false) : (int)PointsTP;
        
        if(SellPositionOpen(true, _Symbol, DnSignalTime, lotSize, mmMode, SlippagePts, sl, tp, MagicNumber))
        {
            g_dailyStats.totalTrades++;
            if(VerboseLogs) Print("SELL position opened successfully");
        }
    }
}

//+------------------------------------------------------------------+
//| Check market conditions                                          |
//+------------------------------------------------------------------+
bool CheckMarketConditions()
{
    // Check spread
    long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
    if(spread > MaxSpreadPts)
    {
        if(VerboseLogs) Print("Spread too high: ", spread, " > ", MaxSpreadPts);
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Check time filters                                               |
//+------------------------------------------------------------------+
bool CheckTimeFilters()
{
    datetime currentTime = TimeCurrent();
    MqlDateTime timeStruct;
    TimeToStruct(currentTime, timeStruct);
    
    // Check day of week filter
    if(!CheckDayFilter(timeStruct.day_of_week))
        return false;
    
    // Check main time filter
    if(UseTimeFilter && !CheckTimeRange(timeStruct.hour, timeStruct.min, BeginHour, BeginMinute, EndHour, EndMinute))
        return false;
    
    // Check trading sessions
    bool inSession = false;
    for(int i = 0; i < 4; i++)
    {
        if(IsInSession(g_sessions[i], currentTime))
        {
            inSession = true;
            break;
        }
    }
    
    // If any session is enabled, we must be in at least one session
    bool anySessionEnabled = Session1_Enable || Session2_Enable || Session3_Enable || Session4_Enable;
    if(anySessionEnabled && !inSession)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Check day filter                                                 |
//+------------------------------------------------------------------+
bool CheckDayFilter(int dayOfWeek)
{
    switch(dayOfWeek)
    {
        case 0: return TradeSun; // Sunday
        case 1: return TradeMon; // Monday
        case 2: return TradeTue; // Tuesday
        case 3: return TradeWed; // Wednesday
        case 4: return TradeThu; // Thursday
        case 5: return TradeFri; // Friday
        case 6: return TradeSat; // Saturday
    }
    return false;
}

//+------------------------------------------------------------------+
//| Check time range                                                 |
//+------------------------------------------------------------------+
bool CheckTimeRange(int hour, int minute, int startHour, int startMinute, int endHour, int endMinute)
{
    int currentMinutes = hour * 60 + minute;
    int startMinutes = startHour * 60 + startMinute;
    int endMinutes = endHour * 60 + endMinute;
    
    if(startMinutes <= endMinutes)
    {
        return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    }
    else // Overnight session
    {
        return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
}

//+------------------------------------------------------------------+
//| Check daily limits                                               |
//+------------------------------------------------------------------+
bool CheckDailyLimits()
{
    // Check maximum trades per day
    if(EnableMaxTradesPerDay && g_dailyStats.totalTrades >= MaxTradesPerDay)
    {
        if(VerboseLogs) Print("Daily trade limit reached: ", g_dailyStats.totalTrades, "/", MaxTradesPerDay);
        SetEAState(ST_FROZEN);
        return false;
    }
    
    // Check daily profit target
    if(EnableProfitCap && g_dailyStats.totalProfit >= DailyProfitTarget)
    {
        if(VerboseLogs) Print("Daily profit target reached: ", DoubleToString(g_dailyStats.totalProfit, 2));
        SetEAState(ST_FROZEN);
        return false;
    }
    
    // Check daily loss limit
    if(EnableLossLimit && g_dailyStats.totalProfit <= -DailyLossLimit)
    {
        if(VerboseLogs) Print("Daily loss limit reached: ", DoubleToString(g_dailyStats.totalProfit, 2));
        SetEAState(ST_FROZEN);
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Check position limits                                            |
//+------------------------------------------------------------------+
bool CheckPositionLimits()
{
    // Count existing positions for this EA
    int positionCount = 0;
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(positionInfo.SelectByIndex(i))
        {
            if(positionInfo.Symbol() == _Symbol && positionInfo.Magic() == MagicNumber)
                positionCount++;
        }
    }
    
    // For this EA, allow only 1 position at a time
    return positionCount == 0;
}

//+------------------------------------------------------------------+
//| Calculate dynamic lot size                                       |
//+------------------------------------------------------------------+
double CalculateDynamicLot()
{
    // ACCOUNT_FREEMARGIN is deprecated; use ACCOUNT_MARGIN_FREE instead
    double accountSize = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    double riskAmount = accountSize * RiskPct / 100.0;
    
    // Calculate lot based on stop loss distance
    double slDistance = PointsSL * _Point;
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    
    if(slDistance > 0 && tickValue > 0)
    {
        double lot = riskAmount / (slDistance * tickValue / _Point);
        return NormalizeDouble(lot, 2);
    }
    
    return FixedLot;
}

//+------------------------------------------------------------------+
//| Calculate points from money amount                               |
//+------------------------------------------------------------------+
int CalculatePointsFromMoney(double moneyAmount, bool isStopLoss)
{
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    
    if(tickValue > 0 && tickSize > 0)
    {
        double points = (moneyAmount * tickSize) / (tickValue * _Point);
        return (int)NormalizeDouble(points, 0);
    }
    
    return isStopLoss ? (int)PointsSL : (int)PointsTP;
}

//+------------------------------------------------------------------+
//| Process smart trailing                                           |
//+------------------------------------------------------------------+
void ProcessSmartTrailing()
{
    // Implementation for smart trailing stop logic
    // This would be a comprehensive trailing stop system
    // For brevity, showing basic structure
    
    for(int i = 0; i < ArraySize(g_positionTrackers); i++)
    {
        ulong ticket = g_positionTrackers[i].ticket;
        
        if(!positionInfo.SelectByTicket(ticket))
            continue;
            
        // Calculate trailing parameters based on profit percentage
        double entryPrice = g_positionTrackers[i].entryPrice;
        double currentPrice = (positionInfo.PositionType() == POSITION_TYPE_BUY) ? 
                             SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        
        // Implement trailing logic here
        // This is a placeholder for the actual trailing implementation
    }
}

//+------------------------------------------------------------------+
//| Check and reset daily statistics                                 |
//+------------------------------------------------------------------+
void CheckDailyReset()
{
    datetime currentTime = TimeCurrent();
    MqlDateTime timeStruct;
    TimeToStruct(currentTime, timeStruct);
    
    datetime currentDay = StringToTime(StringFormat("%04d.%02d.%02d", timeStruct.year, timeStruct.mon, timeStruct.day));
    
    if(currentDay != g_lastDayReset)
    {
        if(VerboseLogs && g_lastDayReset != 0)
            PrintDailyStats();
            
        ResetDailyStats();
        g_lastDayReset = currentDay;
        
        if(VerboseLogs)
            Print("Daily statistics reset for new trading day: ", TimeToString(currentDay, TIME_DATE));
    }
}

//+------------------------------------------------------------------+
//| Reset daily statistics                                           |
//+------------------------------------------------------------------+
void ResetDailyStats()
{
    g_dailyStats.totalTrades = 0;
    g_dailyStats.winTrades = 0;
    g_dailyStats.loseTrades = 0;
    g_dailyStats.totalProfit = 0;
    g_dailyStats.maxDrawdown = 0;
    g_dailyStats.lastTradeTime = 0;
}

//+------------------------------------------------------------------+
//| Print daily statistics                                           |
//+------------------------------------------------------------------+
void PrintDailyStats()
{
    Print("=== Daily Trading Statistics ===");
    Print("Total Trades: ", g_dailyStats.totalTrades);
    Print("Win Trades: ", g_dailyStats.winTrades);
    Print("Lose Trades: ", g_dailyStats.loseTrades);
    Print("Win Rate: ", g_dailyStats.totalTrades > 0 ? DoubleToString((double)g_dailyStats.winTrades / g_dailyStats.totalTrades * 100, 1) + "%" : "0%");
    Print("Total Profit: ", DoubleToString(g_dailyStats.totalProfit, 2));
    Print("Max Drawdown: ", DoubleToString(g_dailyStats.maxDrawdown, 2));
    Print("================================");
}

//+------------------------------------------------------------------+
//| Handle trade events                                              |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                       const MqlTradeRequest& request,
                       const MqlTradeResult& result)
{
    // Handle position close events
    if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
    {
        if(HistoryDealSelect(trans.deal))
        {
            if(HistoryDealGetInteger(trans.deal, DEAL_MAGIC) == MagicNumber)
            {
                double profit = HistoryDealGetDouble(trans.deal, DEAL_PROFIT);
                ENUM_DEAL_TYPE dealType = (ENUM_DEAL_TYPE)HistoryDealGetInteger(trans.deal, DEAL_TYPE);
                
                if(dealType == DEAL_TYPE_BUY || dealType == DEAL_TYPE_SELL)
                {
                    // Position closed
                    UpdateTradeStats(profit);
                    
                    // Remove from position tracker
                    ulong ticket = HistoryDealGetInteger(trans.deal, DEAL_POSITION_ID);
                    RemovePositionTracker(ticket);
                    
                    // Set cooldown state
                    SetEAState(ST_COOLDOWN);
                    
                    if(VerboseLogs)
                        Print("Trade closed. Profit: ", DoubleToString(profit, 2), ", New balance: ", DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2));
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Timer event handler                                              |
//+------------------------------------------------------------------+
void OnTimer()
{
    // Periodic checks can be implemented here
    // For example, checking connection status, updating statistics, etc.
}