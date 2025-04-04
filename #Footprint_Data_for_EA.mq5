#property copyright "Copyright © 2011-2023, ClusterDelta.com"
#property link      "https://clusterdelta.com/footprint"
#property description "#FootPrint data for EA based on version 5.41 (compiled Dec 30, 2023)"
#property description "\n"
#property description "\nhttps://clusterdelta.com/footprint"
#property version "5.4"
#property strict 



#define ARGB(a,r,g,b)  ((uchar(a)<<24)|(uchar(r)<<16)|(uchar(g)<<8)|uchar(b))

// HINT FOR SETTINGS definition
#define RGB(b,g,r)  (color)((uchar(r)<<16)|(uchar(g)<<8)|uchar(b))
// NEVER USE IN REAL SITUATION

#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1





void Main_Func()
{
   // this function called from Main_Cycle()
   if(IDX==-1) return;
   datetime first_cluster = Clusters[ClusterINDEX(0)].opentime;
   datetime last_cluster = Clusters[ClusterINDEX(IDX)].opentime;
   
   //Print("Data for ",FuturesName, " " , DoubleToString(ticksize));
   Print(IntegerToString(IDX)+" Clusters for "+FuturesName+" were loaded");
   Print(TimeToString(first_cluster) + " " +TimeToString(last_cluster));
   
   GetClusters();
}

void GetClusters()
{
   
   if (IDX<0) return; // no clusters loaded
   if(Workspace.TickMultiplier == 0) return; // unknown tick size
   int i=0,q=0;
   
   q=0;
   while(q<=IDX)  // process all clusters 
   {  
      i=ClusterINDEX(q); // get them in sorted order
      
      // small checking if occasionaly we will get wrong value
      if(i>=ArraySize(Clusters)) { Print ("Unexpected error (GetClusters function)"); return; } 
      
      if(Clusters[i].need_regenerate_img == 1) // I use this key when new data to clusters come, so it needs to reprocess data
      {
        // if new data in the cluster needs recalculations
        ReCalculateCluster(i);
      
      }
      
            
      
      q++;
   }
      
}

int Main_Cycle()
{ 
   // called by timer each 250ms
   int data_is_ready;
   int footprint_is_ready;
   bool ready_to_fetch;
  
  

   ready_to_fetch=((TimeLocal() >= myUpdateTime) ? true : false );  // Data fetching each UpdateFreq sec. Do not set it less than 8 sec - it does not have a sense

   // check for any data in DLL buffer
   data_is_ready = GetData();                 // calling dll if there is a new session data 
   footprint_is_ready = GetFootprint();       // calling dll if there is a new stream data 

   if(data_is_ready || footprint_is_ready)    // any of them need to be processed in Main function
   {
     // NEW DATA COMES
     Main_Func();
   }


   if(ready_to_fetch) // time to get new session data
   {  
     SetData(Workspace.StartDate); // method to fetch it
     // if you need to call it without data
     // Main_Func();
     
   }
   
   return(1);
}





void ReCalculateCluster(int i, int timeIdx=0)
{
       if(!Workspace.TickSize || !Workspace.TickMultiplier) return;
       
       int askcurrent,bidcurrent;   
       double pricecurrent;
       double nextprice;

       int PriceNUM = 1+ (int)MathRound(NormalizeDouble((Clusters[i].high-Clusters[i].low),DigitsAfterComa)/Workspace.TickSize); // The number of items in array to process
       int GroupNUM = 1+ (int)MathRound((GroupPriceValue(Clusters[i].high)-GroupPriceValue(Clusters[i].low))/Workspace.TickMultiplier); // the total number of cells in cluster if TickMultiplier is used
       

       static int LastIDX=0;
       
       
       if(i == 0) Find_TopValue(); // 
       
       int sX=0; 
       int sY=0;
       int sX1 = 0;
       int sY1 = 0;
       int sY2 = 0;
       int sX2 = 0;


       int AskCumulate=0, BidCumulate=0;
       int cumK=0;
       int maxVolume_inCluster=1;



       // LOOKING FOR MAX VALUE INSIDE CLUSTER       
       pricecurrent=Clusters[i].high;
       for(int k=0; k<PriceNUM; k++)
       {
          getVolumeByPrice(i,pricecurrent,askcurrent,bidcurrent);
          AskCumulate += askcurrent;
          BidCumulate += bidcurrent;
          nextprice = NormalizeDouble(pricecurrent-Workspace.TickSize, DigitsAfterComa);
          if(GroupPriceValue(nextprice) != GroupPriceValue(pricecurrent) || k==PriceNUM-1 /* LAST VALUE */ )
          {
            int Volume_value = (AskCumulate + BidCumulate);
            int Delta_value = (AskCumulate - BidCumulate);
            if (maxVolume_inCluster < Volume_value) maxVolume_inCluster=Volume_value;
            AskCumulate=0;
            BidCumulate=0;
          } // groupvalue
          
          pricecurrent = nextprice;
       }
       

       // CALCULATE VALUES AREA
       int non_valuearea_size = (int)MathRound((100-ValueAreaPercent) * (Clusters[i].total_ask + Clusters[i].total_bid) / 100);
       int calculate = 0;
       int v_above=0;
       int v_bellow=0;
       double VAH_price=Clusters[i].high;
       double VAL_price=Clusters[i].low;
       while(calculate < non_valuearea_size)
       {
             
              if (v_above <= v_bellow)
              {
                getVolumeByPrice(i,VAH_price,askcurrent,bidcurrent);
                v_above = v_above + askcurrent+bidcurrent; 
                VAH_price = NormalizeDouble(VAH_price-Workspace.TickSize, DigitsAfterComa);
              }  else
              {
                getVolumeByPrice(i,VAL_price,askcurrent,bidcurrent);              
                v_bellow = v_bellow + askcurrent+bidcurrent;
                VAL_price = NormalizeDouble(VAL_price+Workspace.TickSize, DigitsAfterComa);
              }
              calculate = v_above+v_bellow;
       }

       
       // PROCESS THE CLUSTER FROM HIGHEST PRICE TO LOWEST
       AskCumulate=0; BidCumulate=0;
       cumK=0;
       pricecurrent=Clusters[i].high;
       for(int k=0; k<PriceNUM; k++)
       {

          getVolumeByPrice(i,pricecurrent,askcurrent,bidcurrent);
          AskCumulate += askcurrent;
          BidCumulate += bidcurrent;
          nextprice = NormalizeDouble(pricecurrent-Workspace.TickSize, DigitsAfterComa);
          if(GroupPriceValue(nextprice) != GroupPriceValue(pricecurrent) || k==PriceNUM-1 /* LAST VALUE */ )
          {
                // **** THE GENERATION CODE WAS REMOVED ****
              
              // HERE WE PROCESS THE ASK AND BID DATA EXACTLY FOR THE PRICE. 
              // ASK data is  AskCumulate
              // BID data is  BidCumulate
              // function is universal as for normal data so to the data with TickMultiplier
              // so to compare prices that would be equal in TickMultiplier>1 mode we use function GroupPriceValue
              
              
  
  
              // I KEEP SOME EXAMPLES ON HOW TO COMPARE DATA
              /*    
                  //Get_CellValue(cell_valuetype, AskCumulate, BidCumulate, CELL_VALUE);
                  //Get_CellColorScheme(cell_colorscheme, AskCumulate, BidCumulate, cell_is_currentprice, cell_BG, cell_Font, cell_Bold);
                  
                  
                  // INSIDE BODY CANDLE 
                  if((GroupPriceValue(pricecurrent)>=GroupPriceValue(Clusters[i].open) && GroupPriceValue(pricecurrent)<=GroupPriceValue(Clusters[i].close)) ||
                     (GroupPriceValue(pricecurrent)<=GroupPriceValue(Clusters[i].open) && GroupPriceValue(pricecurrent)>=GroupPriceValue(Clusters[i].close)))
                  {
                     
                     
                  }
                  
                  if(GroupPriceValue(pricecurrent) == GroupPriceValue(VAH_price) && Show_VAH_VAL)
                  {
                    // VAH PRICE
                  
                  }
                  if(GroupPriceValue(pricecurrent) == GroupPriceValue(VAL_price) && Show_VAH_VAL)
                  {
                    // VAL PRICE

                  
                  }
                  

                  if(CELL_VALUE!="")
                  {
                    // DRAW CELL VALUE

                  }
                  
                  
                  
            */
            
            if(COT && maxVolume_inCluster == (AskCumulate+BidCumulate))
            {
                 // MAX VOLUME IN CLUSTER - COT/POC
            }            

            AskCumulate=0;
            BidCumulate=0;
            cumK++;
          } // groupvalue
          
          pricecurrent = nextprice;
       }
        
       
       Clusters[i].modified=1;       
       Clusters[i].need_regenerate_img=0;
       return;
}



// EXPLANATIONS OF ARRAYS

// opetimeIdx - has sorted times of loaded clusters (it is always sorted in ascending order)
// visual example 
// [0]="20230105010000", [1]="20230105010500", [2]="20230105011000", [3]="20230105011500"
// but in real it keeps value in datetime type, NOT string
// so you would see it with TimeToString function. It is the the same as it in the Clusters[x].opentime

// clustersIdx -  has reference to Cluster array refereiing to its index in opentimeIdx
// [0]=0, [1]=1, [2]=2, [3]=3   - normal array after first load
// after loading history data opentimeIdx sorts in ascending mode and clustersIdx would be the next
// [0]=4, [1]=5, [2]=6, [3]=0, [4]=1, [5]=2, [6]=3  
// normally you do not have to care about it

// Two arrays above are the arrays that helps to have sorted Clusters using their opentime to improve performance using internal MQL sort functions

