//+------------------------------------------------------------------+
//|                                Enhanced_ST_VWAP_Indicator.mq5 |
//|              Enhanced SuperTrend & VWAP with Advanced Analytics |
//|                                         Performance Optimized  |
//+------------------------------------------------------------------+
#property copyright "Enhanced ST&VWAP Indicator © 2025"
#property link      "https://www.mql5.com"
#property version   "2.00"
#property description "Advanced SuperTrend with VWAP Filter, Performance Dashboard & Real-time Analytics"

#property indicator_chart_window
#property indicator_buffers 8
#property indicator_plots   3

// Plot configurations
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrLime,clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

#property indicator_type2   DRAW_LINE
#property indicator_color2  clrYellow
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

#property indicator_type3   DRAW_NONE

//+------------------------------------------------------------------+
//| Performance Optimization Constants                               |
//+------------------------------------------------------------------+
#define MAX_DASHBOARD_ITEMS 50
#define CALCULATION_CACHE_SIZE 100
#define UPDATE_FREQUENCY_MS 1000
#define MEMORY_CLEANUP_BARS 1000

//+------------------------------------------------------------------+
//| Input Parameters - Organized Groups                             |
//+------------------------------------------------------------------+
// SuperTrend Parameters
input group "=== SUPERTREND SETTINGS ==="
input int ATRPeriod = 22;                                    // ATR Period
input double Multiplier = 3.0;                               // SuperTrend Multiplier
input ENUM_APPLIED_PRICE SourcePrice = PRICE_MEDIAN;         // Price for SuperTrend
input bool TakeWicksIntoAccount = true;                       // Include wicks in calculation

// VWAP Parameters
input group "=== VWAP SETTINGS ==="
input ENUM_APPLIED_PRICE VWAPPriceMethod = PRICE_TYPICAL;     // VWAP Price Method
input double MinVolumeThreshold = 1.0;                       // Minimum Volume Threshold
input bool ResetVWAPDaily = true;                             // Reset VWAP Daily
input bool EnableVWAPFilter = true;                           // Enable VWAP Filtering
input bool ShowVWAPLine = true;                               // Show VWAP Line

// Advanced Analytics
input group "=== ADVANCED ANALYTICS ==="
input bool EnableAdvancedAnalytics = true;                   // Enable Advanced Analytics
input bool EnablePerformanceTracking = true;                 // Enable Performance Tracking
input bool EnableMarketStateAnalysis = true;                 // Enable Market State Analysis
input int AnalysisLookback = 500;                            // Bars for analysis
input double VolatilityThreshold = 1.5;                      // Volatility threshold multiplier

// Signal Processing
input group "=== SIGNAL PROCESSING ==="
input bool FilterSignalsOnClose = true;                      // Only signals on bar close
input bool RequireVWAPConfirmation = true;                   // Require VWAP confirmation
input double MinPointsFromVWAP = 50.0;                       // Min distance from VWAP (points)
input int SignalCooldownBars = 3;                            // Bars between signals

// Performance Settings
input group "=== PERFORMANCE SETTINGS ==="
input bool EnableWinRate = true;                             // Enable Win Rate Calculation
input double WinThresholdPoints = 10.0;                      // Win threshold in points
input int MaxSignalHistory = 1000;                           // Maximum signals to track
input bool EnableRealTimeUpdates = true;                     // Real-time dashboard updates

// Dashboard Configuration
input group "=== DASHBOARD SETTINGS ==="
input bool ShowDashboard = true;                             // Show Performance Dashboard
input int DashboardX = 20;                                   // Dashboard X Position
input int DashboardY = 30;                                   // Dashboard Y Position
input int DashboardWidth = 420;                              // Dashboard Width
input int DashboardHeight = 500;                             // Dashboard Height
input color DashboardBgColor = C'25,25,25';                  // Background Color
input color DashboardBorderColor = clrDarkSlateGray;         // Border Color
input color DashboardTextColor = clrWhite;                   // Text Color

// Layout Settings
input group "=== LAYOUT SETTINGS ==="
input string DashboardFont = "Consolas";                     // Dashboard Font
input int LabelFontSize = 9;                                 // Label Font Size
input int ValueFontSize = 9;                                 // Value Font Size
input int LabelXOffset = 15;                                 // Label Column X Offset
input int ValueXOffset = 280;                                // Value Column X Offset
input color AccentColor = clrDodgerBlue;                     // Accent Color
input color SuccessColor = clrLimeGreen;                     // Success Color
input color WarningColor = clrOrange;                        // Warning Color
input color ErrorColor = clrTomato;                          // Error Color

// Advanced Display
input group "=== ADVANCED DISPLAY ==="
input bool ShowMarketState = true;                           // Show Market State
input bool ShowVolatilityMeter = true;                       // Show Volatility Meter
input bool ShowTrendStrength = true;                         // Show Trend Strength
input bool ShowSignalQuality = true;                         // Show Signal Quality
input bool ShowPerformanceMetrics = true;                    // Show Performance Metrics
input bool ShowRealTimeStats = true;                         // Show Real-time Statistics

// Alert Settings
input group "=== ALERT SETTINGS ==="
input bool EnableAlerts = false;                             // Enable Alert System
input bool AlertPopup = true;                                // Show Popup Alerts
input bool AlertSound = true;                                // Play Sound Alerts
input string AlertSoundFile = "alert.wav";                   // Alert Sound File

// Visual Feedback
input group "=== VISUAL FEEDBACK ==="
input bool EnableVisualFeedback = true;                      // Enable Visual Signals
input int CircleWidth = 2;                                   // Signal Circle Width
input color BullishSignalColor = clrDodgerBlue;              // Bullish Signal Color
input color BearishSignalColor = clrOrangeRed;               // Bearish Signal Color
input color RejectedSignalColor = clrGray;                   // Rejected Signal Color
input int SignalLifetimeBars = 200;                          // Signal Display Duration

//+------------------------------------------------------------------+
//| Enhanced Enumerations                                            |
//+------------------------------------------------------------------+
enum DASHBOARD_STATE
{
    STATE_NO_SIGNAL = 0,
    STATE_BULLISH = 1,
    STATE_BEARISH = -1,
    STATE_NEUTRAL = 2
};

enum MARKET_STATE
{
    MARKET_UNKNOWN = 0,
    MARKET_TRENDING_UP = 1,
    MARKET_TRENDING_DOWN = -1,
    MARKET_RANGING = 2,
    MARKET_VOLATILE = 3,
    MARKET_QUIET = 4
};

enum SIGNAL_QUALITY
{
    QUALITY_UNKNOWN = 0,
    QUALITY_EXCELLENT = 4,
    QUALITY_GOOD = 3,
    QUALITY_FAIR = 2,
    QUALITY_POOR = 1
};

//+------------------------------------------------------------------+
//| Advanced Structures                                              |
//+------------------------------------------------------------------+
struct SignalSegment
{
    int direction;              // 1 for bullish, -1 for bearish
    double entryPrice;          // Signal entry price
    datetime startTime;         // Signal start time
    int startBar;              // Signal start bar
    double reachedPoints;       // Maximum favorable excursion
    double reachedPercent;      // Percentage move achieved
    bool isWin;                // Win/loss status
    bool finalized;            // Whether segment is complete
    SIGNAL_QUALITY quality;     // Signal quality rating
    double vwapDistance;       // Distance from VWAP at signal
    double volatility;         // Market volatility at signal
    double trendStrength;      // Trend strength at signal
};

