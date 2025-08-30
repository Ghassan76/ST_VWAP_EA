//+------------------------------------------------------------------+
//|                                        Enhanced_ST_VWAP_EA.mq5 |
//|              Enhanced SuperTrend & VWAP Expert Advisor System  |
//|                                  Performance Optimized v2.0     |
//+------------------------------------------------------------------+
#property copyright "Enhanced ST&VWAP Expert Advisor © 2025"
#property link      "https://www.mql5.com"
#property version   "2.00"
#property description "Enhanced EA with SuperTrend & VWAP, Advanced Analytics & Performance Optimization"

//+------------------------------------------------------------------+
//| Include Files                                                    |
//+------------------------------------------------------------------+
#include <Enhanced_TradeAlgorithms.mqh>

//+------------------------------------------------------------------+
//| Performance & Analytics Constants                                |
//+------------------------------------------------------------------+
#define PERFORMANCE_UPDATE_INTERVAL 60    // Update analytics every 60 seconds
#define RISK_CHECK_INTERVAL 30           // Risk check every 30 seconds
#define MAX_CONCURRENT_POSITIONS 5       // Maximum concurrent positions
#define SIGNAL_VALIDATION_BARS 3         // Bars to validate signals
#define ANALYTICS_BUFFER_SIZE 1000       // Analytics buffer size

//+------------------------------------------------------------------+
//| Input Parameters - Enhanced Organization                         |
//+------------------------------------------------------------------+
// General Settings
input group "=== GENERAL SETTINGS ==="
input ulong   MagicNumber                 = 567890;
input bool    VerboseLogs                 = true;      // Verbose logging mode
input bool    EnableEntry                 = true;      // Master enable switch
input bool    EnableBuy                   = true;      // Allow long trades
input bool    EnableSell                  = true;      // Allow short trades
input bool    EnableAnalytics             = true;      // Enable advanced analytics
input bool    EnablePerformanceOptimization = true;   // Enable performance optimizations

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

// Market Conditions & Risk Management
input group "=== MARKET CONDITIONS & RISK ==="
input int     MaxSpreadPts                = 140;
input double  MaxSlippagePts              = 30.0;      // Maximum allowed slippage
input double  MaxDrawdownPercent          = 10.0;      // Maximum drawdown percentage
input bool    EnableDrawdownProtection    = true;      // Enable drawdown protection
input double  VolatilityFilter            = 2.0;       // Volatility filter multiplier

// Position Sizing with Advanced Risk Management
input group "=== POSITION SIZING ==="
input bool    DynamicLots                 = false;
input double  RiskPct                     = 1.0;
input double  FixedLot                    = 2.00;
input int     SlippagePts                 = 30;        // Order slippage
input bool    UsePositionSizing           = true;      // Enable advanced position sizing
input double  MaxRiskPerTrade             = 2.0;       // Maximum risk per trade %
input bool    EnableVolatilityAdjustment  = true;      // Adjust size based on volatility

// Stop Loss & Take Profit - Enhanced
input group "=== STOP LOSS & TAKE PROFIT ==="
input bool    UseMoneyTargets             = false;
input double  MoneySLAmount               = 50.0;
input double  MoneyTPAmount               = 100.0;
input double  PointsSL                    = 10000;
input double  PointsTP                    = 10000;
input bool    UseATRBasedSLTP             = true;      // Use ATR-based SL/TP
input double  ATRMultiplierSL             = 2.0;       // ATR multiplier for SL
input double  ATRMultiplierTP             = 4.0;       // ATR multiplier for TP
input bool    EnableDynamicSLTP           = true;      // Dynamic SL/TP adjustment

// Enhanced State Management
input group "=== STATE MANAGEMENT ==="
input int     FreezeDurationMinutes       = 15;        // Freeze duration after issues
input int     PostTradeCooldownMin        = 5;         // Cooldown after trade close
input bool    FreezeOnDataMissing         = true;      // Freeze on missing data
input bool    EnableStateRecovery         = true;      // Enable state recovery
input int     MaxConsecutiveLosses        = 5;         // Max consecutive losses before freeze

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

// Daily Risk Management - Enhanced
input group "=== DAILY RISK MANAGEMENT ==="
input bool    EnableMaxTradesPerDay       = false;
input int     MaxTradesPerDay             = 10;
input bool    EnableProfitCap             = false;
input double  DailyProfitTarget           = 100.0;
input bool    EnableLossLimit             = false;
input double  DailyLossLimit              = 200.0;
input bool    EnableDailyDrawdownLimit    = true;      // Enable daily drawdown limit
input double  DailyDrawdownLimit          = 5.0;       // Daily drawdown limit %

// SuperTrend & VWAP Indicator Parameters - Enhanced
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

