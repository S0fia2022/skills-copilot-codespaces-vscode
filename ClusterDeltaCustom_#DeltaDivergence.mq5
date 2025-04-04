#property copyright "Copyright © 2011-2021, ClusterDelta.com"
#property link      "http://my.clusterdelta.com/premium"
#property description "ClusterDelta Premium Delta, Version 5.2"
#property description "\nDelta Indicator show difference between size of volume executed on Ask (Bears trades) price (or above) and size of volume executed on Bid (Bulls trades) price (or below). Delta equals formula: Ask minus Bid. This indicator show delta of each bar on the current timeframe. Data looks like a histogramm in a separate window."
#property description "\nMore information can be found here: http://my.clusterdelta.com/delta"
#property version "5.2"

#define RGB(r,g,b)  (color)((uchar(r)<<16)|(uchar(g)<<8)|uchar(b))
#define ARGB(a,r,g,b)  ((uchar(a)<<24)|(uchar(r)<<16)|(uchar(g)<<8)|uchar(b))
#define NOTIFY_TEXT "Press Status Icon on the left to put your Account Information.\nSource of Data may be changed in the properties of Indicator (Instrument)\n\nTake your attention that source should corresponds to your Chart Ticker.\n\nhttp://my.clusterdelta.com/volume"

#import "clusterdelta_v5x2_x64.dll"
string Receive_Information(int&,string);
int Send_Query(int &, string, string, int, string, string, string, string, string, string, int, string, string, string,int);
int WindowDialog(int &, string, string, string);
#import

#import "online_mt5_v4x1.dll"
int Online_Init(int&,string,int);
string Online_Data(int&,string);
int Online_Subscribe(int &, string, string, int, string, string, string, string, string, string, int, string, string, string,int);
#import

#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  LimeGreen,OrangeRed
#property indicator_style1  0
#property indicator_width1  2



enum ChartFutures { Auto∙Select=0, 
                    ·6A→AUDUSD=1, ·6B→GBPUSD=2, ·6C→USDCAD=3, ·6E→EURUSD=4, ·6J→USDJPY=5, ·6S→USDCHF=6, ·6N→NZDUSD=7, ·6M→USDMXN=8,
                    ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬=10,
                    ES→SP500=11,NQ→Nasdaq·100=12,YM→Dow·Jones=13,RTY→Russel·2000=14,FDAX→Dax40·Index=15,FESX→Euro·Stoxx50=16,DX→Dollar·Index=17, 
                    ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬=10,
                    BRN→Brent·Oil=21,CL→Crude·Oil=22,NG→Natural·Gas=23,GC→XAUUSD·Gold=24,SI→XAGUSD·Silver=25,HG→Copper=26,ZW→Wheat=27,ZB→US·Bonds=28, 
                    ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬=29,
                    WIN·Bovespa·Index=30, WDO·USDBRL·Brazilian·Real=31, 
                    ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬=40,
                    BTCUSDT→Bitcoin=41, ETHUSDT→Etherium=42,
                    ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬=50,
                     ADAUSDT→Cardano=51, APEUSDT→ApeCoin=53, AVAXUSDT→Avalanche=55, BNBUSDT→Binance·Coin=57, 
                     DOTUSDT→Polkadot=60, FTMUSDT→Fantom=63, GMTUSDT→Green·Metaverse=64, LINKUSDT→ChainLink=65,
                     LITUSDT→Litentry=66, LTCUSDT→Litecoin=67, NEARUSDT→Near·Protocol=70, PEOPLEUSDT→ConstitutionDAO =71, 
                     SOLUSDT→Solana=80, TONUSDT→Toncoin=81, TRXUSDT→Tron=82, WAVESUSDT→Waves=83, XRPUSDT→Ripple=84
                    };




input string HELP_URL="http://clusterdelta.com/delta";
string Instrument="";
input ChartFutures ChartInstrument=0; // Select Futures from List