struct PerformanceMetrics
{
    // Basic Statistics
    int totalSignals;
    int bullishSignals;
    int bearishSignals;
    int acceptedSignals;
    int rejectedSignals;
    
    // Performance Metrics
    double winRate;
    int wins;
    int losses;
    double avgWinPoints;
    double avgLossPoints;
    double profitFactor;
    double sharpeRatio;
    
    // Advanced Metrics
    double maxConsecutiveWins;
    double maxConsecutiveLosses;
    double currentStreak;
    double avgSignalQuality;
    double bestSignalPoints;
    double worstSignalPoints;
    
    // Time-based Metrics
    double avgBullishDuration;
    double avgBearishDuration;
    datetime lastSignalTime;
    int signalsPerDay;
    
    // Market Context
    MARKET_STATE marketState;
    double trendStrength;
    double volatilityIndex;
    double signalReliability;
};

struct MarketConditions
{
    double currentPrice;
    double priceChange;
    double priceChangePercent;
    double volatility;
    double trendStrength;
    MARKET_STATE state;
    double momentum;
    double averageVolume;
    double spreadCost;
    datetime lastUpdate;
};

struct DashboardData
{
    // Current Values
    double currentSuperTrend;
    double currentVWAP;
    DASHBOARD_STATE currentState;
    
    // Market Analysis
    MarketConditions market;
    
    // Performance Data
    PerformanceMetrics performance;
    
    // Real-time Data
    int barsProcessed;
    datetime sessionStart;
    string status;
    double systemLoad;
};

//+------------------------------------------------------------------+
//| Indicator Handles and Buffers                                   |
//+------------------------------------------------------------------+
int atrHandle;

// Main Indicator Buffers
double SuperTrendBuffer[];
double SuperTrendColorBuffer[];
double VWAPBuffer[];
double SuperTrendDirectionBuffer[];
double SignalBuffer[];

// Analysis Buffers (Hidden)
double VolatilityBuffer[];
double TrendStrengthBuffer[];
double SignalQualityBuffer[];

//+------------------------------------------------------------------+
//| Global Variables with Optimization                              |
//+------------------------------------------------------------------+
// VWAP Calculation Variables
datetime g_currentDay = 0;
double g_sumPriceVolume = 0.0;
double g_sumVolume = 0.0;

// Signal Tracking
SignalSegment g_signalHistory[];
int g_signalCount = 0;
SignalSegment g_currentSegment;
bool g_hasActiveSegment = false;
datetime g_lastSignalTime = 0;
int g_signalCooldown = 0;

// Performance Tracking
DashboardData g_dashboardData;
bool g_dashboardCreated = false;
datetime g_lastUpdate = 0;
datetime g_lastAlertTime = 0;

// Optimization Variables
static double g_priceCache[];
static datetime g_cacheTime = 0;
static int g_cacheSize = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
    // Validate inputs
    if(ATRPeriod <= 0 || Multiplier <= 0.0)
    {
        Print("ERROR: Invalid SuperTrend parameters");
        return INIT_PARAMETERS_INCORRECT;
    }
    
    if(AnalysisLookback <= 0 || MaxSignalHistory <= 0)
    {
        Print("ERROR: Invalid analysis parameters");
        return INIT_PARAMETERS_INCORRECT;
    }
    
    // Initialize ATR handle
    atrHandle = iATR(NULL, 0, ATRPeriod);
    if(atrHandle == INVALID_HANDLE)
    {
        Print("ERROR: Failed to create ATR indicator");
        return INIT_FAILED;
    }
    
    // Set up indicator buffers
    SetIndexBuffer(0, SuperTrendBuffer, INDICATOR_DATA);
    SetIndexBuffer(1, SuperTrendColorBuffer, INDICATOR_COLOR_INDEX);
    SetIndexBuffer(2, VWAPBuffer, INDICATOR_DATA);
    SetIndexBuffer(3, SuperTrendDirectionBuffer, INDICATOR_CALCULATIONS);
    SetIndexBuffer(4, SignalBuffer, INDICATOR_CALCULATIONS);
    SetIndexBuffer(5, VolatilityBuffer, INDICATOR_CALCULATIONS);
    SetIndexBuffer(6, TrendStrengthBuffer, INDICATOR_CALCULATIONS);
    SetIndexBuffer(7, SignalQualityBuffer, INDICATOR_CALCULATIONS);
    
    // Configure plotting
    PlotIndexSetString(0, PLOT_LABEL, "SuperTrend");
    PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
    
    if(ShowVWAPLine)
    {
        PlotIndexSetString(2, PLOT_LABEL, "VWAP");
        PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, 0.0);
    }
    else
    {
        PlotIndexSetInteger(2, PLOT_DRAW_TYPE, DRAW_NONE);
    }
    
    // Initialize arrays
    ArraySetAsSeries(SuperTrendBuffer, false);
    ArraySetAsSeries(SuperTrendColorBuffer, false);
    ArraySetAsSeries(VWAPBuffer, false);
    ArraySetAsSeries(SuperTrendDirectionBuffer, false);
    ArraySetAsSeries(SignalBuffer, false);
    ArraySetAsSeries(VolatilityBuffer, false);
    ArraySetAsSeries(TrendStrengthBuffer, false);
    ArraySetAsSeries(SignalQualityBuffer, false);
    
    // Initialize data structures
    InitializeDataStructures();
    
    // Set indicator properties
    string indicatorName = StringFormat("Enhanced ST&VWAP (ATR:%d, Mult:%.1f)", ATRPeriod, Multiplier);
    IndicatorSetString(INDICATOR_SHORTNAME, indicatorName);
    IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
    
    Print("Enhanced SuperTrend & VWAP Indicator initialized successfully");
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Clean up handles
    if(atrHandle != INVALID_HANDLE)
        IndicatorRelease(atrHandle);
    
    // Clean up dashboard
    CleanupDashboard();
    
    // Clean up visual objects
    if(EnableVisualFeedback)
        CleanupVisualObjects();
    
    // Save performance data (optional)
    if(EnablePerformanceTracking)
        SavePerformanceData();
    
    Print("Enhanced SuperTrend & VWAP Indicator deinitialized");
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(
    const int rates_total,
    const int prev_calculated,
    const datetime& time[],
    const double& open[],
    const double& high[],
    const double& low[],
    const double& close[],
    const long& tick_volume[],
    const long& volume[],
    const int& spread[]
)
{
    if(rates_total < ATRPeriod + 1)
        return 0;
    
    // Set array indexing
    ArraySetAsSeries(time, false);
    ArraySetAsSeries(open, false);
    ArraySetAsSeries(high, false);
    ArraySetAsSeries(low, false);
    ArraySetAsSeries(close, false);
    ArraySetAsSeries(tick_volume, false);
    
    // Prepare ATR buffer
    double atrBuffer[];
    ArraySetAsSeries(atrBuffer, false);
    
    // Determine calculation start
    int start = MathMax(prev_calculated - 1, ATRPeriod);
    if(prev_calculated == 0)
        start = ATRPeriod;
    
    // Main calculation loop
    for(int i = start; i < rates_total && !IsStopped(); i++)
    {
        // Calculate VWAP for current bar
        CalculateAdvancedVWAP(i, time, open, high, low, close, tick_volume);
        
        // Get source price
        double srcPrice = GetSourcePrice(i, open, high, low, close);
        
        // Get price extremes
        double highPrice = TakeWicksIntoAccount ? high[i] : MathMax(open[i], close[i]);
        double lowPrice = TakeWicksIntoAccount ? low[i] : MathMin(open[i], close[i]);
        
        // Get ATR value
        double atr = GetATRValue(i, rates_total, srcPrice);
        
        // Calculate SuperTrend levels
        double longStop = srcPrice - Multiplier * atr;
        double shortStop = srcPrice + Multiplier * atr;
        
        // Apply SuperTrend logic with previous values
        if(i > 0)
        {
            ApplySuperTrendLogic(i, longStop, shortStop, highPrice, lowPrice, open, close);
        }
        
        // Determine SuperTrend direction and values
        int supertrendDir = CalculateSuperTrendDirection(i, highPrice, lowPrice);
        
        // Set buffer values
        if(supertrendDir == 1)
        {
            SuperTrendBuffer[i] = longStop;
            SuperTrendDirectionBuffer[i] = 1;
            SuperTrendColorBuffer[i] = 0; // Bullish color
        }
        else
        {
            SuperTrendBuffer[i] = shortStop;
            SuperTrendDirectionBuffer[i] = -1;
            SuperTrendColorBuffer[i] = 1; // Bearish color
        }
        
        // Calculate advanced analytics
        if(EnableAdvancedAnalytics)
        {
            CalculateAdvancedMetrics(i, high, low, close, tick_volume);
        }
        
        // Process signals
        ProcessEnhancedSignals(i, time[i], close[i], supertrendDir, high, low, rates_total);
        
        // Update real-time data
        if(i == rates_total - 1 && EnableRealTimeUpdates)
        {
            UpdateRealTimeData(i, time, close, high, low);
        }
    }
    
    // Update dashboard
    if(ShowDashboard && ShouldUpdateDashboard())
    {
        UpdateAdvancedDashboard(rates_total, time, close);
    }
    
    // Clean up old visual objects
    if(EnableVisualFeedback && rates_total > SignalLifetimeBars)
    {
        CleanupOldObjects(time, rates_total);
    }
    
    return rates_total;
}