// Clusters contain information of each cluster and do not sort in any mode
// opentime - time of open candle
// open/close/high/low - OHLC
// total_ask, total_bid - summary data per bar
// cumdelta - cumulative data using previous period
// delta_min, delta_max - extremums in delta within bar
// need_regenerate_img - I keep this flag, you do not need it there but I need it in footprint 
// modified -this is also for footprint image generation. When I processed new data from previous key, I use this one to show new generated cluster image in footprint 
// onfly/previous_cluster - not user
// prices / ask / bid - NOT sorted arrays of data 
// prices[0]=1.0515, ask[0]=12, bid[0]=0
// prices[1]=1.0520, ask[1]=24, bid[1]=16
//....
// when cluster does not have more data you will meet
// prices[n]=0, ask[n]=0, bid[n]=0
// or you will reach a temporary end of array size
// it would be like n equals ArraySize(Clusters[x].prices)
//
//
// Clusters[index] - call to cluster
// 
// IDX - last existing index of Clusters
// for(q=0; q<=IDX; q++) - process data of all clusters
// if you need clusters withoud sorting just use Clusters[q] 
// but commonly it is needed sorted by open time
// so use
// i = ClustersINDEX{q)
// Clusters[i]...  - 
//
// Clusters[ClustersINDEX(IDX)] - the last cluster in time



int IDX=-1; // -1 means that no data loaded

struct Cluster {
  datetime opentime;
  string range_barid;  
  double open;   // OPEN price
  double close; // CLOSE price
  double high;  // HIGH price
  double low;   // LOW price
                // SUM OF ASK / BID  
  long total_ask;
  long total_bid;
  long cumdelta;
  long delta_min;
  long delta_max;
   
  int modified;
  int need_regenerate_img;
  int onfly;

  double prices[];
  long ask[];
  long bid[];
 
  int previous_cluster;
  
} Clusters[], LastMinute, MarketProfile, LastLoadedProfile;

long opentimeIdx[];
int clustersIdx[];






































































#include <tools/DateTime.mqh>



int NumberRates = 1; // Just for easy MT5 convert on Time[NumberRates-1]

string dll_clusterdelta_version="5.2";
string dll_footprint_version="1.0";
string footprint_ver = "5.4";
// import "clusterdelta_v5x2_x64.dll"

#ifdef __MQL4__

#import "clusterdelta_v5x6.dll"
string Receive_Information(int &, string);
int Send_Query(int &, string, string, int, string, string, string, string, string, string, int, string, string, string,int);
int WindowDialog(int &, string, string, string);
#import

// footprint_v1x0_x64.dll
#import "footprint_v1x0.dll"
string Footprint_Data(int&,string);
int Footprint_Subscribe(int &, string, string, int, string, string, string, string, string, string, int, string, string, string,int);
#import

#endif 

#ifdef __MQL5__

#import "clusterdelta_v5x6_x64.dll"
string Receive_Information(int &, string);
int Send_Query(int &, string, string, int, string, string, string, string, string, string, int, string, string, string,int);
int WindowDialog(int &, string, string, string);
#import

#import "footprint_v1x0_x64.dll"
string Footprint_Data(int&,string);
int Footprint_Subscribe(int &, string, string, int, string, string, string, string, string, string, int, string, string, string,int);
#import

#endif








enum TimeFrames { ·Current·TimeFrame=0, ·Custom·TimeFrame = 1, ·Range·Chart = -1 };

enum ChartFutures { ·AUTO=0, ·6A·AUDUSD=1, ·6B·GBPUSD=2, ·6C·CADUSD=3, ·6E·EURUSD=4, ·6J·JPYUSD=5, ·6S·CHFUSD=6, ·6N·NZDUSD=7, ·6M·MXNUSD=8,
                    ·FDAX·DAX30·Futures=9, ·BRN·Brent·Oil=10, ·CL·Crude·Oil=11, ·GC·XAUUSD·Gold=13, ·ES·SP500=14,
                    ·NQ·Nasdaq·100=15, ·YM·Dow·Jones=16, ·DX·Dollar·Index=17, ·ZB·US·Bonds=18, ·NG·Natural·Gas=19, ·SI·XAGUSD·Silver=20,
                    ·HG·Copper=21, ·ZW·Wheat=22, ·BTC·Bitcoin=23, ·ETH·Etherium=28, ·FESX·Euro·Stoxx50=29,
                    ·NIFTY·NSE·Index=30, ·BANKNIFTY·NSE·Index=31                    };                    


input bool ONLINE_STREAM=false; // Connect to stream data 


input ChartFutures ChartInstrument=·AUTO; // Futures Name (http://clusterdelta.com/ticker) or leave AUTO
input string MetaTrader_GMT="AUTO"; // GMT of MetaTrader (on Open Market leave AUTO)
input int Online_TimeOut=30; // Inactivity timeout in seconds for auto adjusting workspace

input int TopPercent=85; // Top Values Level (Range 0-100)
input int MajorPercent=68; // Major Values Level (0-100), Major < Top
input int MinorPercent=0; // Minor Values Level (0-100), Minor < Major
input int TopValue_koef=1; // Percent of Total Candles for Top Value Calculation (0-100)
input bool COT=true; // Show POC/COT on the Candle 
input bool ForceChartToBackground=true;

input int TimeFrame_in_Minutes=0; // Custom TimeFrame in Minutes 
input int _Range_CustomTicks=30; // Number of ticks per Range bar

input int ChartTickMultiplier= 1; // Predefined Tick Multiplier

input bool Maximize_Mode = false; // Maximized Mode (true) on Start or Normal (false)
input int Minimum_TopValue=100; // Minimum TopValue on Start
input int Maximum_TopValue=0; // Maximum TopValue on Start (0 - auto)
input int _Online_Bar=2; // Shift from right edge (in bars) for online purposes

input string ___________________________="--- Reverse Pairs settings ---";
input bool Reverse_6C_to_USDCAD=true;
input bool Reverse_6J_to_USDJPY=true;
input bool Reverse_6M_to_USDMXN=true;
input bool Reverse_6S_to_USDCHF=true;


input bool Show_VAH_VAL = false;
input int  ValueAreaPercent = 68; // Percentage of Value Are










int Online_Bar=_Online_Bar;    
int Range_CustomTicks=_Range_CustomTicks;




bool STOP_DATA_LOADING=false;      


//datetime Custom_Start_time=D'2020.01.01 00:00';
datetime Custom_End_time=D'2020.01.01 00:00';
bool ReverseChart=false;

string clusterdelta_client=""; // key to DLL
string indicator_id=""; // Indicator Global ID
string indicator_name = "ClusterDelta #FootPrint";
bool ReverseChart_SET=false; // for USD/ pairs
int greatest_Volume=0; 

datetime myUpdateTime=D'1970.01.01 00:00'; // init of fvar

string MessageFromServer=""; // first string of response
string FirstStringFromServer=""; // first string of response

string HASH_IND=" ";
bool query_in_progress=false;
datetime last_loaded=0;
string last_rangeid="";
int Days=0;
int UpdateFreq=15;
string Instrument;

int LoadHistory=0;
int RangeTimeAndSalesComplete=0;




int OrderflowIDX=-1;
datetime last_known_range_time;
int last_known_range_id ;

int ts_clean_id=0;

struct wsstruct {
  int chartwidth;
  int chartheight;
  int Width;
  int Height;
  int PricePanelWidth;
  int X;
  int Y;
  int OffsetX;  
  int OffsetY;

  int TimePanelWidth;  
  int NavPanelWidth;  
  int NavPanelHeight;
  int TimePanelHeight;

  double HighestPrice;
  double LowestPrice;
  double TickSize;
  datetime MinTime;
  datetime MaxTime;

  datetime Load_MinTime;
  datetime Load_MaxTime;

  
  int BAR_CLUSTER_WIDTH;
  int PRICE_HEIGHT;
  
  datetime StartDate;  
  
  
  int TickMultiplier;
  
  string CURRENT_TIMEFRAME;  
  string CURRENT_CHARTTYPE;
  
  
      
  
  int MinorPercent;
  int MajorPercent;
  int TopPercent;
   
  int TopValueVolume;
  int TopValueDelta;
  int TopValueAsk;
  int TopValueBid;
  
  int TopValue_k;
  int AboutX;
  int AboutY;

  int IndicatorsX;
  int IndicatorsY;
  
  
  
  
} Workspace;




int MAXIDX=5000;

double ticksize; // minimum change 
int DigitsAfterComa=0;
int GMT=0;

double CURRENT_PRICE;



string FuturesName="";
string Expiration="";



//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   
   CheckDLLExists();   
   
//---- name for DataWindow and indicator subwindow label
   IndicatorSetString(INDICATOR_SHORTNAME,indicator_name);
//---- indicator digits
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//----

   ArrayFill(clustersIdx,0,ArraySize(clustersIdx),0);
   ArrayFill(opentimeIdx,0,ArraySize(opentimeIdx),0);

   //Comment(" ");
   //ObjectDelete(0,"User is not authorized");    

   // this block do not use ClusterDelta_Server but register for unique id
   do
   {
     clusterdelta_client = "CDPF" + StringSubstr(IntegerToString(TimeLocal()),7,3)+""+DoubleToString((MathAbs(MathRand()+ChartID())%10),0);     
     indicator_id = "CLUSTERDELTA_"+clusterdelta_client;
   } while (GlobalVariableCheck(indicator_id));
   GlobalVariableTemp(indicator_id);
   HASH_IND=clusterdelta_client;   
   
   

   ReverseChart_SET=ReverseChart;

   Days=1;

   DefaultWorkspace(); // init values of Workspace
   int i=0;


   if(ONLINE_STREAM) Print("ONLINE STREAM ENABLED"); else Print("ONLINE STREAM DISABLED");

   EventSetMillisecondTimer(250);   
   return (INIT_SUCCEEDED);

  }
   


void OnTimer()
{
  Timer();
} 

void Timer()
{
   if(STOP_DATA_LOADING) return;
  
   Main_Cycle();
}
//+------------------------------------------------------------------+
  
void start()
{

}  