input string MetaTrader_GMT="AUTO";
input string Comment_History="--- Premium Settings ";
input int Days_in_History=0;
input datetime Custom_Start_time=D'2017.01.01 00:00';
input datetime Custom_End_time=D'2017.01.01 00:00';
input string Reverse_Settings="--------- Reverse for USD/XXX symbols ---------";
input bool ReverseChart=false;
input string DO_NOT_SET_ReverseChart="...for USD/JPY, USD/CAD, USD/CHF --";
input color Current_Delta_Positive=clrLimeGreen;
input color Current_Delta_Negative=clrOrangeRed;
input int Font_Size=8;
// Absorption settings
input string Divergence_Settings ="--- Divergence filter (absorption)";
enum abs_ct {Bearish, Bullish, Both};
input abs_ct Bars_Direction = Both;
input int Filter = 0;
input bool Show = true;
// Absorption vars
int PABuf[]; // Buffer for price action storage (absorption)

int Update_in_sec=25;

double DeltaBuf[];
double bufValueClr[];         // Буфер цвета 


datetime TimeData[];
double VolumeData[];
double DeltaData[];

string ver = "5.2";
string MessageFromServer="";
datetime last_loaded=D'1970.01.01 00:00';
datetime myUpdateTime=D'1970.01.01 00:00';
int UpdateFreq=25; // sec
int OneTimeAlert=0;

string clusterdelta_client="";

string HASH_IND="";
string indicator_name = "ClusterDelta PremiumDelta (http://my.clusterdelta.com)";

string short_name="";
bool ReverseChart_SET=false;

int GMT=0;
int GMT_SET=0;


int NumberRates=0;
datetime LastTime[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   
//---- buffers   
   SetIndexBuffer(0,DeltaBuf,INDICATOR_DATA);
   SetIndexBuffer(1,bufValueClr,INDICATOR_COLOR_INDEX);

   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- name for DataWindow and indicator subwindow label
   IndicatorSetString(INDICATOR_SHORTNAME,indicator_name );
//---- indicator digits
   IndicatorSetInteger(INDICATOR_DIGITS,0);
//----

   // this block do not use ClusterDelta_Server but register for unique id
   do
   {
     clusterdelta_client = "CDPA" + StringSubstr(IntegerToString(TimeLocal()),7,3)+""+DoubleToString(MathAbs(MathRand()%10),0);     
     HASH_IND = "CLUSTERDELTA_"+clusterdelta_client;
   } while (GlobalVariableCheck(HASH_IND));
   GlobalVariableTemp(HASH_IND);
   HASH_IND=clusterdelta_client;   
   ReverseChart_SET=ReverseChart;
   
   ArrayResize(TimeData, 0);
   ArrayResize(VolumeData, 0);
   ArrayResize(DeltaData, 0);   

   ArrayResize(LastTime, 0);
   if (Update_in_sec>2 && Update_in_sec<130) { UpdateFreq=Update_in_sec; }   

   int usd_str_index = StringFind(Symbol(),"USD");
   int cad_str_index = StringFind(Symbol(),"CAD");
   int chf_str_index = StringFind(Symbol(),"CHF");
   int jpy_str_index = StringFind(Symbol(),"JPY");   

         if (usd_str_index!=-1) // точно форекс
         {
             if (  cad_str_index  != -1 || chf_str_index  != -1 || jpy_str_index  != -1)
             {
                ReverseChart_SET= !ReverseChart ;
             }
         }         


   EventSetMillisecondTimer(100);
   ClearAbsChart();

   return (INIT_SUCCEEDED);

  }
  
void OnTimer()
{
  MainCode();
} 
//+------------------------------------------------------------------+
//| Average True Range                                               |
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
      NumberRates = rates_total;
      ArrayResize(LastTime, ArraySize(time));
      ArrayCopy(LastTime , time);
      return (1);//MainCode();

  }
  
