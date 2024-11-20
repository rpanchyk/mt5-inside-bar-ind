//+------------------------------------------------------------------+
//|                                                    InsideBar.mq5 |
//|                                         Copyright 2024, rpanchyk |
//|                                      https://github.com/rpanchyk |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2024, rpanchyk"
#property link        "https://github.com/rpanchyk"
#property version     "1.03"
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
//| Model for Bar keeping OHLC prices at Time                        |
//+------------------------------------------------------------------+
class HLBar
  {
public:
                     HLBar() : m_Time(0), m_Open(0), m_High(0), m_Low(0), m_Close(0) {}
   datetime          GetTime() { return m_Time; }
   double            GetOpen() { return m_Open; }
   double            GetHigh() { return m_High; }
   double            GetLow() { return m_Low; }
   double            GetClose() { return m_Close; }
   void              Set(datetime time, double open, double high, double low, double close) { m_Time = time; m_Open = open; m_High = high; m_Low = low; m_Close = close; }
private:
   datetime          m_Time;
   double            m_Open;
   double            m_High;
   double            m_Low;
   double            m_Close;
  };

enum ENUM_FINDBY_TYPE
  {
   FINDBY_HL, // High/Low (wicks)
   FINDBY_OC // Open/Close (body)
  };

enum ENUM_ALERT_TYPE
  {
   NO_ALERT, // None
   EACH_BAR_ALERT, // On each inside bar
   FIRST_BAR_ALERT // On first inside bar only
  };

// buffers
double InsideBarOpenBuf[], InsideBarHighBuf[], InsideBarLowBuf[], InsideBarCloseBuf[]; // Buffers for data
double InsideBarLineColorBuf[]; // Buffer for color indexes

// config
input group "Section :: Main";
input ENUM_FINDBY_TYPE InpFindByType = FINDBY_HL; // Find by
input bool InpMarkFirstBarOnly = false; // Mark first inside bar only in sequence
input ENUM_ALERT_TYPE InpAlertType = NO_ALERT; // Alert type

input group "Section :: Style";
input color InpUpBarColor = clrSilver; // Color of bullish inside bar
input color InpDownBarColor = clrSilver; // Color of bearish inside bar

input group "Section :: Dev";
input bool InpDebugEnabled = false; // Enable debug (verbose logging)

// runtime
HLBar prevBar;
HLBar currBar;

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
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 0, InpUpBarColor); // 0th index color
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 1, InpDownBarColor); // 1st index color

   IndicatorSetString(INDICATOR_SHORTNAME, "InsideBar indicator");

   prevBar.Set(0, 0, 0, 0, 0);
   currBar.Set(0, 0, 0, 0, 0);

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

   ArraySetAsSeries(time, true);
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);

   int limit = (int) MathMin(rates_total, rates_total - prev_calculated + 2);
   if(InpDebugEnabled)
     {
      PrintFormat("RatesTotal: %i, PrevCalculated: %i, Limit: %i", rates_total, prev_calculated, limit);
     }

   InsideBarOpenBuf[0] = -1;
   InsideBarHighBuf[0] = -1;
   InsideBarLowBuf[0] = -1;
   InsideBarCloseBuf[0] = -1;
   InsideBarLineColorBuf[0] = -1;

   for(int i = limit - 2; i > 0; i--)
     {
      InsideBarOpenBuf[i] = open[i];
      InsideBarHighBuf[i] = high[i];
      InsideBarLowBuf[i] = low[i];
      InsideBarCloseBuf[i] = close[i];

      currBar.Set(time[i], open[i], high[i], low[i], close[i]);

      if(IsInsideBar())
        {
         string message = "New inside bar at " + TimeToString(time[i]);
         if(InpDebugEnabled)
           {
            Print(message);
           }

         if(InpMarkFirstBarOnly)
           {
            bool isFirstInsideBar = time[i] - prevBar.GetTime() == PeriodSeconds(PERIOD_CURRENT);
            InsideBarLineColorBuf[i] = isFirstInsideBar ? open[i] <= close[i] ? 0 : 1 : -1;
           }
         else
           {
            InsideBarLineColorBuf[i] = open[i] <= close[i] ? 0 : 1;
           }

         if(i == 1 && IsAlertEnabled(time[i])) // Handle alert on last bar only
           {
            if(time[i] != ReadLastInsideBarTime()) // Don't flood with the same alerts
              {
               Alert(message);
               WriteLastInsideBarTime(time[i]);
              }
           }
        }
      else
        {
         InsideBarLineColorBuf[i] = -1;

         prevBar.Set(time[i], open[i], high[i], low[i], close[i]);
        }
     }

   return rates_total; // Set prev_calculated on next call
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsInsideBar()
  {
   double prevMax = InpFindByType == FINDBY_HL
                    ? MathMax(prevBar.GetHigh(), prevBar.GetLow())
                    : MathMax(prevBar.GetOpen(), prevBar.GetClose());
   double prevMin = InpFindByType == FINDBY_HL
                    ? MathMin(prevBar.GetHigh(), prevBar.GetLow())
                    : MathMin(prevBar.GetOpen(), prevBar.GetClose());

   double currMax = MathMax(currBar.GetHigh(), currBar.GetLow());
   double currMin = MathMin(currBar.GetHigh(), currBar.GetLow());

   return prevMax >= currMax && prevMin <= currMin;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsAlertEnabled(datetime time)
  {
   switch(InpAlertType)
     {
      case EACH_BAR_ALERT:
         return true;
      case FIRST_BAR_ALERT:
         return time - prevBar.GetTime() == PeriodSeconds(PERIOD_CURRENT);
      case NO_ALERT:
      default:
         return false;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime ReadLastInsideBarTime()
  {
   int h = FileOpen(GetLastInsideBarFileName(), FILE_READ | FILE_ANSI | FILE_TXT);
   if(h == INVALID_HANDLE)
     {
      PrintFormat("Error opening '%s' file to read.");
      return 0;
     }
   string time = FileReadString(h);
   FileClose(h);
   return StringToTime(time);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void WriteLastInsideBarTime(datetime time)
  {
   int h = FileOpen(GetLastInsideBarFileName(), FILE_WRITE | FILE_ANSI | FILE_TXT);
   if(h == INVALID_HANDLE)
     {
      PrintFormat("Error opening '%s' file to write.");
      return;
     }
   FileWrite(h, TimeToString(time));
   FileClose(h);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string GetLastInsideBarFileName()
  {
   return "insidebar_m" + IntegerToString(PeriodSeconds(PERIOD_CURRENT) / 60) + ".txt";
  }
//+------------------------------------------------------------------+
