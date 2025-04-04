#property copyright "Copyright © 2011-2021, ClusterDelta.com"
#property link      "https://clusterdelta.com"
#property description "ClusterDelta AskBid over Volumes, Developers Version 5.6"
#property description "Indicator AskBid_over_Volumes shows biggest Ask or Bid value or Delta values over Volume"
#property description "\nVOLUME = ASK + BID"
#property description "DELTA = ASK - BID"
#property version "5.6"

#define RGB(r,g,b)  (color)((uchar(r)<<16)|(uchar(g)<<8)|uchar(b))
#define ARGB(a,r,g,b)  ((uchar(a)<<24)|(uchar(r)<<16)|(uchar(g)<<8)|uchar(b))
#define NOTIFY_TEXT "Press Status Icon on the left to put your Account Information.\nSource of Data may be changed in the properties of Indicator (Instrument)\n\nTake your attention that source should corresponds to your Chart Ticker.\n\nhttp://my.clusterdelta.com/volume"

#property indicator_separate_window

#ifdef __MQL4__

#import "clusterdelta_v5x6.dll"
string Receive_Information(int &, string);
int Send_Query(int &, string, string, int, string, string, string, string, string, string, int, string, string, string,int);
int WindowDialog(int &, string, string, string);
#import


#import "online_mt4_v4x1.dll"
int Online_Init(int&, string, int);
string Online_Data(int&,string);
int Online_Subscribe(int &, string, string, int, string, string, string, string, string, string, int, string, string, string,int);
#import


#property indicator_buffers 5

#property indicator_label1  "Volumes" 
#property indicator_color1 DodgerBlue
#property indicator_width1 1

#property indicator_label2  "Ask" 
#property indicator_color2 YellowGreen
#property indicator_width2 3

#property indicator_label3  "Bid" 
#property indicator_color3 Salmon
#property indicator_width3 3

#property indicator_label4  "Delta+" 
#property indicator_color4 LimeGreen
#property indicator_width4 3

#property indicator_label5  "Delta-" 
#property indicator_color5 OrangeRed
#property indicator_width5 3

#endif

#ifdef __MQL5__

#import "clusterdelta_v5x6_x64.dll"
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
#property indicator_buffers 10
#property indicator_plots   5

#property indicator_label1  "Volumes" 
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  clrDodgerBlue
#property indicator_width1  1
#property indicator_style1  0

#property indicator_label2  "Ask" 
#property indicator_type2   DRAW_COLOR_HISTOGRAM
#property indicator_color2  clrYellowGreen
#property indicator_width2  3
#property indicator_style2  0

#property indicator_label3  "Bid" 
#property indicator_type3   DRAW_COLOR_HISTOGRAM
#property indicator_color3  clrSalmon
#property indicator_width3  3
#property indicator_style3  0

#property indicator_label4  "Delta+" 
#property indicator_type4   DRAW_COLOR_HISTOGRAM
#property indicator_color4  clrLimeGreen
#property indicator_width4  3
#property indicator_style4  0

#property indicator_label5  "Delta-" 
#property indicator_type5   DRAW_COLOR_HISTOGRAM
#property indicator_color5  clrOrangeRed
#property indicator_width5  3
#property indicator_style5  0

#endif 
#property indicator_minimum 0