int MainCode()
{ 
//---check for rates total
   static int dll_init=0;   
   int data_is_ready;
   int online_is_ready;   
   bool ready_to_fetch;

   int ix=0;
   int iBase;

   int count = 0;
   int myVolume=0, mydelta=0;

   int filterType = 0;
   
   static bool use_standart_bsearch=false;

   if(ArraySize(LastTime)==0) return 0;

   ready_to_fetch=((TimeLocal() >= myUpdateTime) ? true : false ); 
   
   data_is_ready = GetData();
   online_is_ready = GetOnline();      
   if(ready_to_fetch)
   {  
     // set new update time
     myUpdateTime = TimeLocal() + UpdateFreq;
     // send parameter for data update
     SetData();
   }
   ChartRedraw();  
     
   // if we got data before   
   if(!data_is_ready && !online_is_ready) { return 1; }// from GetData
   // data are in the buffer just show them

   int finish_idx=NumberRates-1;

   ix = NumberRates-1;
   if(ArraySize(TimeData)<finish_idx) finish_idx = ArraySize(TimeData) ;
   if (Custom_Start_time!=D'2017.01.01 00:00' || Custom_End_time!=D'2017.01.01 00:00') { finish_idx=NumberRates-1; }
   
   if (finish_idx ==0 ) return 0;

   ix =0;  
   while(ix<(NumberRates-finish_idx)){DeltaBuf[ix]=EMPTY_VALUE;bufValueClr[ix]=0;ix++; }
   ix = (NumberRates-finish_idx);   

   while(ix < NumberRates)
   {
      bufValueClr[ix]=0;
      iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] );

      if (iBase < 0 && Period() >= PERIOD_M5) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] - 1*60 ); } // 1 Min BrokenHour
      if (iBase < 0 && Period() >= PERIOD_M5) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] - 2*60 ); } // 1 Min BrokenHour      
      if (iBase < 0 && Period() >= PERIOD_M5) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] - 3*60 ); } // 1 Min BrokenHour            
      if (iBase < 0 && Period() >= PERIOD_M5) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] - 4*60 ); } // 1 Min BrokenHour                  
      if (iBase < 0 && Period() >= PERIOD_M15) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] - 5*60 ); } // 5 Min BrokenHour      
      if (iBase < 0 && Period() >= PERIOD_H1) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] - 30*60 ); } // 35 Min BrokenHour / ES      
      if (iBase < 0 && Period() >= PERIOD_H1) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] - 35*60 ); } // 35 Min BrokenHour / ES
      if (iBase < 0 && Period() >= PERIOD_H4) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] - 60*60 ); } // 60 Min BrokenHour / ES      
      if (iBase < 0 && Period() >= PERIOD_H4) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] + 60*60 ); } // 60 Min BrokenHour / ES            
      if (iBase < 0 && Period() >= PERIOD_H4) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] + 2*60*60 ); } // 120 Min BrokenHour / ES            
      
      if (iBase < 0 && Period() >= PERIOD_W1) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] + 24*60*60); } // 35 Min BrokenHour / ES            
      if (iBase < 0 && Period() >= PERIOD_W1) { iBase = ArrayBsearchCorrect(TimeData, LastTime[ix] + 25*60*60); } // 35 Min BrokenHour / ES            
      if (iBase >= 0) //  && (MathAbs(LastTime[ix]-TimeData[iBase])<Period()*60))
      {
         count++;    
         myVolume= (int)VolumeData[iBase]; // VOLUME
         mydelta=  (int)DeltaData[iBase];  // DELTA       
         
         DeltaBuf[ix]=mydelta;//*(ReverseChart_SET ? -1:1);; //myvolume;
         
         // Divergence calculations 
         
         int CurrentBarIndex = (NumberRates-1) - ix; // Retrieve bar index number
         int PAFactor;
         
         if (iOpen(NULL,PERIOD_CURRENT, CurrentBarIndex) > iClose(NULL,PERIOD_CURRENT,CurrentBarIndex)) {
            // Negative Close
            PAFactor = -1;
         }
         else {
            // Positive Close
            PAFactor = 1;
         }
         
         ShowDivergence(ix, mydelta, PAFactor, CurrentBarIndex);
         if (Show) {
            if (Bars_Direction == 0 && mydelta > Filter && PAFactor ==-1) { // Show only positive filtered delta on bearish candles
               DeltaBuf[ix] = mydelta;
            }
            else if (Bars_Direction == 1 && mydelta < (Filter*-1) && PAFactor == 1) { // Show only negative filtered delta on bullish candles
               DeltaBuf[ix] = mydelta;
            }
            else if (Bars_Direction == 2 && mydelta > Filter && PAFactor ==-1) {
                DeltaBuf[ix] = mydelta;
            }
            else if (Bars_Direction == 2 && mydelta < (Filter*-1) && PAFactor == 1) {
                DeltaBuf[ix] = mydelta;
            }
            else {
               DeltaBuf[ix] = 0;
            }
         }
         
         if(mydelta>0) bufValueClr[ix]=0; else bufValueClr[ix]=1;
      } else
      {
         if(ix<NumberRates-1) { DeltaBuf[ix]=EMPTY_VALUE;}
      }
      ix++;
   }
   if(ix == NumberRates)
   {
      ResetLastError();
      ObjectCreate(0,"Delta"+"_"+HASH_IND,OBJ_TEXT,ChartWindowFind(),LastTime[NumberRates-1],DeltaBuf[ix-1]);
      if( GetLastError() )
      {
        ObjectSetInteger(0,"Delta"+"_"+HASH_IND,OBJPROP_TIME,LastTime[NumberRates-1]);
        ObjectSetDouble(0,"Delta"+"_"+HASH_IND,OBJPROP_PRICE,DeltaBuf[ix-1]);
      }
      ObjectSetString(0,"Delta"+"_"+HASH_IND,OBJPROP_TOOLTIP,"Delta: "+DoubleToString(DeltaBuf[ix-1],0));
      ObjectSetString(0,"Delta"+"_"+HASH_IND,OBJPROP_TEXT,DoubleToString(DeltaBuf[ix-1],0));      
      ObjectSetString(0,"Delta"+"_"+HASH_IND,OBJPROP_FONT,"Arial");            
      ObjectSetInteger(0,"Delta"+"_"+HASH_IND, OBJPROP_FONTSIZE, Font_Size);      
      ObjectSetInteger(0,"Delta"+"_"+HASH_IND, OBJPROP_COLOR, (DeltaBuf[ix-1]>=0 ?Current_Delta_Positive:Current_Delta_Negative));
      ObjectSetInteger(0,"Delta"+"_"+HASH_IND, OBJPROP_ANCHOR,(DeltaBuf[ix-1]>=0 ?ANCHOR_LEFT_LOWER:ANCHOR_LEFT_UPPER)); 

      ObjectSetString(0,"Delta"+"_"+HASH_IND,OBJPROP_TOOLTIP,"Delta: "+DoubleToString(DeltaBuf[ix-1],0));
      if(DeltaBuf[ix-1]>=0) { ObjectSetInteger(0,"Delta"+"_"+HASH_IND, OBJPROP_COLOR, Current_Delta_Positive); } else {ObjectSetInteger(0,"Delta"+"_"+HASH_IND, OBJPROP_COLOR, Current_Delta_Negative); }
   }
   
   ChartRedraw(0);   
   
   return(ix);
  }
  
