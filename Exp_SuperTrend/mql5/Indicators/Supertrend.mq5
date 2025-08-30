//+------------------------------------------------------------------+
//|                                                   Supertrend.mq5 |
//|                   Copyright © 2005, Jason Robinson (jnrtrading). |
//|                     Enhanced Performance & Analytics Version     |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, Jason Robinson (jnrtrading)."
#property link      "http://www.jnrtrading.co.uk"
#property version   "2.01"
#property description "Enhanced SuperTrend Indicator with Performance Optimization & Analytics"

//---- indicator settings
#property indicator_chart_window
#property indicator_buffers 8
#property indicator_plots   4

//+-----------------------------------+
//|  Enhanced Plot Parameters         |
//+-----------------------------------+
//---- SuperTrend Up Line
#property indicator_type1 DRAW_LINE
#property indicator_color1 clrLime
#property indicator_style1 STYLE_SOLID
#property indicator_width1 2
#property indicator_label1  "Supertrend Up"

//---- SuperTrend Down Line
#property indicator_type2 DRAW_LINE
#property indicator_color2 clrRed
#property indicator_style2 STYLE_SOLID
#property indicator_width2 2
#property indicator_label2  "Supertrend Down"

//---- Buy Signal Arrows
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrDodgerBlue
#property indicator_style3  STYLE_SOLID
#property indicator_width3  4
#property indicator_label3  "Buy SuperTrend Signal"

//---- Sell Signal Arrows
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrOrangeRed
#property indicator_style4  STYLE_SOLID
#property indicator_width4  4
#property indicator_label4  "Sell SuperTrend Signal"

//+------------------------------------------------------------------+
//| Performance Optimization Constants                               |
//+------------------------------------------------------------------+
#define CALCULATION_CACHE_SIZE 500
#define UPDATE_FREQUENCY 10        // Update every N ticks for performance

//+------------------------------------------------------------------+
//| Enhanced Input Parameters                                        |
//+------------------------------------------------------------------+
input group "=== SUPERTREND SETTINGS ==="
input int CCIPeriod = 50;         // CCI Period
input int ATRPeriod = 5;          // ATR Period  
input int Level = 0;              // CCI Trigger Level
input int Shift = 0;              // Horizontal Shift

input group "=== PERFORMANCE SETTINGS ==="
input bool EnableOptimization = true;     // Enable Performance Optimization
input bool EnableAnalytics = true;        // Enable Signal Analytics
input int AnalysisDepth = 100;            // Bars for analysis
input bool ShowStatistics = false;        // Show Statistics in Comments

input group "=== VISUAL SETTINGS ==="
input bool EnableVisualAlerts = true;     // Enable Visual Signal Alerts
input color UpTrendColor = clrLime;       // Up trend color
input color DownTrendColor = clrRed;      // Down trend color
input color BuySignalColor = clrDodgerBlue;  // Buy signal color
input color SellSignalColor = clrOrangeRed;  // Sell signal color

input group "=== ALERT SETTINGS ==="
input bool EnableAlerts = false;          // Enable Alert System
input bool AlertOnSignal = true;          // Alert on new signals
input bool AlertSound = true;             // Play sound alerts
input string SoundFile = "alert.wav";     // Sound file name

//+------------------------------------------------------------------+
//| Enhanced Indicator Buffers                                       |
//+------------------------------------------------------------------+
double TrendUp[];       // SuperTrend up values
double TrendDown[];     // SuperTrend down values  
double SignUp[];        // Buy signal arrows
double SignDown[];      // Sell signal arrows

// Hidden calculation buffers for optimization
double CCIBuffer[];     // CCI calculation buffer
double ATRBuffer[];     // ATR calculation buffer
double TrendState[];    // Trend state buffer (1=up, -1=down)
double SignalBuffer[];  // Signal detection buffer

//+------------------------------------------------------------------+
//| Performance & Analytics Variables                                |
//+------------------------------------------------------------------+
int min_rates_total;
int CCI_Handle, ATR_Handle;

// Performance optimization variables
static int g_lastCalculated = 0;
static datetime g_lastUpdate = 0;
static int g_updateCounter = 0;

// Analytics variables
struct SignalStats
{
   int totalSignals;
   int buySignals;
   int sellSignals;
   datetime lastSignalTime;
   int signalBar;
   double lastSignalPrice;
   