enum ChartFutures { Auto∙Select=0, 
                    ·6A→AUDUSD=1, ·6B→GBPUSD=2, ·6C→USDCAD=3, ·6E→EURUSD=4, ·6J→USDJPY=5, ·6S→USDCHF=6, ·6N→NZDUSD=7, ·6M→USDMXN=8,
                    ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬=10,
                    ES→SP500=11,NQ→Nasdaq·100=12,YM→Dow·Jones=13,RTY→Russel·2000=14,FDAX→Dax40·Index=15,FESX→Euro·Stoxx50=16,DX→Dollar·Index=17, MNQ→Micro·Nasdaq100=18, 
                    ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬=20,
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


input string HELP_URL="https://clusterdelta.com/ab-over-v";
string Instrument="";
input ChartFutures ChartInstrument=0; // Instrument as Data Source

input string MetaTrader_GMT="AUTO";
input string Comment_Layers="--- ASK BID Layers ";
input  bool Volume_Layer=true;
input  bool AskBid_Layer=true;
input  bool Delta_Layer=true;

input string Comment_History="--- Custom Settings ";
input int Days_in_History=0;
input datetime Custom_Start_date=D'2017.01.01 00:00';
input datetime Custom_End_date=D'2017.01.01 00:00';
datetime Custom_Start_time=D'2017.01.01 00:00';
datetime Custom_End_time=D'2017.01.01 00:00';
input string Reverse_Settings="--------- Reverse for USD/XXX symbols ---------";
input bool ReverseChart=false;
input string DO_NOT_SET_ReverseChart="...for USD/JPY, USD/CAD, USD/CHF --";

input int Font_Size=8;

// GUI REMOVED FROM DEVELOPERS VERSION

//input bool GUI_Show=true;
//bool GUI=true;
//input string GUI_Hint="Press 'Z' to hide / 'X' to show GUI"; // GUI Hint

int Update_in_sec=15;


datetime TimeData[];
double VolumeData[];
double DeltaData[];

double info_Volume[];
double info_Ask[];
double info_Bid[];
double info_Delta_Pos[];
double info_Delta_Neg[];

double AskColor[];
double BidColor[];
double VolumeColor[];
double DeltaPosColor[];
double DeltaNegColor[];


string ver = "5.2";
//string MessageFromServer="";
datetime last_loaded=D'1970.01.01 00:00';
datetime myUpdateTime=D'1970.01.01 00:00';
int UpdateFreq=15; // sec
int OneTimeAlert=0;

string clusterdelta_client="";
string indicator_id="";
string indicator_name = "Volumes/AskBid/Delta";
string short_name="";
string HASH_IND=" ";

int GMT=0;
int GMT_SET=0;

int NumberRates=0;
datetime LastTime[];
bool ReverseChart_SET=false;

string Expiration="";
string FirstStringFromServer=""; // first string of response
int subwindow=0;
string Source="loading...";
datetime LoadMore_Time;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   

   LoadMore_Time=TimeCurrent();
   Custom_Start_time=Custom_Start_date;
   Custom_End_time=Custom_End_date;
   

   #ifdef __MQL4__
   
   SetIndexStyle(0,DRAW_HISTOGRAM);
   SetIndexBuffer(0,info_Volume);
   SetIndexLabel(0,"Volumes");

   SetIndexStyle(1,DRAW_HISTOGRAM);
   SetIndexBuffer(1,info_Ask);
   SetIndexLabel(1,"Ask");

   SetIndexStyle(2,DRAW_HISTOGRAM);
   SetIndexBuffer(2,info_Bid);
   SetIndexLabel(2,"Bid");

   SetIndexStyle(3,DRAW_HISTOGRAM);
   SetIndexBuffer(3,info_Delta_Pos);
   SetIndexLabel(3,"Delta+");

   SetIndexStyle(4,DRAW_HISTOGRAM);
   SetIndexBuffer(4,info_Delta_Neg);
   SetIndexLabel(4,"Delta-");

   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE); 
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);    
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE); 
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);    
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,EMPTY_VALUE);    
   #endif
   
   #ifdef __MQL5__
//--- indicator buffers mapping 
   SetIndexBuffer(0,info_Volume,INDICATOR_DATA); 
   SetIndexBuffer(1,VolumeColor,INDICATOR_COLOR_INDEX);    
   SetIndexBuffer(2,info_Ask,INDICATOR_DATA); 
   SetIndexBuffer(3,AskColor,INDICATOR_COLOR_INDEX);       
   SetIndexBuffer(4,info_Bid,INDICATOR_DATA); 
   SetIndexBuffer(5,BidColor,INDICATOR_COLOR_INDEX);       
   SetIndexBuffer(6,info_Delta_Pos,INDICATOR_DATA); 
   SetIndexBuffer(7,DeltaPosColor,INDICATOR_COLOR_INDEX);       
   SetIndexBuffer(8,info_Delta_Neg,INDICATOR_DATA); 
   SetIndexBuffer(9,DeltaNegColor,INDICATOR_COLOR_INDEX);       


