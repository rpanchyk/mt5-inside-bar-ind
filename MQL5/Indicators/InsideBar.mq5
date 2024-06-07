//+------------------------------------------------------------------+
//|                                                    InsideBar.mq5 |
//|                                         Copyright 2024, rpanchyk |
//|                                      https://github.com/rpanchyk |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, rpanchyk"
#property link      "https://github.com/rpanchyk"
#property version   "1.00"
#property description "Indicator shows inside bars"
#property description ""
#property description "Used documentation:"
#property description "- https://www.mql5.com/en/code/1349"
#property description "- https://www.mql5.com/en/docs/customind/indicators_examples/draw_color_candles"

#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots 1

#property indicator_type1 DRAW_COLOR_CANDLES
#property indicator_label1 "Open;High;Low;Close"
#property indicator_width1 3

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class HLBar
  {
public:
                     HLBar(double high, double low) : m_High(high), m_Low(low) {}
   double            GetHigh() { return m_High; }
   double            GetLow() { return m_Low; }
   //bool              IsGreaterOrEqual(double high, double low) { return m_High >= high && m_Low <= low; }
   //bool              IsInsideBar(HLBar bar) { return bar-> >= high && m_Low <= low; }
private:
   double            m_High;
   double            m_Low;
  };

// buffers
double InsideBarOpenBuf[], InsideBarHighBuf[], InsideBarLowBuf[], InsideBarCloseBuf[]; // Buffers for data
double InsideBarLineColorBuf[]; // Buffer for color indexes

// config
input group "Section :: Main";
input color InpUpBarColor = clrGray;
input color InpDownBarColor = clrGray;

input group "Section :: Dev";
input bool InpDebugEnabled = false; // Endble debug (verbose logging)

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print("InsideBar indicator initialization started");

   ArrayInitialize(InsideBarOpenBuf, EMPTY_VALUE);
   ArrayInitialize(InsideBarHighBuf, EMPTY_VALUE);
   ArrayInitialize(InsideBarLowBuf, EMPTY_VALUE);
   ArrayInitialize(InsideBarCloseBuf, EMPTY_VALUE);
   ArrayInitialize(InsideBarLineColorBuf, EMPTY_VALUE);

   ArraySetAsSeries(InsideBarOpenBuf, true);
   ArraySetAsSeries(InsideBarHighBuf, true);
   ArraySetAsSeries(InsideBarLowBuf, true);
   ArraySetAsSeries(InsideBarCloseBuf, true);
   ArraySetAsSeries(InsideBarLineColorBuf, true);

   SetIndexBuffer(0, InsideBarOpenBuf, INDICATOR_DATA);
   SetIndexBuffer(1, InsideBarHighBuf, INDICATOR_DATA);
   SetIndexBuffer(2, InsideBarLowBuf, INDICATOR_DATA);
   SetIndexBuffer(3, InsideBarCloseBuf, INDICATOR_DATA);
   SetIndexBuffer(4, InsideBarLineColorBuf, INDICATOR_COLOR_INDEX);

   PlotIndexSetInteger(0, PLOT_COLOR_INDEXES, 2);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 0, InpUpBarColor);   // 0th index color
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 1, InpDownBarColor); // 1st index color

   IndicatorSetString(INDICATOR_SHORTNAME, "InsideBar indicator");

   Print("InsideBar indicator initialization finished");
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Print("InsideBar indicator deinitialization started");

   ArrayFree(InsideBarOpenBuf);
   ArrayFree(InsideBarHighBuf);
   ArrayFree(InsideBarLowBuf);
   ArrayFree(InsideBarCloseBuf);
   ArrayFree(InsideBarLineColorBuf);

   Print("InsideBar indicator deinitialization finished");
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
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
   if(rates_total == prev_calculated)
     {
      return rates_total;
     }

   ArraySetAsSeries(open, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);

   if(InpDebugEnabled)
     {
      PrintFormat("RatesTotal: %i, PrevCalculated: %i", rates_total, prev_calculated);
     }

   HLBar *prevBar = NULL;
   HLBar *currBar = NULL;
   for(int i = rates_total - prev_calculated - 2; i > 0; i--)
     {
      InsideBarOpenBuf[i] = open[i];
      InsideBarHighBuf[i] = high[i];
      InsideBarLowBuf[i] = low[i];
      InsideBarCloseBuf[i] = close[i];

      //HLBar prevBar(high[i + 1], low[i + 1]);
      //HLBar currBar(high[i], low[i]);

      prevBar = prevBar != NULL ? prevBar : new HLBar(high[i + 1], low[i + 1]);
      currBar = new HLBar(high[i], low[i]);

      if(isInsideBar(prevBar, currBar))
        {
         InsideBarLineColorBuf[i] = open[i] <= close[i] ? 0 : 1;
        }
      else
        {
         InsideBarLineColorBuf[i] = -1;

         prevBar = NULL;
        }

      //bool currInsideBar = isInsideBar(i, open, high, low, close);
      //InsideBarLineColorBuf[i] = currInsideBar ? open[i] <= close[i] ? 0 : 1 : -1;


     }
   delete prevBar;
   delete currBar;

   return rates_total; // set prev_calculated on next call
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//bool isInsideBar(int i, const double &open[], const double &high[], const double &low[], const double &close[])
//  {
//   double prevHigh = high[i + 1];
//   double prevLow = low[i + 1];
//   double currHigh = high[i];
//   double currLow = low[i];
//
//   return prevHigh >= currHigh && prevLow <= currLow;
//  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isInsideBar(HLBar *prevBar, HLBar *currBar)
  {
   return prevBar.GetHigh() >= currBar.GetHigh() && prevBar.GetLow() <= currBar.GetLow();
  }
//+------------------------------------------------------------------+