   void Init()
   {
      totalSignals = 0;
      buySignals = 0;
      sellSignals = 0;
      lastSignalTime = 0;
      signalBar = 0;
      lastSignalPrice = 0;
   }
};

SignalStats g_signalStats;

// Caching for performance
static double g_priceCache[];
static datetime g_timeCache[];
static int g_cacheSize = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
int OnInit()
{
   // Validate input parameters
   if(CCIPeriod <= 0 || ATRPeriod <= 0)
   {
      Print("ERROR: Invalid input parameters");
      return INIT_PARAMETERS_INCORRECT;
   }
   
   // Initialize calculation requirements
   min_rates_total = MathMax(CCIPeriod, ATRPeriod) + 10;
   
   // Get indicator handles
   CCI_Handle = iCCI(NULL, 0, CCIPeriod, PRICE_TYPICAL);
   if(CCI_Handle == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create CCI indicator handle");
      return INIT_FAILED;
   }
   
   ATR_Handle = iATR(NULL, 0, ATRPeriod);
   if(ATR_Handle == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create ATR indicator handle");
      IndicatorRelease(CCI_Handle);
      return INIT_FAILED;
   }
   
   // Set up indicator buffers
   SetIndexBuffer(0, TrendUp, INDICATOR_DATA);
   SetIndexBuffer(1, TrendDown, INDICATOR_DATA);
   SetIndexBuffer(2, SignUp, INDICATOR_DATA);
   SetIndexBuffer(3, SignDown, INDICATOR_DATA);
   
   // Hidden calculation buffers
   SetIndexBuffer(4, CCIBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(5, ATRBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(6, TrendState, INDICATOR_CALCULATIONS);
   SetIndexBuffer(7, SignalBuffer, INDICATOR_CALCULATIONS);
   
   // Configure main trend plots
   PlotIndexSetInteger(0, PLOT_SHIFT, Shift);
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, min_rates_total);
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, UpTrendColor);
   
   PlotIndexSetInteger(1, PLOT_SHIFT, Shift);
   PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, min_rates_total);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(1, PLOT_LINE_COLOR, DownTrendColor);
   
   // Configure signal arrows
   PlotIndexSetInteger(2, PLOT_SHIFT, Shift);
   PlotIndexSetInteger(2, PLOT_DRAW_BEGIN, min_rates_total);
   PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(2, PLOT_ARROW, 233); // Up arrow
   PlotIndexSetInteger(2, PLOT_LINE_COLOR, BuySignalColor);
   
   PlotIndexSetInteger(3, PLOT_SHIFT, Shift);
   PlotIndexSetInteger(3, PLOT_DRAW_BEGIN, min_rates_total);
   PlotIndexSetDouble(3, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(3, PLOT_ARROW, 234); // Down arrow
   PlotIndexSetInteger(3, PLOT_LINE_COLOR, SellSignalColor);
   
   // Initialize arrays as time series
   ArraySetAsSeries(TrendUp, true);
   ArraySetAsSeries(TrendDown, true);
   ArraySetAsSeries(SignUp, true);
   ArraySetAsSeries(SignDown, true);
   ArraySetAsSeries(CCIBuffer, true);
   ArraySetAsSeries(ATRBuffer, true);
   ArraySetAsSeries(TrendState, true);
   ArraySetAsSeries(SignalBuffer, true);
   
   // Initialize performance optimization
   if(EnableOptimization)
   {
      InitializeOptimization();
   }
   
   // Initialize analytics
   if(EnableAnalytics)
   {
      InitializeAnalytics();
   }
   
   // Set indicator name
   string shortname = StringFormat("Enhanced SuperTrend (CCI:%d, ATR:%d, Shift:%d)", 
                                  CCIPeriod, ATRPeriod, Shift);
   IndicatorSetString(INDICATOR_SHORTNAME, shortname);
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits + 1);
   
   Print("Enhanced SuperTrend indicator initialized successfully");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Release indicator handles
   if(CCI_Handle != INVALID_HANDLE)
      IndicatorRelease(CCI_Handle);
   
   if(ATR_Handle != INVALID_HANDLE)
      IndicatorRelease(ATR_Handle);
   
   // Print final analytics if enabled
   if(EnableAnalytics && ShowStatistics)
   {
      PrintAnalytics();
   }
   
   // Clean up optimization data
   if(EnableOptimization)
   {
      CleanupOptimization();
   }
   
   Print("Enhanced SuperTrend indicator deinitialized");
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double& high[],
                const double& low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   // Check for sufficient data
   if(rates_total < min_rates_total)
      return 0;
   
   // Check for indicator data availability
   if(BarsCalculated(CCI_Handle) < rates_total || 
      BarsCalculated(ATR_Handle) < rates_total)
      return 0;
   
   // Performance optimization: skip calculation on frequent updates
   if(EnableOptimization && !ShouldRecalculate(rates_total, prev_calculated))
      return prev_calculated;
   
   // Set array indexing
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(time, true);
   ArraySetAsSeries(close, true);
   
   // Determine calculation range
   int limit, to_copy;
   if(prev_calculated > rates_total || prev_calculated <= 0)
   {
      limit = rates_total - min_rates_total;
   }
   else
   {
      limit = rates_total - prev_calculated;
   }
   
   to_copy = limit + 1;
   
   // Copy indicator data with error checking
   if(!CopyIndicatorData(to_copy))
      return 0;
   
   // Main calculation loop with optimization
   CalculateSuperTrend(limit, high, low, time, close);
   
   // Update performance metrics
   if(EnableOptimization)
   {
      UpdatePerformanceMetrics(rates_total, prev_calculated);
   }
   
   // Update analytics
   if(EnableAnalytics)
   {
      UpdateAnalytics(limit, time, close);
   }
   
   // Update statistics display
   if(ShowStatistics && EnableAnalytics)
   {
      UpdateStatisticsDisplay();
   }
   
   return rates_total;
}