void DefaultWorkspace()
{
   ArrayResize(Clusters,MAXIDX);
   ArrayResize(opentimeIdx, MAXIDX);
   ArrayResize(clustersIdx, MAXIDX);

   Workspace.TopValue_k=TopValue_koef;
   
   Workspace.MinorPercent=MinorPercent;
   Workspace.MajorPercent=MajorPercent;
   Workspace.TopPercent=TopPercent;

   Workspace.TickMultiplier=1;
   if(ChartTickMultiplier>=1 && ChartTickMultiplier<=1000) Workspace.TickMultiplier=ChartTickMultiplier;
   if(Online_Bar<2) Online_Bar=2;

   Instrument="";
   ResetChartData();
   

   if(Instrument == "")
   {    
      switch (ChartInstrument) {
        case 0: Instrument="AUTO"; break;   
        case 1: Instrument="6A"; break;
        case 2: Instrument="6B"; break;
        case 3: Instrument="6C"; break;
        case 4: Instrument="6E"; break;
        case 5: Instrument="6J"; break;
        case 6: Instrument="6S"; break;
        case 7: Instrument="6N"; break;
        case 8: Instrument="6M"; break;     
        case 9: Instrument="FDAX"; break;
        case 10: Instrument="BRN"; break;
        case 11: Instrument="CL"; break;
        //case 12: Instrument="BR"; break;
        case 13: Instrument="GC"; break;
        case 14: Instrument="ES"; break;
        case 15: Instrument="NQ"; break;
        case 16: Instrument="YM"; break;
        case 17: Instrument="DX"; break;
        case 18: Instrument="ZB"; break;
        case 19: Instrument="NG"; break;
        case 20: Instrument="SI"; break;
        case 21: Instrument="HG"; break;
        case 22: Instrument="ZW"; break;
        case 23: Instrument="BTC"; break;
        //case 24: Instrument="RI"; break;
        case 29: Instrument="FESX"; break;
        //case 26: Instrument="MM"; break;
        //case 27: Instrument="MBT"; break;
        case 28: Instrument="ETH"; break;
        case 30: Instrument="NIFTY"; break;                
        case 31: Instrument="BANKNIFTY"; break;                
        
      }
   }

   
   
   Workspace.CURRENT_TIMEFRAME = IntegerToString(TimeFrame_in_Minutes); 
   
     if(TimeFrame_in_Minutes>300 && TimeFrame_in_Minutes % 60 !=0) 
     {
        Workspace.CURRENT_TIMEFRAME = IntegerToString(TimeFrame_in_Minutes - TimeFrame_in_Minutes%60 );
     }
     
     if(TimeFrame_in_Minutes>1440 && TimeFrame_in_Minutes % 1440 !=0) 
     {
        Workspace.CURRENT_TIMEFRAME = IntegerToString(TimeFrame_in_Minutes - TimeFrame_in_Minutes%1440 );
     }
   
   if( Workspace.CURRENT_TIMEFRAME == "0") { Workspace.CURRENT_TIMEFRAME=IntegerToString(Period_To_Minutes()); }
   

   ArrayResize(LastMinute.prices,40);
   ArrayFill(LastMinute.prices, 0,40,0);   
   ArrayResize(LastMinute.ask,40);
   ArrayFill(LastMinute.ask, 0,40,0);   
   ArrayResize(LastMinute.bid,40);
   ArrayFill(LastMinute.bid, 0,40,0);   
   RangeTimeAndSalesComplete=0;
}




void ResetChartData()
{
  if(!IsDllsAllowed())
   {
     CheckDLLExists();
   }
   int i=0;
   IDX=-1;
   Workspace.MinTime=0;
   Workspace.MaxTime=0;
   Workspace.Load_MaxTime=0;
   Workspace.Load_MinTime=0;
   Workspace.StartDate = TimeLocal(); 
   Workspace.TopValueVolume=Minimum_TopValue;  
   if(Maximum_TopValue>0 && Maximum_TopValue>Minimum_TopValue) Workspace.TopValueVolume=Maximum_TopValue;  
   Workspace.TopValueDelta=1;  
   Workspace.TopValueAsk=1;  
   Workspace.TopValueBid=1;  
   ticksize=0;
   Workspace.HighestPrice=0;   
   Workspace.LowestPrice=0;   
   Workspace.TickMultiplier=ChartTickMultiplier;
   last_loaded=0;
   FuturesName="";
   LoadHistory=0;
   DigitsAfterComa=0;
   ticksize=0;
   Workspace.TickSize=0;
   
   OrderflowIDX=-1;
   RangeTimeAndSalesComplete=0;
   
 
   string old_id=indicator_id;  
   do
   {
     clusterdelta_client = "CDPF" + StringSubstr(IntegerToString(TimeLocal()),7,3)+""+DoubleToString(MathAbs(MathRand()%10),0);     
     indicator_id = "CLUSTERDELTA_"+clusterdelta_client;
   } while (GlobalVariableCheck(indicator_id));
   if(old_id!="") { GlobalVariableDel(old_id); }
   GlobalVariableTemp(indicator_id);
   
   
}


void OnDeinit(const int reason)
{

   GlobalVariableDel(indicator_id);
   EventKillTimer();

   return;
}


