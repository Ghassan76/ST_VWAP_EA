//+------------------------------------------------------------------+
//|                                               exp_supertrend.mq5 |
//|                       Enhanced SuperTrend Expert Advisor v2.0    |
//|                                  Performance Optimized Trading   |
//+------------------------------------------------------------------+
#property copyright "Enhanced SuperTrend Expert Advisor © 2025"
#property link      "https://www.mql5.com"
#property version   "2.00"
#property description "Enhanced SuperTrend EA with Performance Optimization & Analytics"

//+------------------------------------------------------------------+
//| Include Files                                                    |
//+------------------------------------------------------------------+
#include <TradeAlgorithms.mqh>

//+------------------------------------------------------------------+
//| Performance & Analytics Constants                                |
//+------------------------------------------------------------------+
#define PERFORMANCE_UPDATE_INTERVAL 120   // Update analytics every 2 minutes
#define RISK_CHECK_INTERVAL 60           // Risk check every 1 minute
#define MAX_CONCURRENT_POSITIONS 3       // Maximum concurrent positions
#define ANALYTICS_BUFFER_SIZE 500        // Analytics buffer size

//+------------------------------------------------------------------+
//| Input Parameters - Enhanced Organization                         |
//+------------------------------------------------------------------+
// General Settings
input group "=== GENERAL SETTINGS ==="
input ulong   MagicNumber                 = 123456;
input bool    VerboseLogs                 = true;      // Verbose logging mode
input bool    EnableEntry                 = true;      // Master enable switch
input bool    EnableBuy                   = true;      // Allow long trades
input bool    EnableSell                  = true;      // Allow short trades
input bool    EnableAnalytics             = true;      // Enable basic analytics
input bool    EnablePerformanceOptimization = true;   // Enable performance optimizations

// Time Filters
input group "=== TIME FILTERS ==="
input bool    UseTimeFilter               = false;
input int     BeginHour                   = 8;
input int     BeginMinute                 = 0;
input int     EndHour                     = 18;
input int     EndMinute                   = 0;

// Risk Management
input group "=== RISK MANAGEMENT ==="
input int     MaxSpreadPts                = 100;
input double  MaxDrawdownPercent          = 15.0;      // Maximum drawdown percentage
input bool    EnableDrawdownProtection    = true;      // Enable drawdown protection

// Position Sizing
input group "=== POSITION SIZING ==="
input bool    DynamicLots                 = false;
input double  RiskPct                     = 2.0;
input double  FixedLot                    = 0.1;
input int     SlippagePts                 = 20;        // Order slippage

// Stop Loss & Take Profit
input group "=== STOP LOSS & TAKE PROFIT ==="
input bool    UseMoneyTargets             = false;
input double  MoneySLAmount               = 100.0;
input double  MoneyTPAmount               = 200.0;
input double  PointsSL                    = 1000;
input double  PointsTP                    = 2000;
input bool    UseTrailingStop             = false;     // Enable trailing stop
input double  TrailingStopPoints          = 500;       // Trailing stop distance

// Daily Risk Management
input group "=== DAILY RISK MANAGEMENT ==="
input bool    EnableMaxTradesPerDay       = false;
input int     MaxTradesPerDay             = 5;
input bool    EnableDailyLossLimit        = true;      // Enable daily loss limit
input double  DailyLossLimit              = 500.0;     // Daily loss limit

// SuperTrend Indicator Parameters
input group "=== SUPERTREND PARAMETERS ==="
input ENUM_TIMEFRAMES InpIndTimeframe     = PERIOD_H1; // Indicator timeframe
input int     CCIPeriod                   = 50;        // CCI period
input int     ATRPeriod                   = 5;         // ATR period
input int     CCILevel                    = 0;         // CCI trigger level
input uint    SignalBar                   = 1;         // Bar number for signal

// Signal Filtering
input group "=== SIGNAL FILTERING ==="
input bool    FilterSignalsOnClose        = true;      // Only take signals on bar close
input bool    RequireSignalConfirmation   = false;     // Require signal confirmation
input int     SignalCooldownBars          = 2;         // Bars between signals

