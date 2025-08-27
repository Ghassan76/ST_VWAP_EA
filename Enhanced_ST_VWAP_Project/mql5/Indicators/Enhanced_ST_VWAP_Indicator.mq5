//+------------------------------------------------------------------+
//| Enhanced_ST_VWAP_Indicator.mq5 |
//| Complete Enhanced SuperTrend with VWAP Filter & Advanced Dashboard |
//+------------------------------------------------------------------+
#property copyright "Complete Enhanced SuperTrend with VWAP Filter & Dashboard © 2025"
#property link "https://www.mql5.com"
#property version "4.00"
#property indicator_chart_window
#property indicator_plots 3
#property indicator_buffers 5
#property indicator_type1 DRAW_COLOR_LINE
#property indicator_style1 STYLE_SOLID
#property indicator_width1 2
#property indicator_color1 clrGreen, clrRed

#property indicator_type2 DRAW_LINE
#property indicator_style2 STYLE_SOLID
#property indicator_width2 2
#property indicator_color2 clrYellow

#property indicator_type3 DRAW_NONE

//--- SuperTrend Input Parameters ---
input group "=== SuperTrend Settings ==="
input int ATRPeriod = 22;
input double Multiplier = 3.0;
input ENUM_APPLIED_PRICE SourcePrice = PRICE_MEDIAN;
input bool TakeWicksIntoAccount = true;

//--- VWAP Input Parameters ---
input group "=== VWAP Settings ==="
input ENUM_APPLIED_PRICE VWAPPriceMethod = PRICE_TYPICAL;
input double MinVolumeThreshold = 1.0;
input bool ResetVWAPDaily = true;

//--- VWAP Filter Settings ---
input group "=== VWAP Filter Settings ==="
input bool EnableVWAPFilter = true;
input bool ShowVWAPLine = true;

//--- Time Window Settings ---
input group "=== Time Window Settings ==="
input bool EnableTimeWindow = false;
input int StartHour = 9;
input int StartMinute = 30;
input int EndHour = 16;
input int EndMinute = 0;
enum TimeWindowMode
{
    MODE_DASHBOARD_ONLY = 0,
    MODE_SIGNALS_ONLY = 1,
    MODE_BOTH = 2
};
input TimeWindowMode WindowMode = MODE_DASHBOARD_ONLY;

//--- Performance Settings ---
input group "=== Performance & Win Rate Settings ==="
input bool EnableWinRate = true;
input double WinThresholdPoints = 100.0;
input bool FilterSignalsOnClose = true;

//--- Dashboard Settings ---
input group "=== Dashboard Settings ==="
input bool ShowDashboard = true;
input int DashboardX = 20;
input int DashboardY = 50;
input string DashboardFont = "Arial Black";
input int LabelFontSize = 9;
input int ValueFontSize = 8;
input color DashboardBgColor = clrBlack;
input color DashboardBorderColor = clrWhite;
input color DashboardTextColor = clrWhite;
input int LabelXOffset = 5;
input int ValueXOffset = 180;

//--- Visual Feedback Settings ---
input group "=== Visual Feedback Settings ==="
input bool EnableVisualFeedback = true;
input int CircleWidth = 2;
input color RejectionColor = clrGray;
input color BullishAcceptColor = clrBlue;
input color BearishAcceptColor = clrWhite;
input int SignalLifetimeBars = 200;

//--- Advanced Settings ---
input group "=== Advanced Settings ==="
input bool ShowDebugInfo = false;
input int MaxObjectsOnChart = 500;

//--- Alert Settings ---
input group "=== Alert Settings ==="
input bool EnableAlerts = false;
input bool AlertPopup = true;
input string AlertSoundFile = "alert.wav";

//--- Dashboard State Enumeration ---
enum DASHBOARD_STATE
{
    STATE_NO_SIGNAL = 0,
    STATE_BULLISH = 1,
    STATE_BEARISH = -1
};

//--- Signal Segment Structure ---
struct SignalSegment
{
    int direction;          // 1 for bullish, -1 for bearish
    double entryPrice;      // Entry price
    datetime startTime;     // Signal start time
    int startBar;          // Signal start bar
    double reachedPoints;   // Maximum favorable excursion in points
    bool isWin;            // Whether this segment reached the win threshold
    bool finalized;        // Whether this segment is complete
    bool inWindow;         // Whether this segment started in time window
};

//--- Indicator Handles ---
int atrHandle;

//--- Indicator Buffers ---
double SuperTrendBuffer[];
double SuperTrendColorBuffer[];
double VWAPBuffer[];
double SuperTrendDirectionBuffer[];
double SignalBuffer[];

//--- Global VWAP Variables ---
datetime g_currentDay = 0;
double g_sumPriceVolume = 0.0;
double g_sumVolume = 0.0;
datetime g_lastAlertTime = 0;

