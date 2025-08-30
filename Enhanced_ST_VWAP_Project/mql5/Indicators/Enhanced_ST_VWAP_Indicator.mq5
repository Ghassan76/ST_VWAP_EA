//+------------------------------------------------------------------+
//|                                                   ST_VWAP.mq5    |
//|   SuperTrend with VWAP filter and on-chart statistics dashboard  |
//|   Generates blue (buy), white (sell) and gray (rejected) arrows  |
//+------------------------------------------------------------------+
#property copyright "OpenAI"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_plots 5
#property indicator_buffers 7

#property indicator_type1   DRAW_COLOR_LINE        // SuperTrend
#property indicator_color1  clrGreen, clrRed
#property indicator_width1  2

#property indicator_type2   DRAW_LINE              // VWAP
#property indicator_color2  clrYellow
#property indicator_width2  1

#property indicator_type3   DRAW_ARROW             // Buy signals
#property indicator_color3  clrBlue
#property indicator_width3  2

#property indicator_type4   DRAW_ARROW             // Sell signals
#property indicator_color4  clrWhite
#property indicator_width4  2

#property indicator_type5   DRAW_ARROW             // Rejected signals
#property indicator_color5  clrGray
#property indicator_width5  2

//--- input parameters -------------------------------------------------
input group "=== SuperTrend Settings ==="
input int              ATRPeriod          = 22;
input double           Multiplier         = 3.0;
input ENUM_APPLIED_PRICE SourcePrice      = PRICE_MEDIAN;
input bool             TakeWicksIntoAccount = true;

input group "=== VWAP Settings ==="
input ENUM_APPLIED_PRICE VWAPPriceMethod  = PRICE_TYPICAL;
input double           MinVolumeThreshold = 1.0;
input bool             ResetVWAPDaily     = true;

input group "=== VWAP Filter Settings ==="
input bool             EnableVWAPFilter   = true;
input bool             ShowVWAPLine       = true;
input double           MinPointsFromVWAP  = 0.0;   // minimum distance in points

input group "=== Dashboard Settings ==="
input bool             ShowDashboard      = true;

//--- indicator buffers ------------------------------------------------
double STBuffer[];            // SuperTrend line
double STColorBuffer[];       // SuperTrend color indexes
double VWAPBuffer[];          // VWAP values

double BuyArrowBuffer[];      // accepted buy arrows
double SellArrowBuffer[];     // accepted sell arrows
double RejectArrowBuffer[];   // rejected arrows

double SignalBuffer[];        // 1 buy, -1 sell, 0 none

int    atrHandle;             // handle for ATR

datetime g_currentDay = 0;    // VWAP helpers
double g_sumPV = 0.0;
double g_sumV  = 0.0;