//--- пустое значение 
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE); 
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);    
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);    
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);       
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,EMPTY_VALUE); 
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,EMPTY_VALUE);    
   PlotIndexSetDouble(6,PLOT_EMPTY_VALUE,EMPTY_VALUE);    
   PlotIndexSetDouble(7,PLOT_EMPTY_VALUE,EMPTY_VALUE);    
   PlotIndexSetDouble(8,PLOT_EMPTY_VALUE,EMPTY_VALUE); 
   #endif   

   IndicatorSetString(INDICATOR_SHORTNAME,indicator_name);
   IndicatorSetInteger(INDICATOR_DIGITS,0);


   // this block do not use ClusterDelta_Server but register for unique id
   do
   {
     clusterdelta_client = "CDPA" + StringSubstr(IntegerToString(TimeLocal()),7,3)+""+DoubleToString(MathAbs(MathRand()%10),0);     
     indicator_id = "CLUSTERDELTA_"+clusterdelta_client;
   } while (GlobalVariableCheck(indicator_id));
   GlobalVariableTemp(indicator_id);
   HASH_IND=clusterdelta_client;   
      
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


   CheckDLLExists();      
   ClearGarbage();


   EventSetMillisecondTimer(180);
   return (INIT_SUCCEEDED);

  }
  

bool IsDllAllowed()
{
  return (bool)TerminalInfoInteger(TERMINAL_DLLS_ALLOWED);

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

      if(NumberRates != rates_total)
      {
         #ifdef __MQL5__
         ArrayResize(LastTime, ArraySize(time));
         ArrayCopy(LastTime , time);
         #endif
         
      }
      
      NumberRates = rates_total;

      return (1);//MainCode();

  }
  
int MainCode()
{ 
//---check for rates total

   int data_is_ready;
   int online_is_ready;
   bool ready_to_fetch;

   int ix=0;
   int iBase;

   int count = 0;
   static int reload=0;   
   double myVolume=0, mydelta=0;

   //if(ArraySize(LastTime)==0) return 0;

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
   ChartRedraw(ChartID());      
   
   // if we got data before   
   if(!data_is_ready && !online_is_ready) { return 1; }// from GetData
   // data are in the buffer just show them

   int finish_idx=NumberRates-1;

   ix = NumberRates-1;
   if(ArraySize(TimeData)<finish_idx) finish_idx = ArraySize(TimeData) ;
   if (Custom_Start_time!=D'2017.01.01 00:00' || Custom_End_time!=D'2017.01.01 00:00') { finish_idx=NumberRates-1; }
   
   if (finish_idx ==0 ) return 0;

   ix =0;  

   while(ix<(NumberRates-finish_idx))
   {
      info_Ask[ix]=0;
      info_Bid[ix]=0;
      info_Volume[ix]=0;
      info_Delta_Pos[ix]=0;
      info_Delta_Neg[ix]=0;
      ix++; 
   }   
   
   int index = (NumberRates-finish_idx);   
   


   while(index < NumberRates)
   {
      
      #ifdef __MQL4__
        ix = NumberRates - 1 - index ;   
        iBase = SearchTimeIndex(Time[ix]);
      #endif
      
      #ifdef __MQL5__
        ix = index;
        iBase = SearchTimeIndex(LastTime[ix]);

        AskColor[ix]=0;
        BidColor[ix]=0;
        VolumeColor[ix]=0;
        DeltaNegColor[ix]=0;
        DeltaPosColor[ix]=0;
        
      #endif      
      
      
     if (iBase >= 0)
      {
         count++;             
         myVolume=VolumeData[iBase];
         mydelta=DeltaData[iBase];         

         double myAsk = MathRound((myVolume-0+mydelta)/2);         
         double myBid = myVolume - myAsk; //MathRound((myVolume-mydelta)/2);
         
         if(Volume_Layer) { info_Volume[ix]=myVolume; } else { info_Volume[ix]=EMPTY_VALUE; }
         if(AskBid_Layer && myAsk>=myBid) { info_Ask[ix] = myAsk; } else { info_Ask[ix]=EMPTY_VALUE; }
         if(AskBid_Layer && myAsk<myBid) {  info_Bid[ix] = myBid; } else { info_Bid[ix]=EMPTY_VALUE; }
         if(Delta_Layer)
         {
           if(mydelta>0) { info_Delta_Pos[ix]=mydelta; info_Delta_Neg[ix]=EMPTY_VALUE; } else { info_Delta_Neg[ix]=-mydelta; info_Delta_Pos[ix]=EMPTY_VALUE; }
         } else { info_Delta_Pos[ix]=EMPTY_VALUE; info_Delta_Neg[ix]=EMPTY_VALUE;}
         #ifdef __MQL5__
            if(!LoadMore_Time || LoadMore_Time>LastTime[ix]) { LoadMore_Time=LastTime[ix]; }                  
         #endif
         #ifdef __MQL4__
            if(!LoadMore_Time || LoadMore_Time>Time[ix]) { LoadMore_Time=Time[ix]; }         
         #endif
         
      } else
      {
         if(ix<NumberRates-1) {        
           if(Volume_Layer) info_Volume[ix]=EMPTY_VALUE;
           if(Delta_Layer) { info_Delta_Pos[ix]=EMPTY_VALUE; info_Delta_Neg[ix]=EMPTY_VALUE; }
           if(AskBid_Layer) { info_Ask[ix] = EMPTY_VALUE; info_Bid[ix] = EMPTY_VALUE; }
         }
      }      
      index++;
   }
   if(index == NumberRates)
   {
     //PutLoadMoreButton();
     //Removed from developers version

      /*
      if(LoadMoreButton is Clicked) // even to Load more history 
      {
           datetime CurrentEndTime = Custom_End_time;
           datetime CurrentLastLoaded =last_loaded;
           last_loaded = 0;
           Custom_End_time = LoadMore_Time;
           SetData();
           Custom_End_time = CurrentEndTime;
           last_loaded = CurrentLastLoaded;
           
      }*/
     
   }
   ChartRedraw(0);      
  

   return(1);
  }