//+------------------------------------------------------------------+
//| Initialize Data Structures                                       |
//+------------------------------------------------------------------+
void InitializeDataStructures()
{
    // Initialize signal history
    ArrayResize(g_signalHistory, MaxSignalHistory);
    g_signalCount = 0;
    g_hasActiveSegment = false;
    
    // Initialize dashboard data
    ZeroMemory(g_dashboardData);
    g_dashboardData.sessionStart = TimeCurrent();
    g_dashboardData.performance.marketState = MARKET_UNKNOWN;
    g_dashboardData.status = "Initializing...";
    
    // Initialize cache
    ArrayResize(g_priceCache, CALCULATION_CACHE_SIZE);
    g_cacheSize = 0;
    
    g_dashboardCreated = false;
}

//+------------------------------------------------------------------+
//| Advanced VWAP Calculation                                        |
//+------------------------------------------------------------------+
void CalculateAdvancedVWAP(int bar, const datetime& time[], const double& open[], 
                          const double& high[], const double& low[], const double& close[], 
                          const long& tick_volume[])
{
    // Handle daily reset
    if(ResetVWAPDaily)
    {
        MqlDateTime timeStruct;
        TimeToStruct(time[bar], timeStruct);
        datetime currentDay = StringToTime(StringFormat("%04d.%02d.%02d", 
                                          timeStruct.year, timeStruct.mon, timeStruct.day));
        
        if(currentDay != g_currentDay)
        {
            g_currentDay = currentDay;
            g_sumPriceVolume = 0.0;
            g_sumVolume = 0.0;
        }
    }
    
    // Get price based on method
    double price = GetVWAPPrice(bar, open, high, low, close);
    
    // Get volume with minimum threshold
    double vol = (double)tick_volume[bar];
    if(vol < MinVolumeThreshold)
        vol = MinVolumeThreshold;
    
    // Update VWAP calculation
    g_sumPriceVolume += price * vol;
    g_sumVolume += vol;
    
    VWAPBuffer[bar] = (g_sumVolume > 0) ? (g_sumPriceVolume / g_sumVolume) : price;
    
    // Store in market conditions
    g_dashboardData.market.averageVolume = g_sumVolume / MathMax(1, bar + 1);
}

//+------------------------------------------------------------------+
//| Get VWAP Price Method                                           |
//+------------------------------------------------------------------+
double GetVWAPPrice(int bar, const double& open[], const double& high[], 
                   const double& low[], const double& close[])
{
    switch(VWAPPriceMethod)
    {
        case PRICE_OPEN: return open[bar];
        case PRICE_HIGH: return high[bar];
        case PRICE_LOW: return low[bar];
        case PRICE_CLOSE: return close[bar];
        case PRICE_MEDIAN: return (high[bar] + low[bar]) / 2.0;
        case PRICE_TYPICAL: return (high[bar] + low[bar] + close[bar]) / 3.0;
        case PRICE_WEIGHTED: return (high[bar] + low[bar] + 2.0 * close[bar]) / 4.0;
        default: return close[bar];
    }
}

//+------------------------------------------------------------------+
//| Get Source Price for SuperTrend                                 |
//+------------------------------------------------------------------+
double GetSourcePrice(int bar, const double& open[], const double& high[], 
                     const double& low[], const double& close[])
{
    switch(SourcePrice)
    {
        case PRICE_CLOSE: return close[bar];
        case PRICE_OPEN: return open[bar];
        case PRICE_HIGH: return high[bar];
        case PRICE_LOW: return low[bar];
        case PRICE_MEDIAN: return (high[bar] + low[bar]) / 2.0;
        case PRICE_TYPICAL: return (high[bar] + low[bar] + close[bar]) / 3.0;
        case PRICE_WEIGHTED: return (high[bar] + low[bar] + 2.0 * close[bar]) / 4.0;
        default: return close[bar];
    }
}

//+------------------------------------------------------------------+
//| Get ATR Value with Error Handling                               |
//+------------------------------------------------------------------+
double GetATRValue(int bar, int rates_total, double srcPrice)
{
    double atr;
    double atrBuffer[];
    
    if(CopyBuffer(atrHandle, 0, rates_total - bar - 1, 1, atrBuffer) > 0)
    {
        atr = atrBuffer[0];
    }
    else
    {
        atr = srcPrice * 0.01; // Fallback ATR
    }
    
    if(atr <= 0.0)
        atr = srcPrice * 0.01;
    
    return atr;
}

//+------------------------------------------------------------------+
//| Apply SuperTrend Logic                                           |
//+------------------------------------------------------------------+
void ApplySuperTrendLogic(int bar, double& longStop, double& shortStop, 
                         double highPrice, double lowPrice, const double& open[], const double& close[])
{
    double longStopPrev = (SuperTrendDirectionBuffer[bar-1] == 1) ? SuperTrendBuffer[bar-1] : longStop;
    double shortStopPrev = (SuperTrendDirectionBuffer[bar-1] == -1) ? SuperTrendBuffer[bar-1] : shortStop;
    
    // Check for doji or gap (avoid false signals)
    if(!(open[bar] == close[bar] && open[bar] == lowPrice && open[bar] == highPrice))
    {
        longStop = (lowPrice > longStopPrev) ? MathMax(longStop, longStopPrev) : longStop;
        shortStop = (highPrice < shortStopPrev) ? MathMin(shortStop, shortStopPrev) : shortStop;
    }
    else
    {
        longStop = longStopPrev;
        shortStop = shortStopPrev;
    }
}