//+------------------------------------------------------------------+
//| Performance Optimization Functions                               |
//+------------------------------------------------------------------+
void InitializeOptimization()
{
   // Initialize cache arrays
   ArrayResize(g_priceCache, CALCULATION_CACHE_SIZE);
   ArrayResize(g_timeCache, CALCULATION_CACHE_SIZE);
   g_cacheSize = 0;
   
   g_lastCalculated = 0;
   g_lastUpdate = TimeCurrent();
   g_updateCounter = 0;
}

void CleanupOptimization()
{
   ArrayResize(g_priceCache, 0);
   ArrayResize(g_timeCache, 0);
   g_cacheSize = 0;
}

bool ShouldRecalculate(int rates_total, int prev_calculated)
{
   g_updateCounter++;
   
   // Force recalculation every N updates for accuracy
   if(g_updateCounter >= UPDATE_FREQUENCY)
   {
      g_updateCounter = 0;
      return true;
   }
   
   // Always recalculate on new bars
   if(prev_calculated != g_lastCalculated)
   {
      g_lastCalculated = prev_calculated;
      return true;
   }
   
   // Check for significant time passage
   datetime currentTime = TimeCurrent();
   if(currentTime > g_lastUpdate + 60) // 1 minute
   {
      g_lastUpdate = currentTime;
      return true;
   }
   
   return false;
}

void UpdatePerformanceMetrics(int rates_total, int prev_calculated)
{
   // Cache recent price data for performance
   int cacheIndex = g_cacheSize % CALCULATION_CACHE_SIZE;
   
   if(rates_total > 0)
   {
      g_priceCache[cacheIndex] = iClose(_Symbol, PERIOD_CURRENT, 0);
      g_timeCache[cacheIndex] = TimeCurrent();
      
      if(g_cacheSize < CALCULATION_CACHE_SIZE)
         g_cacheSize++;
   }
}

//+------------------------------------------------------------------+
//| Enhanced Calculation Functions                                   |
//+------------------------------------------------------------------+
bool CopyIndicatorData(int to_copy)
{
   // Copy ATR data with error handling
   if(CopyBuffer(ATR_Handle, 0, 0, to_copy, ATRBuffer) <= 0)
   {
      Print("ERROR: Failed to copy ATR data");
      return false;
   }
   
   // Copy CCI data with error handling
   if(CopyBuffer(CCI_Handle, 0, 0, to_copy + 1, CCIBuffer) <= 0)
   {
      Print("ERROR: Failed to copy CCI data");
      return false;
   }
   
   return true;
}