//+------------------------------------------------------------------+

int SearchTimeIndex(datetime timeix)
{
      int iBase = ArrayBsearchCorrect(TimeData, timeix ); 

      if (iBase < 0 && Period() >= PERIOD_M5) { iBase = ArrayBsearchCorrect(TimeData, timeix - 1*60 ); } // 1 Min BrokenHour
      if (iBase < 0 && Period() >= PERIOD_M5) { iBase = ArrayBsearchCorrect(TimeData, timeix - 2*60 ); } // 1 Min BrokenHour      
      if (iBase < 0 && Period() >= PERIOD_M5) { iBase = ArrayBsearchCorrect(TimeData, timeix - 3*60 ); } // 1 Min BrokenHour            
      if (iBase < 0 && Period() >= PERIOD_M5) { iBase = ArrayBsearchCorrect(TimeData, timeix - 4*60 ); } // 1 Min BrokenHour                  
      if (iBase < 0 && Period() >= PERIOD_M15) { iBase = ArrayBsearchCorrect(TimeData, timeix - 5*60 ); } // 5 Min BrokenHour      
      if (iBase < 0 && Period() >= PERIOD_M15) { iBase = ArrayBsearchCorrect(TimeData, timeix - 10*60 ); } // 5 Min BrokenHour      
      if (iBase < 0 && Period() >= PERIOD_M30) { iBase = ArrayBsearchCorrect(TimeData, timeix - 15*60 ); } // 5 Min BrokenHour      
      if (iBase < 0 && Period() >= PERIOD_H1) { iBase = ArrayBsearchCorrect(TimeData, timeix - 30*60 ); } // 35 Min BrokenHour / ES      
      if (iBase < 0 && Period() >= PERIOD_H1) { iBase = ArrayBsearchCorrect(TimeData, timeix - 35*60 ); } // 35 Min BrokenHour / ES
      if (iBase < 0 && Period() >= PERIOD_H4) { iBase = ArrayBsearchCorrect(TimeData, timeix - 60*60 ); } // 60 Min BrokenHour / ES      
      if (iBase < 0 && Period() >= PERIOD_H4) { iBase = ArrayBsearchCorrect(TimeData, timeix + 60*60 ); } // 60 Min BrokenHour / ES            
      if (iBase < 0 && Period() >= PERIOD_H4) { iBase = ArrayBsearchCorrect(TimeData, timeix + 2*60*60 ); } // 120 Min BrokenHour / ES            
      if (iBase < 0 && Period() >= PERIOD_W1) { iBase = ArrayBsearchCorrect(TimeData, timeix + 24*60*60); } // 35 Min BrokenHour / ES      
      return iBase;
}