input color Bar_Shadow = clrWhite;
input color Bar_Bear_Border = 0x00007700; 
input color Bar_Bear_Fill = 0x0000cc00;
input color Bar_Bull_Border = 0x000000aa;
input color Bar_Bull_Fill = 0x000000cc;
  
void ShowDivergence(int ix, int mydelta, int PAFactor, int CurrentBarIndex) {

         if(CurrentBarIndex<1) return;
         if (!Show) {
            ClearAbsChart();
            return;
         }
         //Print("Delta is:" + mydelta + " PA Factor =" +PAFactor + " filter: " + Filter + " Bars_Direction=" + Bars_Direction);
         if (
              (mydelta > Filter && PAFactor < 0      && (Bars_Direction == 0 || Bars_Direction == 2))  ||
              (mydelta < (Filter*-1) && PAFactor > 0 && (Bars_Direction == 1 || Bars_Direction == 2))
            )
         {
            // Divergence (positive delta, bearish PA)
            //ObjectCreate(0,HASH_IND+IntegerToString(CurrentBarIndex),OBJ_ARROW_CHECK,0,iTime(NULL, PERIOD_CURRENT, CurrentBarIndex),iHigh(NULL,PERIOD_CURRENT, CurrentBarIndex));
            MarkCandle(CurrentBarIndex);
         }

         
      }
      