//+------------------------------------------------------------------+
//| Calculate SuperTrend Direction                                   |
//+------------------------------------------------------------------+
int CalculateSuperTrendDirection(int bar, double highPrice, double lowPrice)
{
    if(bar == 0)
        return 1; // Default to bullish
    
    int prevDir = (int)SuperTrendDirectionBuffer[bar-1];
    int supertrendDir = prevDir;
    
    // Check for direction change
    if(supertrendDir == -1 && highPrice > SuperTrendBuffer[bar-1])
    {
        supertrendDir = 1;
    }
    else if(supertrendDir == 1 && lowPrice < SuperTrendBuffer[bar-1])
    {
        supertrendDir = -1;
    }
    
    return supertrendDir;
}

//+------------------------------------------------------------------+
//| Calculate Advanced Metrics                                       |
//+------------------------------------------------------------------+
void CalculateAdvancedMetrics(int bar, const double& high[], const double& low[], 
                             const double& close[], const long& tick_volume[])
{
    // Calculate volatility (normalized ATR)
    if(bar >= ATRPeriod)
    {
        double atr = GetATRValue(bar, bar + 1, close[bar]);
        double normalizedVolatility = (atr / close[bar]) * 100.0;
        VolatilityBuffer[bar] = normalizedVolatility;
        
        g_dashboardData.market.volatility = normalizedVolatility;
    }
    
    // Calculate trend strength
    if(bar >= 20) // Minimum bars for trend calculation
    {
        double trendStrength = CalculateTrendStrength(bar, close);
        TrendStrengthBuffer[bar] = trendStrength;
        
        g_dashboardData.market.trendStrength = trendStrength;
    }
    
    // Update market state
    UpdateMarketState(bar);
}

//+------------------------------------------------------------------+
//| Calculate Trend Strength                                         |
//+------------------------------------------------------------------+
double CalculateTrendStrength(int bar, const double& close[])
{
    int lookback = MathMin(20, bar);
    if(lookback < 5) return 0.0;
    
    double sumUp = 0, sumDown = 0;
    
    for(int i = bar - lookback + 1; i <= bar; i++)
    {
        if(i > 0)
        {
            double change = close[i] - close[i-1];
            if(change > 0)
                sumUp += change;
            else
                sumDown -= change; // Make positive
        }
    }
    
    double totalChange = sumUp + sumDown;
    if(totalChange == 0) return 0.0;
    
    double trendStrength = (sumUp - sumDown) / totalChange;
    return NormalizeDouble(trendStrength * 100.0, 2); // Convert to percentage
}

//+------------------------------------------------------------------+
//| Update Market State                                              |
//+------------------------------------------------------------------+
void UpdateMarketState(int bar)
{
    double volatility = VolatilityBuffer[bar];
    double trendStrength = TrendStrengthBuffer[bar];
    
    // Determine market state based on volatility and trend strength
    if(MathAbs(trendStrength) > 60.0)
    {
        g_dashboardData.market.state = (trendStrength > 0) ? MARKET_TRENDING_UP : MARKET_TRENDING_DOWN;
    }
    else if(volatility > VolatilityThreshold)
    {
        g_dashboardData.market.state = MARKET_VOLATILE;
    }
    else if(volatility < VolatilityThreshold * 0.3)
    {
        g_dashboardData.market.state = MARKET_QUIET;
    }
    else
    {
        g_dashboardData.market.state = MARKET_RANGING;
    }
    
    g_dashboardData.performance.marketState = g_dashboardData.market.state;
}

//+------------------------------------------------------------------+
//| Process Enhanced Signals                                         |
//+------------------------------------------------------------------+
void ProcessEnhancedSignals(int bar, datetime barTime, double price, int direction, 
                           const double& high[], const double& low[], int rates_total)
{
    // Check signal cooldown
    if(g_signalCooldown > 0)
    {
        g_signalCooldown--;
        return;
    }
    
    // Check for direction change (signal generation)
    bool isSignal = false;
    if(bar > 0)
    {
        int prevDir = (int)SuperTrendDirectionBuffer[bar-1];
        if(direction != prevDir)
        {
            isSignal = true;
        }
    }
    
    if(!isSignal) return;
    
    // Apply filters
    bool vwapOK = !RequireVWAPConfirmation || 
                 (VWAPBuffer[bar] != 0 && VWAPBuffer[bar] != EMPTY_VALUE &&
                  MathAbs(price - VWAPBuffer[bar]) >= MinPointsFromVWAP * _Point);
    
    bool signalAccepted = vwapOK;
    
    // Calculate signal quality
    SIGNAL_QUALITY quality = CalculateSignalQuality(bar, price, direction, vwapOK);
    SignalQualityBuffer[bar] = (double)quality;
    
    // Update statistics
    UpdateSignalStatistics(direction, signalAccepted, quality);
    
    // Finalize previous segment if exists
    if(g_hasActiveSegment)
    {
        FinalizeSignalSegment(bar, high, low);
    }
    
    // Start new segment if signal accepted
    if(signalAccepted)
    {
        StartNewSignalSegment(bar, barTime, price, direction, quality);
        g_signalCooldown = SignalCooldownBars;
    }
    
    // Create visual feedback
    if(EnableVisualFeedback)
    {
        CreateAdvancedVisualFeedback(bar, barTime, price, direction, signalAccepted, quality);
    }
    
    // Trigger alerts
    if(EnableAlerts && signalAccepted)
    {
        TriggerEnhancedAlert(direction, price, quality, barTime);
    }
}

//+------------------------------------------------------------------+
//| Calculate Signal Quality                                         |
//+------------------------------------------------------------------+
SIGNAL_QUALITY CalculateSignalQuality(int bar, double price, int direction, bool vwapOK)
{
    int score = 0;
    
    // VWAP confirmation (+1 point)
    if(vwapOK) score++;
    
    // Trend alignment (+1 point)
    if(TrendStrengthBuffer[bar] * direction > 0) score++;
    
    // Volatility consideration (+1 point if moderate volatility)
    double volatility = VolatilityBuffer[bar];
    if(volatility > VolatilityThreshold * 0.5 && volatility < VolatilityThreshold * 2.0)
        score++;
    
    // Market state consideration (+1 point)
    MARKET_STATE state = g_dashboardData.market.state;
    if((direction > 0 && state == MARKET_TRENDING_UP) || 
       (direction < 0 && state == MARKET_TRENDING_DOWN))
        score++;
    
    // Convert score to quality enum
    switch(score)
    {
        case 4: return QUALITY_EXCELLENT;
        case 3: return QUALITY_GOOD;
        case 2: return QUALITY_FAIR;
        case 1: return QUALITY_POOR;
        default: return QUALITY_UNKNOWN;
    }
}