void OnDeinit(const int reason)
{
  
    GlobalVariableDel(indicator_id);
    EventKillTimer();

    ObjectDelete(0,"DLL files are not loaded");
    ObjectDelete(0,"User is not authorized");    

    int    obj_total=ObjectsTotal(0,-1,-1);
    GlobalVariableDel(indicator_id);
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
  
   string tmc;//=TimeToString(TimeTradeServer());
   string tm0;//=TimeToString(LastTime[NumberRates-1]);
   string lsl=TimeToString(last_loaded);
   string cst=TimeToString(Custom_Start_time);
   string cet=TimeToString(Custom_End_time);
   string cmp=AccountInfoString(ACCOUNT_COMPANY);
   int acnt=(int)AccountInfoInteger(ACCOUNT_LOGIN);
   
   #ifdef __MQL4__
     tmc = TimeToString(TimeCurrent());
     tm0 = TimeToString(Time[0]);
   #endif
     
   #ifdef __MQL5__
     if(NumberRates < 1) 
     {
         myUpdateTime = TimeLocal();
         return 0;
     }   
     tmc = TimeToString(TimeTradeServer());
     tm0 = TimeToString(LastTime[NumberRates-1]);
   #endif
  
  
  
  if(Instrument == "")
  {    
      Instrument="AUTO";
      switch (ChartInstrument) 
      {

        case 1: Instrument="6A"; break;
        case 2: Instrument="6B"; break;
        case 3: Instrument="6C"; break;
        case 4: Instrument="6E"; break;
        case 5: Instrument="6J"; break;
        case 6: Instrument="6S"; break;
        case 7: Instrument="6N"; break;
        case 8: Instrument="6M"; break;     
        
        case 11: Instrument="ES"; break;
        case 12: Instrument="NQ"; break;
        case 13: Instrument="YM"; break;
        case 14: Instrument="RTY"; break;
        case 15: Instrument="FDAX"; break;
        case 16: Instrument="FESX"; break;
        case 17: Instrument="DX"; break;
        case 18: Instrument="MNQ"; break;
        case 21: Instrument="BRN"; break;
        case 22: Instrument="CL"; break;
        case 23: Instrument="NG"; break;
        case 24: Instrument="GC"; break;
        case 25: Instrument="SI"; break;
        case 26: Instrument="HG"; break;
        case 27: Instrument="ZW"; break;
        case 28: Instrument="ZB"; break;
        case 30: Instrument="WIN"; break;
        case 31: Instrument="WDO"; break;
        
        case 41: Instrument="BTCUSDT"; break;        
        case 42: Instrument="ETHUSDT"; break;                
        case 51: Instrument="ADAUSDT"; break;                
        case 53: Instrument="APEUSDT"; break;
        case 55: Instrument="AVAXUSDT"; break;
        case 57: Instrument="BNBUSDT"; break;        
        case 60: Instrument="DOTUSDT"; break;        
        case 63: Instrument="FTMUSDT"; break;                
        case 64: Instrument="GMTUSDT"; break;
        case 65: Instrument="LINKUSDT"; break;
        case 66: Instrument="LITUSDT"; break;        
        case 67: Instrument="LTCUSDT"; break;        
        case 70: Instrument="NEARUSDT"; break;        
        case 71: Instrument="PEOPLEUSDT"; break;        
        case 80: Instrument="SOLUSDT"; break;                
        case 81: Instrument="TONUSDT"; break;
        case 82: Instrument="TRXUSDT"; break;
        case 83: Instrument="WAVESUSDT"; break;        
        case 84: Instrument="XRPUSDT"; break;        
        
     }
  }
      
  StringToUpper(Instrument);

  i = Send_Query(k,clusterdelta_client, sym, per, tmc, tm0, Instrument, lsl,MetaTrader_GMT,ver,Days_in_History,cst,cet,cmp,acnt);     

  if (i < 0) { Print ("Error during query registration"); return -1; }
  
  if(Period_To_Minutes()<=PERIOD_H1) {
    i = Online_Subscribe(k,clusterdelta_client, sym, per, tmc, tm0, Instrument, lsl,MetaTrader_GMT,ver,Days_in_History,cst,cet,cmp,acnt);       
  }
  
  return 1;
}  