void CalculateSuperTrend(int limit, const double &high[], const double &low[], 
                        const datetime &time[], const double &close[])
{
   // Enhanced SuperTrend calculation with optimization
   for(int bar = limit; bar >= 0 && !IsStopped(); bar++)
   {
      // Initialize values
      TrendUp[bar] = 0.0;
      TrendDown[bar] = 0.0;
      SignUp[bar] = 0.0;
      SignDown[bar] = 0.0;
      TrendState[bar] = 0.0;
      SignalBuffer[bar] = 0.0;
      
      // Calculate SuperTrend levels
      CalculateTrendLevels(bar, high, low);
      
      // Detect and process signals
      ProcessSignalDetection(bar, time, close);
   }
}

void CalculateTrendLevels(int bar, const double &high[], const double &low[])
{
   // SuperTrend logic based on CCI and ATR
   if(CCIBuffer[bar] >= Level && CCIBuffer[bar + 1] < Level)
   {
      TrendUp[bar] = TrendDown[bar + 1];
      TrendState[bar] = 1; // Bullish trend
   }
   
   if(CCIBuffer[bar] <= Level && CCIBuffer[bar + 1] > Level)
   {
      TrendDown[bar] = TrendUp[bar + 1];
      TrendState[bar] = -1; // Bearish trend
   }
   
   if(CCIBuffer[bar] > Level)
   {
      double newTrendUp = low[bar] - ATRBuffer[bar];
      TrendUp[bar] = newTrendUp;
      
      // Maintain trend continuity
      if(newTrendUp < TrendUp[bar + 1] && CCIBuffer[bar + 1] >= Level)
         TrendUp[bar] = TrendUp[bar + 1];
      
      TrendState[bar] = 1;
   }
   
   if(CCIBuffer[bar] < Level)
   {
      double newTrendDown = high[bar] + ATRBuffer[bar];
      TrendDown[bar] = newTrendDown;
      
      // Maintain trend continuity
      if(newTrendDown > TrendDown[bar + 1] && CCIBuffer[bar + 1] <= Level)
         TrendDown[bar] = TrendDown[bar + 1];
      
      TrendState[bar] = -1;
   }
}

void ProcessSignalDetection(int bar, const datetime &time[], const double &close[])
{
   // Enhanced signal detection with validation
   bool buySignal = false;
   bool sellSignal = false;
   
   // Detect trend changes for signals
   if(bar > 0)
   {
      // Buy signal: transition from bearish to bullish
      if(TrendDown[bar + 1] != 0.0 && TrendUp[bar] != 0.0)
      {
         SignUp[bar] = TrendUp[bar];
         SignalBuffer[bar] = 1; // Buy signal
         buySignal = true;
      }
      
      // Sell signal: transition from bullish to bearish
      if(TrendUp[bar + 1] != 0.0 && TrendDown[bar] != 0.0)
      {
         SignDown[bar] = TrendDown[bar];
         SignalBuffer[bar] = -1; // Sell signal
         sellSignal = true;
      }
   }
   
   // Process signals with analytics and alerts
   if(buySignal || sellSignal)
   {
      ProcessNewSignal(bar, time[bar], close[bar], buySignal ? 1 : -1);
   }
}

void ProcessNewSignal(int bar, datetime signalTime, double signalPrice, int signalType)
{
   // Update analytics
   if(EnableAnalytics)
   {
      UpdateSignalAnalytics(signalType, signalTime, signalPrice, bar);
   }
   
   // Trigger alerts
   if(EnableAlerts && AlertOnSignal)
   {
      TriggerSignalAlert(signalType, signalPrice, signalTime);
   }
   
   // Visual feedback
   if(EnableVisualAlerts)
   {
      ShowVisualSignalFeedback(signalType, signalPrice, signalTime);
   }
}

//+------------------------------------------------------------------+
//| Analytics Functions                                              |
//+------------------------------------------------------------------+
void InitializeAnalytics()
{
   g_signalStats.Init();
   Print("Signal analytics initialized");
}