int GetFootprint()
{
   if(STOP_DATA_LOADING) return 0;
   string ts_stream;
   int length=0,rows;   
   string stream[],lines[],candle[],data[];
   string bartime, open,close;
   CDateTime BarOpen;
   datetime newDateTime;
   uint pause=GetTickCount();
   if(IDX<0) return -1;
   if(IsDllsAllowed())
   {
     ts_stream = Footprint_Data(length, clusterdelta_client);
   }
   if(length  == 0) { return 0; }
   //Print (ts_stream);
   int myPeriod = (int)StringToInteger(Workspace.CURRENT_TIMEFRAME);   
   if(IDX==-1) return -1; // no data ready
   if(StringToInteger(Workspace.CURRENT_TIMEFRAME)<0) return -2;
   if(StringLen(ts_stream))
   {
      
      rows =StringSplit(ts_stream, '\n', lines);
      for(int i=0; i<rows; i++)
      {
        if(StringSplit(lines[i],':',stream)>=3)
        {
          if(stream[0] == clusterdelta_client && StringToUpper(stream[1])==StringToUpper(FuturesName))
          {
           if((FuturesName == "6S" && Reverse_6S_to_USDCHF) || (FuturesName == "6C" && Reverse_6C_to_USDCAD))
           {
             ForceRoundIncomingPrice=5; // Looks like DigitsAfterComa will work also
             
           } else
           if(FuturesName == "6J" && Reverse_6J_to_USDJPY)
           {
             ForceRoundIncomingPrice=3; // Looks like DigitsAfterComa will work also
             
           } else
           if(FuturesName == "6M" && Reverse_6M_to_USDMXN)
           {
             ForceRoundIncomingPrice=3; // Looks like DigitsAfterComa will work also
             
           } else
           {
             ForceRoundIncomingPrice=0;
           
           }
           

          
             // that is our stream
             bartime="";
             int n=StringSplit(stream[2],'|',candle);
             if(n>=1)
             {
               int r=StringSplit(candle[0],';',data);
               if(r>=3)
               {
                  bartime=data[0];
                  open=data[1];
                  close=data[2];
                  
               }
             }
             
             if(bartime!="")
             {
                BarOpen.Year((int)StringToInteger(StringSubstr(bartime,0,4)));
                BarOpen.Mon((int)StringToInteger(StringSubstr(bartime,4,2)));
                BarOpen.Day((int)StringToInteger(StringSubstr(bartime,6,2)));
                BarOpen.Hour((int)StringToInteger(StringSubstr(bartime,8,2)));
                BarOpen.Min((int)StringToInteger(StringSubstr(bartime,10,2)));
                BarOpen.Sec(0); // we get 1min close bar so open is 0
                
                if(BarOpen.DateTime() < LastMinute.opentime) continue; // Time & sales behind clusters (something bad happens)
                int cindex = ClusterINDEX(IDX);
                if(TimeToString(BarOpen.DateTime(),TIME_DATE) != TimeToString(Clusters[cindex].opentime,TIME_DATE))
                {
                  // different days between LastMinute and Stream
                  // we may allow it only if it monday open
                  if(!(BarOpen.day_of_week == 1 && BarOpen.hour<=1)) continue;
                }
                
                   
                
                
                //int StreamStatus=0;
                //if(BarOpen.DateTime() == LastMinute.opentime) StreamStatus=1;
                if(BarOpen.DateTime() > LastMinute.opentime)  {
                     LastMinute.opentime = BarOpen.DateTime();
                     ArrayResize(LastMinute.prices, 40);
                     ArrayResize(LastMinute.ask, 40);
                     ArrayResize(LastMinute.bid, 40);
                     ArrayFill(LastMinute.prices,0,40,0);
                     ArrayFill(LastMinute.ask, 0,40,0);
                     ArrayFill(LastMinute.bid, 0,40,0);
                     LastMinute.delta_max=0;
                     LastMinute.delta_min=0;
                     
                }
                int mindex = ClusterINDEX(IDX);
                if(Clusters[mindex].opentime+myPeriod*60<=BarOpen.DateTime() && myPeriod>0) // T&S ahead clusters. Need new record
                {
                  int w=1;
                  do
                  {
                    newDateTime = Clusters[mindex].opentime+w*myPeriod*60;
                    w++;
                  } while (newDateTime+myPeriod*60<BarOpen.DateTime());
                  
                   
                   IDX=IDX+1;        
                   if(IDX>=MAXIDX)
                   {
                      MAXIDX=MAXIDX+5000;ArrayResize(Clusters,MAXIDX);ArrayResize(opentimeIdx, MAXIDX);ArrayResize(clustersIdx, MAXIDX);
                   }
                   
                   string s = TimeToString(newDateTime,TIME_DATE|TIME_MINUTES);
                   opentimeIdx[IDX]=StringToInteger(StringSubstr(s,2,2)+StringSubstr(s,5,2)+StringSubstr(s,8,2)+StringSubstr(s,11,2)+StringSubstr(s,14,2)+"0000000")/*+ bartime*100000000*/+0;
                   

                   //opentimeIdx[IDX]=newDateTime*100000000+0;
                   clustersIdx[IDX]=IDX;
                   

                   Clusters[IDX].open = NormalizeDouble(StringToDouble(open),DigitsAfterComa);
                   Clusters[IDX].close = NormalizeDouble(StringToDouble(close),DigitsAfterComa);
                   if(ForceRoundIncomingPrice)
                   {
                      Clusters[IDX].open = NormalizeDouble(1/StringToDouble(open),ForceRoundIncomingPrice);
                      Clusters[IDX].close = NormalizeDouble(1/StringToDouble(close),ForceRoundIncomingPrice);
                   }
                   
                   Clusters[IDX].high = Clusters[IDX].open >= Clusters[IDX].close ? Clusters[IDX].open:Clusters[IDX].close ;
                   Clusters[IDX].low = Clusters[IDX].open >= Clusters[IDX].close ? Clusters[IDX].close:Clusters[IDX].open;
                   Clusters[IDX].opentime = newDateTime;
                   Clusters[IDX].total_ask = 0;
                   Clusters[IDX].total_bid = 0;
                   Clusters[IDX].cumdelta = 0;
                   Clusters[IDX].delta_max = 0;
                   Clusters[IDX].delta_min = 0;
                   //Clusters[IDX].width = 0;
                   //Clusters[IDX].height = 0;
                   Clusters[IDX].need_regenerate_img=0;
                   Clusters[IDX].onfly =0;
                   Clusters[IDX].previous_cluster=ClusterINDEX(IDX-1);
                   ArrayResize(Clusters[IDX].prices,40);
                   ArrayResize(Clusters[IDX].ask,40);
                   ArrayResize(Clusters[IDX].bid,40);

                   ArrayFill(Clusters[IDX].prices,0,ArraySize(Clusters[IDX].prices),0);
                   ArrayFill(Clusters[IDX].ask,0,ArraySize(Clusters[IDX].ask),0);
                   ArrayFill(Clusters[IDX].bid,0,ArraySize(Clusters[IDX].bid),0);
                   
                   Clusters[ClusterINDEX(IDX-1)].need_regenerate_img=1; // remove Current Price    
                   // new records created 
                
                }
                  
                double price;
                long deltaAsk,deltaBid,newAsk,newBid;
                
                for(int j=1;j<n;j++) // n=number of cluster inside information
                {
                  int k=StringSplit(candle[j],';',data);
                  if(k>=3)
                  {
                    // DATA FROM STREAM
                    price = NormalizeDouble(StringToDouble(data[0]),DigitsAfterComa);
                    deltaAsk = StringToInteger(data[1]); // VALUE  FROM STREAM FOR 1 MIN
                    deltaBid = StringToInteger(data[2]); 
                    if(ForceRoundIncomingPrice)
                    {
                      price = NormalizeDouble(1/StringToDouble(data[0]),ForceRoundIncomingPrice);
                      deltaAsk = StringToInteger(data[2]); // VALUE  FROM STREAM FOR 1 MIN
                      deltaBid = StringToInteger(data[1]); 
                    }
                    
                    if(price==0 || deltaAsk<0 || deltaBid<0) continue;
                      int t;
                      int sp=ArraySize(LastMinute.prices);
                      for(t=0;t<sp;t++)
                      {
                        if(LastMinute.prices[t] == price)
                        {
                           newAsk = deltaAsk;
                           newBid = deltaBid;
                           deltaAsk = deltaAsk - LastMinute.ask[t]; // LastMinute.ask is VALUE FROM 1 MIN THAT ALREADY IN HIGHER CLUSTER
                           deltaBid = deltaBid - LastMinute.bid[t];
                           LastMinute.ask[t]=newAsk;
                           LastMinute.bid[t]=newBid;
                           break;
                        }
                        if(LastMinute.prices[t] == 0) break;
                      }
                      if(t>=sp) // save changes in LastMinue
                      {
                          ArrayResize(LastMinute.prices, t+40);
                          ArrayResize(LastMinute.ask, t+40);
                          ArrayResize(LastMinute.bid, t+40);
                          ArrayFill(LastMinute.prices, t,40,0);
                          ArrayFill(LastMinute.ask, t,40,0);
                          ArrayFill(LastMinute.bid, t,40,0);
                          
                      }
                      if(LastMinute.prices[t] == 0) 
                      {
                          LastMinute.prices[t]=price;
                          LastMinute.ask[t]=deltaAsk;
                          LastMinute.bid[t]=deltaBid;
                      } 
                      int eindex = ClusterINDEX(IDX);
                      if (Clusters[eindex].opentime+myPeriod*60 > BarOpen.DateTime() && myPeriod>0) // LOOKS like IDX is last Cluster
                      {
                        for(t=0; t<ArraySize(Clusters[ClusterINDEX(IDX)].prices); t++)
                        {
                           if(Clusters[ClusterINDEX(IDX)].prices[t] == price) break;
                           if(Clusters[ClusterINDEX(IDX)].prices[t] == 0) break;
                        }
                        if(t == ArraySize(Clusters[ClusterINDEX(IDX)].prices)) // new Price in this cluster
                        {
                          ArrayResize(Clusters[ClusterINDEX(IDX)].prices,t+40);
                          ArrayResize(Clusters[ClusterINDEX(IDX)].ask,t+40);
                          ArrayResize(Clusters[ClusterINDEX(IDX)].bid,t+40);
                          ArrayFill(Clusters[ClusterINDEX(IDX)].prices,t,40,0);
                          ArrayFill(Clusters[ClusterINDEX(IDX)].ask,t,40,0);
                          ArrayFill(Clusters[ClusterINDEX(IDX)].bid,t,40,0);
                        }
                        if(Clusters[ClusterINDEX(IDX)].prices[t] == 0)
                        {
                          Clusters[ClusterINDEX(IDX)].ask[t]=0;
                          Clusters[ClusterINDEX(IDX)].bid[t]=0;
                          Clusters[ClusterINDEX(IDX)].prices[t]=price;
                        }
                        if(deltaAsk<0) deltaAsk=0;
                        if(deltaBid<0) deltaBid=0;
                        Clusters[ClusterINDEX(IDX)].ask[t]=Clusters[ClusterINDEX(IDX)].ask[t]+deltaAsk;
                        Clusters[ClusterINDEX(IDX)].bid[t]=Clusters[ClusterINDEX(IDX)].bid[t]+deltaBid;
                        Clusters[ClusterINDEX(IDX)].total_ask+=deltaAsk;
                        Clusters[ClusterINDEX(IDX)].total_bid+=deltaBid;
                        //MarketProfileOnlineData(Clusters[ClusterINDEX(IDX)].opentime, price, deltaAsk, deltaBid);
                        long delta = Clusters[ClusterINDEX(IDX)].total_ask-Clusters[ClusterINDEX(IDX)].total_bid;
                        if(delta < Clusters[ClusterINDEX(IDX)].delta_min) Clusters[ClusterINDEX(IDX)].delta_min = delta ;
                        if(delta > Clusters[ClusterINDEX(IDX)].delta_max) Clusters[ClusterINDEX(IDX)].delta_max = delta ;
                        Clusters[ClusterINDEX(IDX)].cumdelta = delta;
                        if(ClusterINDEX(IDX)>0) 
                        {
                           int prev_id = Clusters[ClusterINDEX(IDX)].previous_cluster;
                           if(prev_id>=0)
                             Clusters[ClusterINDEX(IDX)].cumdelta=Clusters[ClusterINDEX(IDX)].cumdelta+Clusters[prev_id].cumdelta; // +  prev cumdelta
                        }
                        if(price>Clusters[ClusterINDEX(IDX)].high) { Clusters[ClusterINDEX(IDX)].high=price; }
                        if(price<Clusters[ClusterINDEX(IDX)].low) { Clusters[ClusterINDEX(IDX)].low=price; }
                        Clusters[ClusterINDEX(IDX)].need_regenerate_img=1;
                        Clusters[ClusterINDEX(IDX)].close=NormalizeDouble(StringToDouble(close),DigitsAfterComa);
                        CURRENT_PRICE = NormalizeDouble(StringToDouble(close),DigitsAfterComa);
                        if(ForceRoundIncomingPrice)
                        {
                          Clusters[ClusterINDEX(IDX)].close=NormalizeDouble(1/StringToDouble(close),ForceRoundIncomingPrice);
                          CURRENT_PRICE = NormalizeDouble(1/StringToDouble(close),ForceRoundIncomingPrice);
                        
                        } 

                      } // opentime
                                        
                    // LOOKING FOR CURRENT VALUES IN LAST CLUSTER
                  } // k>=2, so data is valid
                
                } // for j
                

                Clusters[ClusterINDEX(IDX)].need_regenerate_img=1;
                /*
                //REGENERATE BITMAP FOR Last Cluster
                if(IDX>0)  DrawCluster(IDX-1);//since idx-1
                      else DrawCluster(IDX);
                */
             } // bartime
          } // stream[0] == clusterdelta_client
        } // ts_Stream, stream
      }// for i=0;
      

   } // StringLen

   return length;
}







int SetData(datetime startDate, int mindays=0, int SkipOptimization=0)
{

  if(STOP_DATA_LOADING) return -1;   
  if(ArraySize(Time)==0) return -1;
  if(!IsDllsAllowed()) return 0;
  if(query_in_progress && (TimeLocal()-myUpdateTime)<60) return -1;
  query_in_progress=true;
  myUpdateTime = TimeLocal() + UpdateFreq;
  int k=0,i=0;

  CDateTime startTime;
  CDateTime endTime;
  
  startTime.DateTime(startDate);
  startTime.Hour(0);
  startTime.Min(0);
  startTime.Sec(0);
  startTime.DayDec(startTime.day_of_week==0?2:(startTime.day_of_week==6?1:0)); 
  endTime=startTime;
 
 
  if(mindays>=0)
  {
  
    endTime.DayInc(endTime.day_of_week==0 || endTime.day_of_week==6 ? 7+mindays : 7-endTime.day_of_week+mindays);
    startTime.MinDec((int)MathAbs(StringToInteger(Workspace.CURRENT_TIMEFRAME))*19);
  } else
  {
    endTime.DateTime(Workspace.MinTime);
    endTime.Hour(0);endTime.Min(0);endTime.Sec(0);
    endTime.DayInc(1);
  }
  

  if(IsDllsAllowed())
  {
     i = Send_Query(k,clusterdelta_client, Symbol(), (int)StringToInteger(Workspace.CURRENT_TIMEFRAME), TimeToString(TimeCurrent()), TimeToString(Time[NumberRates-1]), Instrument, TimeToString(last_loaded),MetaTrader_GMT,footprint_ver,(int)StringToInteger(last_rangeid),TimeToString(startTime.DateTime()),TimeToString(endTime.DateTime()),AccountCompany(),AccountNumber());     
  

     if(StringToInteger(Workspace.CURRENT_TIMEFRAME)>0 && ONLINE_STREAM)
     {
        Footprint_Subscribe(k,clusterdelta_client, Symbol(), 1, TimeToString(TimeCurrent()), TimeToString(Time[NumberRates-1]), Instrument, TimeToString(last_loaded),"AUTO",footprint_ver,0,"","",AccountCompany(),AccountNumber());     
     } 
  }

//  SLastRedrawMicroSeconds = GetMicrosecondCount()/10000;
  return 1;
}  