// Signal Filtering - Advanced
input group "=== SIGNAL FILTERING ==="
input bool    FilterSignalsOnClose        = true;      // Only take signals on bar close
input bool    RequireVWAPConfirmation     = true;      // Require VWAP confirmation for signals
input double  MinPointsFromVWAP           = 50.0;      // Minimum distance from VWAP in points
input bool    EnableTrendFilter           = true;      // Enable trend strength filter
input double  MinTrendStrength            = 30.0;      // Minimum trend strength %
input bool    EnableVolatilityFilter      = true;      // Enable volatility filter
input bool    RequireSignalConfirmation   = true;      // Require signal confirmation

// Performance Monitoring
input group "=== PERFORMANCE MONITORING ==="
input bool    EnableRealTimeAnalytics     = true;      // Enable real-time analytics
input bool    EnablePerformanceDashboard  = true;      // Enable performance dashboard
input bool    SavePerformanceData         = true;      // Save performance to file
input int     AnalyticsUpdateInterval     = 60;        // Analytics update interval (seconds)
input bool    EnableAlerts                = true;      // Enable performance alerts
input double  AlertDrawdownLevel          = 5.0;       // Alert when drawdown exceeds %

//+------------------------------------------------------------------+
//| Enhanced Global Variables                                        |
//+------------------------------------------------------------------+
int TimeShiftSec;
int STVWAPHandle;
int ATRHandle;
int min_rates_total;

SessionTime g_sessions[4];
TradeStats g_dailyStats;
PerformanceMetrics g_performanceMetrics;
MarketConditions g_marketConditions;

datetime g_lastDayReset = 0;
datetime g_lastPerformanceUpdate = 0;
datetime g_lastRiskCheck = 0;
datetime g_lastAnalyticsUpdate = 0;

// Signal tracking variables with enhancement
static bool Recount = true;
static bool BUY_Open = false, BUY_Close = false;
static bool SELL_Open = false, SELL_Close = false;
static datetime UpSignalTime, DnSignalTime;
static CIsNewBar NB;

// Performance optimization variables
static double g_lastATRValue = 0;
static datetime g_lastATRUpdate = 0;
static int g_consecutiveLosses = 0;
static double g_sessionHighEquity = 0;
static double g_sessionStartEquity = 0;

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
    // Initialize enhanced trading algorithms
    InitializeEnhancedAlgorithms();
    trade.SetExpertMagicNumber(MagicNumber);
    
    // Validate inputs
    if(!ValidateInputParameters())
    {
        Print("ERROR: Invalid input parameters");
        return INIT_PARAMETERS_INCORRECT;
    }
    
    // Get handle for Enhanced ST&VWAP indicator
    STVWAPHandle = iCustom(_Symbol, InpIndTimeframe, "Enhanced_ST_VWAP_Indicator",
                          ATRPeriod, STMultiplier, SourcePrice, TakeWicksIntoAccount,
                          VWAPPriceMethod, MinVolumeThreshold, ResetVWAPDaily,
                          EnableVWAPFilter, true); // ShowVWAPLine = true
    
    if(STVWAPHandle == INVALID_HANDLE)
    {
        Print("Failed to get Enhanced ST&VWAP indicator handle");
        return INIT_FAILED;
    }
    
    // Get ATR handle for dynamic SL/TP
    if(UseATRBasedSLTP)
    {
        ATRHandle = iATR(_Symbol, InpIndTimeframe, ATRPeriod);
        if(ATRHandle == INVALID_HANDLE)
        {
            Print("Warning: Failed to get ATR handle, using fixed SL/TP");
            UseATRBasedSLTP = false;
        }
    }
    
    // Initialize timeframe shift in seconds
    TimeShiftSec = PeriodSeconds(InpIndTimeframe);
    
    // Initialize minimum rates required
    min_rates_total = int(MathMax(ATRPeriod, 50) + SignalBar + 10);
    
    // Initialize trading sessions
    InitializeSessions();
    
    // Initialize analytics
    InitializeAnalytics();
    
    // Initialize performance tracking
    InitializePerformanceTracking();
    
    // Set EA state to ready
    SetEAState(ST_READY);
    
    // Set up timer for performance monitoring
    if(EnableRealTimeAnalytics && AnalyticsUpdateInterval > 0)
    {
        EventSetTimer(AnalyticsUpdateInterval);
    }
    
    // Print comprehensive initialization info
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
    if(STVWAPHandle != INVALID_HANDLE)
        IndicatorRelease(STVWAPHandle);
    
    if(ATRHandle != INVALID_HANDLE)
        IndicatorRelease(ATRHandle);
    
    // Clean up enhanced algorithms
    CleanupEnhancedAlgorithms();
    
    // Kill timer
    EventKillTimer();
    
    if(VerboseLogs)
    {
        Print("Enhanced ST&VWAP EA deinitialized. Reason: ", reason);
        PrintFinalPerformanceReport();
    }
}