void UpdateAnalytics(int limit, const datetime &time[], const double &close[])
{
   // Update signal statistics for recent bars
   for(int i = MathMin(limit, AnalysisDepth); i >= 0; i--)
   {
      if(SignalBuffer[i] != 0)
      {
         // Signal found, already processed in main calculation
         // Additional analytics can be added here
      }
   }
}

void UpdateSignalAnalytics(int signalType, datetime signalTime, double signalPrice, int signalBar)
{
   g_signalStats.totalSignals++;
   g_signalStats.lastSignalTime = signalTime;
   g_signalStats.lastSignalPrice = signalPrice;
   g_signalStats.signalBar = signalBar;
   
   if(signalType > 0)
      g_signalStats.buySignals++;
   else
      g_signalStats.sellSignals++;
   
   // Log signal for analysis
   if(ShowStatistics)
   {
      string signalText = (signalType > 0) ? "BUY" : "SELL";
      Print("SuperTrend Signal: ", signalText, " at ", DoubleToString(signalPrice, _Digits), 
            " on ", TimeToString(signalTime));
   }
}

void PrintAnalytics()
{
   Print("=== SuperTrend Analytics Summary ===");
   Print("Total Signals: ", g_signalStats.totalSignals);
   Print("Buy Signals: ", g_signalStats.buySignals);
   Print("Sell Signals: ", g_signalStats.sellSignals);
   
   if(g_signalStats.totalSignals > 0)
   {
      double buyPercent = ((double)g_signalStats.buySignals / g_signalStats.totalSignals) * 100.0;
      Print("Buy Signal %: ", DoubleToString(buyPercent, 1), "%");
   }
   
   Print("Last Signal: ", TimeToString(g_signalStats.lastSignalTime), 
         " Price: ", DoubleToString(g_signalStats.lastSignalPrice, _Digits));
   Print("==================================");
}

void UpdateStatisticsDisplay()
{
   if(!ShowStatistics || g_signalStats.totalSignals == 0)
      return;
   
   string statsText = StringFormat("SuperTrend Stats | Total: %d | Buy: %d | Sell: %d | Last: %s", 
                                  g_signalStats.totalSignals, 
                                  g_signalStats.buySignals,
                                  g_signalStats.sellSignals,
                                  TimeToString(g_signalStats.lastSignalTime, TIME_MINUTES));
   
   Comment(statsText);
}

//+------------------------------------------------------------------+
//| Alert Functions                                                  |
//+------------------------------------------------------------------+
void TriggerSignalAlert(int signalType, double price, datetime time)
{
   string signalText = (signalType > 0) ? "BUY" : "SELL";
   string alertMessage = StringFormat("SuperTrend %s Signal at %.5f", signalText, price);
   
   // Popup alert
   Alert(alertMessage);
   
   // Sound alert
   if(AlertSound && SoundFile != "")
   {
      PlaySound(SoundFile);
   }
   
   // Print to log
   Print("ALERT: ", alertMessage, " at ", TimeToString(time));
}

void ShowVisualSignalFeedback(int signalType, double price, datetime time)
{
   // Create temporary visual object for signal feedback
   string objectName = StringFormat("ST_Signal_%lld", time);
   color signalColor = (signalType > 0) ? BuySignalColor : SellSignalColor;
   
   // This could create chart objects for enhanced visual feedback
   // Implementation depends on specific requirements
   
   if(ShowStatistics)
   {
      Print("Visual feedback: ", (signalType > 0 ? "BUY" : "SELL"), " signal at ", 
            DoubleToString(price, _Digits));
   }
}

//+------------------------------------------------------------------+
//| Utility Functions                                                |
//+------------------------------------------------------------------+
string GetIndicatorStatus()
{
   string status = "Enhanced SuperTrend Status:\n";
   status += StringFormat("CCI Period: %d | ATR Period: %d\n", CCIPeriod, ATRPeriod);
   status += StringFormat("Optimization: %s | Analytics: %s\n", 
                         EnableOptimization ? "ON" : "OFF",
                         EnableAnalytics ? "ON" : "OFF");
   
   if(EnableAnalytics)
   {
      status += StringFormat("Signals: %d (Buy: %d, Sell: %d)\n",
                           g_signalStats.totalSignals,
                           g_signalStats.buySignals,
                           g_signalStats.sellSignals);
   }
   
   return status;
}

//+------------------------------------------------------------------+