void MarkCandle( int _CurrentBarIndex)
{

   int chart_scale = (int)ChartGetInteger(0,CHART_SCALE,0);
   int bar_width = (int)MathPow(2,chart_scale)+1;
   double open = iOpen(NULL,PERIOD_CURRENT, _CurrentBarIndex);
   double close= iClose(NULL,PERIOD_CURRENT,_CurrentBarIndex);
   double high = iHigh(NULL,PERIOD_CURRENT, _CurrentBarIndex);
   double low =  iLow(NULL,PERIOD_CURRENT, _CurrentBarIndex);
   
         
       
   color shadow = (Bar_Shadow == clrNONE ? (color)(0xffffff ^ (int)ChartGetInteger(0,CHART_COLOR_BACKGROUND,1)) : Bar_Shadow);
   color bar_color=shadow;
   color bb_color=shadow; 
   
   string name_arrow=HASH_IND+"_OHLC_HL"+IntegerToString(_CurrentBarIndex);
   string name_arrow2=HASH_IND+"_OHLC_OC"+IntegerToString(_CurrentBarIndex);

        if(close>=open) { bar_color= (color)(Bar_Bear_Border); bb_color=(Bar_Bear_Fill);  }
        if(open>close)  { bar_color= (color)Bar_Bull_Border; bb_color=(Bar_Bull_Fill); }
        TrendLineCreate(0,name_arrow,0,iTime(NULL, PERIOD_CURRENT, _CurrentBarIndex),high,iTime(NULL, PERIOD_CURRENT, _CurrentBarIndex),low,0.2,shadow ,STYLE_SOLID,1,false,false,false,false,0);       
        
        
         ObjectDelete(0,name_arrow2);
         ResetLastError(); 
         ObjectCreate(0,name_arrow2,OBJ_RECTANGLE,0,iTime(NULL, PERIOD_CURRENT, _CurrentBarIndex),open,iTime(NULL, PERIOD_CURRENT, _CurrentBarIndex),close);
         //ObjectSetInteger(0,name_arrow2,OBJPROP_TIME1,Time[idxTime]);
         //ObjectSetInteger(0,name_arrow2,OBJPROP_TIME2,Time[idxTime]);
         //ObjectSetDouble(0, name_arrow2, OBJPROP_PRICE1, OHLC[bar].open+ShiftPoints*Point());
         //ObjectSetDouble(0, name_arrow2, OBJPROP_PRICE2, OHLC[bar].close+ShiftPoints*Point());

         ObjectSetInteger(0,name_arrow2,OBJPROP_RAY,0);
         ObjectSetInteger(0,name_arrow2,OBJPROP_COLOR,bb_color); 
         ObjectSetInteger(0,name_arrow2,OBJPROP_STYLE,STYLE_SOLID); 
         ObjectSetInteger(0,name_arrow2,OBJPROP_WIDTH,chart_scale*2-1); 
         ObjectSetInteger(0,name_arrow2,OBJPROP_BACK,false); 
         ObjectSetInteger(0,name_arrow2,OBJPROP_SELECTABLE,false); 
         ObjectSetInteger(0,name_arrow2,OBJPROP_SELECTED,false); 
         ObjectSetInteger(0,name_arrow2,OBJPROP_HIDDEN,false); 
        
}

bool TrendLineCreate(const long            chart_ID=0,        // ID графика 
                   const string          name="Ellipse",    // имя эллипса 
                   const int             sub_window=0,      // номер подокна  
                   datetime              time1=0,           // время первой точки 
                   double                price1=0,          // цена первой точки 
                   datetime              time2=0,           // время второй точки 
                   double                price2=0,          // цена второй точки 
                   double                ellipse_scale=0.2,   // соотношение между временной и ценовой шкалами  
                   const color           clr=clrRed,        // цвет эллипса 
                   const ENUM_LINE_STYLE style=STYLE_SOLID, // стиль линий эллипса 
                   const int             width=1,           // толщина линий эллипса 
                   const bool            fill=false,        // заливка эллипса цветом 
                   const bool            back=false,        // на заднем плане 
                   const bool            selection=true,    // выделить для перемещений 
                   const bool            hidden=true,       // скрыт в списке объектов 
                   const long            z_order=0)         // приоритет на нажатие мышью 
  { 
//--- установим координаты точек привязки, если они не заданы 
//   ChangeEllipseEmptyPoints(time1,price1,time2,price2); 
   ObjectDelete(0,name);
//--- сбросим значение ошибки 
   ResetLastError(); 
//--- создадим эллипс по заданным координатам 
   ObjectCreate(chart_ID,name,OBJ_TREND,sub_window,time1,price1,time1,price2);
//--- установим соотношение между временной и ценовой шкалами  
   //ObjectSetDouble(chart_ID,name,OBJPROP_SCALE,ellipse_scale); 
   ObjectSetInteger(chart_ID,name,OBJPROP_RAY,0);
//--- установим цвет эллипса 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr); 
//--- установим стиль линий эллипса 
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style); 
//--- установим толщину линий эллипса 
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width); 
//--- отобразим на переднем (false) или заднем (true) плане 
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back); 
//--- включим (true) или отключим (false) режим выделения эллипса для перемещений 
//--- при создании графического объекта функцией ObjectCreate, по умолчанию объект 
//--- нельзя выделить и перемещать. Внутри же этого метода параметр selection 
//--- по умолчанию равен true, что позволяет выделять и перемещать этот объект 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection); 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection); 
//--- скроем (true) или отобразим (false) имя графического объекта в списке объектов 
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden); 
//--- установим приоритет на получение события нажатия мыши на графике 
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order); 
//--- успешное выполнение 
   return(true); 
  } 