//+------------------------------------------------------------------+
//| Expert tick function - Enhanced                                  |
//+------------------------------------------------------------------+
void OnTick()
{
    // Performance optimization: Early exit checks
    if(!EnableEntry || !IsEAReadyToTrade())
        return;
    
    // Update performance metrics periodically
    UpdatePerformanceMetrics();
    
    // Check risk management
    if(!CheckRiskManagement())
        return;
    
    // Check daily statistics reset
    CheckDailyReset();
    
    // Check daily risk limits with enhanced logic
    if(!CheckEnhancedDailyLimits())
        return;
    
    // Check market conditions with enhanced filtering
    if(!CheckEnhancedMarketConditions())
        return;
    
    // Check time filters
    if(!CheckTimeFilters())
        return;
    
    // Check indicator data availability with retry logic
    if(!ValidateIndicatorData())
        return;
    
    // Load history for proper indicator calculation
    LoadHistory(TimeCurrent() - PeriodSeconds(InpIndTimeframe) - 1, _Symbol, InpIndTimeframe);
    
    // Process enhanced trading signals
    ProcessEnhancedTradingSignals();
    
    // Process advanced position management
    ProcessAdvancedPositionManagement();
    
    // Update real-time analytics
    if(EnableRealTimeAnalytics)
        UpdateRealTimeAnalytics();
}

//+------------------------------------------------------------------+
//| Timer event handler - Enhanced                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
    // Update analytics
    if(EnableRealTimeAnalytics)
    {
        UpdateAnalyticsData();
        
        // Check for performance alerts
        CheckPerformanceAlerts();
    }
    
    // Update performance dashboard
    if(EnablePerformanceDashboard)
    {
        UpdatePerformanceDashboard();
    }
    
    // Perform periodic maintenance
    PerformPeriodicMaintenance();
}

//+------------------------------------------------------------------+
//| Validation Functions                                             |
//+------------------------------------------------------------------+
bool ValidateInputParameters()
{
    if(ATRPeriod <= 0 || STMultiplier <= 0)
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
    
    if(DailyDrawdownLimit <= 0 || DailyDrawdownLimit > 20)
    {
        Print("ERROR: Invalid daily drawdown limit");
        return false;
    }
    
    return true;
}