// Performance Monitoring
input group "=== PERFORMANCE MONITORING ==="
input bool    EnableRealTimeAnalytics     = true;      // Enable real-time analytics
input bool    SavePerformanceData         = false;     // Save performance to file
input int     AnalyticsUpdateInterval     = 120;       // Analytics update interval (seconds)

//+------------------------------------------------------------------+
//| Enhanced Global Variables                                        |
//+------------------------------------------------------------------+
int TimeShiftSec;
int SuperTrendHandle;
int min_rates_total;

TradeStatistics g_dailyStats;
MarketInfo g_marketInfo;

datetime g_lastDayReset = 0;
datetime g_lastPerformanceUpdate = 0;
datetime g_lastRiskCheck = 0;
datetime g_lastAnalyticsUpdate = 0;

// Signal tracking variables
static bool Recount = true;
static bool BUY_Open = false, BUY_Close = false;
static bool SELL_Open = false, SELL_Close = false;
static datetime UpSignalTime, DnSignalTime;
static CIsNewBar NB;

// Performance optimization variables
static int g_consecutiveLosses = 0;
static double g_sessionHighEquity = 0;
static double g_sessionStartEquity = 0;
static int g_signalCooldown = 0;

// Analytics arrays
double g_equityCurve[];
double g_drawdownCurve[];
datetime g_equityTimes[];
int g_analyticsCount = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialize trading algorithms
    InitializeTradeAlgorithms(_Symbol);
    trade.SetExpertMagicNumber(MagicNumber);
    
    // Validate inputs
    if(!ValidateInputParameters())
    {
        Print("ERROR: Invalid input parameters");
        return INIT_PARAMETERS_INCORRECT;
    }
    
    // Get handle for SuperTrend indicator
    SuperTrendHandle = iCustom(_Symbol, InpIndTimeframe, "Supertrend",
                              CCIPeriod, ATRPeriod, CCILevel, 0); // Shift = 0
    
    if(SuperTrendHandle == INVALID_HANDLE)
    {
        Print("Failed to get SuperTrend indicator handle");
        return INIT_FAILED;
    }
    
    // Initialize timeframe shift in seconds
    TimeShiftSec = PeriodSeconds(InpIndTimeframe);
    
    // Initialize minimum rates required
    min_rates_total = int(MathMax(CCIPeriod, ATRPeriod) + SignalBar + 10);
    
    // Initialize analytics
    InitializeAnalytics();
    
    // Initialize performance tracking
    InitializePerformanceTracking();
    
    // Set up timer for performance monitoring
    if(EnableRealTimeAnalytics && AnalyticsUpdateInterval > 0)
    {
        EventSetTimer(AnalyticsUpdateInterval);
    }
    
    // Print initialization info
    PrintInitializationInfo();
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Save performance data before exit
    if(SavePerformanceData)
        SaveAnalyticsToFile();
    
    // Clean up global variables
    GlobalVariableDel_(_Symbol);
    
    // Release indicator handles
    if(SuperTrendHandle != INVALID_HANDLE)
        IndicatorRelease(SuperTrendHandle);
    
    // Clean up trading algorithms
    CleanupTradeAlgorithms();
    
    // Kill timer
    EventKillTimer();
    
    if(VerboseLogs)
    {
        Print("Enhanced SuperTrend EA deinitialized. Reason: ", reason);
        PrintFinalPerformanceReport();
    }
}

//+------------------------------------------------------------------+
//| Expert tick function - Enhanced                                  |
//+------------------------------------------------------------------+
void OnTick()
{
    // Performance optimization: Early exit checks
    if(!EnableEntry)
        return;
    
    // Update performance metrics periodically
    UpdatePerformanceMetrics();
    
    // Check risk management
    if(!CheckRiskManagement())
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
    if(!ValidateIndicatorData())
        return;
    
    // Load history for proper indicator calculation
    LoadHistory(TimeCurrent() - PeriodSeconds(InpIndTimeframe) - 1, _Symbol, InpIndTimeframe);
    
    // Process trading signals
    ProcessTradingSignals();
    
    // Process position management
    ProcessPositionManagement();
    
    // Update real-time analytics
    if(EnableRealTimeAnalytics)
        UpdateRealTimeAnalytics();
}