int GetOnline()
{
   string response="";
   int length=0;   
   string key="";
   string mydata="";
   int block=0;
   if(Period_To_Minutes()>PERIOD_H1) return 0;

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
      int compare_minutes;
      StringSplit(mydata,StringGetCharacter("!",0),result);
      
      if(!GMT_SET)
      {
        StringSplit(result[2],StringGetCharacter(";",0),bardata);      
        if(VolumeData[ArraySize(VolumeData)-3] == StringToDouble(bardata[1])) // 3-rd bar in stream is 3rd in series
        {
          StringSplit(result[0],StringGetCharacter(";",0),bardata);                      
          compare_minutes = int( (double)(TimeData[ArraySize(TimeData)-1]) - StringToDouble(bardata[0]) );
          GMT = int(compare_minutes / 3600);
          GMT_SET=0;          
        } else
        if(VolumeData[ArraySize(VolumeData)-2] == StringToDouble(bardata[1])) // 3-rd bar in stream is 3rd in series
        {
          compare_minutes = int( (double)(TimeData[ArraySize(TimeData)-2]) - StringToDouble(bardata[0]) );
          GMT = int(compare_minutes / 3600);
          GMT_SET=0;
        } 
      }
      //Print(TimeToString((datetime)bardata[0]));
          StringSplit(result[0],StringGetCharacter(";",0),bardata);                
          UpdateArray(TimeData, VolumeData,DeltaData, StringToDouble(bardata[0])+3600*GMT, StringToDouble(bardata[1]),StringToDouble(bardata[2])*(ReverseChart_SET?-1:1));
          StringSplit(result[1],StringGetCharacter(";",0),bardata);               
          UpdateArray(TimeData, VolumeData,DeltaData, StringToDouble(bardata[0])+3600*GMT, StringToDouble(bardata[1]),StringToDouble(bardata[2])*(ReverseChart_SET?-1:1));
          //StringSplit(result[2],StringGetCharacter(";",0),bardata);               
          //UpdateArray(TimeData, ValueData, StringToDouble(bardata[0])+3600*GMT, StringToDouble(bardata[1]));          


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
   string detect[];   
   response = Receive_Information(length, clusterdelta_client);

   if (length==0) { return 0; }

    if(StringLen(response)>1) // if we got response (no care how), convert it to mt4 buffers
    {
      len=StringSplit(response,StringGetCharacter("\n",0),result);                
      if(!len) { return 0; }
      //MessageFromServer=result[0];
      
      FirstStringFromServer=result[0];
      StringSplit(FirstStringFromServer,' ',detect);
      if(ArraySize(detect)>2)
      {
         string inst = detect[1];
         Source = "#"+inst;
         if(inst == "6A") Source="#6A AUD/USD";
         if(inst == "6B") Source="#6B GBP/USD";
         if(inst == "6C") Source="#6C USD/CAD";         
         if(inst == "6E") Source="#6E EUR/USD";         
         if(inst == "6J") Source="#6J USD/JPY";
         if(inst == "6S") Source="#6S USD/CHF";
         if(inst == "6N") Source="#6N NZD/USD";
         if(inst == "6M") Source="#6M MXN/USD";
         if(inst == "FDAX") Source="#FDAX Dax30";
         if(inst == "BRN") Source="#BRN Brent Oil";
         if(inst == "CL") Source="#CL Crude Oil";
         if(inst == "BR") Source="#BR Brent Moex";
         if(inst == "GC") Source="#GC Gold (XAU/USD)";
         if(inst == "ES") Source="#ES S&P500";
         if(inst == "NQ") Source="#NQ Nasdaq100";
         if(inst == "YM") Source="#YM Dow Jones";
         if(inst == "DX") Source="#DX Dollar Index";
         if(inst == "ZB") Source="#ZB US Bonds";
         if(inst == "NG") Source="#NG Nat.Gas";
         if(inst == "SI") Source="#SI Silver (XAR/USD)";
         if(inst == "HG") Source="#HG Copper";
         if(inst == "ZW") Source="#ZW Wheat";
         if(inst  == "RTY") Source="#RTY Russel 2000";         
         if(inst == "FESX") Source="#FESX Euro Stoxx50";
         if(inst  == "MNQ") Source="#MNQ Micro Nasdaq";
         if(inst  == "WDO") Source="#WDO Brazilian Real";
         if(inst  == "WIN") Source="#WIN Bovespa Index";

         if(inst == "BTC") Source="#BTC Bitcoin";
         if(inst == "ETH") Source="#ETH Etherium";
         if(inst == "BTCUSDT") Source="#BTC Bitcoin";
         if(inst == "ETHUSDT") Source="#ETH Etherium";                    
         

         if(inst == "ADAUSDT") Source="#ADAUSDT Cardano";
         if(inst == "APEUSDT") Source="#APEUSDT ApeCoin";
         if(inst == "AVAXUSDT") Source="#AVAXUSDT";
         if(inst == "BNBUSDT") Source="#BNBUSDT";
         if(inst == "DOTUSDT") Source="#DOTUSDT Polkadot";
         if(inst == "FTMUSDT") Source="#FTMUSDT Fantom";
         if(inst == "GMTUSDT") Source="#GMTUSDT";
         if(inst == "LINKUSDT")Source="#LINKUSDT ChainLink";
         if(inst == "LITUSDT") Source="#LITUSDT Litentry";
         if(inst == "LTCUSDT") Source="#LTCUSDT Litecoin";
         if(inst == "NEARUSDT") Source="#NEARUSDT Near Pr.";
         if(inst == "PEOPLEUSDT")Source="#PEOPLEUSDT";
         if(inst == "SOLUSDT") Source="#SOLUSDT Solana";
         if(inst == "TONUSDT") Source="#TONUSDT Toncoin";
         if(inst == "TRXUSDT") Source="#TRXUSDT Tron";
         if(inst == "WAVESUSDT")Source="#WAVESUSDT Waves";
         if(inst == "XRPUSDT")Source="#XRPUSDT Ripple";
                    
      }
      
      
      for(i=1;i<len;i++)
      {
        if(StringLen(result[i])==0) continue;
        if(StringSubstr(result[i],0,3)=="Exp") 
        { 
           Expiration = StringSubstr(result[i],4); 
           continue; 
        } 
        
        if (StringSplit(result[i],StringGetCharacter(";",0),bardata)<3) continue;                
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
       #ifdef __MQL5__
         if(last_loaded>LastTime[NumberRates-1])last_loaded=LastTime[NumberRates-1]; 
       #endif
       
       #ifdef __MQL4__
         if(last_loaded>Time[0])last_loaded=Time[0];         
       #endif
       
      } 
      if (StringLen(FirstStringFromServer)>8 && OneTimeAlert==0) { 
          int gmt_shift_left_bracket = StringFind(FirstStringFromServer,"[");
          int gmt_shift_right_bracket = StringFind(FirstStringFromServer,"]");
          if (gmt_shift_left_bracket>0 && gmt_shift_right_bracket)
          {
            GMT = (int)StringSubstr(FirstStringFromServer,gmt_shift_left_bracket+1,gmt_shift_right_bracket-gmt_shift_left_bracket-1);
            GMT_SET=1;

          }
          OneTimeAlert=1; 
       } 

      if (StringLen(FirstStringFromServer)>8 && OneTimeAlert==1) 
      { 
         /*Print("MT4 Time ",TimeToString(TimeCurrent()),",  data source info:", FirstStringFromServer ); */
         OneTimeAlert=2;
      }      
      ExpirationIcon();      
      
    }
    return (1);
}