void ClearAbsChart() {
   // Clear previous signals
   //Print ("ClearAbsChart()");
   ObjectsDeleteAll (0,HASH_IND,-1,-1);
}
//+------------------------------------------------------------------+

void OnDeinit(const int reason)
{
    int    obj_total=ObjectsTotal(0);
    GlobalVariableDel(HASH_IND);
    EventKillTimer();
    
    for(int i=0;i<obj_total;i++)
    {
      while ( (StringFind(ObjectName(0,i),HASH_IND)!= -1) ) { ObjectDelete(0,ObjectName(0,i));  }
    } 
    
}

int Period_To_Minutes()
{

  switch(_Period)
  {
    case (PERIOD_M1): return 1;
    case (PERIOD_M2): return 2;
    case (PERIOD_M3): return 3;
    case (PERIOD_M4): return 4;
    case (PERIOD_M5): return 5;
    case (PERIOD_M6): return 6;
    case (PERIOD_M10): return 10;
    case (PERIOD_M12): return 12;
    case (PERIOD_M15): return 15;
    case (PERIOD_M20): return 20;
    case (PERIOD_M30): return 30;
    case (PERIOD_H1): return 60;
    case (PERIOD_H2): return 120;
    case (PERIOD_H3): return 180;
    case (PERIOD_H4): return 240;
    case (PERIOD_H6): return 360;
    case (PERIOD_H8): return 480;
    case (PERIOD_H12): return 60;
    case (PERIOD_D1): return 1440;
    case (PERIOD_W1): return 10080;    
    case (PERIOD_MN1): return 302400;    
    default: return 60;
    
  }

}

int SetData()
{

  int k=0,i;
  string sym=Symbol();
  int per=Period_To_Minutes();
  
  string tmc=TimeToString(TimeTradeServer());
  string tm0=TimeToString(LastTime[NumberRates-1]);
  string lsl=TimeToString(last_loaded);
  string cst=TimeToString(Custom_Start_time);
  string cet=TimeToString(Custom_End_time);
  string cmp=AccountInfoString(ACCOUNT_COMPANY);
  int acnt=(int)AccountInfoInteger(ACCOUNT_LOGIN);

  
  if(Instrument == "")  
  {    
      Instrument="AUTO";
      switch (ChartInstrument) {
        case 1: Instrument="6A"; break;
        case 2: Instrument="6B"; break;
        case 3: Instrument="6C"; break;
        case 4: Instrument="6E"; break;
        case 5: Instrument="6J"; break;
        case 6: Instrument="6S"; break;
        case 7: Instrument="6N"; break;
        case 8: Instrument="6M"; break;
        case 15: Instrument="FDAX"; break;
        case 21: Instrument="BRN"; break;
        case 22: Instrument="CL"; break;
        case 24: Instrument="GC"; break;
        case 11: Instrument="ES"; break;
        case 12: Instrument="NQ"; break;
        case 13: Instrument="YM"; break;
        case 17: Instrument="DX"; break;
        case 28: Instrument="ZB"; break;
        case 23: Instrument="NG"; break;
        case 25: Instrument="SI"; break;
        case 26: Instrument="HG"; break;
        case 27: Instrument="ZW"; break;
        case 14: Instrument="RTY"; break;                         
        case 16: Instrument="FESX"; break;
        case 30: Instrument="WIN"; break;                
        case 31: Instrument="WDO"; break;       
        case 41: Instrument="BTC"; break;
        case 42: Instrument="ETH"; break;

        case 51: Instrument="ADAUSD"; break;
        case 53: Instrument="APEUSD"; break;
        case 55: Instrument="AVAXUSD"; break;
        case 57: Instrument="BNBUSD"; break;        
        case 60: Instrument="DOTUSD"; break;
        case 63: Instrument="FTMUSD"; break;
        case 64: Instrument="GMTUSD"; break;
        case 65: Instrument="LINKUSD"; break;        
        case 66: Instrument="LITUSD"; break;
        case 67: Instrument="LTCUSD"; break;
        case 70: Instrument="NEARUSD"; break;
        case 71: Instrument="PEOPLEUSD"; break;        
        case 80: Instrument="SOLUSD"; break;
        case 81: Instrument="TONUSD"; break;
        case 82: Instrument="TRXUSD"; break;
        case 83: Instrument="WAVESUSD"; break;
        case 84: Instrument="XRPUSD"; break;        

        
      }
   }  


  i = Send_Query(k,clusterdelta_client, sym, per, tmc, tm0, Instrument, lsl,MetaTrader_GMT,ver,Days_in_History,cst,cet,cmp,acnt);     

  if (i < 0) { Alert ("Error during query registration"); return -1; }

  if(Period_To_Minutes()<=60) {
    i = Online_Subscribe(k,clusterdelta_client, sym, per, tmc, tm0, Instrument, lsl,MetaTrader_GMT,ver,Days_in_History,cst,cet,cmp,acnt);       
  }
  
  return 1;
}  