//--- Dashboard Variables ---
struct DashboardStats
{
    // Basic counts (window-filtered if enabled)
    int totalSignals;
    int bullishSignals;
    int bearishSignals;
    int acceptedSignals;
    int rejectedSignals;
    
    // Performance metrics
    double winRate;
    int wins;
    int losses;
    
    // Current values
    double currentPrice;
    double currentSuperTrend;
    double currentVWAP;
    DASHBOARD_STATE dashboardState;
    
    // Last signal info (window-filtered)
    string lastSignalTime;
    double lastSignalReachedPoints;
    
    // Averages (window-filtered)
    double avgBluePoints;
    double avgWhitePoints;
    double avgAllPoints;
    
    // Session info
    datetime sessionStart;
    int barsProcessed;
    bool inTimeWindow;
    string windowStatus;
};

DashboardStats g_stats;
bool g_dashboardCreated = false;

//--- Signal Tracking ---
SignalSegment g_signalSegments[];
int g_segmentCount = 0;
SignalSegment g_currentSegment;
bool g_hasActiveSegment = false;

//+------------------------------------------------------------------+
//| Custom indicator initialization function |
//+------------------------------------------------------------------+
int OnInit()
{
    atrHandle = iATR(NULL, 0, ATRPeriod);
    if(atrHandle == INVALID_HANDLE)
    {
        Print("Error creating ATR indicator. Error code: ", GetLastError());
        return INIT_FAILED;
    }
    
    if(ATRPeriod <= 0 || Multiplier <= 0.0 || MaxObjectsOnChart <= 0)
    {
        Print("Error: Invalid input parameters");
        return INIT_FAILED;
    }
    
    // Set up indicator buffers
    SetIndexBuffer(0, SuperTrendBuffer, INDICATOR_DATA);
    SetIndexBuffer(1, SuperTrendColorBuffer, INDICATOR_COLOR_INDEX);
    SetIndexBuffer(2, VWAPBuffer, INDICATOR_DATA);
    SetIndexBuffer(3, SuperTrendDirectionBuffer, INDICATOR_CALCULATIONS);
    SetIndexBuffer(4, SignalBuffer, INDICATOR_CALCULATIONS);
    
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
    
    // Initialize dashboard stats
    InitializeDashboardStats();
    
    // Set indicator name
    string indicatorName = StringFormat("Enhanced ST&VWAP (ATR:%d, Mult:%.1f)", ATRPeriod, Multiplier);
    IndicatorSetString(INDICATOR_SHORTNAME, indicatorName);
    IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
    
    Print("Enhanced ST&VWAP Indicator initialized successfully");
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    if(atrHandle != INVALID_HANDLE)
        IndicatorRelease(atrHandle);
        
    // Clean up dashboard objects
    CleanupDashboard();
    
    // Clean up visual feedback objects
    if(EnableVisualFeedback)
        CleanupVisualObjects();
        
    Print("Enhanced ST&VWAP Indicator deinitialized");
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function |
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
        return(0);
    
    ArraySetAsSeries(time, false);
    ArraySetAsSeries(open, false);
    ArraySetAsSeries(high, false);
    ArraySetAsSeries(low, false);
    ArraySetAsSeries(close, false);
    ArraySetAsSeries(tick_volume, false);
    
    double atrBuffer[];
    ArraySetAsSeries(atrBuffer, false);
    
    int start = (prev_calculated > ATRPeriod) ? prev_calculated - 1 : ATRPeriod;
    
    for(int i = start; i < rates_total; i++)
    {
        CalculateVWAPForBar(i, time, open, high, low, close, tick_volume);
        
        double srcPrice;
        switch(SourcePrice)
        {
            case PRICE_CLOSE: srcPrice = close[i]; break;
            case PRICE_OPEN: srcPrice = open[i]; break;
            case PRICE_HIGH: srcPrice = high[i]; break;
            case PRICE_LOW: srcPrice = low[i]; break;
            case PRICE_MEDIAN: srcPrice = (high[i] + low[i]) / 2.0; break;
            case PRICE_TYPICAL: srcPrice = (high[i] + low[i] + close[i]) / 3.0; break;
            default: srcPrice = (high[i] + low[i] + close[i] + close[i]) / 4.0; break;
        }
        
        double highPrice = TakeWicksIntoAccount ? high[i] : MathMax(open[i], close[i]);
        double lowPrice = TakeWicksIntoAccount ? low[i] : MathMin(open[i], close[i]);
        
        double atr;
        if(CopyBuffer(atrHandle, 0, rates_total - i - 1, 1, atrBuffer) == -1)
            atr = srcPrice * 0.01;
        else
            atr = atrBuffer[0];
        
        if(atr <= 0.0)
            atr = srcPrice * 0.01;
        
        double longStop = srcPrice - Multiplier * atr;
        double shortStop = srcPrice + Multiplier * atr;
        
        if(i > 0)
        {
            double longStopPrev = (SuperTrendDirectionBuffer[i-1] == 1) ? SuperTrendBuffer[i-1] : longStop;
            double shortStopPrev = (SuperTrendDirectionBuffer[i-1] == -1) ? SuperTrendBuffer[i-1] : shortStop;
            
            if(!(open[i] == close[i] && open[i] == low[i] && open[i] == high[i]))
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
        
        int supertrend_dir = 1;
        if(i > 0)
        {
            int prev_dir = (int)SuperTrendDirectionBuffer[i-1];
            supertrend_dir = prev_dir;
            
            if(supertrend_dir == -1 && highPrice > SuperTrendBuffer[i-1])
            {
                supertrend_dir = 1;
                bool vwapOk = !EnableVWAPFilter || (VWAPBuffer[i] > 0 && close[i] > VWAPBuffer[i]);
                
                if(ShouldGenerateSignals(time[i]))
                {
                    ProcessSignal(i, time[i], close[i], 1, vwapOk, lowPrice, highPrice, high, low, rates_total);
                }
            }
            else if(supertrend_dir == 1 && lowPrice < SuperTrendBuffer[i-1])
            {
                supertrend_dir = -1;
                bool vwapOk = !EnableVWAPFilter || (VWAPBuffer[i] > 0 && close[i] < VWAPBuffer[i]);
                
                if(ShouldGenerateSignals(time[i]))
                {
                    ProcessSignal(i, time[i], close[i], -1, vwapOk, lowPrice, highPrice, high, low, rates_total);
                }
            }
        }
        
        if(supertrend_dir == 1)
        {
            SuperTrendBuffer[i] = longStop;
            SuperTrendDirectionBuffer[i] = 1;
            SuperTrendColorBuffer[i] = 0;
        }
        else
        {
            SuperTrendBuffer[i] = shortStop;
            SuperTrendDirectionBuffer[i] = -1;
            SuperTrendColorBuffer[i] = 1;
        }
        
        SignalBuffer[i] = 0;
        g_stats.barsProcessed = i + 1;
        
        // Update current segment reach for active segments
        UpdateCurrentSegmentReach(i, high, low);
    }
    
    // Update current values for dashboard
    if(rates_total > 0)
    {
        int lastBar = rates_total - 1;
        g_stats.currentPrice = close[lastBar];
        g_stats.currentSuperTrend = SuperTrendBuffer[lastBar];
        g_stats.currentVWAP = VWAPBuffer[lastBar];
        
        // Update time window status
        g_stats.inTimeWindow = IsInTimeWindow(time[lastBar]);
        if(EnableTimeWindow)
        {
            g_stats.windowStatus = g_stats.inTimeWindow ? "ACTIVE" : "OUT OF WINDOW";
        }
        else
        {
            g_stats.windowStatus = "ACTIVE";
        }
    }
    
    // Update averages and win rate
    UpdateAverages();
    
    // Create and update dashboard based on time window rules
    if(ShowDashboard && ShouldUpdateDashboard(rates_total > 0 ? time[rates_total-1] : TimeCurrent()))
    {
        CreateDashboard();
        UpdateDashboard();
    }
    else if(ShowDashboard && EnableTimeWindow)
    {
        // Show idle dashboard outside window
        CreateDashboard();
        UpdateIdleDashboard();
    }
    
    if(EnableVisualFeedback)
        CleanOldObjects(time, rates_total);
    
    return(rates_total - 1);
}

//+------------------------------------------------------------------+
//| Initialize dashboard statistics |
//+------------------------------------------------------------------+
void InitializeDashboardStats()
{
    g_stats.totalSignals = 0;
    g_stats.bullishSignals = 0;
    g_stats.bearishSignals = 0;
    g_stats.acceptedSignals = 0;
    g_stats.rejectedSignals = 0;
    g_stats.winRate = 0.0;
    g_stats.wins = 0;
    g_stats.losses = 0;
    g_stats.currentPrice = 0.0;
    g_stats.currentSuperTrend = 0.0;
    g_stats.currentVWAP = 0.0;
    g_stats.dashboardState = STATE_NO_SIGNAL;
    g_stats.lastSignalTime = "None";
    g_stats.lastSignalReachedPoints = 0.0;
    g_stats.avgBluePoints = 0.0;
    g_stats.avgWhitePoints = 0.0;
    g_stats.avgAllPoints = 0.0;
    g_stats.sessionStart = TimeCurrent();
    g_stats.barsProcessed = 0;
    g_stats.inTimeWindow = false;
    g_stats.windowStatus = "INITIALIZING";
    
    g_segmentCount = 0;
    ArrayResize(g_signalSegments, 0);
    g_hasActiveSegment = false;
}

//+------------------------------------------------------------------+
//| Calculate VWAP for a specific bar |
//+------------------------------------------------------------------+
void CalculateVWAPForBar(int bar, const datetime& time[], const double& open[], 
                        const double& high[], const double& low[], const double& close[], 
                        const long& tick_volume[])
{
    MqlDateTime timeStruct;
    TimeToStruct(time[bar], timeStruct);
    
    datetime currentDay = StringToTime(StringFormat("%04d.%02d.%02d", timeStruct.year, timeStruct.mon, timeStruct.day));
    
    if(ResetVWAPDaily && currentDay != g_currentDay)
    {
        g_currentDay = currentDay;
        g_sumPriceVolume = 0.0;
        g_sumVolume = 0.0;
    }
    
    double price;
    switch(VWAPPriceMethod)
    {
        case PRICE_CLOSE: price = close[bar]; break;
        case PRICE_OPEN: price = open[bar]; break;
        case PRICE_HIGH: price = high[bar]; break;
        case PRICE_LOW: price = low[bar]; break;
        case PRICE_MEDIAN: price = (high[bar] + low[bar]) / 2.0; break;
        case PRICE_TYPICAL: price = (high[bar] + low[bar] + close[bar]) / 3.0; break;
        default: price = (high[bar] + low[bar] + close[bar] + close[bar]) / 4.0; break;
    }
    
    double volume = (double)tick_volume[bar];
    if(volume < MinVolumeThreshold)
        volume = MinVolumeThreshold;
    
    g_sumPriceVolume += price * volume;
    g_sumVolume += volume;
    
    VWAPBuffer[bar] = (g_sumVolume > 0) ? (g_sumPriceVolume / g_sumVolume) : price;
}

//+------------------------------------------------------------------+
//| Check if signals should be generated |
//+------------------------------------------------------------------+
bool ShouldGenerateSignals(datetime signalTime)
{
    if(!EnableTimeWindow)
        return true;
        
    bool inWindow = IsInTimeWindow(signalTime);
    
    switch(WindowMode)
    {
        case MODE_DASHBOARD_ONLY: return true;
        case MODE_SIGNALS_ONLY: return inWindow;
        case MODE_BOTH: return inWindow;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Check if dashboard should be updated |
//+------------------------------------------------------------------+
bool ShouldUpdateDashboard(datetime currentTime)
{
    if(!EnableTimeWindow)
        return true;
        
    bool inWindow = IsInTimeWindow(currentTime);
    
    switch(WindowMode)
    {
        case MODE_DASHBOARD_ONLY: return true;
        case MODE_SIGNALS_ONLY: return true;
        case MODE_BOTH: return inWindow;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Check if current time is in trading window |
//+------------------------------------------------------------------+
bool IsInTimeWindow(datetime checkTime)
{
    if(!EnableTimeWindow)
        return true;
        
    MqlDateTime timeStruct;
    TimeToStruct(checkTime, timeStruct);
    
    int currentMinutes = timeStruct.hour * 60 + timeStruct.min;
    int startMinutes = StartHour * 60 + StartMinute;
    int endMinutes = EndHour * 60 + EndMinute;
    
    if(startMinutes <= endMinutes)
    {
        return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    }
    else
    {
        return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
}

//+------------------------------------------------------------------+
//| Process signal detection |
//+------------------------------------------------------------------+
void ProcessSignal(int bar, datetime signalTime, double signalPrice, int direction, 
                  bool vwapOk, double lowPrice, double highPrice, 
                  const double& high[], const double& low[], int rates_total)
{
    bool inWindow = IsInTimeWindow(signalTime);
    
    // Finalize previous segment if exists
    if(g_hasActiveSegment)
    {
        FinalizeCurrentSegment(bar, high, low);
    }
    
    // Count all signals (but filter for dashboard based on window settings)
    bool countForDashboard = (!EnableTimeWindow || WindowMode == MODE_DASHBOARD_ONLY || inWindow);
    
    if(countForDashboard)
    {
        g_stats.totalSignals++;
        
        if(direction == 1)
            g_stats.bullishSignals++;
        else
            g_stats.bearishSignals++;
    }
    
    // Determine signal acceptance
    bool accepted = vwapOk;
    
    if(countForDashboard)
    {
        if(accepted)
            g_stats.acceptedSignals++;
        else
            g_stats.rejectedSignals++;
            
        // Update last signal info
        g_stats.lastSignalTime = TimeToString(signalTime, TIME_DATE | TIME_MINUTES);
        g_stats.lastSignalReachedPoints = 0.0; // Will be updated as position moves
        
        // Update dashboard state
        if(accepted)
        {
            g_stats.dashboardState = (direction == 1) ? STATE_BULLISH : STATE_BEARISH;
        }
    }
    
    // Start new segment tracking
    if(accepted && EnableWinRate)
    {
        StartNewSegment(bar, signalTime, signalPrice, direction, inWindow);
    }
    
    // Visual feedback
    if(EnableVisualFeedback)
    {
        CreateVisualFeedback(bar, signalPrice, direction, accepted, signalTime);
    }
    
    // Alerts
    if(EnableAlerts && accepted)
    {
        TriggerAlert(direction, signalPrice, signalTime);
    }
    
    if(ShowDebugInfo)
    {
        Print(StringFormat("Signal: %s at %.5f | VWAP: %s | Window: %s | Accepted: %s", 
              (direction == 1) ? "BUY" : "SELL", signalPrice,
              vwapOk ? "OK" : "REJECTED", inWindow ? "YES" : "NO", accepted ? "YES" : "NO"));
    }
}

//+------------------------------------------------------------------+
//| Start new segment tracking |
//+------------------------------------------------------------------+
void StartNewSegment(int bar, datetime signalTime, double signalPrice, int direction, bool inWindow)
{
    g_currentSegment.direction = direction;
    g_currentSegment.entryPrice = signalPrice;
    g_currentSegment.startTime = signalTime;
    g_currentSegment.startBar = bar;
    g_currentSegment.reachedPoints = 0.0;
    g_currentSegment.isWin = false;
    g_currentSegment.finalized = false;
    g_currentSegment.inWindow = inWindow;
    g_hasActiveSegment = true;
    
    if(ShowDebugInfo)
    {
        Print(StringFormat("Started new segment: %s at %.5f", 
              (direction == 1) ? "BUY" : "SELL", signalPrice));
    }
}

//+------------------------------------------------------------------+
//| Update current segment reach |
//+------------------------------------------------------------------+
void UpdateCurrentSegmentReach(int bar, const double& high[], const double& low[])
{
    if(!g_hasActiveSegment || !EnableWinRate)
        return;
        
    double favorablePrice;
    if(g_currentSegment.direction == 1) // Bullish
        favorablePrice = high[bar];
    else // Bearish
        favorablePrice = low[bar];
        
    double reachedPoints;
    if(g_currentSegment.direction == 1)
        reachedPoints = (favorablePrice - g_currentSegment.entryPrice) / _Point;
    else
        reachedPoints = (g_currentSegment.entryPrice - favorablePrice) / _Point;
        
    if(reachedPoints > g_currentSegment.reachedPoints)
    {
        g_currentSegment.reachedPoints = reachedPoints;
        
        // Update dashboard
        bool countForDashboard = (!EnableTimeWindow || WindowMode == MODE_DASHBOARD_ONLY || g_currentSegment.inWindow);
        if(countForDashboard)
        {
            g_stats.lastSignalReachedPoints = reachedPoints;
        }
        
        // Check for win
        if(!g_currentSegment.isWin && reachedPoints >= WinThresholdPoints)
        {
            g_currentSegment.isWin = true;
            
            if(ShowDebugInfo)
            {
                Print(StringFormat("Segment reached win threshold: %.1f points", reachedPoints));
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Finalize current segment |
//+------------------------------------------------------------------+
void FinalizeCurrentSegment(int bar, const double& high[], const double& low[])
{
    if(!g_hasActiveSegment)
        return;
        
    // Final update of reached points
    UpdateCurrentSegmentReach(bar, high, low);
    
    // Mark as finalized
    g_currentSegment.finalized = true;
    
    // Add to segments array
    ArrayResize(g_signalSegments, g_segmentCount + 1);
    g_signalSegments[g_segmentCount] = g_currentSegment;
    g_segmentCount++;
    
    // Update win/loss stats
    bool countForDashboard = (!EnableTimeWindow || WindowMode == MODE_DASHBOARD_ONLY || g_currentSegment.inWindow);
    if(countForDashboard && EnableWinRate)
    {
        if(g_currentSegment.isWin)
            g_stats.wins++;
        else
            g_stats.losses++;
    }
    
    g_hasActiveSegment = false;
    
    if(ShowDebugInfo)
    {
        Print(StringFormat("Finalized segment: %.1f points, Win: %s", 
              g_currentSegment.reachedPoints, g_currentSegment.isWin ? "YES" : "NO"));
    }
}

//+------------------------------------------------------------------+
//| Update averages and win rate |
//+------------------------------------------------------------------+
void UpdateAverages()
{
    if(g_segmentCount == 0)
    {
        g_stats.avgBluePoints = 0.0;
        g_stats.avgWhitePoints = 0.0;
        g_stats.avgAllPoints = 0.0;
        g_stats.winRate = 0.0;
        return;
    }
    
    double totalBluePoints = 0.0, totalWhitePoints = 0.0, totalAllPoints = 0.0;
    int blueCount = 0, whiteCount = 0, totalCount = 0;
    int totalWins = g_stats.wins, totalLosses = g_stats.losses;
    
    for(int i = 0; i < g_segmentCount; i++)
    {
        bool countForDashboard = (!EnableTimeWindow || WindowMode == MODE_DASHBOARD_ONLY || g_signalSegments[i].inWindow);
        
        if(countForDashboard)
        {
            totalAllPoints += g_signalSegments[i].reachedPoints;
            totalCount++;
            
            if(g_signalSegments[i].direction == 1) // Bullish (Blue)
            {
                totalBluePoints += g_signalSegments[i].reachedPoints;
                blueCount++;
            }
            else // Bearish (White)
            {
                totalWhitePoints += g_signalSegments[i].reachedPoints;
                whiteCount++;
            }
        }
    }
    
    // Include current active segment if exists
    if(g_hasActiveSegment)
    {
        bool countForDashboard = (!EnableTimeWindow || WindowMode == MODE_DASHBOARD_ONLY || g_currentSegment.inWindow);
        
        if(countForDashboard)
        {
            totalAllPoints += g_currentSegment.reachedPoints;
            totalCount++;
            
            if(g_currentSegment.direction == 1)
            {
                totalBluePoints += g_currentSegment.reachedPoints;
                blueCount++;
            }
            else
            {
                totalWhitePoints += g_currentSegment.reachedPoints;
                whiteCount++;
            }
        }
    }
    
    // Calculate averages
    g_stats.avgBluePoints = (blueCount > 0) ? (totalBluePoints / blueCount) : 0.0;
    g_stats.avgWhitePoints = (whiteCount > 0) ? (totalWhitePoints / whiteCount) : 0.0;
    g_stats.avgAllPoints = (totalCount > 0) ? (totalAllPoints / totalCount) : 0.0;
    
    // Calculate win rate
    if(EnableWinRate)
    {
        int totalDecided = totalWins + totalLosses;
        g_stats.winRate = (totalDecided > 0) ? ((double)totalWins / totalDecided * 100.0) : 0.0;
    }
}

//+------------------------------------------------------------------+
//| Create visual feedback |
//+------------------------------------------------------------------+
void CreateVisualFeedback(int bar, double price, int direction, bool accepted, datetime signalTime)
{
    string objectName = StringFormat("ST_VWAP_Signal_%lld", signalTime);
    
    color signalColor;
    if(!accepted)
        signalColor = RejectionColor;
    else if(direction == 1)
        signalColor = BullishAcceptColor;
    else
        signalColor = BearishAcceptColor;
    
    if(ObjectCreate(0, objectName, OBJ_TREND, 0, signalTime, price, signalTime, price))
    {
        ObjectSetInteger(0, objectName, OBJPROP_COLOR, signalColor);
        ObjectSetInteger(0, objectName, OBJPROP_WIDTH, CircleWidth);
        ObjectSetInteger(0, objectName, OBJPROP_STYLE, STYLE_SOLID);
        ObjectSetInteger(0, objectName, OBJPROP_BACK, false);
        ObjectSetInteger(0, objectName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, objectName, OBJPROP_HIDDEN, true);
        
        // Store object creation time for cleanup
        ObjectSetString(0, objectName, OBJPROP_TEXT, "ST_VWAP_Signal");
    }
}

//+------------------------------------------------------------------+
//| Trigger alert |
//+------------------------------------------------------------------+
void TriggerAlert(int direction, double price, datetime signalTime)
{
    if(signalTime <= g_lastAlertTime)
        return;
        
    string alertText = StringFormat("ST&VWAP %s Signal at %.5f", 
                                   (direction == 1) ? "BUY" : "SELL", price);
    
    if(AlertPopup)
        Alert(alertText);
        
    if(AlertSoundFile != "")
        PlaySound(AlertSoundFile);
        
    g_lastAlertTime = signalTime;
}

//+------------------------------------------------------------------+
//| Clean old objects |
//+------------------------------------------------------------------+
void CleanOldObjects(const datetime& time[], int rates_total)
{
    if(rates_total < SignalLifetimeBars)
        return;
        
    datetime cutoffTime = time[rates_total - SignalLifetimeBars];
    
    for(int i = ObjectsTotal(0, 0) - 1; i >= 0; i--)
    {
        string objectName = ObjectName(0, i);
        
        if(StringFind(objectName, "ST_VWAP_Signal_") == 0)
        {
            datetime objectTime = (datetime)StringToInteger(StringSubstr(objectName, 15));
            
            if(objectTime < cutoffTime)
                ObjectDelete(0, objectName);
        }
    }
}

//+------------------------------------------------------------------+
//| Create dashboard |
//+------------------------------------------------------------------+
void CreateDashboard()
{
    if(g_dashboardCreated)
        return;
        
    // Create dashboard background
    string bgName = "ST_VWAP_Dashboard_BG";
    if(ObjectFind(0, bgName) < 0)
    {
        ObjectCreate(0, bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
        ObjectSetInteger(0, bgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, bgName, OBJPROP_XDISTANCE, DashboardX);
        ObjectSetInteger(0, bgName, OBJPROP_YDISTANCE, DashboardY);
        ObjectSetInteger(0, bgName, OBJPROP_XSIZE, 350);
        ObjectSetInteger(0, bgName, OBJPROP_YSIZE, 300);
        ObjectSetInteger(0, bgName, OBJPROP_BGCOLOR, DashboardBgColor);
        ObjectSetInteger(0, bgName, OBJPROP_BORDER_COLOR, DashboardBorderColor);
        ObjectSetInteger(0, bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
        ObjectSetInteger(0, bgName, OBJPROP_WIDTH, 1);
        ObjectSetInteger(0, bgName, OBJPROP_BACK, true);
        ObjectSetInteger(0, bgName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, bgName, OBJPROP_HIDDEN, true);
    }
    
    // Create dashboard title
    string titleName = "ST_VWAP_Dashboard_Title";
    if(ObjectFind(0, titleName) < 0)
    {
        ObjectCreate(0, titleName, OBJ_LABEL, 0, 0, 0);
        ObjectSetString(0, titleName, OBJPROP_TEXT, "Enhanced ST&VWAP Dashboard");
        ObjectSetString(0, titleName, OBJPROP_FONT, DashboardFont);
        ObjectSetInteger(0, titleName, OBJPROP_FONTSIZE, LabelFontSize + 2);
        ObjectSetInteger(0, titleName, OBJPROP_COLOR, clrYellow);
        ObjectSetInteger(0, titleName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, titleName, OBJPROP_XDISTANCE, DashboardX + 10);
        ObjectSetInteger(0, titleName, OBJPROP_YDISTANCE, DashboardY + 10);
        ObjectSetInteger(0, titleName, OBJPROP_BACK, false);
        ObjectSetInteger(0, titleName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, titleName, OBJPROP_HIDDEN, true);
    }
    
    // Create labels and values
    CreateDashboardLabels();
    
    g_dashboardCreated = true;
}

//+------------------------------------------------------------------+
//| Create dashboard labels |
//+------------------------------------------------------------------+
void CreateDashboardLabels()
{
    string labels[] = {
        // Current Market State
        "Current Price:", "SuperTrend:", "VWAP:", "Direction:",
        "", // Section separator
        // Signal Statistics  
        "Total Signals:", "Bullish:", "Bearish:", "Accepted:", "Rejected:",
        "", // Section separator
        // Performance
        "Win Rate:", "Last Signal:", "Last Signal Reached Points:", 
        "Average Blue Signals points are:", "Average white Signals points are:", 
        "Average of all Blue-white signals are:",
        "", // Section separator
        // Technical Info
        "Bars Processed:", "Session:", "Status:"
    };
    
    int yOffset = 35;
    int labelIndex = 0;
    int lineHeight = MathMax(LabelFontSize, ValueFontSize) + 4; // Adaptive line height
    
    for(int i = 0; i < ArraySize(labels); i++)
    {
        if(labels[i] == "") // Section separator
        {
            yOffset += 8; // Extra spacing between sections
            continue;
        }
        
        // Create label with independent positioning and font size
        string labelName = "ST_VWAP_Dashboard_Label_" + IntegerToString(labelIndex);
        if(ObjectFind(0, labelName) < 0)
        {
            ObjectCreate(0, labelName, OBJ_LABEL, 0, 0, 0);
            ObjectSetString(0, labelName, OBJPROP_TEXT, labels[i]);
            ObjectSetString(0, labelName, OBJPROP_FONT, DashboardFont);
            ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, LabelFontSize);
            ObjectSetInteger(0, labelName, OBJPROP_COLOR, DashboardTextColor);
            ObjectSetInteger(0, labelName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
            ObjectSetInteger(0, labelName, OBJPROP_XDISTANCE, DashboardX + LabelXOffset);
            ObjectSetInteger(0, labelName, OBJPROP_YDISTANCE, DashboardY + yOffset);
            ObjectSetInteger(0, labelName, OBJPROP_BACK, false);
            ObjectSetInteger(0, labelName, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, labelName, OBJPROP_HIDDEN, true);
        }
        
        // Create value with independent positioning and font size
        string valueName = "ST_VWAP_Dashboard_Value_" + IntegerToString(labelIndex);
        if(ObjectFind(0, valueName) < 0)
        {
            ObjectCreate(0, valueName, OBJ_LABEL, 0, 0, 0);
            ObjectSetString(0, valueName, OBJPROP_FONT, DashboardFont);
            ObjectSetInteger(0, valueName, OBJPROP_FONTSIZE, ValueFontSize);
            ObjectSetInteger(0, valueName, OBJPROP_COLOR, clrWhite);
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
//| Update dashboard with current data |
//+------------------------------------------------------------------+
void UpdateDashboard()
{
    if(!g_dashboardCreated) return;
    
    string directionText = "NO SIGNAL";
    color directionColor = clrGray;
    
    if(g_stats.dashboardState == STATE_BULLISH)
    {
        directionText = "BULLISH";
        directionColor = clrLimeGreen;
    }
    else if(g_stats.dashboardState == STATE_BEARISH)
    {
        directionText = "BEARISH";
        directionColor = clrTomato;
    }
    
    // Format win rate based on whether it's enabled
    string winRateText = EnableWinRate ? DoubleToString(g_stats.winRate, 1) + "%" : "N/A";
    color winRateColor = EnableWinRate ? ((g_stats.winRate >= 50) ? clrLimeGreen : clrTomato) : clrGray;
    
    // Format time window info
    string sessionText = TimeToString(g_stats.sessionStart, TIME_DATE|TIME_MINUTES);
    if(EnableTimeWindow)
    {
        sessionText += " • " + IntegerToString(StartHour) + ":" + 
                      StringFormat("%02d", StartMinute) + " → " + 
                      IntegerToString(EndHour) + ":" + 
                      StringFormat("%02d", EndMinute);
    }
    
    // Update values array
    string values[] = {
        // Current Market State
        DoubleToString(g_stats.currentPrice, _Digits),
        DoubleToString(g_stats.currentSuperTrend, _Digits),
        DoubleToString(g_stats.currentVWAP, _Digits),
        directionText,
        "", // Section separator
        // Signal Statistics
        IntegerToString(g_stats.totalSignals),
        IntegerToString(g_stats.bullishSignals),
        IntegerToString(g_stats.bearishSignals),
        IntegerToString(g_stats.acceptedSignals),
        IntegerToString(g_stats.rejectedSignals),
        "", // Section separator
        // Performance
        winRateText,
        g_stats.lastSignalTime,
        DoubleToString(g_stats.lastSignalReachedPoints, 1),
        DoubleToString(g_stats.avgBluePoints, 1),
        DoubleToString(g_stats.avgWhitePoints, 1),
        DoubleToString(g_stats.avgAllPoints, 1),
        "", // Section separator
        // Technical Info
        IntegerToString(g_stats.barsProcessed),
        sessionText,
        g_stats.windowStatus
    };
    
    color colors[] = {
        // Current Market State
        clrWhite, clrWhite, clrWhite, directionColor,
        clrWhite, // Section separator placeholder
        // Signal Statistics
        clrWhite, clrCyan, clrOrange, clrLimeGreen, clrTomato,
        clrWhite, // Section separator placeholder
        // Performance
        winRateColor, clrWhite, clrYellow, clrCyan, clrWhite, clrLightBlue,
        clrWhite, // Section separator placeholder
        // Technical Info
        clrWhite, clrWhite, g_stats.inTimeWindow ? clrLimeGreen : clrGray
    };
    
    int valueIndex = 0;
    for(int i = 0; i < ArraySize(values); i++)
    {
        if(values[i] == "") // Skip section separators
            continue;
            
        string valueName = "ST_VWAP_Dashboard_Value_" + IntegerToString(valueIndex);
        if(ObjectFind(0, valueName) >= 0)
        {
            ObjectSetString(0, valueName, OBJPROP_TEXT, values[i]);
            ObjectSetInteger(0, valueName, OBJPROP_COLOR, colors[i]);
        }
        
        valueIndex++;
    }
}

//+------------------------------------------------------------------+
//| Update idle dashboard (outside time window) |
//+------------------------------------------------------------------+
void UpdateIdleDashboard()
{
    if(!g_dashboardCreated) return;
    
    // Show minimal info when outside window
    string idleText = "OUTSIDE TRADING WINDOW";
    string windowInfo = IntegerToString(StartHour) + ":" + StringFormat("%02d", StartMinute) + 
                       " → " + IntegerToString(EndHour) + ":" + StringFormat("%02d", EndMinute);
    
    // Update only essential values
    string valueName = "ST_VWAP_Dashboard_Value_3"; // Direction field
    if(ObjectFind(0, valueName) >= 0)
    {
        ObjectSetString(0, valueName, OBJPROP_TEXT, idleText);
        ObjectSetInteger(0, valueName, OBJPROP_COLOR, clrGray);
    }
    
    valueName = "ST_VWAP_Dashboard_Value_17"; // Status field  
    if(ObjectFind(0, valueName) >= 0)
    {
        ObjectSetString(0, valueName, OBJPROP_TEXT, windowInfo);
        ObjectSetInteger(0, valueName, OBJPROP_COLOR, clrGray);
    }
}

//+------------------------------------------------------------------+
//| Cleanup dashboard |
//+------------------------------------------------------------------+
void CleanupDashboard()
{
    string prefixes[] = {"ST_VWAP_Dashboard_"};
    
    for(int p = 0; p < ArraySize(prefixes); p++)
    {
        for(int i = ObjectsTotal(0, 0) - 1; i >= 0; i--)
        {
            string objectName = ObjectName(0, i);
            
            if(StringFind(objectName, prefixes[p]) == 0)
                ObjectDelete(0, objectName);
        }
    }
    
    g_dashboardCreated = false;
}

//+------------------------------------------------------------------+
//| Cleanup visual objects |
//+------------------------------------------------------------------+
void CleanupVisualObjects()
{
    for(int i = ObjectsTotal(0, 0) - 1; i >= 0; i--)
    {
        string objectName = ObjectName(0, i);
        
        if(StringFind(objectName, "ST_VWAP_Signal_") == 0)
            ObjectDelete(0, objectName);
    }
}