// ======================================================================================================================================================

void CheckDLLExists()
{

   if(!IsDllAllowed())
   {
      Print("Dll calls are not allowed. Press Ctrl+O -> Expert Advisers -> Check Allow DLL calls -> Press Ok ");
   }
   
   ChartRedraw();
   if (IsDllAllowed())
   {
     int test;
     Receive_Information(test, "");
     Online_Init(test,AccountInfoString(ACCOUNT_COMPANY),(int)AccountInfoInteger(ACCOUNT_LOGIN));     
     // WARNING:
     // If DLL files are missed, MT will crash there 
     ChartRedraw();
   }
}  



void UserNotAuthorized()
{

   Print ("User is not Authorized. Press A to call authorizer.\n");
   ChartRedraw();
}  


bool LabelCreate(const long              chart_ID=0,               // ID графика 
                 const string            name="Label",             // имя метки 
                 const int               sub_window=0,             // номер подокна 
                 const int               x=0,                      // координата по оси X 
                 const int               y=0,                      // координата по оси Y 
                 const ENUM_BASE_CORNER  corner=CORNER_LEFT_UPPER, // угол графика для привязки 
                 const string            text="Label",             // текст 
                 const string            font="Arial",             // шрифт 
                 const int               font_size=10,             // размер шрифта 
                 const color             clr=clrRed,               // цвет 
                 const double            angle=0.0,                // наклон текста 
                 const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER, // способ привязки 
                 const bool              back=false,               // на заднем плане 
                 const bool              selection=false,          // выделить для перемещений 
                 const bool              hidden=true,              // скрыт в списке объектов 
                 const long              z_order=0,
                 const string             tooltip=" ")                // приоритет на нажатие мышью 
  { 
//  ObjectDelete(chart_ID,name);
//--- сбросим значение ошибки 
   ResetLastError(); 
//--- создадим текстовую метку 
   if(ObjectCreate(chart_ID,name,OBJ_LABEL,sub_window,0,0)) 
     { 
         ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back); 
//--- включим (true) или отключим (false) режим перемещения метки мышью 
         ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection); 
         ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection); 
//--- скроем (true) или отобразим (false) имя графического объекта в списке объектов 
         ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden); 
     } 