int    g_totalSignals = 0;    // dashboard stats
int    g_acceptedSignals = 0;
int    g_rejectedSignals = 0;
int    g_bullishSignals = 0;
int    g_bearishSignals = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   atrHandle = iATR(NULL,0,ATRPeriod);
   if(atrHandle==INVALID_HANDLE)
      return(INIT_FAILED);

   SetIndexBuffer(0,STBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,STColorBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,VWAPBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,BuyArrowBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,SellArrowBuffer,INDICATOR_DATA);
   SetIndexBuffer(5,RejectArrowBuffer,INDICATOR_DATA);
   SetIndexBuffer(6,SignalBuffer,INDICATOR_CALCULATIONS);

   PlotIndexSetInteger(2,PLOT_ARROW,233); // up arrow
   PlotIndexSetInteger(3,PLOT_ARROW,234); // down arrow
   PlotIndexSetInteger(4,PLOT_ARROW,159); // small dot for rejected

   ArraySetAsSeries(STBuffer,false);
   ArraySetAsSeries(STColorBuffer,false);
   ArraySetAsSeries(VWAPBuffer,false);
   ArraySetAsSeries(BuyArrowBuffer,false);
   ArraySetAsSeries(SellArrowBuffer,false);
   ArraySetAsSeries(RejectArrowBuffer,false);
   ArraySetAsSeries(SignalBuffer,false);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration                                        |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   if(rates_total<=ATRPeriod)
      return(0);

   int start = prev_calculated>0 ? prev_calculated-1 : ATRPeriod;

   double atr[];
   ArraySetAsSeries(atr,false);

   for(int i=start;i<rates_total;i++)
   {
      //--- reset arrow buffers
      BuyArrowBuffer[i]    = EMPTY_VALUE;
      SellArrowBuffer[i]   = EMPTY_VALUE;
      RejectArrowBuffer[i] = EMPTY_VALUE;
      SignalBuffer[i]      = 0.0;

      //--- VWAP calculation
      MqlDateTime t; TimeToStruct(time[i],t);
      datetime day = StringToTime(StringFormat("%04d.%02d.%02d",t.year,t.mon,t.day));
      if(ResetVWAPDaily && day!=g_currentDay)
      {
         g_currentDay = day; g_sumPV=0.0; g_sumV=0.0;
      }
      double price;
      switch(VWAPPriceMethod)
      {
         case PRICE_CLOSE: price=close[i]; break;
         case PRICE_OPEN:  price=open[i];  break;
         case PRICE_HIGH:  price=high[i];  break;
         case PRICE_LOW:   price=low[i];   break;
         case PRICE_MEDIAN: price=(high[i]+low[i])/2.0; break;
         case PRICE_TYPICAL: price=(high[i]+low[i]+close[i])/3.0; break;
         default: price=(high[i]+low[i]+close[i]+close[i])/4.0; break;
      }
      double vol = (double)tick_volume[i];
      if(vol<MinVolumeThreshold) vol=MinVolumeThreshold;
      g_sumPV += price*vol; g_sumV += vol;
      VWAPBuffer[i] = g_sumV>0? g_sumPV/g_sumV : price;

      //--- ATR
      if(CopyBuffer(atrHandle,0,rates_total-i-1,1,atr)<=0)
         atr[0]=0.0;
      double atrValue = atr[0];
      if(atrValue<=0) atrValue = price*0.01;

      //--- price source
      double src;
      switch(SourcePrice)
      {
         case PRICE_CLOSE:   src=close[i]; break;
         case PRICE_OPEN:    src=open[i];  break;
         case PRICE_HIGH:    src=high[i];  break;
         case PRICE_LOW:     src=low[i];   break;
         case PRICE_MEDIAN:  src=(high[i]+low[i])/2.0; break;
         case PRICE_TYPICAL: src=(high[i]+low[i]+close[i])/3.0; break;
         default:            src=(high[i]+low[i]+close[i]+close[i])/4.0; break;
      }

      double highPrice = TakeWicksIntoAccount ? high[i] : MathMax(open[i],close[i]);
      double lowPrice  = TakeWicksIntoAccount ? low[i]  : MathMin(open[i],close[i]);

      double longStop  = src - Multiplier*atrValue;
      double shortStop = src + Multiplier*atrValue;

      int direction = 1;
      if(i>0)
      {
         double prevST = STBuffer[i-1];
         int prevDir   = (int)STColorBuffer[i-1]==0?1:-1;
         longStop  = prevDir==1 ? MathMax(longStop,prevST) : longStop;
         shortStop = prevDir==-1? MathMin(shortStop,prevST): shortStop;
         if(prevDir==1)
         {
            direction = (lowPrice<prevST)?-1:1;
         }
         else
         {
            direction = (highPrice>prevST)?1:-1;
         }
         // signal generation when direction changes
         if(direction!=prevDir)
         {
            bool vwapOK = true;
            if(EnableVWAPFilter)
            {
               double distPoints = MathAbs(close[i]-VWAPBuffer[i])/_Point;
               if(direction==1) vwapOK = close[i] > VWAPBuffer[i] && distPoints>=MinPointsFromVWAP;
               else             vwapOK = close[i] < VWAPBuffer[i] && distPoints>=MinPointsFromVWAP;
            }
            g_totalSignals++;
            if(vwapOK)
            {
               g_acceptedSignals++;
               if(direction==1){
                  g_bullishSignals++;
                  BuyArrowBuffer[i] = low[i];
                  SignalBuffer[i] = 1.0;
               }else{
                  g_bearishSignals++;
                  SellArrowBuffer[i] = high[i];
                  SignalBuffer[i] = -1.0;
               }
            }
            else
            {
               g_rejectedSignals++;
               RejectArrowBuffer[i] = (direction==1?low[i]:high[i]);
            }
         }
      }

      STBuffer[i]      = (direction==1? longStop : shortStop);
      STColorBuffer[i] = (direction==1?0:1);
   }

   if(!ShowVWAPLine)
      PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_NONE);

   if(ShowDashboard && rates_total>0)
      ShowDashboardInfo(rates_total-1);

   return(rates_total);
}

//+------------------------------------------------------------------+
//| Display dashboard using Comment                                  |
//+------------------------------------------------------------------+
void ShowDashboardInfo(int lastBar)
{
   string txt = StringFormat("ST %.2f  VWAP %.2f\nSignals %d  Accepted %d  Rejected %d\nBullish %d  Bearish %d",\
                STBuffer[lastBar],VWAPBuffer[lastBar],g_totalSignals,g_acceptedSignals,g_rejectedSignals,g_bullishSignals,g_bearishSignals);
   Comment(txt);
}

//+------------------------------------------------------------------+