int ForceRoundIncomingPrice=0;

int GetData()
{
   if(STOP_DATA_LOADING) return 0;
   string response="";
   int length=0;
   
   
   string lines[];
   string v[];
   string candle[];
   string ohlc[];
   string data[], askbid[];
   string tsdata[];   
   int rows=0;
   int m, e, i, n, p, d, b, k, c, j;
   long ask, bid;

   int index;
   int init_last_range=0;
   string barstartid;
   int barid;
   int last_cluster_idx=-1;
   datetime bartime;
   datetime maxdate;
   datetime prevdate=D'1970.01.01 00:00:00';
   int maxbarid;
   
   double baropen,barhigh,barlow,barclos, price;
   int mindelta=0;
   int maxdelta=0;
   string ticksizeStr;
   ulong perfomance = GetTickCount();
   if(IsDllsAllowed())
   {
     response = Receive_Information(length, clusterdelta_client);
   }
   datetime my_last_known_range_time =0;
   int my_last_known_range_id =0;                       

   if (length==0) { return 0; }
   
   query_in_progress=false;
   maxdate = last_loaded;
   maxbarid = (int)StringToInteger(last_rangeid);
   
    if(StringLen(response)>1) // if we got response (no care how), convert it to mt4 buffers
    { 
        //Print("Response size (bytes): ",StringLen(response));
        // Comment(response);
       
       
       rows =StringSplit(response, '\n', lines);
       if(rows) 
       {
         FirstStringFromServer=lines[0];

         if(StringSubstr(FirstStringFromServer,0,5)=="Alert") 
         {
             UserNotAuthorized();
         }
         
       }

       if(rows>1)
       {
         e=StringSplit(lines[0], ' ', v);
         
         if(e>=4)
         {
           string myticker = v[0];
           FuturesName=myticker;
           Instrument = myticker;
           
           ticksizeStr = v[1];

           DigitsAfterComa=0;
           c=StringFind(ticksizeStr,".");
           
           if((FuturesName == "6S" && Reverse_6S_to_USDCHF) || (FuturesName == "6C" && Reverse_6C_to_USDCAD))
           {
             ticksizeStr ="0.00001";
             ForceRoundIncomingPrice=5; // Looks like DigitsAfterComa will work also
             if(!last_loaded && Workspace.TickMultiplier==1) Workspace.TickMultiplier = 10;
             
           } else
           if(FuturesName == "6J" && Reverse_6J_to_USDJPY)
           {
             ticksizeStr ="0.001";
             ForceRoundIncomingPrice=3; // Looks like DigitsAfterComa will work also
             if(!last_loaded  && Workspace.TickMultiplier==1) Workspace.TickMultiplier = 10;
             
           } else
           if(FuturesName == "6M" && Reverse_6M_to_USDMXN)
           {
             ticksizeStr ="0.001";
             ForceRoundIncomingPrice=3; // Looks like DigitsAfterComa will work also
             if(!last_loaded  && Workspace.TickMultiplier==1) Workspace.TickMultiplier = 5;             
           } else
           {
             ForceRoundIncomingPrice=0;
           
           }
 
           
           if(c>0) DigitsAfterComa=StringLen(ticksizeStr)-c-1;
           
           
           Workspace.TickSize=NormalizeDouble(StringToDouble(ticksizeStr),DigitsAfterComa);
           ticksize=NormalizeDouble(Workspace.TickSize*Workspace.TickMultiplier,DigitsAfterComa);
             
           if (v[2]=="TMS") { GMT = (int)StringToInteger(v[3]); } 

           

           int LastMinuteIndex=0;
           
           for(i=1; i<rows; i++)
           {
              //if(i>rows-6) { Print(StringSubstr(lines[i],0,30)); }
              if(StringSubstr(lines[i],0,3) == "//!") { MessageFromServer=StringSubstr(lines[i],3); continue;              }
              if(StringSubstr(lines[i],0,2) == "//") { MessageFromServer+=StringSubstr(lines[i],2); continue;              }
              if(StringSubstr(lines[i],0,3)=="Exp") 
              { 
                  Expiration = StringSubstr(lines[i],4); 
                  continue; 
              } 
              
              if(StringSubstr(lines[i],0,1) == "*") // LAST MINUTE SAVING
              {
                m = StringSplit(lines[i],'#',candle);
                
                if(StringToInteger(Workspace.CURRENT_TIMEFRAME)>0) // TIMEFRAME
                {
                   if(m>=2)
                   {
                     n=StringSplit(candle[1],';', ohlc);
                     if(n>=5)
                     {
                          bartime = StringToTime(ohlc[0]);
                          if(m>=3 && LastMinute.opentime<=bartime)
                          {
                              p=StringSplit(candle[2],';', data);                       
                              if(p>0) {                           
                                    if(LastMinute.opentime<bartime)
                                    {
                                    
                                       LastMinute.opentime = bartime;
                                       ArrayResize(LastMinute.prices, 40);
                                       ArrayResize(LastMinute.ask, 40);
                                       ArrayResize(LastMinute.bid, 40);
                                       ArrayFill(LastMinute.prices,0,40,0);
                                       ArrayFill(LastMinute.ask,0,40,0);
                                       ArrayFill(LastMinute.bid,0,40,0);
                                    } 
                                    
   
                                    for(d=0; d<p-1; d++)
                                    {
                                      if(StringSplit(data[d],':',askbid)>=2)
                                      {
                                        price = NormalizeDouble(StringToDouble(askbid[0]),DigitsAfterComa);
                                        ask = StringToInteger(askbid[1]);
                                        bid = StringToInteger(askbid[2]);
                                        if(ForceRoundIncomingPrice)
                                        {
                                          price = NormalizeDouble(1/StringToDouble(askbid[0]),ForceRoundIncomingPrice);
                                          ask = StringToInteger(askbid[2]);
                                          bid = StringToInteger(askbid[1]);
                                        }
                                        
                                        
                                        
                                        
                                        int ee=0;
                                        for(ee=0;ee<ArraySize(LastMinute.prices);ee++)
                                        {
                                          if(LastMinute.prices[ee]==0) break;
                                          if(LastMinute.prices[ee]==price) break;
                                        }
                                        
                                        
                                        if(ee==ArraySize(LastMinute.prices))
                                        {
                                          ArrayResize(LastMinute.prices, ee+40);
                                          ArrayResize(LastMinute.ask, ee+40);
                                          ArrayResize(LastMinute.bid, ee+40);
                                          ArrayFill(LastMinute.prices,ee,40,0);
                                          ArrayFill(LastMinute.ask,ee,40,0);
                                          ArrayFill(LastMinute.bid,ee,40,0);
                                        }
                                        if(LastMinute.prices[ee]==0)
                                        {
                                          LastMinute.prices[ee]=price;
                                        }
                                        
                                        if(LastMinute.ask[ee]<ask) LastMinute.ask[ee]=ask;
                                        if(LastMinute.bid[ee]<bid) LastMinute.bid[ee]=bid;
                                        
                                      } 
                                    } // for d
                                 } // p>0
                          } // m>=3
                     } //n>=5
                   } // m>=2
                } // TIMEFRAME LASTMINUTE COMPLETE
                else
                if(StringToInteger(Workspace.CURRENT_TIMEFRAME)<0) // RANGE
                {
                  if(m>=2)
                  {
                     
                    n=StringSplit(candle[1],';', tsdata);
                    if(n>=5)
                    {
                       //StringReplace(tsdata[0],"-","."); // 2020-04-10 to 2020.04.10
                       bartime = StringToTime(tsdata[0]);
                       barid = (int)StringToInteger(tsdata[1]);
                       price = NormalizeDouble(StringToDouble(tsdata[2]),DigitsAfterComa);
                       ask =  StringToInteger(tsdata[3]);
                       bid =  StringToInteger(tsdata[4]);
                       if(ForceRoundIncomingPrice)
                       {
                           price = NormalizeDouble(1/StringToDouble(tsdata[2]),ForceRoundIncomingPrice);
                           ask =  StringToInteger(tsdata[4]);
                           bid =  StringToInteger(tsdata[3]);
                       }

                       
                       
                       if(init_last_range == 0) // 1st line is 
                       {
                       
                         my_last_known_range_time = bartime;
                         my_last_known_range_id = barid;                       
                         
                         if(last_known_range_time < bartime) { last_known_range_time=bartime; }
                         if(last_known_range_id < barid) { last_known_range_id=barid; }
                         init_last_range = 1;
                         ts_clean_id=barid;
                       }
                       
                       if(init_last_range ==1)
                       {
                         if(bartime == last_known_range_time && last_known_range_id < barid)  { last_known_range_id = barid; }
                         if(bartime == my_last_known_range_time) { my_last_known_range_id = barid; ts_clean_id=barid;}
                         
                       }
                       
                        if(TimeToString(bartime,TIME_DATE)!=TimeToString(last_known_range_time,TIME_DATE))
                        {
                           OrderflowIDX=-1;
                        }
                       
                       if(bartime>=last_known_range_time && barid>last_known_range_id)
                       {
                         RangeTimeAndSalesComplete=0;
                         
                         
                       }
                    }
                  } // m>=2
                } // RANGE LASTBAR COMPLETE
                continue;
              } // LAST MINUTE SAVED


              
              m = StringSplit(lines[i],'#',candle); // #time;o;h;l;c#cluster
              if(m<2) {/*Print ("Error:",lines[i]);*/ continue; } // wrong data format
             
                n=StringSplit(candle[1],';', ohlc);
                if(n<5) {/*Print("Error:",candle[1]);*/ continue; } // wrong data format
                
                bartime = StringToTime(ohlc[0]);
                baropen = NormalizeDouble(StringToDouble(ohlc[1]),DigitsAfterComa);
                barhigh = NormalizeDouble(StringToDouble(ohlc[2]),DigitsAfterComa);
                barlow  = NormalizeDouble(StringToDouble(ohlc[3]),DigitsAfterComa);
                barclos = NormalizeDouble(StringToDouble(ohlc[4]),DigitsAfterComa);
                if(ForceRoundIncomingPrice)
                {
                  baropen = NormalizeDouble(1/StringToDouble(ohlc[1]),ForceRoundIncomingPrice);
                  barhigh = NormalizeDouble(1/StringToDouble(ohlc[2]),ForceRoundIncomingPrice);
                  barlow  = NormalizeDouble(1/StringToDouble(ohlc[3]),ForceRoundIncomingPrice);
                  barclos = NormalizeDouble(1/StringToDouble(ohlc[4]),ForceRoundIncomingPrice);
                }
                barstartid = "0";
                if(n>=6) // range chart id
                {
                  CDateTime bt,pbt;
                  bt.DateTime(bartime);
                  pbt.DateTime(prevdate);
                  if(bt.day != pbt.day) { maxbarid=0; }

                  barstartid = ohlc[5];
                  prevdate = bartime;
                } 
                if(n>=8) // MaxMin Delta Data
                {
                
                  mindelta = (int)StringToInteger(ohlc[6]);
                  maxdelta = (int)StringToInteger(ohlc[7]);
                  if(ForceRoundIncomingPrice)
                  {
                    maxdelta = 0-(int)StringToInteger(ohlc[6]);
                    mindelta = 0-(int)StringToInteger(ohlc[7]);
                  }
                  
                }
                if(maxdate<bartime) { maxdate=bartime; }
                if(maxbarid<StringToInteger(barstartid)) { maxbarid=(int)StringToInteger(barstartid); }
                

                
                k=0;
                index=IDX+1;        
                int newrecord=1;
                int temp=0;
                for(k=0;k<=IDX;k++)
                {
                  temp = ClusterINDEX(k);
                  if(StringToInteger(Workspace.CURRENT_TIMEFRAME) < 0)
                  {
                    //   for range chart, for timeframe it will ignored 
                    if(Clusters[temp].opentime==bartime && Clusters[temp].onfly) { index=temp; newrecord=0; break; }
                    if(Clusters[temp].opentime==bartime && Clusters[temp].range_barid==barstartid) { index=temp; newrecord=0; break; }
                  } else {
                    if(Clusters[temp].opentime==bartime) { index=temp; newrecord=0; break; }
                  }
                }

                if(IDX<index) { IDX=index; }
                if(IDX>=MAXIDX)
                {
                    MAXIDX=MAXIDX+5000;
                    ArrayResize(Clusters,MAXIDX);
                    ArrayResize(opentimeIdx, MAXIDX);
                    ArrayResize(clustersIdx, MAXIDX);
                    
                }
                
                if(newrecord)
                {
                  //opentimeIdx[index]=bartime*100000000+(int)StringToInteger(barstartid);
                  string s = TimeToString(bartime,TIME_DATE|TIME_MINUTES);
                  opentimeIdx[index]=StringToInteger(StringSubstr(s,2,2)+StringSubstr(s,5,2)+StringSubstr(s,8,2)+StringSubstr(s,11,2)+StringSubstr(s,14,2)+"0000000")/*+ bartime*100000000*/+(int)StringToInteger(barstartid);
                  
                  clustersIdx[index]=index;
                  
                  Clusters[index].close=0;
                  Clusters[index].high=0;
                  Clusters[index].low=0;
                  ArrayResize(Clusters[index].prices,40);
                  ArrayResize(Clusters[index].ask,40);
                  ArrayResize(Clusters[index].bid,40);
                  ArrayFill(Clusters[index].prices,0,ArraySize(Clusters[index].prices),0);
                  ArrayFill(Clusters[index].ask,0,ArraySize(Clusters[index].ask),0);
                  ArrayFill(Clusters[index].bid,0,ArraySize(Clusters[index].bid),0);
                  Clusters[index].total_ask = 0;
                  Clusters[index].total_bid = 0;
                  Clusters[index].cumdelta = 0;
                  Clusters[index].delta_max = 0;
                  Clusters[index].delta_min = 0;
                  //Clusters[index].width = 0;
                  //Clusters[index].height = 0;
                  Clusters[index].onfly=0;
                  Clusters[index].need_regenerate_img=0;                  
                  Clusters[index].range_barid = barstartid;
                }                
                
                      
                Clusters[index].open = baropen;
                if(!Clusters[index].close)  Clusters[index].close = barclos;
                if(!Clusters[index].high || Clusters[index].high<barhigh) Clusters[index].high = barhigh;
                if(!Clusters[index].low ||  Clusters[index].low>barlow) Clusters[index].low = barlow;
                Clusters[index].opentime = bartime;
                
                if(maxdelta > Clusters[index].delta_max) Clusters[index].delta_max = maxdelta;
                if(mindelta < Clusters[index].delta_min) Clusters[index].delta_min = mindelta;

                
                //if(TimeToString(bartime,TIME_DATE|TIME_MINUTES) == TimeToString(D'2020.04.17 23:46:00',TIME_DATE|TIME_MINUTES))
                
                

                
                if(m>=3)
                {
                  p=StringSplit(candle[2],';', data);
                  if(p>0) {                  
                     int lastcluster=0;
                     if(Clusters[index].opentime >= last_loaded && StringToInteger(Workspace.CURRENT_TIMEFRAME)>0 && last_loaded>0) 
                     { // LAST Clusters
                       lastcluster=1;
                       
                       
                       
                      
                     } else
                     {
                       if(p-1>=ArraySize(Clusters[index].prices))
                       {
                          ArrayResize(Clusters[index].prices, p+40);
                          ArrayResize(Clusters[index].ask, p+40);
                          ArrayResize(Clusters[index].bid, p+40);
                          ArrayFill(Clusters[index].prices, p-1,41,0);
                          ArrayFill(Clusters[index].ask, p-1,41,0);
                          ArrayFill(Clusters[index].bid, p-1,41,0);

                       }
                       Clusters[index].total_ask = 0;
                       Clusters[index].total_bid = 0;
                       Clusters[index].cumdelta = 0;
                       Clusters[index].delta_max = maxdelta;
                       Clusters[index].delta_min = mindelta;
                     }
                     
                     for(d=0; d<p-1; d++)
                     {
                       b=StringSplit(data[d],':',askbid);
                       if(b>=2)
                       {
                         price = NormalizeDouble(StringToDouble(askbid[0]),DigitsAfterComa);
                         ask = StringToInteger(askbid[1]);
                         bid = StringToInteger(askbid[2]);
                         if(ForceRoundIncomingPrice)
                         {
                           price = NormalizeDouble(1/StringToDouble(askbid[0]),ForceRoundIncomingPrice);
                           ask = StringToInteger(askbid[2]);
                           bid = StringToInteger(askbid[1]);
                         }
                         
                         
                         
                         if(!lastcluster)
                         {

                            Clusters[index].prices[d]=price;
                            Clusters[index].ask[d]=ask;
                            Clusters[index].bid[d]=bid;
                            Clusters[index].total_ask += ask;
                            Clusters[index].total_bid += bid;
                            
                            
                            
                         } else
                         {
                         
                                     int ee=0;
                                     for(ee=0;ee<ArraySize(Clusters[index].prices);ee++)
                                     {
                                       if(Clusters[index].prices[ee]==0) break;
                                       if(Clusters[index].prices[ee]==price) break;
                                     }
                                     if(ee>=ArraySize(Clusters[index].prices))
                                     {
                                       ArrayResize(Clusters[index].prices, ee+40);
                                       ArrayResize(Clusters[index].ask, ee+40);
                                       ArrayResize(Clusters[index].bid, ee+40);
                                       ArrayFill(Clusters[index].prices, ee,40,0);
                                       ArrayFill(Clusters[index].ask, ee,40,0);
                                       ArrayFill(Clusters[index].bid, ee,40,0);
                                     }
                                     if(Clusters[index].prices[ee]==0)
                                     {
                                       Clusters[index].prices[ee]=price;
                                       Clusters[index].ask[ee]=0;
                                       Clusters[index].bid[ee]=0;
                                     }
                                     if(Clusters[index].ask[ee]<ask) 
                                     { 
                                        Clusters[index].total_ask=Clusters[index].total_ask+(ask-Clusters[index].ask[ee]); 
                                        Clusters[index].ask[ee]=ask; 
                                     }
                                        
                                     if(Clusters[index].bid[ee]<bid) 
                                     { 
                                        Clusters[index].total_bid=Clusters[index].total_bid+(bid-Clusters[index].bid[ee]); 
                                        Clusters[index].bid[ee]=bid; 
                                     }

                         }
                         if(price<Clusters[index].low && (ask+bid)>0)  { Clusters[index].low=price; }
                         if(price>Clusters[index].high && (ask+bid)>0) { Clusters[index].high=price;}
                         
                       } // b>0
                     } // for d
                     Clusters[index].need_regenerate_img=1;
                     last_cluster_idx=index;
                     Clusters[index].onfly=0;
                  } // p>0
                  
          
                  
                 } // m>=3
            } // for i
         } // e>0         
         
         
       } // rows>1
        //Print(GetTickCount()-perfomance, " ms , finish array");
       // Sort by opentime
       perfomance = GetTickCount();
       SortDictionary(opentimeIdx,clustersIdx,IDX+1);
       
       
       //Print(GetTickCount()-perfomance, " ms , finish sort ", IDX);
       
       
       if(IDX>=0)
       {       
         
         Find_TopValue();       
         CURRENT_PRICE = Clusters[ClusterINDEX(IDX)].close;       

         int prev_id=-1;
         CDateTime prev_time;
         prev_time.DateTime();
         
         long cumdelta=0;
         for(j=0;j<=IDX;j++)
         {
           //if(Clusters[ClusterINDEX(j)].need_regenerate_img) GenerateClusterIMG(ClusterINDEX(j),j);
           
           /*
           if(prev_id>=0 && (Reset_CumDelta_NewDay || Reset_CumDelta_NewWeek))
           {
             CDateTime curr_time;
             curr_time.DateTime(Clusters[ClusterINDEX(j)].opentime);
             if((Reset_CumDelta_NewDay && curr_time.day!=prev_time.day) ||
                (Reset_CumDelta_NewWeek && curr_time.day_of_week==1 && prev_time.day_of_week!=1))
             {
               prev_id=-1;
               cumdelta=0;
             }
           }
           */
           Clusters[ClusterINDEX(j)].previous_cluster=prev_id;
           cumdelta = cumdelta +  Clusters[ClusterINDEX(j)].total_ask-Clusters[ClusterINDEX(j)].total_bid;
           Clusters[ClusterINDEX(j)].cumdelta=cumdelta;
           prev_time.DateTime(Clusters[ClusterINDEX(j)].opentime);
           prev_id=ClusterINDEX(j);
         }
         if(IDX>0)
         {
           if(last_cluster_idx>=0)
           {
             //last_loaded=Clusters[ClusterINDEX(last_cluster_idx)].opentime;
             //last_rangeid=Clusters[ClusterINDEX(last_cluster_idx)].range_barid;
             last_loaded = maxdate; 
             last_rangeid = IntegerToString(maxbarid); 
             
           }
         }
         
         
       }
    } // len response > 1
    
    return (1);
}