//--- установим координаты метки 
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x); 
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y); 
//--- установим угол графика, относительно которого будут определяться координаты точки 
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner); 
//--- установим текст 
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text); 
//--- установим шрифт текста 
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font); 
//--- установим размер шрифта 
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size); 
//--- установим угол наклона текста 
   ObjectSetDouble(chart_ID,name,OBJPROP_ANGLE,angle); 
//--- установим способ привязки 
   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor); 
//--- установим цвет 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr); 
//--- отобразим на переднем (false) или заднем (true) плане 
//--- установим приоритет на получение события нажатия мыши на графике 
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order); 
   ObjectSetString(chart_ID,name,OBJPROP_TOOLTIP,tooltip);                 //--- установим текст    
//--- успешное выполнение 
   return(true); 
  } 



void ClearGarbage()
{
       int obj_total = ObjectsTotal(0,-1,-1);
       int w=ChartWindowFind();
       for(int i=0; i<obj_total; i++)
       {
         while(StringFind(ObjectName(0,i),"SETTINGS_CDPA")== -1 && StringFind(ObjectName(0,i),"CDPA")!=-1 && ObjectFind(0,ObjectName(0,i))==w) // check for settings
         {
           if(StringFind(ObjectName(0,i),HASH_IND)!=-1)
           {
              ObjectDelete(0, ObjectName(0,i));
           }else
           {
           //search it in the current window
              string gname = "CLUSTERDELTA_"+StringSubstr(ObjectName(0,i),StringLen(ObjectName(0,i))-8,8); // CLUSTERDELTA_CDPF1234
              if( GlobalVariableCheck(gname) == false && StringLen(gname)==21)
              {
                ObjectDelete(0, ObjectName(0,i));
              }  else { break; }
            }
            
         }
      
       }

}



int YearMQL4()
  {
   MqlDateTime tm;
   TimeCurrent(tm);
   return(tm.year);
  }


int DayMQL4()
  {
   MqlDateTime tm;
   TimeCurrent(tm);
   return(tm.day);
  }

int MonthMQL4()
  {
   MqlDateTime tm;
   TimeCurrent(tm);
   return(tm.mon);
  }

void ExpirationIcon()
{
   string date_format[];
   string exp_date_str, now_date_str;
   int exp_date, localdate;
   if(StringSubstr(FirstStringFromServer,0,5)=="Alert" || StringSubstr(FirstStringFromServer,0,5)=="Warni") // no access or no subscription
   {
     //IconRed
     UserNotAuthorized();
   } else          
   if(Expiration != "")
   {
     
     int n=StringSplit(Expiration,'.',date_format);
     
     if(n>=2)
     {
       exp_date_str = StringFormat("%d%02d%02d",StringToInteger(date_format[2]),StringToInteger(date_format[1]),StringToInteger(date_format[0]));
       now_date_str = StringFormat("%d%02d%02d",YearMQL4(),MonthMQL4(),DayMQL4());
       exp_date = (int)StringToInteger(exp_date_str);
       localdate = (int)StringToInteger(now_date_str);
       ObjectDelete(0,"User is not authorized"); 
       if(exp_date-localdate<=2 || n<3)  {  
         //IconOrange
       }
       else 
       {
         //IconGreen
       }
     } else
     if(StringSubstr(Expiration,0,2)=="no")
     {
        ObjectDelete(0,"User is not authorized"); 
        //IconOrange
     } else {
        //IconBlue
     }
     
   }
   else
   {
     //IconBlue
   }


}


void OnChartEvent(const int id,         // идентификатор события   
                  const long& lparam,   // параметр события типа long 
                  const double& dparam, // параметр события типа double 
                  const string& sparam  // параметр события типа string 
)
{
  int k;
  if(id == CHARTEVENT_KEYDOWN)
  {
    
    if((uint)sparam==30) // Xx
    {
        if(IsDllAllowed()) 
        {
          WindowDialog(k,"ClusterDelta#AskBid",AccountInfoString(ACCOUNT_COMPANY),IntegerToString((int)AccountInfoInteger(ACCOUNT_LOGIN)));       
        }       
    }
    
    
  }
  if(id==CHARTEVENT_OBJECT_CLICK)
  {
    
      if(sparam == "User is not authorized" || sparam== "DLL files are not loaded")
      {
        ObjectDelete(0, sparam);
      }      
  }      
  
  

  if(subwindow != ChartWindowFind())
  {
    // change something
    if(ChartWindowFind()>-1)
    {
      subwindow = ChartWindowFind();
    }
  }
}