//+------------------------------------------------------------------+
//| Update Signal Statistics                                         |
//+------------------------------------------------------------------+
void UpdateSignalStatistics(int direction, bool accepted, SIGNAL_QUALITY quality)
{
    g_dashboardData.performance.totalSignals++;
    
    if(direction > 0)
        g_dashboardData.performance.bullishSignals++;
    else
        g_dashboardData.performance.bearishSignals++;
    
    if(accepted)
    {
        g_dashboardData.performance.acceptedSignals++;
        
        // Update average signal quality
        double totalQuality = g_dashboardData.performance.avgSignalQuality * (g_dashboardData.performance.acceptedSignals - 1);
        totalQuality += (double)quality;
        g_dashboardData.performance.avgSignalQuality = totalQuality / g_dashboardData.performance.acceptedSignals;
    }
    else
    {
        g_dashboardData.performance.rejectedSignals++;
    }
    
    g_dashboardData.performance.lastSignalTime = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Start New Signal Segment                                         |
//+------------------------------------------------------------------+
void StartNewSignalSegment(int bar, datetime barTime, double price, int direction, SIGNAL_QUALITY quality)
{
    g_currentSegment.direction = direction;
    g_currentSegment.entryPrice = price;
    g_currentSegment.startTime = barTime;
    g_currentSegment.startBar = bar;
    g_currentSegment.reachedPoints = 0.0;
    g_currentSegment.reachedPercent = 0.0;
    g_currentSegment.isWin = false;
    g_currentSegment.finalized = false;
    g_currentSegment.quality = quality;
    g_currentSegment.vwapDistance = MathAbs(price - VWAPBuffer[bar]) / _Point;
    g_currentSegment.volatility = VolatilityBuffer[bar];
    g_currentSegment.trendStrength = TrendStrengthBuffer[bar];
    
    g_hasActiveSegment = true;
}

//+------------------------------------------------------------------+
//| Finalize Signal Segment                                          |
//+------------------------------------------------------------------+
void FinalizeSignalSegment(int bar, const double& high[], const double& low[])
{
    if(!g_hasActiveSegment) return;
    
    // Calculate final metrics
    UpdateSegmentReach(bar, high, low);
    
    // Mark as finalized
    g_currentSegment.finalized = true;
    
    // Add to history
    if(g_signalCount < MaxSignalHistory)
    {
        g_signalHistory[g_signalCount] = g_currentSegment;
        g_signalCount++;
    }
    else
    {
        // Shift array and add new signal
        for(int i = 0; i < MaxSignalHistory - 1; i++)
        {
            g_signalHistory[i] = g_signalHistory[i + 1];
        }
        g_signalHistory[MaxSignalHistory - 1] = g_currentSegment;
    }
    
    // Update performance metrics
    UpdatePerformanceFromSegment();
    
    g_hasActiveSegment = false;
}

//+------------------------------------------------------------------+
//| Update Segment Reach                                             |
//+------------------------------------------------------------------+
void UpdateSegmentReach(int bar, const double& high[], const double& low[])
{
    if(!g_hasActiveSegment) return;
    
    double bestPrice = g_currentSegment.entryPrice;
    
    // Find the best price reached
    for(int i = g_currentSegment.startBar; i <= bar; i++)
    {
        if(g_currentSegment.direction > 0) // Bullish
        {
            if(high[i] > bestPrice)
                bestPrice = high[i];
        }
        else // Bearish
        {
            if(low[i] < bestPrice)
                bestPrice = low[i];
        }
    }
    
    // Calculate points and percentage
    if(g_currentSegment.direction > 0)
    {
        g_currentSegment.reachedPoints = (bestPrice - g_currentSegment.entryPrice) / _Point;
    }
    else
    {
        g_currentSegment.reachedPoints = (g_currentSegment.entryPrice - bestPrice) / _Point;
    }
    
    g_currentSegment.reachedPercent = (g_currentSegment.reachedPoints * _Point / g_currentSegment.entryPrice) * 100.0;
    
    // Check win condition
    if(EnableWinRate && g_currentSegment.reachedPoints >= WinThresholdPoints)
    {
        g_currentSegment.isWin = true;
    }
}

//+------------------------------------------------------------------+
//| Update Performance From Segment                                  |
//+------------------------------------------------------------------+
void UpdatePerformanceFromSegment()
{
    if(g_currentSegment.isWin)
    {
        g_dashboardData.performance.wins++;
        
        // Update average win points
        double totalWinPoints = g_dashboardData.performance.avgWinPoints * (g_dashboardData.performance.wins - 1);
        totalWinPoints += g_currentSegment.reachedPoints;
        g_dashboardData.performance.avgWinPoints = totalWinPoints / g_dashboardData.performance.wins;
        
        // Update best signal
        if(g_currentSegment.reachedPoints > g_dashboardData.performance.bestSignalPoints)
            g_dashboardData.performance.bestSignalPoints = g_currentSegment.reachedPoints;
    }
    else
    {
        g_dashboardData.performance.losses++;
        
        // Update average loss points (use negative values for losses)
        double lossPoints = -MathAbs(g_currentSegment.reachedPoints);
        double totalLossPoints = g_dashboardData.performance.avgLossPoints * (g_dashboardData.performance.losses - 1);
        totalLossPoints += lossPoints;
        g_dashboardData.performance.avgLossPoints = totalLossPoints / g_dashboardData.performance.losses;
        
        // Update worst signal
        if(lossPoints < g_dashboardData.performance.worstSignalPoints)
            g_dashboardData.performance.worstSignalPoints = lossPoints;
    }
    
    // Calculate win rate
    int totalDecisions = g_dashboardData.performance.wins + g_dashboardData.performance.losses;
    if(totalDecisions > 0)
    {
        g_dashboardData.performance.winRate = ((double)g_dashboardData.performance.wins / totalDecisions) * 100.0;
    }
    
    // Calculate profit factor
    double grossProfit = g_dashboardData.performance.avgWinPoints * g_dashboardData.performance.wins;
    double grossLoss = MathAbs(g_dashboardData.performance.avgLossPoints * g_dashboardData.performance.losses);
    
    if(grossLoss > 0)
        g_dashboardData.performance.profitFactor = grossProfit / grossLoss;
}

//+------------------------------------------------------------------+
//| Update Real-Time Data                                            |
//+------------------------------------------------------------------+
void UpdateRealTimeData(int bar, const datetime& time[], const double& close[], 
                       const double& high[], const double& low[])
{
    g_dashboardData.currentSuperTrend = SuperTrendBuffer[bar];
    g_dashboardData.currentVWAP = VWAPBuffer[bar];
    g_dashboardData.barsProcessed = bar + 1;
    
    // Update current state based on SuperTrend direction
    int direction = (int)SuperTrendDirectionBuffer[bar];
    if(direction > 0)
        g_dashboardData.currentState = STATE_BULLISH;
    else if(direction < 0)
        g_dashboardData.currentState = STATE_BEARISH;
    else
        g_dashboardData.currentState = STATE_NEUTRAL;
    
    // Update market data
    g_dashboardData.market.currentPrice = close[bar];
    if(bar > 0)
    {
        g_dashboardData.market.priceChange = close[bar] - close[bar-1];
        g_dashboardData.market.priceChangePercent = (g_dashboardData.market.priceChange / close[bar-1]) * 100.0;
    }
    
    g_dashboardData.market.lastUpdate = time[bar];
    
    // Update active segment reach
    if(g_hasActiveSegment)
    {
        UpdateSegmentReach(bar, high, low);
    }
    
    // Update system load (simple approximation)
    g_dashboardData.systemLoad = ((double)bar / 1000.0) * 100.0;
    if(g_dashboardData.systemLoad > 100.0)
        g_dashboardData.systemLoad = 100.0;
}

//+------------------------------------------------------------------+
//| Should Update Dashboard                                          |
//+------------------------------------------------------------------+
bool ShouldUpdateDashboard()
{
    datetime currentTime = TimeCurrent();
    if(EnableRealTimeUpdates && currentTime > g_lastUpdate + 1) // Update every second
    {
        g_lastUpdate = currentTime;
        return true;
    }
    
    return !EnableRealTimeUpdates; // Always update if real-time is disabled
}

//+------------------------------------------------------------------+
//| Update Advanced Dashboard                                        |
//+------------------------------------------------------------------+
void UpdateAdvancedDashboard(int rates_total, const datetime& time[], const double& close[])
{
    if(!ShowDashboard) return;
    
    // Create dashboard if needed
    if(!g_dashboardCreated)
    {
        CreateAdvancedDashboard();
    }
    
    // Update dashboard status
    g_dashboardData.status = "Running";
    
    // Prepare dashboard values with enhanced formatting
    string values[] = {
        // Current Market State
        DoubleToString(g_dashboardData.market.currentPrice, _Digits),
        DoubleToString(g_dashboardData.currentSuperTrend, _Digits),
        DoubleToString(g_dashboardData.currentVWAP, _Digits),
        GetStateText(g_dashboardData.currentState),
        GetMarketStateText(g_dashboardData.market.state),
        
        // Market Analysis
        StringFormat("%.2f%%", g_dashboardData.market.priceChangePercent),
        StringFormat("%.2f%%", g_dashboardData.market.volatility),
        StringFormat("%.1f", g_dashboardData.market.trendStrength),
        StringFormat("%.0f", g_dashboardData.market.averageVolume),
        
        // Signal Statistics
        IntegerToString(g_dashboardData.performance.totalSignals),
        IntegerToString(g_dashboardData.performance.bullishSignals),
        IntegerToString(g_dashboardData.performance.bearishSignals),
        IntegerToString(g_dashboardData.performance.acceptedSignals),
        IntegerToString(g_dashboardData.performance.rejectedSignals),
        
        // Performance Metrics
        StringFormat("%.1f%%", g_dashboardData.performance.winRate),
        StringFormat("%.1f", g_dashboardData.performance.avgWinPoints),
        StringFormat("%.1f", MathAbs(g_dashboardData.performance.avgLossPoints)),
        StringFormat("%.2f", g_dashboardData.performance.profitFactor),
        StringFormat("%.1f", g_dashboardData.performance.avgSignalQuality),
        
        // Advanced Metrics
        StringFormat("%.1f", g_dashboardData.performance.bestSignalPoints),
        StringFormat("%.1f", MathAbs(g_dashboardData.performance.worstSignalPoints)),
        IntegerToString(g_dashboardData.performance.wins),
        IntegerToString(g_dashboardData.performance.losses),
        
        // System Information
        IntegerToString(g_dashboardData.barsProcessed),
        TimeToString(g_dashboardData.sessionStart, TIME_DATE | TIME_MINUTES),
        g_dashboardData.status,
        StringFormat("%.1f%%", g_dashboardData.systemLoad)
    };
    
    // Color array for enhanced visual feedback
    color colors[] = {
        // Current Market State
        AccentColor,  // Price
        GetDirectionColor(g_dashboardData.currentState),  // SuperTrend
        WarningColor,  // VWAP
        GetDirectionColor(g_dashboardData.currentState),  // Direction
        GetMarketStateColor(g_dashboardData.market.state),  // Market State
        
        // Market Analysis
        GetChangeColor(g_dashboardData.market.priceChangePercent),  // Price Change
        GetVolatilityColor(g_dashboardData.market.volatility),  // Volatility
        GetTrendColor(g_dashboardData.market.trendStrength),  // Trend Strength
        DashboardTextColor,  // Volume
        
        // Signal Statistics
        AccentColor,  // Total Signals
        SuccessColor,  // Bullish
        ErrorColor,  // Bearish
        SuccessColor,  // Accepted
        ErrorColor,  // Rejected
        
        // Performance Metrics
        GetWinRateColor(g_dashboardData.performance.winRate),  // Win Rate
        SuccessColor,  // Avg Win
        ErrorColor,  // Avg Loss
        GetProfitFactorColor(g_dashboardData.performance.profitFactor),  // Profit Factor
        GetQualityColor(g_dashboardData.performance.avgSignalQuality),  // Signal Quality
        
        // Advanced Metrics
        SuccessColor,  // Best Signal
        ErrorColor,  // Worst Signal
        SuccessColor,  // Total Wins
        ErrorColor,  // Total Losses
        
        // System Information
        AccentColor,  // Bars Processed
        DashboardTextColor,  // Session Start
        GetSystemStatusColor(g_dashboardData.status),  // Status
        GetLoadColor(g_dashboardData.systemLoad)  // System Load
    };
    
    // Update dashboard labels with values and colors
    for(int i = 0; i < ArraySize(values); i++)
    {
        string valueName = "ESTVWAP_Value_" + IntegerToString(i);
        if(ObjectFind(0, valueName) >= 0)
        {
            ObjectSetString(0, valueName, OBJPROP_TEXT, values[i]);
            ObjectSetInteger(0, valueName, OBJPROP_COLOR, colors[i]);
        }
    }
    
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Create Advanced Dashboard                                        |
//+------------------------------------------------------------------+
void CreateAdvancedDashboard()
{
    if(g_dashboardCreated) return;
    
    // Create main dashboard background
    string bgName = "ESTVWAP_Dashboard_BG";
    if(ObjectFind(0, bgName) < 0)
    {
        ObjectCreate(0, bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
        ObjectSetInteger(0, bgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, bgName, OBJPROP_XDISTANCE, DashboardX);
        ObjectSetInteger(0, bgName, OBJPROP_YDISTANCE, DashboardY);
        ObjectSetInteger(0, bgName, OBJPROP_XSIZE, DashboardWidth);
        ObjectSetInteger(0, bgName, OBJPROP_YSIZE, DashboardHeight);
        ObjectSetInteger(0, bgName, OBJPROP_BGCOLOR, DashboardBgColor);
        ObjectSetInteger(0, bgName, OBJPROP_BORDER_COLOR, DashboardBorderColor);
        ObjectSetInteger(0, bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
        ObjectSetInteger(0, bgName, OBJPROP_WIDTH, 2);
        ObjectSetInteger(0, bgName, OBJPROP_BACK, true);
        ObjectSetInteger(0, bgName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, bgName, OBJPROP_HIDDEN, true);
    }
    
    // Create title
    CreateDashboardTitle();
    
    // Create sections
    CreateDashboardSections();
    
    g_dashboardCreated = true;
}

//+------------------------------------------------------------------+
//| Create Dashboard Title                                           |
//+------------------------------------------------------------------+
void CreateDashboardTitle()
{
    string titleName = "ESTVWAP_Title";
    if(ObjectFind(0, titleName) < 0)
    {
        ObjectCreate(0, titleName, OBJ_LABEL, 0, 0, 0);
        ObjectSetString(0, titleName, OBJPROP_TEXT, "Enhanced SuperTrend & VWAP Analytics");
        ObjectSetString(0, titleName, OBJPROP_FONT, DashboardFont);
        ObjectSetInteger(0, titleName, OBJPROP_FONTSIZE, LabelFontSize + 2);
        ObjectSetInteger(0, titleName, OBJPROP_COLOR, AccentColor);
        ObjectSetInteger(0, titleName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, titleName, OBJPROP_XDISTANCE, DashboardX + LabelXOffset);
        ObjectSetInteger(0, titleName, OBJPROP_YDISTANCE, DashboardY + 10);
        ObjectSetInteger(0, titleName, OBJPROP_BACK, false);
        ObjectSetInteger(0, titleName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, titleName, OBJPROP_HIDDEN, true);
    }
}

//+------------------------------------------------------------------+
//| Create Dashboard Sections                                        |
//+------------------------------------------------------------------+
void CreateDashboardSections()
{
    string labels[] = {
        // Current Market State
        "Current Price:", "SuperTrend:", "VWAP:", "ST Direction:", "Market State:",
        "", // Separator
        // Market Analysis
        "Price Change:", "Volatility:", "Trend Strength:", "Avg Volume:",
        "", // Separator
        // Signal Statistics
        "Total Signals:", "Bullish Signals:", "Bearish Signals:", 
        "Accepted Signals:", "Rejected Signals:",
        "", // Separator
        // Performance Metrics
        "Win Rate:", "Avg Win Points:", "Avg Loss Points:", 
        "Profit Factor:", "Signal Quality:",
        "", // Separator
        // Advanced Metrics
        "Best Signal:", "Worst Signal:", "Total Wins:", "Total Losses:",
        "", // Separator
        // System Information
        "Bars Processed:", "Session Start:", "Status:", "System Load:"
    };
    
    int yOffset = 40;
    int labelIndex = 0;
    int lineHeight = MathMax(LabelFontSize, ValueFontSize) + 5;
    
    for(int i = 0; i < ArraySize(labels); i++)
    {
        if(labels[i] == "") // Section separator
        {
            yOffset += 8;
            continue;
        }
        
        // Create section header for major sections
        if(i == 0) CreateSectionHeader("Market State", yOffset - 15);
        else if(i == 6) CreateSectionHeader("Market Analysis", yOffset - 15);
        else if(i == 11) CreateSectionHeader("Signal Statistics", yOffset - 15);
        else if(i == 17) CreateSectionHeader("Performance", yOffset - 15);
        else if(i == 23) CreateSectionHeader("Advanced Metrics", yOffset - 15);
        else if(i == 28) CreateSectionHeader("System Info", yOffset - 15);
        
        // Create label
        string labelName = "ESTVWAP_Label_" + IntegerToString(labelIndex);
        if(ObjectFind(0, labelName) < 0)
        {
            ObjectCreate(0, labelName, OBJ_LABEL, 0, 0, 0);
            ObjectSetString(0, labelName, OBJPROP_TEXT, labels[i]);
            ObjectSetString(0, labelName, OBJPROP_FONT, DashboardFont);
            ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, LabelFontSize);
            ObjectSetInteger(0, labelName, OBJPROP_COLOR, DashboardTextColor);
            ObjectSetInteger(0, labelName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
            ObjectSetInteger(0, labelName, OBJPROP_XDISTANCE, DashboardX + LabelXOffset + 10);
            ObjectSetInteger(0, labelName, OBJPROP_YDISTANCE, DashboardY + yOffset);
            ObjectSetInteger(0, labelName, OBJPROP_BACK, false);
            ObjectSetInteger(0, labelName, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, labelName, OBJPROP_HIDDEN, true);
        }
        
        // Create value
        string valueName = "ESTVWAP_Value_" + IntegerToString(labelIndex);
        if(ObjectFind(0, valueName) < 0)
        {
            ObjectCreate(0, valueName, OBJ_LABEL, 0, 0, 0);
            ObjectSetString(0, valueName, OBJPROP_TEXT, "...");
            ObjectSetString(0, valueName, OBJPROP_FONT, DashboardFont);
            ObjectSetInteger(0, valueName, OBJPROP_FONTSIZE, ValueFontSize);
            ObjectSetInteger(0, valueName, OBJPROP_COLOR, DashboardTextColor);
            ObjectSetInteger(0, valueName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
            ObjectSetInteger(0, valueName, OBJPROP_XDISTANCE, DashboardX + ValueXOffset);
            ObjectSetInteger(0, valueName, OBJPROP_YDISTANCE, DashboardY + yOffset);
            ObjectSetInteger(0, valueName, OBJPROP_BACK, false);
            ObjectSetInteger(0, valueName, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, valueName, OBJPROP_HIDDEN, true);
        }
        
        labelIndex++;
        yOffset += lineHeight;
    }
}

//+------------------------------------------------------------------+
//| Create Section Header                                            |
//+------------------------------------------------------------------+
void CreateSectionHeader(string text, int yPos)
{
    string headerName = "ESTVWAP_Header_" + text;
    if(ObjectFind(0, headerName) < 0)
    {
        ObjectCreate(0, headerName, OBJ_LABEL, 0, 0, 0);
        ObjectSetString(0, headerName, OBJPROP_TEXT, "▼ " + text);
        ObjectSetString(0, headerName, OBJPROP_FONT, DashboardFont);
        ObjectSetInteger(0, headerName, OBJPROP_FONTSIZE, LabelFontSize + 1);
        ObjectSetInteger(0, headerName, OBJPROP_COLOR, AccentColor);
        ObjectSetInteger(0, headerName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, headerName, OBJPROP_XDISTANCE, DashboardX + LabelXOffset);
        ObjectSetInteger(0, headerName, OBJPROP_YDISTANCE, DashboardY + yPos);
        ObjectSetInteger(0, headerName, OBJPROP_BACK, false);
        ObjectSetInteger(0, headerName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, headerName, OBJPROP_HIDDEN, true);
    }
}

//+------------------------------------------------------------------+
//| Helper Functions for Dashboard Colors                            |
//+------------------------------------------------------------------+
string GetStateText(DASHBOARD_STATE state)
{
    switch(state)
    {
        case STATE_BULLISH: return "BULLISH";
        case STATE_BEARISH: return "BEARISH";
        case STATE_NEUTRAL: return "NEUTRAL";
        default: return "NO SIGNAL";
    }
}

string GetMarketStateText(MARKET_STATE state)
{
    switch(state)
    {
        case MARKET_TRENDING_UP: return "TRENDING UP";
        case MARKET_TRENDING_DOWN: return "TRENDING DOWN";
        case MARKET_RANGING: return "RANGING";
        case MARKET_VOLATILE: return "VOLATILE";
        case MARKET_QUIET: return "QUIET";
        default: return "UNKNOWN";
    }
}

color GetDirectionColor(DASHBOARD_STATE state)
{
    switch(state)
    {
        case STATE_BULLISH: return SuccessColor;
        case STATE_BEARISH: return ErrorColor;
        default: return WarningColor;
    }
}

color GetMarketStateColor(MARKET_STATE state)
{
    switch(state)
    {
        case MARKET_TRENDING_UP: return SuccessColor;
        case MARKET_TRENDING_DOWN: return ErrorColor;
        case MARKET_VOLATILE: return WarningColor;
        case MARKET_QUIET: return AccentColor;
        default: return DashboardTextColor;
    }
}

color GetChangeColor(double change)
{
    if(change > 0.1) return SuccessColor;
    if(change < -0.1) return ErrorColor;
    return WarningColor;
}

color GetVolatilityColor(double volatility)
{
    if(volatility > VolatilityThreshold * 2) return ErrorColor;
    if(volatility > VolatilityThreshold) return WarningColor;
    return SuccessColor;
}

color GetTrendColor(double strength)
{
    if(MathAbs(strength) > 70) return SuccessColor;
    if(MathAbs(strength) > 30) return WarningColor;
    return ErrorColor;
}

color GetWinRateColor(double winRate)
{
    if(winRate >= 70) return SuccessColor;
    if(winRate >= 50) return WarningColor;
    return ErrorColor;
}

color GetProfitFactorColor(double pf)
{
    if(pf >= 2.0) return SuccessColor;
    if(pf >= 1.0) return WarningColor;
    return ErrorColor;
}

color GetQualityColor(double quality)
{
    if(quality >= 3.5) return SuccessColor;
    if(quality >= 2.5) return WarningColor;
    return ErrorColor;
}

color GetSystemStatusColor(string status)
{
    if(status == "Running") return SuccessColor;
    if(status == "Initializing...") return WarningColor;
    return ErrorColor;
}

color GetLoadColor(double load)
{
    if(load < 50) return SuccessColor;
    if(load < 80) return WarningColor;
    return ErrorColor;
}

//+------------------------------------------------------------------+
//| Create Advanced Visual Feedback                                  |
//+------------------------------------------------------------------+
void CreateAdvancedVisualFeedback(int bar, datetime barTime, double price, int direction, 
                                  bool accepted, SIGNAL_QUALITY quality)
{
    string objectName = StringFormat("ESTVWAP_Signal_%lld", barTime);
    
    // Determine colors based on quality and acceptance
    color signalColor;
    if(!accepted)
        signalColor = RejectedSignalColor;
    else
    {
        switch(quality)
        {
            case QUALITY_EXCELLENT: signalColor = (direction > 0) ? clrLime : clrRed; break;
            case QUALITY_GOOD: signalColor = (direction > 0) ? BullishSignalColor : BearishSignalColor; break;
            case QUALITY_FAIR: signalColor = (direction > 0) ? clrCyan : clrOrange; break;
            default: signalColor = RejectedSignalColor; break;
        }
    }
    
    // Create signal marker
    if(ObjectCreate(0, objectName, OBJ_ARROW, 0, barTime, price))
    {
        int arrowCode = (direction > 0) ? 233 : 234; // Up or down arrow
        ObjectSetInteger(0, objectName, OBJPROP_ARROWCODE, arrowCode);
        ObjectSetInteger(0, objectName, OBJPROP_COLOR, signalColor);
        ObjectSetInteger(0, objectName, OBJPROP_WIDTH, CircleWidth + (int)quality);
        ObjectSetInteger(0, objectName, OBJPROP_BACK, false);
        ObjectSetInteger(0, objectName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, objectName, OBJPROP_HIDDEN, true);
        
        // Set tooltip with detailed information
        string tooltip = StringFormat("%s Signal - Quality: %s\nVWAP Distance: %.1f pts\nVolatility: %.2f%%",
                                     (direction > 0) ? "BULLISH" : "BEARISH",
                                     EnumToString(quality),
                                     g_currentSegment.vwapDistance,
                                     g_currentSegment.volatility);
        ObjectSetString(0, objectName, OBJPROP_TOOLTIP, tooltip);
    }
}

//+------------------------------------------------------------------+
//| Trigger Enhanced Alert                                           |
//+------------------------------------------------------------------+
void TriggerEnhancedAlert(int direction, double price, SIGNAL_QUALITY quality, datetime alertTime)
{
    if(alertTime <= g_lastAlertTime + 5) // Minimum 5 seconds between alerts
        return;
    
    string qualityText = EnumToString(quality);
    string directionText = (direction > 0) ? "BULLISH" : "BEARISH";
    string alertMessage = StringFormat("%s: %s %s Signal at %.5f", 
                                      _Symbol, qualityText, directionText, price);
    
    if(AlertPopup)
        Alert(alertMessage);
    
    if(AlertSound && AlertSoundFile != "")
        PlaySound(AlertSoundFile);
    
    Print("ENHANCED ALERT: ", alertMessage);
    g_lastAlertTime = alertTime;
}

//+------------------------------------------------------------------+
//| Cleanup Functions                                                |
//+------------------------------------------------------------------+
void CleanupDashboard()
{
    // Remove all dashboard objects
    for(int i = ObjectsTotal(0) - 1; i >= 0; i--)
    {
        string objectName = ObjectName(0, i);
        if(StringFind(objectName, "ESTVWAP_") == 0)
            ObjectDelete(0, objectName);
    }
    
    g_dashboardCreated = false;
}

void CleanupVisualObjects()
{
    for(int i = ObjectsTotal(0) - 1; i >= 0; i--)
    {
        string objectName = ObjectName(0, i);
        if(StringFind(objectName, "ESTVWAP_Signal_") == 0)
            ObjectDelete(0, objectName);
    }
}

void CleanupOldObjects(const datetime& time[], int rates_total)
{
    if(rates_total <= SignalLifetimeBars) return;
    
    datetime cutoffTime = time[rates_total - SignalLifetimeBars];
    
    for(int i = ObjectsTotal(0) - 1; i >= 0; i--)
    {
        string objectName = ObjectName(0, i);
        if(StringFind(objectName, "ESTVWAP_Signal_") == 0)
        {
            datetime objectTime = (datetime)ObjectGetInteger(0, objectName, OBJPROP_TIME);
            if(objectTime < cutoffTime)
                ObjectDelete(0, objectName);
        }
    }
}

//+------------------------------------------------------------------+
//| Save Performance Data                                            |
//+------------------------------------------------------------------+
void SavePerformanceData()
{
    string fileName = "Enhanced_ST_VWAP_Performance.csv";
    int fileHandle = FileOpen(fileName, FILE_WRITE | FILE_CSV);
    
    if(fileHandle != INVALID_HANDLE)
    {
        // Write header
        FileWrite(fileHandle, "Timestamp", "TotalSignals", "WinRate", "ProfitFactor", 
                 "AvgWin", "AvgLoss", "BestSignal", "WorstSignal", "SignalQuality");
        
        // Write current data
        FileWrite(fileHandle, TimeToString(TimeCurrent()), 
                 g_dashboardData.performance.totalSignals,
                 g_dashboardData.performance.winRate,
                 g_dashboardData.performance.profitFactor,
                 g_dashboardData.performance.avgWinPoints,
                 g_dashboardData.performance.avgLossPoints,
                 g_dashboardData.performance.bestSignalPoints,
                 g_dashboardData.performance.worstSignalPoints,
                 g_dashboardData.performance.avgSignalQuality);
        
        FileClose(fileHandle);
        Print("Performance data saved to: ", fileName);
    }
    else
    {
        Print("Failed to save performance data");
    }
}

//+------------------------------------------------------------------+