bool ValidateIndicatorData()
{
    if(BarsCalculated(STVWAPHandle) < min_rates_total)
    {
        if(FreezeOnDataMissing)
        {
            SetEAState(ST_FROZEN, FREEZE_DATA_MISSING);
        }
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Enhanced Market Conditions Check                                 |
//+------------------------------------------------------------------+
bool CheckEnhancedMarketConditions()
{
    // Update market conditions
    UpdateMarketConditions();
    
    // Basic spread check
    long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
    if(spread > MaxSpreadPts)
    {
        if(VerboseLogs) 
            Print("Spread too high: ", spread, " > ", MaxSpreadPts);
        return false;
    }
    
    // Enhanced volatility filter
    if(EnableVolatilityFilter && g_marketConditions.volatility > 0)
    {
        double normalizedVol = g_marketConditions.volatility;
        if(normalizedVol > VolatilityFilter * 2.0) // Too volatile
        {
            if(VerboseLogs) 
                Print("Market too volatile: ", normalizedVol, " > ", VolatilityFilter * 2.0);
            return false;
        }
        
        if(normalizedVol < VolatilityFilter * 0.1) // Too quiet
        {
            if(VerboseLogs) 
                Print("Market too quiet: ", normalizedVol, " < ", VolatilityFilter * 0.1);
            return false;
        }
    }
    
    // Trend strength filter
    if(EnableTrendFilter && MathAbs(g_marketConditions.trendStrength) < MinTrendStrength)
    {
        if(VerboseLogs) 
            Print("Insufficient trend strength: ", MathAbs(g_marketConditions.trendStrength), " < ", MinTrendStrength);
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Enhanced Daily Limits Check                                      |
//+------------------------------------------------------------------+
bool CheckEnhancedDailyLimits()
{
    // Standard daily limits
    if(EnableMaxTradesPerDay && g_dailyStats.totalTrades >= MaxTradesPerDay)
    {
        if(VerboseLogs) 
            Print("Daily trade limit reached: ", g_dailyStats.totalTrades, "/", MaxTradesPerDay);
        SetEAState(ST_FROZEN);
        return false;
    }
    
    if(EnableProfitCap && g_dailyStats.totalProfit >= DailyProfitTarget)
    {
        if(VerboseLogs) 
            Print("Daily profit target reached: ", DoubleToString(g_dailyStats.totalProfit, 2));
        SetEAState(ST_FROZEN);
        return false;
    }
    
    if(EnableLossLimit && g_dailyStats.totalProfit <= -DailyLossLimit)
    {
        if(VerboseLogs) 
            Print("Daily loss limit reached: ", DoubleToString(g_dailyStats.totalProfit, 2));
        SetEAState(ST_FROZEN);
        return false;
    }
    
    // Enhanced daily drawdown check
    if(EnableDailyDrawdownLimit)
    {
        double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
        double dailyDrawdown = ((g_sessionStartEquity - currentEquity) / g_sessionStartEquity) * 100.0;
        
        if(dailyDrawdown > DailyDrawdownLimit)
        {
            if(VerboseLogs) 
                Print("Daily drawdown limit exceeded: ", DoubleToString(dailyDrawdown, 2), "% > ", DailyDrawdownLimit, "%");
            SetEAState(ST_FROZEN);
            return false;
        }
    }
    
    // Consecutive losses protection
    if(g_consecutiveLosses >= MaxConsecutiveLosses)
    {
        if(VerboseLogs) 
            Print("Maximum consecutive losses reached: ", g_consecutiveLosses);
        SetEAState(ST_FROZEN);
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Enhanced Risk Management                                         |
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
        double maxEquity = g_performanceMetrics.startTime > 0 ? 
                          MathMax(g_sessionHighEquity, currentEquity) : currentEquity;
        
        g_sessionHighEquity = maxEquity;
        
        double drawdownPercent = ((maxEquity - currentEquity) / maxEquity) * 100.0;
        
        if(drawdownPercent > MaxDrawdownPercent)
        {
            Print("CRITICAL: Maximum drawdown exceeded: ", DoubleToString(drawdownPercent, 2), 
                  "% > ", MaxDrawdownPercent, "%");
            
            // Close all positions
            CloseAllPositions("Drawdown protection triggered");
            SetEAState(ST_FROZEN, FREEZE_MANUAL);
            
            return false;
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Initialize Enhanced Systems                                       |
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
    // Reset performance metrics
    ZeroMemory(g_performanceMetrics);
    g_performanceMetrics.startTime = TimeCurrent();
    
    // Initialize market conditions
    ZeroMemory(g_marketConditions);
    g_marketConditions.lastUpdate = TimeCurrent();
    
    if(VerboseLogs)
        Print("Performance tracking initialized");
}

//+------------------------------------------------------------------+
//| Enhanced Signal Processing                                        |
//+------------------------------------------------------------------+
void ProcessEnhancedTradingSignals()
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
        
        // Get enhanced signals from indicator
        if(!GetEnhancedSignals())
            return;
        
        // Apply advanced signal filtering
        if(!ApplyAdvancedSignalFilters())
            return;
        
        // Validate signals with confirmation
        if(RequireSignalConfirmation && !ValidateSignalConfirmation())
            return;
        
        if(VerboseLogs && (BUY_Open || SELL_Open))
        {
            string signalType = BUY_Open ? "BUY" : "SELL";
            Print("Enhanced ", signalType, " signal validated and ready for execution");
        }
    }
    
    // Execute trades with enhanced logic
    ExecuteEnhancedTrades();
}

bool GetEnhancedSignals()
{
    // Get SuperTrend signals (buffers from enhanced indicator)
    double BuySignal[1], SellSignal[1];
    double SuperTrend[1], VWAP[1], TrendStrength[1];
    
    // Copy signal buffers from Enhanced ST&VWAP indicator
    if(CopyBuffer(STVWAPHandle, 2, SignalBar, 1, BuySignal) <= 0) {Recount = true; return false;}
    if(CopyBuffer(STVWAPHandle, 3, SignalBar, 1, SellSignal) <= 0) {Recount = true; return false;}
    if(CopyBuffer(STVWAPHandle, 0, SignalBar, 1, SuperTrend) <= 0) {Recount = true; return false;}
    if(CopyBuffer(STVWAPHandle, 2, SignalBar, 1, VWAP) <= 0) {Recount = true; return false;}
    
    // Get trend strength if available
    bool hasTrendStrength = (CopyBuffer(STVWAPHandle, 6, SignalBar, 1, TrendStrength) > 0);
    
    datetime signalTime = iTime(_Symbol, InpIndTimeframe, SignalBar);
    double currentPrice = iClose(_Symbol, InpIndTimeframe, SignalBar);
    
    // Process buy signals with enhanced validation
    if(BuySignal[0] != 0 && BuySignal[0] != EMPTY_VALUE)
    {
        bool vwapOK = ValidateVWAPCondition(currentPrice, VWAP[0]);
        bool trendOK = !EnableTrendFilter || !hasTrendStrength || TrendStrength[0] >= MinTrendStrength;
        
        if(vwapOK && trendOK)
        {
            if(EnableBuy && EnableEntry) 
                BUY_Open = true;
            if(EnableSell) 
                SELL_Close = true;
                
            UpSignalTime = signalTime + TimeShiftSec;
            
            if(VerboseLogs)
                Print("Enhanced BUY signal: Price=", DoubleToString(currentPrice, _Digits), 
                      " VWAP=", DoubleToString(VWAP[0], _Digits),
                      " TrendStrength=", hasTrendStrength ? DoubleToString(TrendStrength[0], 1) : "N/A");
        }
    }
    
    // Process sell signals with enhanced validation  
    if(SellSignal[0] != 0 && SellSignal[0] != EMPTY_VALUE)
    {
        bool vwapOK = ValidateVWAPCondition(currentPrice, VWAP[0]);
        bool trendOK = !EnableTrendFilter || !hasTrendStrength || TrendStrength[0] <= -MinTrendStrength;
        
        if(vwapOK && trendOK)
        {
            if(EnableSell && EnableEntry) 
                SELL_Open = true;
            if(EnableBuy) 
                BUY_Close = true;
                
            DnSignalTime = signalTime + TimeShiftSec;
            
            if(VerboseLogs)
                Print("Enhanced SELL signal: Price=", DoubleToString(currentPrice, _Digits), 
                      " VWAP=", DoubleToString(VWAP[0], _Digits),
                      " TrendStrength=", hasTrendStrength ? DoubleToString(TrendStrength[0], 1) : "N/A");
        }
    }
    
    return true;
}

bool ValidateVWAPCondition(double price, double vwap)
{
    if(!RequireVWAPConfirmation)
        return true;
    
    if(vwap == 0 || vwap == EMPTY_VALUE)
        return false;
    
    double distancePoints = MathAbs(price - vwap) / _Point;
    return distancePoints >= MinPointsFromVWAP;
}

bool ApplyAdvancedSignalFilters()
{
    if(!BUY_Open && !SELL_Open)
        return true;
    
    // Check market volatility for signal validation
    if(EnableVolatilityFilter && g_marketConditions.volatility > 0)
    {
        if(g_marketConditions.volatility < VolatilityFilter * 0.3)
        {
            if(VerboseLogs) Print("Signal rejected: Market too quiet");
            BUY_Open = SELL_Open = false;
            return false;
        }
    }
    
    return true;
}

bool ValidateSignalConfirmation()
{
    // Additional validation bars check
    if(SIGNAL_VALIDATION_BARS <= 1)
        return true;
    
    // Check signal consistency over validation bars
    bool signalConsistent = true;
    int validationBars = MathMin(SIGNAL_VALIDATION_BARS, 5);
    
    for(int i = 1; i <= validationBars; i++)
    {
        double trendDirection[1];
        if(CopyBuffer(STVWAPHandle, 3, SignalBar + i, 1, trendDirection) > 0) // Direction buffer
        {
            if(BUY_Open && trendDirection[0] <= 0)
                signalConsistent = false;
            if(SELL_Open && trendDirection[0] >= 0)
                signalConsistent = false;
        }
    }
    
    if(!signalConsistent)
    {
        if(VerboseLogs) Print("Signal rejected: Inconsistent over validation period");
        BUY_Open = SELL_Open = false;
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Enhanced Trade Execution                                         |
//+------------------------------------------------------------------+
void ExecuteEnhancedTrades()
{
    // Calculate enhanced lot size
    double lotSize = CalculateEnhancedLotSize();
    MarginMode mmMode = DynamicLots ? FREEMARGIN : LOT;
    
    // Close positions first
    if(BUY_Close)
        SellPositionClose(true, _Symbol, SlippagePts, MagicNumber);
        
    if(SELL_Close)
        BuyPositionClose(true, _Symbol, SlippagePts, MagicNumber);
    
    // Check position limits before opening new positions
    if(!CheckEnhancedPositionLimits())
        return;
    
    // Open new positions with enhanced parameters
    if(BUY_Open)
    {
        ExecuteEnhancedBuyOrder(lotSize, mmMode);
    }
    
    if(SELL_Open)
    {
        ExecuteEnhancedSellOrder(lotSize, mmMode);
    }
}

double CalculateEnhancedLotSize()
{
    if(!DynamicLots && !UsePositionSizing)
        return FixedLot;
    
    double baseLot = DynamicLots ? CalculateDynamicLot() : FixedLot;
    
    if(!EnableVolatilityAdjustment)
        return baseLot;
    
    // Adjust lot size based on volatility
    if(g_marketConditions.volatility > 0)
    {
        double volAdjustment = 1.0;
        double normalizedVol = g_marketConditions.volatility;
        
        // Reduce lot size in high volatility
        if(normalizedVol > VolatilityFilter)
        {
            volAdjustment = VolatilityFilter / normalizedVol;
        }
        // Increase lot size in low volatility (up to 1.5x)
        else if(normalizedVol < VolatilityFilter * 0.5)
        {
            volAdjustment = MathMin(1.5, VolatilityFilter * 0.5 / normalizedVol);
        }
        
        baseLot *= volAdjustment;
        
        if(VerboseLogs)
            Print("Volatility-adjusted lot size: ", DoubleToString(baseLot, 2), 
                  " (adjustment factor: ", DoubleToString(volAdjustment, 2), ")");
    }
    
    return baseLot;
}

void ExecuteEnhancedBuyOrder(double lotSize, MarginMode mmMode)
{
    // Calculate enhanced SL/TP
    int sl, tp;
    CalculateEnhancedSLTP(true, sl, tp);
    
    if(BuyPositionOpen(true, _Symbol, UpSignalTime, lotSize, mmMode, SlippagePts, sl, tp, MagicNumber))
    {
        g_dailyStats.totalTrades++;
        
        // Record trade analytics
        RecordTradeAnalytics(ORDER_TYPE_BUY, lotSize, sl, tp);
        
        if(VerboseLogs) 
            Print("Enhanced BUY position opened: Lot=", DoubleToString(lotSize, 2), 
                  " SL=", sl, " TP=", tp);
    }
}

void ExecuteEnhancedSellOrder(double lotSize, MarginMode mmMode)
{
    // Calculate enhanced SL/TP
    int sl, tp;
    CalculateEnhancedSLTP(false, sl, tp);
    
    if(SellPositionOpen(true, _Symbol, DnSignalTime, lotSize, mmMode, SlippagePts, sl, tp, MagicNumber))
    {
        g_dailyStats.totalTrades++;
        
        // Record trade analytics
        RecordTradeAnalytics(ORDER_TYPE_SELL, lotSize, sl, tp);
        
        if(VerboseLogs) 
            Print("Enhanced SELL position opened: Lot=", DoubleToString(lotSize, 2), 
                  " SL=", sl, " TP=", tp);
    }
}

void CalculateEnhancedSLTP(bool isBuy, int &sl, int &tp)
{
    if(UseATRBasedSLTP && ATRHandle != INVALID_HANDLE)
    {
        double atrValue = GetCurrentATRValue();
        if(atrValue > 0)
        {
            sl = (int)(atrValue * ATRMultiplierSL / _Point);
            tp = (int)(atrValue * ATRMultiplierTP / _Point);
            
            if(VerboseLogs)
                Print("ATR-based SL/TP: ATR=", DoubleToString(atrValue, 5), 
                      " SL=", sl, " TP=", tp);
            
            return;
        }
    }
    
    // Fallback to traditional calculation
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

double GetCurrentATRValue()
{
    datetime currentTime = TimeCurrent();
    
    // Use cached ATR value if recent
    if(currentTime < g_lastATRUpdate + 300) // 5 minutes cache
        return g_lastATRValue;
    
    double atrBuffer[1];
    if(CopyBuffer(ATRHandle, 0, 0, 1, atrBuffer) > 0)
    {
        g_lastATRValue = atrBuffer[0];
        g_lastATRUpdate = currentTime;
        return g_lastATRValue;
    }
    
    return 0;
}

//+------------------------------------------------------------------+
//| Enhanced Position Management                                      |
//+------------------------------------------------------------------+
void ProcessAdvancedPositionManagement()
{
    // Process break-even with enhanced logic
    if(EnableBreakEven)
        ProcessBreakEven(BreakEvenPercent, BESLPctOfTP);
    
    // Process smart trailing
    if(EnableSmartTrailing)
        ProcessEnhancedSmartTrailing();
    
    // Update position metrics
    UpdateAllPositionMetrics();
}

void ProcessEnhancedSmartTrailing()
{
    // Enhanced smart trailing with volatility consideration
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
    
    // Calculate profit percentage
    bool isBuy = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
    double profitPoints = isBuy ? (currentPrice - openPrice) : (openPrice - currentPrice);
    double profitPercent = (profitPoints / openPrice) * 100.0;
    
    // Enhanced trailing logic with volatility adjustment
    if(profitPercent >= TrailStartPercent)
    {
        double volatilityAdjustment = 1.0;
        if(g_marketConditions.volatility > 0)
        {
            // Adjust trailing step based on volatility
            volatilityAdjustment = MathMax(0.5, MathMin(2.0, g_marketConditions.volatility / VolatilityFilter));
        }
        
        int adjustedStep = (int)(TrailingSLStepPoints * volatilityAdjustment);
        
        // Apply enhanced trailing
        ApplyEnhancedTrailing(ticket, isBuy, currentPrice, currentSL, adjustedStep);
    }
}

void ApplyEnhancedTrailing(ulong ticket, bool isBuy, double currentPrice, double currentSL, int stepPoints)
{
    double newSL = 0;
    
    if(isBuy)
    {
        newSL = currentPrice - stepPoints * _Point;
        if(newSL > currentSL + _Point) // Only move SL up
        {
            ModifyPositionSL(ticket, newSL);
        }
    }
    else
    {
        newSL = currentPrice + stepPoints * _Point;
        if(newSL < currentSL - _Point) // Only move SL down
        {
            ModifyPositionSL(ticket, newSL);
        }
    }
}

void ModifyPositionSL(ulong ticket, double newSL)
{
    double currentTP = PositionGetDouble(POSITION_TP);
    
    if(trade.PositionModify(ticket, newSL, currentTP))
    {
        if(VerboseLogs)
            Print("Enhanced trailing executed for ticket ", ticket, ". New SL: ", DoubleToString(newSL, _Digits));
    }
    else
    {
        if(VerboseLogs)
            Print("Failed to modify position ", ticket, ". Error: ", trade.ResultRetcode());
    }
}

bool CheckEnhancedPositionLimits()
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
    // Update metrics for all positions
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(positionInfo.SelectByIndex(i))
        {
            if(positionInfo.Symbol() == _Symbol && positionInfo.Magic() == MagicNumber)
            {
                UpdatePositionMetrics(positionInfo.Ticket());
            }
        }
    }
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
    
    // Update market conditions
    UpdateMarketConditions();
    
    // Calculate performance metrics
    CalculatePerformanceMetrics();
    
    // Update analytics data
    if(EnableRealTimeAnalytics)
        UpdateAnalyticsData();
}

void UpdateRealTimeAnalytics()
{
    datetime currentTime = TimeCurrent();
    
    if(currentTime < g_lastAnalyticsUpdate + 30) // Update every 30 seconds
        return;
    
    g_lastAnalyticsUpdate = currentTime;
    
    // Record equity curve
    RecordEquityPoint();
    
    // Update performance metrics
    PerformanceUpdate();
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

void RecordTradeAnalytics(ENUM_ORDER_TYPE orderType, double lotSize, int sl, int tp)
{
    // Record trade details for analytics
    datetime tradeTime = TimeCurrent();
    
    if(VerboseLogs)
    {
        Print("Trade Analytics - Type: ", EnumToString(orderType),
              " Lot: ", DoubleToString(lotSize, 2),
              " SL: ", sl, " TP: ", tp,
              " MarketState: ", EnumToString(g_marketConditions.state),
              " Volatility: ", DoubleToString(g_marketConditions.volatility, 2),
              " TrendStrength: ", DoubleToString(g_marketConditions.trendStrength, 1));
    }
}

void CheckPerformanceAlerts()
{
    if(!EnableAlerts)
        return;
    
    // Check for drawdown alert
    double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    double drawdownPercent = ((g_sessionHighEquity - currentEquity) / g_sessionHighEquity) * 100.0;
    
    if(drawdownPercent > AlertDrawdownLevel)
    {
        string alertMsg = StringFormat("ALERT: Drawdown %.2f%% exceeds alert level %.2f%%", 
                                      drawdownPercent, AlertDrawdownLevel);
        Print(alertMsg);
        
        // Could send email or other notifications here
    }
}

void UpdatePerformanceDashboard()
{
    // Update performance dashboard (if implemented)
    // This could create chart objects or update external dashboard
    
    if(VerboseLogs && g_analyticsCount > 0)
    {
        Print("Performance Update - Equity: ", DoubleToString(g_equityCurve[g_analyticsCount-1], 2),
              " Drawdown: ", DoubleToString(g_drawdownCurve[g_analyticsCount-1], 2), "%",
              " Trades: ", g_dailyStats.totalTrades,
              " Market: ", EnumToString(g_marketConditions.state));
    }
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
    
    string fileName = "Enhanced_ST_VWAP_EA_Analytics.csv";
    int fileHandle = FileOpen(fileName, FILE_WRITE | FILE_CSV);
    
    if(fileHandle != INVALID_HANDLE)
    {
        // Write header
        FileWrite(fileHandle, "DateTime", "Equity", "Drawdown%", "MarketState", 
                 "Volatility", "TrendStrength", "TotalTrades");
        
        // Write data
        for(int i = 0; i < g_analyticsCount; i++)
        {
            FileWrite(fileHandle, TimeToString(g_equityTimes[i]),
                     g_equityCurve[i], g_drawdownCurve[i],
                     EnumToString(g_marketConditions.state),
                     g_marketConditions.volatility,
                     g_marketConditions.trendStrength,
                     g_dailyStats.totalTrades);
        }
        
        FileClose(fileHandle);
        Print("Analytics data saved to: ", fileName);
    }
}

void PrintInitializationInfo()
{
    if(!VerboseLogs)
        return;
    
    Print("=== Enhanced ST&VWAP EA v2.0 Initialization ===");
    Print("Magic Number: ", MagicNumber);
    Print("Symbol: ", _Symbol);
    Print("Timeframe: ", EnumToString(InpIndTimeframe));
    Print("SuperTrend - ATR Period: ", ATRPeriod, ", Multiplier: ", STMultiplier);
    Print("VWAP Filter: ", EnableVWAPFilter ? "Enabled" : "Disabled");
    Print("Risk Management: ", DynamicLots ? "Dynamic (" + DoubleToString(RiskPct, 1) + "%)" : "Fixed (" + DoubleToString(FixedLot, 2) + " lots)");
    Print("ATR-based SL/TP: ", UseATRBasedSLTP ? "Enabled" : "Disabled");
    Print("Break-Even: ", EnableBreakEven ? "Enabled" : "Disabled");
    Print("Smart Trailing: ", EnableSmartTrailing ? "Enabled" : "Disabled");
    Print("Drawdown Protection: ", EnableDrawdownProtection ? DoubleToString(MaxDrawdownPercent, 1) + "%" : "Disabled");
    Print("Real-time Analytics: ", EnableRealTimeAnalytics ? "Enabled" : "Disabled");
    Print("Performance Dashboard: ", EnablePerformanceDashboard ? "Enabled" : "Disabled");
    Print("=== Initialization Complete ===");
}

void PrintFinalPerformanceReport()
{
    Print("=== Final Performance Report ===");
    Print(GetPerformanceReport());
    Print("=== End of Report ===");
}

//+------------------------------------------------------------------+
//| Trade Transaction Handler - Enhanced                             |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                       const MqlTradeRequest& request,
                       const MqlTradeResult& result)
{
    // Handle position close events with enhanced analytics
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
                    UpdateTradeStats(totalPnL);
                    
                    // Update consecutive losses counter
                    if(totalPnL < 0)
                        g_consecutiveLosses++;
                    else
                        g_consecutiveLosses = 0;
                    
                    // Remove from position tracker
                    ulong ticket = HistoryDealGetInteger(trans.deal, DEAL_POSITION_ID);
                    RemovePositionTracker(ticket);
                    
                    // Set cooldown state
                    SetEAState(ST_COOLDOWN);
                    
                    // Record analytics
                    RecordEquityPoint();
                    
                    if(VerboseLogs)
                    {
                        Print("Enhanced Trade Closed - Ticket: ", ticket,
                              " Profit: ", DoubleToString(profit, 2),
                              " Commission: ", DoubleToString(commission, 2),
                              " Swap: ", DoubleToString(swap, 2),
                              " Net: ", DoubleToString(totalPnL, 2),
                              " ConsecutiveLosses: ", g_consecutiveLosses);
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Session Management - Enhanced from Base                         |
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
//| Shared Functions from Base (Enhanced)                           |
//+------------------------------------------------------------------+
double CalculateDynamicLot()
{
    double accountSize = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    double riskAmount = accountSize * RiskPct / 100.0;
    
    // Enhanced risk calculation with ATR
    double slDistance = PointsSL * _Point;
    
    if(UseATRBasedSLTP)
    {
        double atrValue = GetCurrentATRValue();
        if(atrValue > 0)
            slDistance = atrValue * ATRMultiplierSL;
    }
    
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    
    if(slDistance > 0 && tickValue > 0)
    {
        double lot = riskAmount / (slDistance * tickValue / _Point);
        lot = NormalizeDouble(lot, 2);
        
        // Apply maximum risk per trade limit
        double maxLot = (accountSize * MaxRiskPerTrade / 100.0) / (slDistance * tickValue / _Point);
        lot = MathMin(lot, NormalizeDouble(maxLot, 2));
        
        return lot;
    }
    
    return FixedLot;
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
    g_dailyStats.totalTrades = 0;
    g_dailyStats.winTrades = 0;
    g_dailyStats.loseTrades = 0;
    g_dailyStats.totalProfit = 0;
    g_dailyStats.maxDrawdown = 0;
    g_dailyStats.lastTradeTime = 0;
}

void PrintDailyStats()
{
    Print("=== Enhanced Daily Trading Statistics ===");
    Print("Total Trades: ", g_dailyStats.totalTrades);
    Print("Win Trades: ", g_dailyStats.winTrades);
    Print("Lose Trades: ", g_dailyStats.loseTrades);
    Print("Win Rate: ", g_dailyStats.totalTrades > 0 ? DoubleToString((double)g_dailyStats.winTrades / g_dailyStats.totalTrades * 100, 1) + "%" : "0%");
    Print("Total Profit: ", DoubleToString(g_dailyStats.totalProfit, 2));
    Print("Max Drawdown: ", DoubleToString(g_dailyStats.maxDrawdown, 2));
    Print("Consecutive Losses: ", g_consecutiveLosses);
    Print("Session Drawdown: ", DoubleToString(((g_sessionStartEquity - AccountInfoDouble(ACCOUNT_EQUITY)) / g_sessionStartEquity) * 100, 2), "%");
    Print("Market State: ", EnumToString(g_marketConditions.state));
    Print("Volatility Index: ", DoubleToString(g_marketConditions.volatility, 2));
    Print("Trend Strength: ", DoubleToString(g_marketConditions.trendStrength, 1));
    Print("==========================================");
}

//+------------------------------------------------------------------+