int ClusterINDEX(int idx)
{
  if(idx==-1) return -1;
  if(idx>IDX) { idx=IDX; }
  return clustersIdx[idx];
}

void Find_TopValue()
{
       int maxvalues[], maxdelta[], maxask[], maxbid[];
       int totalV=0, totalD=0, totalA=0, totalB=0;
       int j;

       if(IDX<0) return;
       ArrayResize(maxvalues,IDX+1);
       ArrayFill(maxvalues,0,IDX+1,0);
       ArrayResize(maxdelta,IDX+1);
       ArrayFill(maxdelta,0,IDX+1,0);
       ArrayResize(maxask,IDX+1);
       ArrayFill(maxask,0,IDX+1,0);
       ArrayResize(maxbid,IDX+1);
       ArrayFill(maxbid,0,IDX+1,0);
 
 
       for(j=0;j<=IDX;j++) 
       {
         Find_ClusterPOCValue(j,maxvalues[j],maxdelta[j], maxask[j], maxbid[j]);
         if(Workspace.TopValueAsk<maxask[j]) Workspace.TopValueAsk=maxask[j];
         if(Workspace.TopValueBid<maxbid[j]) Workspace.TopValueBid=maxbid[j];

       }
       ArraySort(maxvalues);//,WHOLE_ARRAY,0,MODE_DESCEND);
       ArraySort(maxdelta);//,WHOLE_ARRAY,0,MODE_DESCEND);
       
       
       int p=(int)MathRound(IDX*Workspace.TopValue_k/100.0);
       
       //Print(IDX," ",Workspace.TopValue_k," <-- ",p);
       
       
       if(p>IDX) p=IDX;
       if(p==0) p=1;       
       
       for(j=0;j<p;j++) 
       {
         totalV+=maxvalues[IDX-j]; //IDX-
         totalD+=maxdelta[IDX-j]; //IDX-
         totalA+=maxask[IDX-j];
         totalB+=maxbid[IDX-j];
       }
       Workspace.TopValueVolume = (int)MathRound(totalV/p);
       
       if(Workspace.TopValueVolume < Minimum_TopValue) Workspace.TopValueVolume=Minimum_TopValue;
       if(Maximum_TopValue>0 && Maximum_TopValue>Minimum_TopValue) Workspace.TopValueVolume=Maximum_TopValue;         

       Workspace.TopValueDelta = (int)MathRound(totalD/p);
       //Workspace.TopValueAsk = (int)MathRound(totalA/p);
       //Workspace.TopValueBid = (int)MathRound(totalB/p);

}