int GetData()
{

   string response="";
   int length=0;
   int valid=0;   
   int len=0,td_index;
   int i=0;
   datetime index;   
   int iBase=0;
   double volume_value=0, delta_value=0;
   string result[];
   string bardata[];        
   response = Receive_Information(length, clusterdelta_client);

   if (length==0) { return 0; }
    
    if(StringLen(response)>1) // if we got response (no care how), convert it to mt4 buffers
    {
      len=StringSplit(response,StringGetCharacter("\n",0),result);                
      if(!len) { return 0; }
      MessageFromServer=result[0];
      
      for(i=1;i<len;i++)
      {
        if(StringLen(result[i])==0) continue;
        if (StringSplit(result[i],StringGetCharacter(";",0),bardata)<2) continue;                
        td_index=ArraySize(TimeData);
        index = StringToTime(bardata[0]);
        volume_value= StringToDouble(bardata[1]);
        delta_value= StringToDouble(bardata[2])*(ReverseChart_SET?-1:1);        
        
        if(index==0) continue;
        iBase = ArrayBsearchCorrect(TimeData, index ); 
        if (iBase >= 0) { td_index=iBase; } 
        if(td_index>=ArraySize(TimeData))
        {
           ArrayResize(TimeData, td_index+1);
           ArrayResize(VolumeData, td_index+1);
           ArrayResize(DeltaData, td_index+1);           
        } else { if((VolumeData[td_index])>(volume_value) && td_index>=ArraySize(TimeData)-2) { volume_value=VolumeData[td_index]; delta_value=DeltaData[td_index];}  }
    
        TimeData[td_index]= index;
        VolumeData[td_index] = volume_value;
        DeltaData[td_index] = delta_value;        
      
      }
      valid=ArraySize(TimeData);      

      if (valid>0)
      {
       //SortDictionary(TimeData,ValueData);
       Sort2Dictionary(TimeData,VolumeData,DeltaData);       
       int lastindex = ArraySize(TimeData);
       last_loaded=TimeData[lastindex-1];  
       if(lastindex>5)
       {
         last_loaded=TimeData[lastindex-6];  
       }
       if(last_loaded>LastTime[NumberRates-1])last_loaded=LastTime[NumberRates-1]; 
      } 
      if (StringLen(MessageFromServer)>8 && OneTimeAlert==0) { 
          int gmt_shift_left_bracket = StringFind(MessageFromServer,"[");
          int gmt_shift_right_bracket = StringFind(MessageFromServer,"]");
          if (gmt_shift_left_bracket>0 && gmt_shift_right_bracket)
          {
            GMT = (int)StringSubstr(MessageFromServer,gmt_shift_left_bracket+1,gmt_shift_right_bracket-gmt_shift_left_bracket-1);
            GMT_SET=1;
          }
         
          OneTimeAlert=1; 
       } 

       //if (StringLen(MessageFromServer)>8 && OneTimeAlert==1) { Print("MT4 Time ",TimeToString(TimeCurrent()),",  data source info:", MessageFromServer ); OneTimeAlert=2;}      
    }
    return (1);
}