//+------------------------------------------------------------------+
//| Timer event handler                                              |
//+------------------------------------------------------------------+
void OnTimer()
{
    // Update analytics
    if(EnableRealTimeAnalytics)
    {
        UpdateAnalyticsData();
    }
    
    // Perform periodic maintenance
    PerformPeriodicMaintenance();
}

//+------------------------------------------------------------------+
//| Validation Functions                                             |
//+------------------------------------------------------------------+
bool ValidateInputParameters()
{
    if(CCIPeriod <= 0 || ATRPeriod <= 0)
    {
        Print("ERROR: Invalid SuperTrend parameters");
        return false;
    }
    
    if(RiskPct <= 0 || RiskPct > 100)
    {
        Print("ERROR: Invalid risk percentage");
        return false;
    }
    
    if(MaxDrawdownPercent <= 0 || MaxDrawdownPercent > 50)
    {
        Print("ERROR: Invalid maximum drawdown percentage");
        return false;
    }
    
    return true;
}

bool ValidateIndicatorData()
{
    if(BarsCalculated(SuperTrendHandle) < min_rates_total)
    {
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Market Conditions Check                                          |
//+------------------------------------------------------------------+
bool CheckMarketConditions()
{
    // Update market info
    UpdateMarketInfoCache(_Symbol);
    
    // Basic spread check
    if(g_marketInfo.spread > MaxSpreadPts)
    {
        if(VerboseLogs) 
            Print("Spread too high: ", g_marketInfo.spread, " > ", MaxSpreadPts);
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Daily Limits Check                                               |
//+------------------------------------------------------------------+
bool CheckDailyLimits()
{
    // Standard daily limits
    if(EnableMaxTradesPerDay && g_dailyStats.totalTrades >= MaxTradesPerDay)
    {
        if(VerboseLogs) 
            Print("Daily trade limit reached: ", g_dailyStats.totalTrades, "/", MaxTradesPerDay);
        return false;
    }
    
    if(EnableDailyLossLimit && (g_dailyStats.totalProfit - g_dailyStats.totalLoss) <= -DailyLossLimit)
    {
        if(VerboseLogs) 
            Print("Daily loss limit reached: ", DoubleToString(g_dailyStats.totalProfit - g_dailyStats.totalLoss, 2));
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Risk Management                                                  |
//+------------------------------------------------------------------+
bool CheckRiskManagement()
{
    datetime currentTime = TimeCurrent();
    
    // Perform risk check at intervals
    if(currentTime < g_lastRiskCheck + RISK_CHECK_INTERVAL)
        return true;
    
    g_lastRiskCheck = currentTime;
    
    // Check drawdown protection
    if(EnableDrawdownProtection)
    {
        double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
        double maxEquity = MathMax(g_sessionHighEquity, currentEquity);
        
        g_sessionHighEquity = maxEquity;
        
        double drawdownPercent = ((maxEquity - currentEquity) / maxEquity) * 100.0;
        
        if(drawdownPercent > MaxDrawdownPercent)
        {
            Print("CRITICAL: Maximum drawdown exceeded: ", DoubleToString(drawdownPercent, 2), 
                  "% > ", MaxDrawdownPercent, "%");
            
            // Close all positions
            CloseAllPositions("Drawdown protection triggered");
            
            return false;
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Initialize Systems                                                |
//+------------------------------------------------------------------+
void InitializeAnalytics()
{
    // Initialize analytics arrays
    ArrayResize(g_equityCurve, ANALYTICS_BUFFER_SIZE);
    ArrayResize(g_drawdownCurve, ANALYTICS_BUFFER_SIZE);
    ArrayResize(g_equityTimes, ANALYTICS_BUFFER_SIZE);
    
    g_analyticsCount = 0;
    
    // Record initial equity
    double initialEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    g_sessionStartEquity = initialEquity;
    g_sessionHighEquity = initialEquity;
    
    if(VerboseLogs)
        Print("Analytics system initialized. Initial equity: ", DoubleToString(initialEquity, 2));
}

void InitializePerformanceTracking()
{
    // Initialize structures
    g_dailyStats.Init();
    g_marketInfo.Init();
    
    if(VerboseLogs)
        Print("Performance tracking initialized");
}

//+------------------------------------------------------------------+
//| Signal Processing                                                 |
//+------------------------------------------------------------------+
void ProcessTradingSignals()
{
    // Check signal cooldown
    if(g_signalCooldown > 0)
    {
        g_signalCooldown--;
        return;
    }
    
    // Check for new bar or force recount
    if(!SignalBar || NB.IsNewBar(_Symbol, InpIndTimeframe) || Recount)
    {
        // Reset signal flags
        BUY_Open = false;
        SELL_Open = false;
        BUY_Close = false;
        SELL_Close = false;
        Recount = false;
        
        // Get signals from indicator
        if(!GetSignals())
            return;
        
        // Apply signal filtering
        if(!ApplySignalFilters())
            return;
        
        if(VerboseLogs && (BUY_Open || SELL_Open))
        {
            string signalType = BUY_Open ? "BUY" : "SELL";
            Print("SuperTrend ", signalType, " signal validated and ready for execution");
        }
    }
    
    // Execute trades
    ExecuteTrades();
}

bool GetSignals()
{
    // Get SuperTrend signals from indicator buffers
    double UpTrend[1], DownTrend[1];
    double UpSignal[1], DownSignal[1];
    
    // Copy trend buffers
    if(CopyBuffer(SuperTrendHandle, 0, SignalBar, 1, UpTrend) <= 0) {Recount = true; return false;}
    if(CopyBuffer(SuperTrendHandle, 1, SignalBar, 1, DownTrend) <= 0) {Recount = true; return false;}
    if(CopyBuffer(SuperTrendHandle, 2, SignalBar, 1, UpSignal) <= 0) {Recount = true; return false;}
    if(CopyBuffer(SuperTrendHandle, 3, SignalBar, 1, DownSignal) <= 0) {Recount = true; return false;}
    
    datetime signalTime = iTime(_Symbol, InpIndTimeframe, SignalBar);
    double currentPrice = iClose(_Symbol, InpIndTimeframe, SignalBar);
    
    // Process buy signals
    if(UpSignal[0] != 0 && UpSignal[0] != EMPTY_VALUE && UpTrend[0] != 0)
    {
        if(EnableBuy && EnableEntry) 
            BUY_Open = true;
        if(EnableSell) 
            SELL_Close = true;
            
        UpSignalTime = signalTime + TimeShiftSec;
        
        if(VerboseLogs)
            Print("SuperTrend BUY signal: Price=", DoubleToString(currentPrice, _Digits), 
                  " Trend=", DoubleToString(UpTrend[0], _Digits));
    }
    
    // Process sell signals
    if(DownSignal[0] != 0 && DownSignal[0] != EMPTY_VALUE && DownTrend[0] != 0)
    {
        if(EnableSell && EnableEntry) 
            SELL_Open = true;
        if(EnableBuy) 
            BUY_Close = true;
            
        DnSignalTime = signalTime + TimeShiftSec;
        
        if(VerboseLogs)
            Print("SuperTrend SELL signal: Price=", DoubleToString(currentPrice, _Digits), 
                  " Trend=", DoubleToString(DownTrend[0], _Digits));
    }
    
    return true;
}

bool ApplySignalFilters()
{
    if(!BUY_Open && !SELL_Open)
        return true;
    
    // Additional signal validation can be added here
    return true;
}

//+------------------------------------------------------------------+
//| Trade Execution                                                  |
//+------------------------------------------------------------------+
void ExecuteTrades()
{
    // Calculate lot size
    double lotSize = CalculateLotSize();
    MarginMode mmMode = DynamicLots ? FREEMARGIN : LOT;
    
    // Close positions first
    if(BUY_Close)
        SellPositionClose(true, _Symbol, SlippagePts, MagicNumber);
        
    if(SELL_Close)
        BuyPositionClose(true, _Symbol, SlippagePts, MagicNumber);
    
    // Check position limits before opening new positions
    if(!CheckPositionLimits())
        return;
    
    // Open new positions
    if(BUY_Open)
    {
        ExecuteBuyOrder(lotSize, mmMode);
    }
    
    if(SELL_Open)
    {
        ExecuteSellOrder(lotSize, mmMode);
    }
}

double CalculateLotSize()
{
    if(DynamicLots)
    {
        double accountSize = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
        double riskAmount = accountSize * RiskPct / 100.0;
        double slDistance = PointsSL * _Point;
        double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
        
        if(slDistance > 0 && tickValue > 0)
        {
            double lot = riskAmount / (slDistance * tickValue / _Point);
            return NormalizeDouble(lot, 2);
        }
    }
    
    return FixedLot;
}

void ExecuteBuyOrder(double lotSize, MarginMode mmMode)
{
    // Calculate SL/TP
    int sl, tp;
    CalculateSLTP(true, sl, tp);
    
    if(BuyPositionOpen(true, _Symbol, UpSignalTime, lotSize, mmMode, SlippagePts, sl, tp, MagicNumber))
    {
        g_dailyStats.totalTrades++;
        g_signalCooldown = SignalCooldownBars;
        
        if(VerboseLogs) 
            Print("BUY position opened: Lot=", DoubleToString(lotSize, 2), 
                  " SL=", sl, " TP=", tp);
    }
}

void ExecuteSellOrder(double lotSize, MarginMode mmMode)
{
    // Calculate SL/TP
    int sl, tp;
    CalculateSLTP(false, sl, tp);
    
    if(SellPositionOpen(true, _Symbol, DnSignalTime, lotSize, mmMode, SlippagePts, sl, tp, MagicNumber))
    {
        g_dailyStats.totalTrades++;
        g_signalCooldown = SignalCooldownBars;
        
        if(VerboseLogs) 
            Print("SELL position opened: Lot=", DoubleToString(lotSize, 2), 
                  " SL=", sl, " TP=", tp);
    }
}

void CalculateSLTP(bool isBuy, int &sl, int &tp)
{
    if(UseMoneyTargets)
    {
        sl = CalculatePointsFromMoney(MoneySLAmount, true);
        tp = CalculatePointsFromMoney(MoneyTPAmount, false);
    }
    else
    {
        sl = (int)PointsSL;
        tp = (int)PointsTP;
    }
}

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
//| Position Management                                              |
//+------------------------------------------------------------------+
void ProcessPositionManagement()
{
    // Process trailing stops
    if(UseTrailingStop)
        ProcessTrailingStops();
    
    // Update position metrics
    UpdateAllPositionMetrics();
}

void ProcessTrailingStops()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(positionInfo.SelectByIndex(i))
        {
            if(positionInfo.Symbol() == _Symbol && positionInfo.Magic() == MagicNumber)
            {
                ProcessPositionTrailing(positionInfo.Ticket());
            }
        }
    }
}

void ProcessPositionTrailing(ulong ticket)
{
    if(!PositionSelectByTicket(ticket))
        return;
    
    double currentPrice = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ?
                         SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                         SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    
    double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
    double currentSL = PositionGetDouble(POSITION_SL);
    double currentTP = PositionGetDouble(POSITION_TP);
    
    bool isBuy = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
    double profitPoints = isBuy ? (currentPrice - openPrice) : (openPrice - currentPrice);
    
    // Apply trailing stop
    if(profitPoints >= TrailingStopPoints * _Point)
    {
        double newSL = 0;
        
        if(isBuy)
        {
            newSL = currentPrice - TrailingStopPoints * _Point;
            if(newSL > currentSL + _Point)
            {
                trade.PositionModify(ticket, newSL, currentTP);
            }
        }
        else
        {
            newSL = currentPrice + TrailingStopPoints * _Point;
            if(newSL < currentSL - _Point)
            {
                trade.PositionModify(ticket, newSL, currentTP);
            }
        }
    }
}

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
    
    return positionCount < MAX_CONCURRENT_POSITIONS;
}

void UpdateAllPositionMetrics()
{
    // Update position cache for performance tracking
    UpdatePositionCache(_Symbol, MagicNumber);
}

//+------------------------------------------------------------------+
//| Analytics and Performance Functions                              |
//+------------------------------------------------------------------+
void UpdatePerformanceMetrics()
{
    datetime currentTime = TimeCurrent();
    
    if(currentTime < g_lastPerformanceUpdate + PERFORMANCE_UPDATE_INTERVAL)
        return;
    
    g_lastPerformanceUpdate = currentTime;
    
    // Update market info
    UpdateMarketInfoCache(_Symbol);
}

void UpdateRealTimeAnalytics()
{
    datetime currentTime = TimeCurrent();
    
    if(currentTime < g_lastAnalyticsUpdate + 60) // Update every minute
        return;
    
    g_lastAnalyticsUpdate = currentTime;
    
    // Record equity curve
    RecordEquityPoint();
}

void UpdateAnalyticsData()
{
    // Update real-time analytics data
    datetime currentTime = TimeCurrent();
    double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    
    if(VerboseLogs)
        Print("Analytics data updated - Equity: ", DoubleToString(currentEquity, 2));
}

void RecordEquityPoint()
{
    if(g_analyticsCount >= ANALYTICS_BUFFER_SIZE)
    {
        // Shift array to make room for new data
        for(int i = 0; i < ANALYTICS_BUFFER_SIZE - 1; i++)
        {
            g_equityCurve[i] = g_equityCurve[i + 1];
            g_drawdownCurve[i] = g_drawdownCurve[i + 1];
            g_equityTimes[i] = g_equityTimes[i + 1];
        }
        g_analyticsCount = ANALYTICS_BUFFER_SIZE - 1;
    }
    
    double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    double drawdown = ((g_sessionHighEquity - currentEquity) / g_sessionHighEquity) * 100.0;
    
    g_equityCurve[g_analyticsCount] = currentEquity;
    g_drawdownCurve[g_analyticsCount] = MathMax(0, drawdown);
    g_equityTimes[g_analyticsCount] = TimeCurrent();
    
    g_analyticsCount++;
    
    // Update session high
    if(currentEquity > g_sessionHighEquity)
        g_sessionHighEquity = currentEquity;
}

void PerformPeriodicMaintenance()
{
    // Clean up old data
    if(g_analyticsCount > ANALYTICS_BUFFER_SIZE * 0.9)
    {
        if(VerboseLogs)
            Print("Performing analytics buffer maintenance");
        
        // Keep most recent 50% of data
        int keepCount = ANALYTICS_BUFFER_SIZE / 2;
        for(int i = 0; i < keepCount; i++)
        {
            g_equityCurve[i] = g_equityCurve[g_analyticsCount - keepCount + i];
            g_drawdownCurve[i] = g_drawdownCurve[g_analyticsCount - keepCount + i];
            g_equityTimes[i] = g_equityTimes[g_analyticsCount - keepCount + i];
        }
        g_analyticsCount = keepCount;
    }
}

//+------------------------------------------------------------------+
//| Utility Functions                                                |
//+------------------------------------------------------------------+
void CloseAllPositions(string reason)
{
    Print("Closing all positions. Reason: ", reason);
    
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(positionInfo.SelectByIndex(i))
        {
            if(positionInfo.Symbol() == _Symbol && positionInfo.Magic() == MagicNumber)
            {
                ulong ticket = positionInfo.Ticket();
                if(trade.PositionClose(ticket))
                {
                    Print("Position ", ticket, " closed successfully");
                }
                else
                {
                    Print("Failed to close position ", ticket, ". Error: ", trade.ResultRetcode());
                }
            }
        }
    }
}

void SaveAnalyticsToFile()
{
    if(!SavePerformanceData || g_analyticsCount == 0)
        return;
    
    string fileName = "SuperTrend_EA_Analytics.csv";
    int fileHandle = FileOpen(fileName, FILE_WRITE | FILE_CSV);
    
    if(fileHandle != INVALID_HANDLE)
    {
        // Write header
        FileWrite(fileHandle, "DateTime", "Equity", "Drawdown%", "TotalTrades");
        
        // Write data
        for(int i = 0; i < g_analyticsCount; i++)
        {
            FileWrite(fileHandle, TimeToString(g_equityTimes[i]),
                     g_equityCurve[i], g_drawdownCurve[i], g_dailyStats.totalTrades);
        }
        
        FileClose(fileHandle);
        Print("Analytics data saved to: ", fileName);
    }
}

void PrintInitializationInfo()
{
    if(!VerboseLogs)
        return;
    
    Print("=== Enhanced SuperTrend EA v2.0 Initialization ===");
    Print("Magic Number: ", MagicNumber);
    Print("Symbol: ", _Symbol);
    Print("Timeframe: ", EnumToString(InpIndTimeframe));
    Print("SuperTrend - CCI Period: ", CCIPeriod, ", ATR Period: ", ATRPeriod);
    Print("Risk Management: ", DynamicLots ? "Dynamic (" + DoubleToString(RiskPct, 1) + "%)" : "Fixed (" + DoubleToString(FixedLot, 2) + " lots)");
    Print("Trailing Stop: ", UseTrailingStop ? "Enabled (" + DoubleToString(TrailingStopPoints, 0) + " pts)" : "Disabled");
    Print("Drawdown Protection: ", EnableDrawdownProtection ? DoubleToString(MaxDrawdownPercent, 1) + "%" : "Disabled");
    Print("Real-time Analytics: ", EnableRealTimeAnalytics ? "Enabled" : "Disabled");
    Print("=== Initialization Complete ===");
}

void PrintFinalPerformanceReport()
{
    Print("=== Final Performance Report ===");
    PrintTradeStatistics();
    Print("=== End of Report ===");
}

//+------------------------------------------------------------------+
//| Trade Transaction Handler                                         |
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
                double commission = HistoryDealGetDouble(trans.deal, DEAL_COMMISSION);
                double swap = HistoryDealGetDouble(trans.deal, DEAL_SWAP);
                
                ENUM_DEAL_TYPE dealType = (ENUM_DEAL_TYPE)HistoryDealGetInteger(trans.deal, DEAL_TYPE);
                
                if(dealType == DEAL_TYPE_BUY || dealType == DEAL_TYPE_SELL)
                {
                    // Position closed - update statistics
                    double totalPnL = profit + commission + swap;
                    UpdateTradeStatistics(false, totalPnL);
                    
                    // Update consecutive losses counter
                    if(totalPnL < 0)
                        g_consecutiveLosses++;
                    else
                        g_consecutiveLosses = 0;
                    
                    // Record analytics
                    RecordEquityPoint();
                    
                    if(VerboseLogs)
                    {
                        ulong ticket = HistoryDealGetInteger(trans.deal, DEAL_POSITION_ID);
                        Print("Trade Closed - Ticket: ", ticket,
                              " Profit: ", DoubleToString(profit, 2),
                              " Commission: ", DoubleToString(commission, 2),
                              " Swap: ", DoubleToString(swap, 2),
                              " Net: ", DoubleToString(totalPnL, 2));
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Time Filters                                                     |
//+------------------------------------------------------------------+
bool CheckTimeFilters()
{
    if(!UseTimeFilter)
        return true;
    
    datetime currentTime = TimeCurrent();
    MqlDateTime timeStruct;
    TimeToStruct(currentTime, timeStruct);
    
    int currentMinutes = timeStruct.hour * 60 + timeStruct.min;
    int startMinutes = BeginHour * 60 + BeginMinute;
    int endMinutes = EndHour * 60 + EndMinute;
    
    if(startMinutes <= endMinutes)
    {
        return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    }
    else // Overnight session
    {
        return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
}

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
        
        // Reset session equity tracking
        g_sessionStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);
        g_sessionHighEquity = g_sessionStartEquity;
        g_consecutiveLosses = 0;
        
        if(VerboseLogs)
            Print("Daily statistics reset for new trading day: ", TimeToString(currentDay, TIME_DATE));
    }
}

void ResetDailyStats()
{
    g_dailyStats.Init();
}

void PrintDailyStats()
{
    Print("=== Daily Trading Statistics ===");
    Print("Total Trades: ", g_dailyStats.totalTrades);
    Print("Winning Trades: ", g_dailyStats.winningTrades);
    Print("Losing Trades: ", g_dailyStats.losingTrades);
    Print("Win Rate: ", DoubleToString(g_dailyStats.winRate, 1), "%");
    Print("Total Profit: ", DoubleToString(g_dailyStats.totalProfit, 2));
    Print("Total Loss: ", DoubleToString(g_dailyStats.totalLoss, 2));
    Print("Net Profit: ", DoubleToString(g_dailyStats.totalProfit - g_dailyStats.totalLoss, 2));
    Print("Profit Factor: ", DoubleToString(g_dailyStats.profitFactor, 2));
    Print("Consecutive Losses: ", g_consecutiveLosses);
    Print("=================================");
}

//+------------------------------------------------------------------+