int Find_ClusterPOCValue(int i, int &maxvolume, int &maxdelta, int &maxask, int &maxbid)
{
    if(Workspace.TickSize == 0) return 0;
    int PriceNUM = 1+ (int)MathRound(NormalizeDouble((Clusters[i].high-Clusters[i].low),DigitsAfterComa)/Workspace.TickSize);

    double nextprice, pricecurrent=Clusters[i].high;
    int AskCumulate=0, BidCumulate=0, askcurrent, bidcurrent;
    
    for(int k=0; k<PriceNUM; k++)
    {
          getVolumeByPrice(i,pricecurrent,askcurrent,bidcurrent);
          AskCumulate += askcurrent;
          BidCumulate += bidcurrent;
          nextprice = NormalizeDouble(pricecurrent-Workspace.TickSize, DigitsAfterComa);
          if(GroupPriceValue(nextprice) != GroupPriceValue(pricecurrent) || k==PriceNUM-1 /* LAST VALUE */ )
          {
            if( maxvolume < (AskCumulate+BidCumulate)) maxvolume= AskCumulate+BidCumulate;
            if( maxdelta < MathAbs(AskCumulate-BidCumulate)) maxdelta = MathAbs(AskCumulate-BidCumulate);
            if( maxask < MathAbs(AskCumulate)) maxask = MathAbs(AskCumulate);
            if( maxbid < MathAbs(BidCumulate)) maxbid = MathAbs(BidCumulate);
            AskCumulate=0;
            BidCumulate=0;

          }
          pricecurrent = nextprice;
    }
    return 1;
   
}



void GenerateClusterIMG(int q, int timeIdx=0)
{
   int i = ClusterINDEX(q);
   Clusters[i].need_regenerate_img=1;
}

void Get_CellValue(int cell_value, int _AskCumulate, int _BidCumulate, string &VALUE) //, int _minor_value, int _major_value, int _top_value, int _top_delta, int _top_ask, int _top_bid)
{
  VALUE = "";
  int _Volume_value = (_AskCumulate + _BidCumulate);
  int _Delta_value = (_AskCumulate - _BidCumulate);
  
  VALUE = IntegerToString(_Volume_value);
 /*
  if(cell_value == 1)  VALUE = IntegerToString(_Volume_value); // VOLUME RIGHT
  if(cell_value == 2)  VALUE = IntegerToString(_Delta_value);  // DELTA RIGHT
  if(cell_value == 3)  VALUE = IntegerToString(_AskCumulate);  // ASK RIGHT
  if(cell_value == 4)  VALUE = IntegerToString(_BidCumulate);  // BID RIGHT
  
  if(cell_value == 5 && _Delta_value>=0)  VALUE = IntegerToString(_Delta_value);  // DELTA RIGHT
  if(cell_value == 6 && _Delta_value<0)  VALUE = IntegerToString(_Delta_value);  // DELTA RIGHT

  if(cell_value == 11) VALUE = IntegerToString(_Volume_value); // VOLUME LEFT
  if(cell_value == 12) VALUE = IntegerToString(_Delta_value);  // DELTA LEFT
  if(cell_value == 13) VALUE = IntegerToString(_AskCumulate);  // ASK LEFT
  if(cell_value == 14) VALUE = IntegerToString(_BidCumulate);  // BID LEFT 
  
  if(cell_value == 15 && _Delta_value>=0)  VALUE = IntegerToString(_Delta_value);  // DELTA RIGHT
  if(cell_value == 16 && _Delta_value<0)  VALUE = IntegerToString(_Delta_value);  // DELTA RIGHT
  */

}

void Get_CellColorScheme(int cell_colorstyle, 
                                   int _AskCumulate, int _BidCumulate, int _cell_is_currentprice,
                                   uint &_cell_BG, uint &_cell_Font, bool  &_cell_Bold)
{
  int Volume_value = (_AskCumulate + _BidCumulate);
  int Delta_value = (_AskCumulate - _BidCumulate);
 
  int top_value  =  (int)MathRound(Workspace.TopValueVolume * Workspace.TopPercent/100.0);
  int minor_value = (int)MathRound(Workspace.TopValueVolume * Workspace.MinorPercent/100.0)+1;
  int major_value = (int)MathRound(Workspace.TopValueVolume * Workspace.MajorPercent/100.0);
  int top_delta =  (int)MathRound(Workspace.TopValueDelta * Workspace.TopPercent/100.0);
  int top_ask = (int)MathRound(Workspace.TopValueAsk);// * 100/100.0);
  int top_bid = (int)MathRound(Workspace.TopValueBid);// * Workspace.TopPercent/100.0);

  

  if(top_delta==0) top_delta=1;
  if(top_ask==0) top_ask=1;
  if(top_bid==0) top_bid=1;


  // [the code was cutted]

}                                   


int GroupPriceValue(double p)
{
  if(Workspace.TickSize==0) return 0;
  int c = (int)MathRound(p / Workspace.TickSize);
  return c - c % Workspace.TickMultiplier; 
}

void getVolumeByPrice(int ci, double pi, int &a, int &b)
{
   int n=ArraySize(Clusters[ci].prices);
   int l=0;
   a=0; b=0;
   while(l<n)
   {
     if(Clusters[ci].prices[l]==pi) { a=(int)Clusters[ci].ask[l]; b=(int)Clusters[ci].bid[l]; return; }
     l++;
   }
   return;
}














































string nice_date(datetime d)
{ 

  string s=TimeToString(d,TIME_DATE);  
  return StringSubstr(s,8,2)+"."+StringSubstr(s,5,2)+"."+StringSubstr(s,0,4);
}