int GetOnline()
{
   string response="";
   int length=0;   
   string key="";
   string mydata="";
   int block=0;
   if(Period_To_Minutes()>60) return 0;
   response = Online_Data(length, clusterdelta_client);
   if(length  == 0) { return 0; }
   if(ArraySize(TimeData)<4) { return 0; }
   int key_i=StringFind(response, ":");
   key = StringSubstr(response,0,key_i);
   mydata =  StringSubstr(response,key_i+1);

   string result[];
   string bardata[];
   if(key == clusterdelta_client)
   {
      StringSplit(mydata,StringGetCharacter("!",0),result);
      
      if(!GMT_SET)
      {
        StringSplit(result[2],StringGetCharacter(";",0),bardata);      
        if(VolumeData[ArraySize(VolumeData)-3] == StringToDouble(bardata[1])) // 3-rd bar in stream is 3rd in series
        {
          StringSplit(result[0],StringGetCharacter(";",0),bardata);                      
          int compare_minutes = int( (double)(TimeData[ArraySize(TimeData)-1]) - StringToDouble(bardata[0]) );
          GMT = int(compare_minutes / 3600);
          GMT_SET=0;          
        } else
        if(VolumeData[ArraySize(VolumeData)-2] == StringToDouble(bardata[1])) // 3-rd bar in stream is 3rd in series
        {
          int compare_minutes = int( (double)(TimeData[ArraySize(TimeData)-2]) - StringToDouble(bardata[0]) );
          GMT = int(compare_minutes / 3600);
          GMT_SET=0;
        } 
      }
          //Print("UpdateArray -> ", bardata[1]);
          StringSplit(result[0],StringGetCharacter(";",0),bardata);                
          UpdateArray(TimeData, VolumeData,DeltaData, StringToDouble(bardata[0])+3600*GMT, StringToDouble(bardata[1]),StringToDouble(bardata[2])*(ReverseChart_SET?-1:1));
          StringSplit(result[1],StringGetCharacter(";",0),bardata);               
          UpdateArray(TimeData, VolumeData,DeltaData, StringToDouble(bardata[0])+3600*GMT, StringToDouble(bardata[1]),StringToDouble(bardata[2])*(ReverseChart_SET?-1:1));
          //StringSplit(result[2],StringGetCharacter(";",0),bardata);               
          //UpdateArray(TimeData, VolumeData,DeltaData, StringToDouble(bardata[0])+3600*GMT, StringToDouble(bardata[1]),StringToDouble(bardata[2]));



   }
   return 1; 
}


void UpdateArray(datetime& td[],double& ad[], double& bd[], double dtp, double dta, double dtb)
{
    datetime indexx = (datetime)dtp;

    int i=ArraySize(td);    
    int iBase = ArrayBsearchCorrect(td, indexx );
    
    if (iBase >= 0) { i=iBase;  } 
    
    if(i>=ArraySize(td))
    {      
      ArrayResize(td, i+1);
      ArrayResize(ad, i+1);
      ArrayResize(bd, i+1);      
    } else { 
      if(ad[i]>dta && i>=ArraySize(td)-2) { dta=ad[i]; dtb=bd[i]; }       
    }
    
    td[i]= (datetime)dtp;
    ad[i]= dta;
    bd[i]= dtb;
}


int ArrayBsearchCorrect(datetime &array[], datetime value, 
                        int count = WHOLE_ARRAY, int start = 0)
{
   if(ArraySize(array)==0) return(-1);   
   int i = ArrayBsearch(array, value); //, count, start);
   if (value != array[i])
   {
      i = -1;
   }
   return (i);
}


void Sort2Dictionary(datetime &keys[], double &values[],  double &values2[])
{
   datetime keyCopy[];
   double valueCopy[];
   double value2Copy[];
      
   ArrayCopy(keyCopy, keys);
   ArrayCopy(valueCopy, values);
   ArrayCopy(value2Copy, values2);
   
   ArraySort(keys); //, WHOLE_ARRAY, 0, sortDirection);
   for (int i = 0; i < MathMin(ArraySize(keys), ArraySize(values)); i++)
   {
      //values[i] = valueCopy[ArrayBsearch(keyCopy, keys[i])];
      values[ArrayBsearch(keys, keyCopy[i])] = valueCopy[i];
      values2[ArrayBsearch(keys, keyCopy[i])] = value2Copy[i];      
      
   }
}