void SortDictionary(ulong &keys[], int &values[], int count)  
{
   ulong keyCopy[];
   int valueCopy[];
   int i,j;
   int p = ArraySize(keys);
   
   ArrayCopy(keyCopy, keys,0,0,count);
   ArrayCopy(valueCopy, values,0,0,count);
   ArrayResize(keys,count,p);
   ArraySort(keys);//, count, 0, sortDirection);
   
   for (i = 0; i < count; i++)
   {
      for(j=0; j< count; j++)
      {
        if(keys[j]==keyCopy[i]) break;
      }
      if(j<count) 
         values[j] = valueCopy[i];
   }
   ArrayResize(keys,p);
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


void CheckDLLExists()
{

   if(!IsDllsAllowed())
   {
      /*
      if(TerminalInfoString(TERMINAL_LANGUAGE)=="Russian")
      {
         TextOut("КРИТИЧЕСКАЯ ОШИБКА",w/2,15,TA_CENTER|TA_VCENTER,errorImg,w,h,0xff444444,COLOR_FORMAT_XRGB_NOALPHA);
         TextSetFont("Arial",15,FW_BOLD);
         TextOut("ОШИБКА: ИМПОРТ DLL НЕ РАЗРЕШЕН",w/2,40,TA_CENTER|TA_TOP,errorImg,w,h,0xff000000,COLOR_FORMAT_XRGB_NOALPHA);
         TextSetFont("Arial",15);
         TextOut("ДЛЯ ПРОДОЛЖЕНИЯ ВАМ НУЖНО ВКЛЮЧИТЬ ИМПОРТ DLL. СЛЕДУЙТЕ ИНСТРУКЦИИ НИЖЕ.",w/2,70,TA_CENTER|TA_TOP,errorImg,w,h,0xff000000,COLOR_FORMAT_XRGB_NOALPHA);
      }
      else
      {      
         TextOut("FATAL ERROR",w/2,15,TA_CENTER|TA_VCENTER,errorImg,w,h,0xff444444,COLOR_FORMAT_XRGB_NOALPHA);
         TextSetFont("Arial",15,FW_BOLD);
         TextOut("ERROR: DLL IMPORT CALLS ARE NOT ALLOWED",w/2,40,TA_CENTER|TA_TOP,errorImg,w,h,0xff000000,COLOR_FORMAT_XRGB_NOALPHA);
         TextSetFont("Arial",15);
         TextOut("YOU SHOULD ALLOW DLL IMPORT CALLS TO CONTINUE",w/2,70,TA_CENTER|TA_TOP,errorImg,w,h,0xff000000,COLOR_FORMAT_XRGB_NOALPHA);
      }     
     
      //DllIsNotAllowed(errorImg, 20,100, w);
      //DllIsNotAllowed2(errorImg, 312,100, w);
      */
   }
   else
   {
   
      string path= TerminalInfoString(TERMINAL_DATA_PATH)+"\\MQL5";
      /*
      if(TerminalInfoString(TERMINAL_LANGUAGE)=="Russian")
      {
         TextSetFont("Arial",18);
         TextOut("КРИТИЧЕСКАЯ ОШИБКА",w/2,15,TA_CENTER|TA_VCENTER,errorImg,w,h,0xff444444,COLOR_FORMAT_XRGB_NOALPHA);
         TextSetFont("Arial",15);
         TextOut("При попытке загрузки данных в индикатор ClusterDelta обнаружена ошибка",w/2,50,TA_CENTER|TA_TOP,errorImg,w,h,0xff000000,COLOR_FORMAT_XRGB_NOALPHA);
         TextSetFont("Arial",15, FW_BOLD);
         TextOut("Локальный каталог MetaTrader4 (Файл - Открыть каталог данных): ",16,80,TA_LEFT|TA_TOP,errorImg,w,h,0xff000000,COLOR_FORMAT_XRGB_NOALPHA);
         TextSetFont("Arial",15, FW_REGULAR);
   
         TextOut(StringSubstr(path,0,70),30,98,TA_LEFT|TA_TOP,errorImg,w,h,0xff000000,COLOR_FORMAT_XRGB_NOALPHA);
         TextOut(StringSubstr(path,70,140),30,98+16,TA_LEFT|TA_TOP,errorImg,w,h,0xff000000,COLOR_FORMAT_XRGB_NOALPHA);
         TextSetFont("Arial",15, FW_BOLD);
         TextOut("Отсутствует DLL файл из списка ниже: ",16,138,TA_LEFT|TA_TOP,errorImg,w,h,0xff000000,COLOR_FORMAT_XRGB_NOALPHA);
         TextSetFont("Arial",15, FW_REGULAR);
       TextOut("Libraries \\ clusterdelta_v5x2.dll",30,155,TA_LEFT|TA_TOP,errorImg,w,h,0xffa00000,COLOR_FORMAT_XRGB_NOALPHA);
         TextOut("Libraries \\ footprint_v1x0.dll",30,170,TA_LEFT|TA_TOP,errorImg,w,h,0xffa00000,COLOR_FORMAT_XRGB_NOALPHA); 
   
         TextOut("   Скопируйте повторно все файлы из архива Premium индикаторов в локальный ",16,188,TA_LEFT|TA_TOP,errorImg,w,h,0xff000000,COLOR_FORMAT_XRGB_NOALPHA);
         TextOut("каталог MQL4 и перезапустите MetaTrader. Более подробная информация есть ",16,206,TA_LEFT|TA_TOP,errorImg,w,h,0xff000000,COLOR_FORMAT_XRGB_NOALPHA);
         TextOut("в закладке Эксперты (Терминал - CTRL+T) и на сайте https://clusterdelta.com",16,224,TA_LEFT|TA_TOP,errorImg,w,h,0xff000000,COLOR_FORMAT_XRGB_NOALPHA);   
         TextOut("Удалить это окно можно из списка обьектов: CTRL+B, имя: DLL files are not loaded",16,244,TA_LEFT|TA_TOP,errorImg,w,h,0xff000000,COLOR_FORMAT_XRGB_NOALPHA);            
     
      } else
      {
         TextSetFont("Arial",18);
         TextOut("FATAL ERROR",w/2,15,TA_CENTER|TA_VCENTER,errorImg,w,h,0xff444444,COLOR_FORMAT_XRGB_NOALPHA);
         TextSetFont("Arial",15);
         TextOut("ClusterDelta indicator encounters fatal error during loading",w/2,50,TA_CENTER|TA_TOP,errorImg,w,h,0xff000000,COLOR_FORMAT_XRGB_NOALPHA);
         TextSetFont("Arial",15, FW_BOLD);
         TextOut("Local Path to MetaTrader4 files (File - Open Data Folder): ",16,80,TA_LEFT|TA_TOP,errorImg,w,h,0xff000000,COLOR_FORMAT_XRGB_NOALPHA);
         TextSetFont("Arial",15, FW_REGULAR);
   
         TextOut(StringSubstr(path,0,70),30,98,TA_LEFT|TA_TOP,errorImg,w,h,0xff000000,COLOR_FORMAT_XRGB_NOALPHA);
         TextOut(StringSubstr(path,70,140),30,98+16,TA_LEFT|TA_TOP,errorImg,w,h,0xff000000,COLOR_FORMAT_XRGB_NOALPHA);
         TextSetFont("Arial",15, FW_BOLD);
         TextOut("Missing some DLL files from list: ",16,138,TA_LEFT|TA_TOP,errorImg,w,h,0xff000000,COLOR_FORMAT_XRGB_NOALPHA);
         TextSetFont("Arial",15, FW_REGULAR);
         TextOut("Libraries \\ clusterdelta_v5x2.dll",30,158,TA_LEFT|TA_TOP,errorImg,w,h,0xffa00000,COLOR_FORMAT_XRGB_NOALPHA);
         TextOut("Libraries \\ footprint_v1x0.dll",30,170,TA_LEFT|TA_TOP,errorImg,w,h,0xffa00000,COLOR_FORMAT_XRGB_NOALPHA); 
         TextOut("Please copy again all files from indicator archive in MQL4 folder and restart MetaTrader",16,188,TA_LEFT|TA_TOP,errorImg,w,h,0xff000000,COLOR_FORMAT_XRGB_NOALPHA);
         TextOut("More information about error you can find in Experts tab (Terminal window - CTRL+T)",16,206,TA_LEFT|TA_TOP,errorImg,w,h,0xff000000,COLOR_FORMAT_XRGB_NOALPHA);
         TextOut("You can also get last indicator on https://clusterdelta.com/download",16,224,TA_LEFT|TA_TOP,errorImg,w,h,0xff000000,COLOR_FORMAT_XRGB_NOALPHA);   
         TextOut("You can remove this window from objects list: CTRL+B, name: DLL files are not loaded",16,244,TA_LEFT|TA_TOP,errorImg,w,h,0xff000000,COLOR_FORMAT_XRGB_NOALPHA);                     
      }
      */
      
   }    
   
   ChartRedraw();
   if (IsDllsAllowed())
   {
     int test;
     Receive_Information(test, "");
     Footprint_Data(test, "");   
// ***** IF DLL IS ALLOWED BUT SOME DLLS ARE MISSING THE CODE STOPS EXECUTING AT THIS POINT **** 

   }
}  



void UserNotAuthorized()
{
   /*
      if(TerminalInfoString(TERMINAL_LANGUAGE)=="Russian")
      {
         //TextSetFont("Arial",18);
         //TextOut("ДОСТУП ЗАПРЕЩЕН",w/2,15,TA_CENTER|TA_VCENTER,errorImg,w,h,0xff444444,COLOR_FORMAT_XRGB_NOALPHA);
         
      } else
      {
         //TextSetFont("Arial",18);
         //TextOut("ACCESS DENIED",w/2,15,TA_CENTER|TA_VCENTER,errorImg,w,h,0xff444444,COLOR_FORMAT_XRGB_NOALPHA);
      }
   */
}  


#ifdef __MQL5__



int IsDllsAllowed()
{
   return TerminalInfoInteger(TERMINAL_DLLS_ALLOWED);
}

string AccountCompany()
{

  return AccountInfoString(ACCOUNT_COMPANY);
}

int AccountNumber()
{
  return (int)AccountInfoInteger(ACCOUNT_LOGIN);

}

int Year()
{
  CDateTime c;
  c.DateTime(TimeLocal());
  return c.year;
  
}

int Month()
{
  CDateTime c;
  c.DateTime(TimeLocal());
  return c.mon;
  
}

int Day()
{
  CDateTime c;
  c.DateTime(TimeLocal());
  return c.day;
  
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
    case (PERIOD_H12): return 720;
    case (PERIOD_D1): return 1440;
    case (PERIOD_W1): return 10080;    
    case (PERIOD_MN1): return 302400;    
    default: return 60;
  }
  return _Period;
}

datetime Time[];
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &mttime[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
      NumberRates = rates_total;
      if(ArraySize(Time)<ArraySize(mttime))
      {
        ArrayResize(Time, ArraySize(mttime));
      }
      ArrayCopy(Time , mttime);
      return (1);//MainCode();

  }



#else

int Period_To_Minutes()
{
  
  return Period();
}



#endif 

