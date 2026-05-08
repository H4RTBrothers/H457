//+------------------------------------------------------------------+
//|                                          H457 Group EA v3.mq5     |
//|                        MQL5 - BTCUSD intraday scalper             |
//+------------------------------------------------------------------+
#property copyright "H457"
#property link      ""
#property version   "3.13"
#property description "H457 Group EA v3.13"
#property description "v3.13: FIX - DDPct override bug, ProfitMode now controls DD"

#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Trade\AccountInfo.mqh>

CTrade         trade;
CSymbolInfo    symInfo;
CPositionInfo  positionInfo;
COrderInfo     orderInfo;

//+------------------------------------------------------------------+
//| Risk mode preset                                                  |
//+------------------------------------------------------------------+
enum ENUM_RISK_MODE
{
   MODE_CUSTOM       = 0,
   MODE_CONSERVATIVE = 1,
   MODE_MODERATE     = 2,
   MODE_AGGRESSIVE   = 3
};

//+------------------------------------------------------------------+
//| Input parameters                                                  |
//+------------------------------------------------------------------+
input ENUM_RISK_MODE RiskMode             = MODE_MODERATE;
input string   EAName                     = "H457 Group EA - BTC";
input ulong    InpMagicNumber             = 2024;
input string   InpTradeComment            = "Vibrix 3.0";
input int      StartTime                  = 0;
input int      EndTime                    = 23;
input ENUM_TIMEFRAMES TimeFrame           = PERIOD_M15;

input group    "=== Order types enabled ==="
input bool     BUY_market_lowRisk          = true;
input bool     SELL_market_lowRisk         = true;
input bool     BUY_market                  = true;
input bool     SELL_market                 = true;
input bool     BUY_stop                    = true;
input bool     SELL_stop                   = true;
input bool     BUY_limit                   = true;
input bool     SELL_limit                  = true;
input bool     SELL_limit_StrictFilter     = false;
input bool     SkipIfPendingExists         = true;

input group    "=== Lots ==="
input double   Lots                        = 0.01;
input double   AutoLot                     = 0;

input group    "=== ATR distance ==="
input bool     UseATR_Distance             = true;
input int      ATR_Period                  = 14;
input double   ATR_SL_Multiplier           = 1.0;
input double   ATR_Trail_Multiplier        = 0.8;
input double   ATR_DeltaStop_Multiplier    = 0.8;
input double   ATR_DeltaLimit_Multiplier   = 0.5;

input group    "=== Trailing Stop ==="
input int      TrailingStop_Points         = 5000;
input int      TrailingStep_Points         = 1000;
input int      TrailingStop_Pips           = 0;
input int      TrailingStep_Pips           = 0;

input group    "=== Breakeven + Grid Trailing ==="
input bool     UseBreakeven                = true;
input int      BreakevenTrigger_Pips       = 300;
input int      BreakevenOffset_Pips        = 30;
input bool     UseGridTrailing             = true;
input int      GridStep_Pips               = 200;
input int      GridLock_Pips               = 100;

input group    "=== Take Profit ==="
input double   TakeProfitPercentOfBalance  = 0.2;
input double   RiskRewardRatio            = 2.0;
input bool     UseFixedRR                 = false;

input group    "=== SL / Pending distances ==="
input int      MaxStopLoss_Points          = 40000;
input int      MinSL_Points                = 10000;
input int      DeltaStop_Points            = 30000;
input int      DeltaLimit_Points           = 15000;
input int      MaxStopLoss_Pips            = 0;
input int      MinSL_Pips                  = 0;
input int      DeltaStop_Pips              = 0;
input int      DeltaLimit_Pips             = 0;

input group    "=== Drawdown protection ==="
input double   MaxDrawdownPercent          = 6.0;
input double   ResumeRecoveryPercent       = 30.0;

input group    "=== Equity / money protection ==="
input double   TakeProfitPercent           = 2;
input double   All_Prof                    = 50;
input double   All_Loss                    = 200;

input group    "=== Indicators (core signal) ==="
input int      Ma_period                   = 10;
input int      Bb_period                   = 17;
input int      Fast_emaperiod              = 10;
input int      Slow_emaperiod              = 19;
input int      Signal_smaperiod            = 13;
input int      Rsi_period                  = 12;

input group    "=== Confirmation filters ==="
input bool     UseFilter_VolatilityRegime = false;
input int      ATR_VolatilityPeriod       = 20;
input double   HighVolatilityMultiplier   = 2.2;
input bool     UseTrendAlignmentFilter    = true;
input ENUM_TIMEFRAMES TrendTimeframe      = PERIOD_H1;
input int      TrendMA_Period             = 50;

input bool     UseFilter_Stoch             = false;
input int      Stoch_KPeriod               = 14;
input int      Stoch_DPeriod               = 3;
input int      Stoch_Slowing               = 3;
input int      Stoch_Oversold              = 20;
input int      Stoch_Overbought            = 80;

input bool     UseFilter_MACDCross         = false;
input bool     UseFilter_ADX               = false;
input int      ADX_Period                  = 14;
input double   ADX_Threshold               = 22.0;

input bool     UseFilter_HTFTrend          = true;
input ENUM_TIMEFRAMES HTF_Timeframe        = PERIOD_H4;
input int      HTF_EMA_Period              = 50;
input int      HTF_BufferPoints            = 0;

input bool     UseFilter_Volume            = true;
input int      Volume_LookbackBars         = 20;
input double   Volume_Multiplier           = 1.2;

input bool     UseFilter_MTF_MACD          = true;
input ENUM_TIMEFRAMES MTF_MACD_Timeframe   = PERIOD_H1;

input bool     UseFilter_CandleStructure   = true;
input double   CandleBodyMinRatio          = 0.5;

input bool     UseFilter_ATRContraction    = true;
input int      ATR_AvgLookback             = 20;
input double   ATR_MaxRatio                = 1.3;

input group    "=== AI Confidence Engine ==="
input double   AI_DecisionWeight           = 60.0;
input double   AI_ConfidenceThreshold      = 70.0;
input bool     LogAIScores                 = false;
input double   AI_W_Volatility             = 1.0;
input double   AI_W_Momentum               = 1.0;
input double   AI_W_TrendStability         = 1.0;
input double   AI_W_RSIPositioning         = 1.0;
input double   AI_W_ADXPower               = 1.0;
input int      AI_TrendStabilityBars       = 6;

input bool     LogBlockedSignals           = false;

input group    "=== Entry filters ==="
input int      MaxSpreadPoints             = 300;
input bool     UseSessionFilter            = false;
input int      MinHour                     = 0;
input int      MaxHour                     = 23;

input group    "=== Cooldown after losses ==="
input bool     UseCooldownAfterLoss        = true;
input int      Cooldown_AfterLossMinutes   = 60;
input int      MaxConsecutiveLosses        = 3;
input int      Cooldown_AfterStreakHours   = 6;
input int      MaxLossesPerDay             = 5;
input bool     OnlyOneOpenPosition         = true;

input group    "=== Equity safeguards ==="
input bool     UseEquityFloor              = true;
input double   EquityFloorPct              = 90.0;
input bool     UseAutoScaleDownLots        = true;
input double   AutoScaleDownThresholdPct   = 95.0;

input group    "=== Auto-Compounding ==="
enum ENUM_COMPOUND_MODE
{
   COMPOUND_OFF        = 0,
   COMPOUND_LINEAR     = 1,
   COMPOUND_FIXED_RISK = 2
};
input ENUM_COMPOUND_MODE CompoundMode      = COMPOUND_FIXED_RISK;
input bool     UseCustomLotInFixedRisk     = true;
input double   CompoundBaseBalance         = 10000.0;
input double   RiskPerTradePct             = 1.0;
input double   MaxLotCap                   = 5.0;
input double   CompoundStepBalance         = 0.0;

input group    "=== Partial close on TP ==="
input bool     UsePartialClose             = true;
input double   PartialClosePercent         = 50.0;
input double   PartialTPPercent            = 50.0;

input group    "=== Stability Guard (NEW) ==="
input bool     UseStabilityGuard           = true;
input int      StabilityConsecutiveLosses  = 3;
input double   StabilityDownScale          = 0.5;

enum ENUM_PROFIT_MODE
{
   PROFIT_CONTEST   = 0,  // Low DD, high win rate (current)
   PROFIT_BALANCED  = 1,  // Medium DD, medium profit  
   PROFIT_MAX       = 2,  // Higher DD, max profit
   PROFIT_ULTRA     = 3   // 5-10% monthly target
};

input group    "=== Profit Mode ==="
input ENUM_PROFIT_MODE ProfitMode = PROFIT_CONTEST;
input bool     AGR_Enable                 = true;
input double   AGR_Lots                   = 0.03;
input double   AGR_ATR_SL                 = 1.2;
input double   AGR_ATR_Trail              = 0.8;
input double   AGR_ATR_DStop              = 0.8;
input double   AGR_ATR_DLimit             = 0.6;
input int      AGR_BETrigger_Pips         = 400;
input int      AGR_BEOffset_Pips          = 50;
input double   AGR_TPPctBal               = 0.25;
input double   AGR_DDPct                  = 6.0;
input double   AGR_DDResume               = 30.0;
input int      AGR_CoolMin                = 30;
input int      AGR_CoolStreak             = 2;
input int      AGR_CoolStreakHrs          = 2;
input int      AGR_CoolMaxDay             = 4;
input double   AGR_DailyLossStopPct       = 1.5;
input double   AGR_AI_Weight              = 60.0;
input double   AGR_AI_Threshold           = 70.0;
input double   AGR_ADX_Threshold          = 18.0;
input double   AGR_HTF_Buffer             = 2000;
input double   AGR_VolumeMult             = 1.0;
input bool     AGR_UseMTFMACD             = false;
input bool     AGR_UseATRContract         = false;

input group    "=== AGGRESSIVE Mode Custom (display only) ==="

input group    "=== Misc ==="
input ulong    SlippagePoints              = 50;
input bool     UseClosedCandle             = true;
input bool     VerboseLogs                 = true;
input int      PermissionLogIntervalSec    = 300;

//+------------------------------------------------------------------+
//| Globals                                                           |
//+------------------------------------------------------------------+
int      maHandle      = INVALID_HANDLE;
int      bbHandle      = INVALID_HANDLE;
int      macdHandle    = INVALID_HANDLE;
int      rsiHandle     = INVALID_HANDLE;
int      atrHandle     = INVALID_HANDLE;
int      stochHandle   = INVALID_HANDLE;
int      adxHandle     = INVALID_HANDLE;
int      htfEmaHandle  = INVALID_HANDLE;
int      mtfMacdHandle = INVALID_HANDLE;

int      barsCount     = 0;
int      pipMultiplier = 1;

int      effMaxStopLossPts, effMinSLPts, effDeltaStopPts, effDeltaLimitPts;
int      effTrailingStopPts, effTrailingStepPts;
double   priceMaxStopLoss, priceMinSL, priceDeltaStop, priceDeltaLimit;

int      effStartTime, effEndTime, effMinHour, effMaxHour;
int      trendHandle;
int      effMaPeriod, effBbPeriod, effFastEma, effSlowEma, effSignalSma, effRsiPeriod;

double   initBalance        = 0.0;
double   peakEquity         = 0.0;
bool     drawdownPaused     = false;
bool     equityFloorBroken  = false;
double   drawdownPauseEquity = 0.0;

bool     hasLowRiskBuy      = false;
bool     hasLowRiskSell     = false;

datetime lastPermLog        = 0;
bool     lastPermState      = true;

datetime cooldownUntil      = 0;
int      consecutiveLosses  = 0;
int      lossesToday        = 0;
datetime lossesTodayDate    = 0;

double   realizedPnLToday   = 0.0;
bool     dayLockedLoss      = false;

bool     eff_BUY_lowRisk, eff_SELL_lowRisk;
bool     eff_BUY_market,  eff_SELL_market;
bool     eff_BUY_stop,    eff_SELL_stop;
bool     eff_BUY_limit,   eff_SELL_limit;
bool     eff_OnlyOnePos;
double   eff_Lots;
bool     eff_UseATR;
bool     eff_UseTrailing;
double   eff_ATR_SL, eff_ATR_Trail, eff_ATR_DStop, eff_ATR_DLimit;
bool     eff_UseBE, eff_UseGrid;
int      eff_BETrig, eff_BEOff, eff_GridStep, eff_GridLock;
double   eff_TPPctBal, eff_TPPct;
double   eff_DDPct, eff_DDResume;
bool     eff_FStoch, eff_FMACDX, eff_FADX;
bool     eff_FHTF;
int      eff_HTFBuffer;
bool     eff_FVolume, eff_FMTFMACD, eff_FCandle, eff_FATRContract;
double   eff_VolumeMult, eff_CandleMinRatio, eff_ATRMaxRatio;
int      eff_VolumeLookback, eff_ATRAvgLookback;
double   eff_AI_Weight, eff_AI_Threshold;
double   eff_AI_W_Vol, eff_AI_W_Mom, eff_AI_W_Trend, eff_AI_W_RSI, eff_AI_W_ADX;
int      eff_AI_TrendBars;
double   eff_ADXThr;
int      eff_StochOS, eff_StochOB;
bool     eff_UseCool;
int      eff_CoolMin, eff_CoolStreak, eff_CoolStreakHrs, eff_CoolMaxDay;
double   eff_DailyLossStopPct;
bool     eff_UseVolRegime, eff_UseTrendAlign;
double   eff_HighVolMult;
int      eff_ATRVolPeriod, eff_TrendPeriod;

const int LookbackBars = 10;

//+------------------------------------------------------------------+
void ApplyRiskMode()
{
   eff_BUY_lowRisk   = BUY_market_lowRisk;
   eff_SELL_lowRisk  = SELL_market_lowRisk;
   eff_BUY_market    = BUY_market;
   eff_SELL_market   = SELL_market;
   eff_BUY_stop      = BUY_stop;
   eff_SELL_stop     = SELL_stop;
   eff_BUY_limit     = BUY_limit;
   eff_SELL_limit    = SELL_limit;
   eff_OnlyOnePos    = OnlyOneOpenPosition;

   eff_Lots          = Lots;
   eff_UseATR        = UseATR_Distance;
   eff_UseTrailing   = true;
   eff_ATR_SL        = ATR_SL_Multiplier;
   eff_ATR_Trail     = ATR_Trail_Multiplier;
   eff_ATR_DStop     = ATR_DeltaStop_Multiplier;
   eff_ATR_DLimit    = ATR_DeltaLimit_Multiplier;

   eff_UseBE         = UseBreakeven;
   eff_UseGrid       = UseGridTrailing;
   eff_BETrig        = BreakevenTrigger_Pips;
   eff_BEOff         = BreakevenOffset_Pips;
   eff_GridStep      = GridStep_Pips;
   eff_GridLock      = GridLock_Pips;

eff_TPPctBal      = TakeProfitPercentOfBalance;
    eff_TPPct         = TakeProfitPercent;
    eff_DDResume      = ResumeRecoveryPercent;
    if(ProfitMode == PROFIT_CONTEST)
       eff_DDPct      = MaxDrawdownPercent;
    // ProfitMode will override eff_DDPct later

   eff_FStoch        = UseFilter_Stoch;
   eff_FMACDX        = UseFilter_MACDCross;
   eff_FADX          = UseFilter_ADX;
   eff_ADXThr        = ADX_Threshold;
   eff_StochOS       = Stoch_Oversold;
   eff_StochOB       = Stoch_Overbought;
   eff_FHTF          = UseFilter_HTFTrend;
   eff_HTFBuffer     = HTF_BufferPoints;
   eff_FVolume       = UseFilter_Volume;
   eff_FMTFMACD      = UseFilter_MTF_MACD;
   eff_FCandle       = UseFilter_CandleStructure;
   eff_FATRContract  = UseFilter_ATRContraction;
   eff_VolumeMult    = Volume_Multiplier;
   eff_VolumeLookback= Volume_LookbackBars;
   eff_CandleMinRatio= CandleBodyMinRatio;
   eff_ATRMaxRatio   = ATR_MaxRatio;
   eff_ATRAvgLookback= ATR_AvgLookback;
   eff_AI_Weight     = AI_DecisionWeight;
   eff_AI_Threshold  = AI_ConfidenceThreshold;
   eff_AI_W_Vol      = AI_W_Volatility;
   eff_AI_W_Mom      = AI_W_Momentum;
   eff_UseVolRegime  = UseFilter_VolatilityRegime;
   eff_HighVolMult   = HighVolatilityMultiplier;
   eff_ATRVolPeriod  = ATR_VolatilityPeriod;
   eff_UseTrendAlign = UseTrendAlignmentFilter;
   eff_TrendPeriod   = TrendMA_Period;
   eff_AI_W_Trend    = AI_W_TrendStability;
   eff_AI_W_RSI      = AI_W_RSIPositioning;
   eff_AI_W_ADX      = AI_W_ADXPower;
   eff_AI_TrendBars  = AI_TrendStabilityBars;

   eff_UseCool       = UseCooldownAfterLoss;
   eff_CoolMin       = Cooldown_AfterLossMinutes;
   eff_CoolStreak    = MaxConsecutiveLosses;
   eff_CoolStreakHrs = Cooldown_AfterStreakHours;
   eff_CoolMaxDay    = MaxLossesPerDay;
   eff_DailyLossStopPct   = 0.0;

   string label = "CUSTOM";

   if(RiskMode == MODE_AGGRESSIVE)
   {
      label = "AGGRESSIVE";
      eff_BUY_lowRisk = true;  eff_SELL_lowRisk = true;
      eff_BUY_market  = true;  eff_SELL_market  = true;
      eff_BUY_stop    = true;  eff_SELL_stop    = true;
      eff_BUY_limit   = true;  eff_SELL_limit   = true;
      eff_OnlyOnePos  = true;
      
      if(ProfitMode == PROFIT_CONTEST)
      {
         eff_Lots        = 0.03;
         eff_ATR_SL      = 1.2;
         eff_ATR_Trail   = 0.8;
         eff_ATR_DStop   = 0.8;
         eff_ATR_DLimit  = 0.6;
         eff_BETrig      = 400;
         eff_BEOff       = 50;
         eff_TPPctBal    = 0.25;
         eff_DDPct       = 6.0;
         eff_AI_Weight   = 60.0;
         eff_AI_Threshold= 70.0;
      }
      else if(ProfitMode == PROFIT_BALANCED)
      {
         eff_Lots        = 0.12;
         eff_ATR_SL      = 2.0;
         eff_ATR_Trail   = 1.5;
         eff_ATR_DStop   = 1.5;
         eff_ATR_DLimit  = 1.0;
         eff_BETrig      = 600;
         eff_BEOff       = 80;
         eff_TPPctBal    = 1.5;
         eff_DDPct       = 10.0;
         eff_AI_Weight   = 55.0;
         eff_AI_Threshold= 65.0;
      }
      else if(ProfitMode == PROFIT_MAX)
      {
         eff_Lots        = 0.08;
         eff_ATR_SL      = 2.0;
         eff_ATR_Trail   = 1.5;
         eff_ATR_DStop   = 1.5;
         eff_ATR_DLimit  = 1.0;
         eff_BETrig      = 800;
         eff_BEOff       = 100;
         eff_TPPctBal    = 1.0;
         eff_DDPct       = 12.0;
         eff_AI_Weight   = 40.0;
         eff_AI_Threshold= 50.0;
      }
      else if(ProfitMode == PROFIT_ULTRA)
      {
         eff_Lots        = 0.15;
         eff_ATR_SL      = 2.0;
         eff_ATR_Trail   = 1.5;
         eff_ATR_DStop   = 1.5;
         eff_ATR_DLimit  = 1.0;
         eff_BETrig      = 600;
         eff_BEOff       = 80;
         eff_TPPctBal    = 3.0;
         eff_DDPct       = 18.0;
         eff_AI_Weight   = 50.0;
         eff_AI_Threshold= 60.0;
      }
      
      eff_FStoch      = false;
      eff_FMACDX      = false;
      eff_FADX        = true;
      eff_ADXThr      = 18.0;
      eff_FHTF        = true;
      eff_HTFBuffer   = 2000;
      eff_FVolume     = true;
      eff_VolumeMult  = 1.0;
      eff_FMTFMACD    = false;
      eff_FCandle     = false;
      eff_FATRContract= false;
      eff_UseVolRegime = false;
      eff_UseTrendAlign = false;
      eff_AI_W_Mom    = 1.0;
      eff_AI_W_Trend  = 1.0;
      eff_UseATR      = true;
      eff_UseTrailing = false;
      eff_UseBE       = true;
      eff_UseGrid     = false;
      eff_TPPct       = 0;
      eff_DDResume    = 30.0;
      eff_UseCool     = true;
      eff_CoolMin     = 20;
      eff_CoolStreak  = 3;
      eff_CoolStreakHrs = 2;
      eff_CoolMaxDay  = 6;
      eff_DailyLossStopPct   = (ProfitMode == PROFIT_MAX || ProfitMode == PROFIT_ULTRA ? 3.0 : 1.5);
   }

   PrintFormat("[RISKMODE] %s ATR=%s DD=%.1f%% BE=%d/%d TPPct=%.1f AI_W=%.0f",
               label, eff_UseATR?"ON":"OFF", eff_DDPct, eff_BETrig, eff_BEOff, eff_TPPctBal, eff_AI_Weight);
}

//+------------------------------------------------------------------+
bool TradingPermitted()
{
   if(MQLInfoInteger(MQL_TESTER) || MQLInfoInteger(MQL_OPTIMIZATION) ||
      MQLInfoInteger(MQL_VISUAL_MODE) || MQLInfoInteger(MQL_FRAME_MODE))
      return true;

   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))     return false;
   if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))       return false;
   if(!AccountInfoInteger(ACCOUNT_TRADE_EXPERT))        return false;
   long mode = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE);
   if(mode != SYMBOL_TRADE_MODE_FULL)                   return false;
   return true;
}

void LogPermissionState(bool permitted)
{
   if(!VerboseLogs) return;
   if(MQLInfoInteger(MQL_OPTIMIZATION)) return;
   bool transition = (permitted != lastPermState);
   datetime now = TimeCurrent();
   if(!transition && (now - lastPermLog) < PermissionLogIntervalSec) return;
   lastPermLog = now;
   lastPermState = permitted;
}

//+------------------------------------------------------------------+
int DetectPipMultiplier()
{
   int d = _Digits;
   if(d == 5 || d == 3) return 10;
   if(d == 2)           return 10;
   return 1;
}

int ResolveDistance(int pipValue, int pointValue)
{
   if(pipValue > 0) return pipValue * pipMultiplier;
   return pointValue;
}

double PointsToPrice(int points) { return points * _Point; }
int    PipsToPoints(int pips)    { return pips * pipMultiplier; }
double PipsToPrice(int pips)     { return PipsToPoints(pips) * _Point; }

double GetATR(int shift = 1)
{
   double tmp[1];
   if(CopyBuffer(atrHandle, 0, shift, 1, tmp) != 1) return 0;
   return tmp[0];
}

double LastBarRange()
{
   double hi[1], lo[1];
   if(CopyHigh(_Symbol, TimeFrame, 1, 1, hi) != 1) return 0;
   if(CopyLow(_Symbol, TimeFrame, 1, 1, lo) != 1) return 0;
   return MathMax(0.0, hi[0] - lo[0]);
}

double DynamicDistance(double atrMultiplier)
{
   double atr = GetATR(1);
   double range = LastBarRange();
   double d = MathMax(atr * atrMultiplier, range);
   if(d <= 0) d = _Point * 100;
   return d;
}

double ComputeTakeProfitPrice(double entryPrice, bool isBuy, double lot)
{
   if(eff_TPPctBal <= 0 || lot <= 0) return 0.0;
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double targetProfit = balance * eff_TPPctBal / 100.0;
   double contractSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   if(contractSize <= 0) contractSize = 1.0;
   double pointValue = contractSize * _Point;
   double priceDistance = targetProfit / (lot * pointValue);
   priceDistance = MathMax(priceDistance, _Point * 10);
   return isBuy ? entryPrice + priceDistance : entryPrice - priceDistance;
}

//+------------------------------------------------------------------+
void UpdateDrawdownState()
{
   double eq = AccountInfoDouble(ACCOUNT_EQUITY);
   if(eq > peakEquity) peakEquity = eq;

   if(UseEquityFloor && initBalance > 0 && !equityFloorBroken)
   {
      double floor = initBalance * EquityFloorPct / 100.0;
      if(eq < floor)
      {
         equityFloorBroken = true;
         CloseAllPositions("EquityFloorBroken");
         PrintFormat("[EQUITY-FLOOR] HARD STOP - restart EA");
         return;
      }
   }

   if(eff_DDPct <= 0 || peakEquity <= 0) return;
   double ddPct = (peakEquity - eq) / peakEquity * 100.0;

   if(!drawdownPaused && ddPct >= eff_DDPct)
   {
      drawdownPaused = true;
      drawdownPauseEquity = eq;
      PrintFormat("[DD-PAUSE] DD %.2f%% >= %.2f%%", ddPct, eff_DDPct);
   }
   else if(drawdownPaused)
   {
      double lossAtPause = peakEquity - drawdownPauseEquity;
      double recoveredNeeded = lossAtPause * eff_DDResume / 100.0;
      if(eq >= drawdownPauseEquity + recoveredNeeded)
      {
         drawdownPaused = false;
         PrintFormat("[DD-RESUME] Equity recovered");
      }
   }
}

//+------------------------------------------------------------------+
void BreakevenAndGridHandler()
{
   if(!eff_UseBE && !eff_UseGrid) return;
   if(!TradingPermitted()) return;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!positionInfo.SelectByIndex(i)) continue;
      if(positionInfo.Symbol() != _Symbol || positionInfo.Magic() != InpMagicNumber) continue;

      bool isBuy = (positionInfo.PositionType() == POSITION_TYPE_BUY);
      double entry = positionInfo.PriceOpen();
      double sl = positionInfo.StopLoss();
      double tp = positionInfo.TakeProfit();
      double price = isBuy ? symInfo.Bid() : symInfo.Ask();
      double profitPriceDist = isBuy ? (price - entry) : (entry - price);
      if(profitPriceDist <= 0) continue;

      int profitPips = (int)MathFloor(profitPriceDist / _Point) / pipMultiplier;
      int lockPips = -1;

      if(eff_UseBE && profitPips >= eff_BETrig) lockPips = eff_BEOff;

      if(lockPips < 0) continue;

      double lockPrice = isBuy ? entry + PipsToPrice(lockPips) : entry - PipsToPrice(lockPips);
      lockPrice = NormalizeDouble(lockPrice, _Digits);

      bool shouldMove = isBuy ? (sl == 0 || lockPrice > sl + _Point) : (sl == 0 || lockPrice < sl - _Point);
      if(isBuy && lockPrice >= price) continue;
      if(!isBuy && lockPrice <= price) continue;

      if(shouldMove) trade.PositionModify(positionInfo.Ticket(), lockPrice, tp);
   }
}

//+------------------------------------------------------------------+
void TrailingStopHandler() {}

//+------------------------------------------------------------------+
int OnInit()
{
   ApplyRiskMode();
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(SlippagePoints);
   trade.SetTypeFillingBySymbol(_Symbol);
   trade.SetMarginMode();

   if(!symInfo.Name(_Symbol)) { SymbolSelect(_Symbol, true); symInfo.Name(_Symbol); }
   symInfo.RefreshRates();

   effStartTime = (int)MathMax(0, MathMin(23, StartTime));
   effEndTime   = (int)MathMax(0, MathMin(23, EndTime));
   effMinHour   = (int)MathMax(0, MathMin(23, MinHour));
   effMaxHour   = (int)MathMax(0, MathMin(23, MaxHour));
   effMaPeriod  = (int)MathMax(2, MathMin(100, Ma_period));
   effBbPeriod  = (int)MathMax(5, MathMin(100, Bb_period));
   effFastEma   = (int)MathMax(5, MathMin(100, Fast_emaperiod));
   effSlowEma   = (int)MathMax(5, MathMin(150, Slow_emaperiod));
   effSignalSma = (int)MathMax(5, MathMin(150, Signal_smaperiod));
   effRsiPeriod = (int)MathMax(5, MathMin(50, Rsi_period));

   pipMultiplier = DetectPipMultiplier();
   effMaxStopLossPts   = ResolveDistance(MaxStopLoss_Pips,    MaxStopLoss_Points);
   effMinSLPts         = ResolveDistance(MinSL_Pips,          MinSL_Points);
   effDeltaStopPts     = ResolveDistance(DeltaStop_Pips,      DeltaStop_Points);
   effDeltaLimitPts    = ResolveDistance(DeltaLimit_Pips,     DeltaLimit_Points);
   effTrailingStopPts  = ResolveDistance(TrailingStop_Pips,   TrailingStop_Points);
   effTrailingStepPts  = ResolveDistance(TrailingStep_Pips,   TrailingStep_Points);

   priceMaxStopLoss = PointsToPrice(effMaxStopLossPts);
   priceMinSL       = PointsToPrice(effMinSLPts);
   priceDeltaStop   = PointsToPrice(effDeltaStopPts);
   priceDeltaLimit  = PointsToPrice(effDeltaLimitPts);

   maHandle    = iMA(_Symbol, TimeFrame, effMaPeriod, 0, MODE_SMA, PRICE_CLOSE);
   bbHandle    = iBands(_Symbol, TimeFrame, effBbPeriod, 0, 2.0, PRICE_CLOSE);
   macdHandle  = iMACD(_Symbol, TimeFrame, effFastEma, effSlowEma, effSignalSma, PRICE_CLOSE);
   rsiHandle   = iRSI(_Symbol, TimeFrame, effRsiPeriod, PRICE_CLOSE);
   atrHandle   = iATR(_Symbol, TimeFrame, ATR_Period);
   stochHandle = iStochastic(_Symbol, TimeFrame, Stoch_KPeriod, Stoch_DPeriod, Stoch_Slowing, MODE_SMA, STO_LOWHIGH);
   adxHandle   = iADX(_Symbol, TimeFrame, ADX_Period);
   htfEmaHandle = iMA(_Symbol, HTF_Timeframe, HTF_EMA_Period, 0, MODE_EMA, PRICE_CLOSE);
   mtfMacdHandle = iMACD(_Symbol, MTF_MACD_Timeframe, effFastEma, effSlowEma, effSignalSma, PRICE_CLOSE);
   trendHandle = iMA(_Symbol, TrendTimeframe, TrendMA_Period, 0, MODE_EMA, PRICE_CLOSE);

   barsCount   = Bars(_Symbol, TimeFrame);
   initBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   peakEquity  = AccountInfoDouble(ACCOUNT_EQUITY);
   drawdownPaused = false;
   lastPermState = TradingPermitted();

   Print("H457EA v3.00 init OK");
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   if(maHandle != INVALID_HANDLE) IndicatorRelease(maHandle);
   if(bbHandle != INVALID_HANDLE) IndicatorRelease(bbHandle);
   if(macdHandle != INVALID_HANDLE) IndicatorRelease(macdHandle);
   if(rsiHandle != INVALID_HANDLE) IndicatorRelease(rsiHandle);
   if(atrHandle != INVALID_HANDLE) IndicatorRelease(atrHandle);
   if(stochHandle != INVALID_HANDLE) IndicatorRelease(stochHandle);
   if(adxHandle != INVALID_HANDLE) IndicatorRelease(adxHandle);
   if(htfEmaHandle != INVALID_HANDLE) IndicatorRelease(htfEmaHandle);
   if(mtfMacdHandle != INVALID_HANDLE) IndicatorRelease(mtfMacdHandle);
   if(trendHandle != INVALID_HANDLE) IndicatorRelease(trendHandle);
}

//+------------------------------------------------------------------+
void RefreshLowRiskFlags()
{
   hasLowRiskBuy = hasLowRiskSell = false;
   for(int i = PositionsTotal()-1; i >= 0; i--)
      if(positionInfo.SelectByIndex(i) && positionInfo.Symbol() == _Symbol && positionInfo.Magic() == InpMagicNumber)
      {
         if(positionInfo.PositionType() == POSITION_TYPE_BUY) hasLowRiskBuy = true;
         if(positionInfo.PositionType() == POSITION_TYPE_SELL) hasLowRiskSell = true;
      }
}

bool HasPendingOfType(ENUM_ORDER_TYPE type)
{
   for(int i = OrdersTotal()-1; i >= 0; i--)
      if(orderInfo.SelectByIndex(i) && orderInfo.Symbol() == _Symbol && orderInfo.Magic() == InpMagicNumber && orderInfo.OrderType() == type) return true;
   return false;
}

bool GetIndicator(int handle, int buffer, int shift, double &value)
{
   double tmp[1];
   if(CopyBuffer(handle, buffer, shift, 1, tmp) != 1) return false;
   value = tmp[0];
   return true;
}

double TotalProfit()
{
   double sum = 0;
   for(int i = PositionsTotal()-1; i >= 0; i--)
      if(positionInfo.SelectByIndex(i) && positionInfo.Symbol() == _Symbol && positionInfo.Magic() == InpMagicNumber)
         sum += positionInfo.Profit() + positionInfo.Swap() + positionInfo.Commission();
   return sum;
}

void CloseAllPositions(string reason)
{
   if(!TradingPermitted()) return;
   for(int i = PositionsTotal()-1; i >= 0; i--)
      if(positionInfo.SelectByIndex(i) && positionInfo.Symbol() == _Symbol && positionInfo.Magic() == InpMagicNumber)
         trade.PositionClose(positionInfo.Ticket());
   for(int i = OrdersTotal()-1; i >= 0; i--)
      if(orderInfo.SelectByIndex(i) && orderInfo.Symbol() == _Symbol && orderInfo.Magic() == InpMagicNumber)
         trade.OrderDelete(orderInfo.Ticket());
   hasLowRiskBuy = hasLowRiskSell = false;
}

double NormalizeLot(double lot)
{
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double stepLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(stepLot <= 0) stepLot = 0.01;
   lot = MathFloor(lot / stepLot) * stepLot;
   lot = MathMax(minLot, MathMin(maxLot, lot));
   return NormalizeDouble(lot, (stepLot >= 0.1) ? 2 : 3);
}

double CompoundReferenceBalance()
{
   if(CompoundBaseBalance > 0) return CompoundBaseBalance;
   if(initBalance > 0) return initBalance;
   return 10000.0;
}

double ComputeLots()
{
   double bal = AccountInfoDouble(ACCOUNT_BALANCE);
   double lot = eff_Lots;

   if(CompoundMode == COMPOUND_LINEAR)
   {
      double refBal = CompoundReferenceBalance();
      if(refBal > 0) lot = eff_Lots * (bal / refBal);
   }
   else if(CompoundMode == COMPOUND_FIXED_RISK)
   {
      if(UseCustomLotInFixedRisk) lot = eff_Lots;
      else
      {
         double slDistance = EffectiveMaxSLDistance();
         double contractSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
         if(contractSize <= 0) contractSize = 1.0;
         double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
         if(tickValue <= 0) tickValue = 1.0;
         double riskPerLot = (slDistance / _Point) * tickValue;
         if(riskPerLot > 0 && RiskPerTradePct > 0) lot = (bal * RiskPerTradePct / 100.0) / riskPerLot;
      }
   }
   else if(AutoLot > 0) lot = NormalizeDouble((AccountInfoDouble(ACCOUNT_MARGIN_FREE) * AutoLot) / 10000.0, 2);

   if(MaxLotCap > 0 && lot > MaxLotCap) lot = MaxLotCap;

   if(UseAutoScaleDownLots && initBalance > 0)
   {
      double balPct = bal / initBalance * 100.0;
      if(balPct < AutoScaleDownThresholdPct)
      {
         double range = AutoScaleDownThresholdPct - EquityFloorPct;
         if(range > 0) lot = lot * MathMax(0.5, MathMin(1.0, (balPct - EquityFloorPct) / range));
      }
   }

   lot = NormalizeLot(lot);
   if(lot <= 0) return 0;
   double marginReq, ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, lot, ask, marginReq))
      if(marginReq > AccountInfoDouble(ACCOUNT_MARGIN_FREE)) return 0;
   return lot;
}

double LookbackHigh(int bars)
{
   double hi[];
   if(CopyHigh(_Symbol, TimeFrame, 1, bars, hi) != bars) return 0;
   double v = hi[0];
   for(int i=1; i<bars; i++) if(hi[i] > v) v = hi[i];
   return v;
}

double LookbackLow(int bars)
{
   double lo[];
   if(CopyLow(_Symbol, TimeFrame, 1, bars, lo) != bars) return 0;
   double v = lo[0];
   for(int i=1; i<bars; i++) if(lo[i] < v) v = lo[i];
   return v;
}

double EffectiveMaxSLDistance() { return eff_UseATR ? DynamicDistance(eff_ATR_SL) : priceMaxStopLoss; }

double BuyStopLoss(double entry, double lookbackLow)
{
   double maxDist = EffectiveMaxSLDistance();
   double slDistance = entry - lookbackLow;
   if(slDistance <= 0 || slDistance > maxDist) slDistance = maxDist;
   return NormalizeDouble(entry - slDistance, _Digits);
}

double SellStopLoss(double entry, double lookbackHigh)
{
   double maxDist = EffectiveMaxSLDistance();
   double slDistance = lookbackHigh - entry;
   if(slDistance <= 0 || slDistance > maxDist) slDistance = maxDist;
   return NormalizeDouble(entry + slDistance, _Digits);
}

double GetStopsLevel() { return SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point; }

int GetSpreadPoints() { return (int)MathRound((symInfo.Ask() - symInfo.Bid()) / _Point); }

bool IsBTCSession()
{
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   if(UseSessionFilter && ((dt.hour >= 0 && dt.hour < 8) || (dt.hour >= 13 && dt.hour < 17))) return false;
   return true;
}

//+------------------------------------------------------------------+
bool ADXFilter()
{
   double adxVal;
   if(!GetIndicator(adxHandle, 0, 1, adxVal)) return false;
   return adxVal >= eff_ADXThr;
}

bool HTFTrendFilter(bool wantBuy)
{
   double ema;
   if(!GetIndicator(htfEmaHandle, 0, 0, ema)) return false;
   if(ema <= 0) return false;
   double price = wantBuy ? symInfo.Ask() : symInfo.Bid();
   double buffer = eff_HTFBuffer * _Point;
   return wantBuy ? price >= (ema + buffer) : price <= (ema - buffer);
}

bool VolumeFilter()
{
   long volBuf[];
   int n = MathMax(5, eff_VolumeLookback);
   if(CopyTickVolume(_Symbol, TimeFrame, 1, n + 1, volBuf) != n + 1) return false;
   long signalVol = volBuf[n];
   double sum = 0;
   for(int i = 0; i < n; i++) sum += (double)volBuf[i];
   return (double)signalVol >= (sum / n) * eff_VolumeMult;
}

bool MTFMACDFilter(bool wantBuy)
{
   double main_curr, main_prev;
   if(!GetIndicator(mtfMacdHandle, 0, 1, main_curr)) return false;
   if(!GetIndicator(mtfMacdHandle, 0, 2, main_prev)) return false;
   return wantBuy ? main_curr > main_prev : main_curr < main_prev;
}

bool VolatilityRegimeFilter()
{
   if(!eff_UseVolRegime) return true;
   double atr[], avgAtr;
   int period = eff_ATRVolPeriod;
   if(CopyBuffer(atrHandle, 0, 1, period, atr) != period) return true;
   avgAtr = 0;
   for(int i = 0; i < period; i++) avgAtr += atr[i];
   avgAtr /= period;
   double currentAtr = atr[0];
   if(currentAtr > avgAtr * eff_HighVolMult) return false;
   return true;
}

bool TrendAlignmentFilter(bool wantBuy)
{
   if(!eff_UseTrendAlign) return true;
   double trendMa, price;
   if(!GetIndicator(trendHandle, 0, 0, trendMa)) return true;
   price = wantBuy ? symInfo.Ask() : symInfo.Bid();
   return wantBuy ? price > trendMa : price < trendMa;
}

bool AI_Approves(bool wantBuy)
{
   if(eff_AI_Weight <= 0.0) return true;
   double v, m, t, r, a;
   double score = AI_ConfidenceScore(wantBuy, v, m, t, r, a);
   return score >= eff_AI_Threshold * (eff_AI_Weight / 100.0);
}

double AI_ConfidenceScore(bool wantBuy, double &outVol, double &outMom, double &outTrend, double &outRSI, double &outADX)
{
   outVol = outMom = outTrend = outRSI = outADX = 50.0;
   double atr; if(GetIndicator(atrHandle, 0, 1, atr) && atr > 0)
   {
      double range = LastBarRange();
      if(range > 0) outVol = MathMax(0, MathMin(100, 100 - MathAbs(range/atr - 1.0) * 80));
   }
   double main_curr, main_prev, sig_curr, sig_prev;
   if(GetIndicator(macdHandle, 0, 1, main_curr) && GetIndicator(macdHandle, 0, 2, main_prev) &&
      GetIndicator(macdHandle, 1, 1, sig_curr) && GetIndicator(macdHandle, 1, 2, sig_prev))
   {
      double hist_change = (main_curr - sig_curr) - (main_prev - sig_prev);
      outMom = MathMax(0, MathMin(100, 50 + (wantBuy?hist_change:-hist_change) / (atr*0.05) * 25));
   }
   double rsi; if(GetIndicator(rsiHandle, 0, 1, rsi))
      outRSI = MathMax(0, MathMin(100, 100 - MathAbs(rsi - (wantBuy?52:48)) * 3.33));
   double adx; if(GetIndicator(adxHandle, 0, 1, adx))
      outADX = MathMax(0, (adx - 15) * 4);
   double wsum = eff_AI_W_Vol + eff_AI_W_Mom + eff_AI_W_Trend + eff_AI_W_RSI + eff_AI_W_ADX;
   if(wsum <= 0) return 50.0;
   return (outVol*eff_AI_W_Vol + outMom*eff_AI_W_Mom + outTrend*eff_AI_W_Trend + outRSI*eff_AI_W_RSI + outADX*eff_AI_W_ADX) / wsum;
}

//+------------------------------------------------------------------+
bool ConfirmationFilters(bool wantBuy)
{
   if(MaxSpreadPoints > 0 && GetSpreadPoints() > MaxSpreadPoints) return false;
   if(!IsBTCSession()) return false;
   if(eff_FADX && !ADXFilter()) return false;
   if(eff_FHTF && !HTFTrendFilter(wantBuy)) return false;
   if(eff_FVolume && !VolumeFilter()) return false;
   if(eff_FMTFMACD && !MTFMACDFilter(wantBuy)) return false;
   if(!VolatilityRegimeFilter()) return false;
   if(!TrendAlignmentFilter(wantBuy)) return false;
   if(!AI_Approves(wantBuy)) return false;
   return true;
}

//+------------------------------------------------------------------+
void OnTick()
{
   if(!TradingPermitted()) { UpdateLabels(); return; }
   if(!symInfo.RefreshRates()) return;

   RefreshLowRiskFlags();
   UpdateLabels();
   UpdateDrawdownState();
   CheckEquityTakeProfit();
   CheckMoneyTPSL();
   BreakevenAndGridHandler();

   if(UseClosedCandle && !IsNewBar()) return;
   if(!InTradingWindow()) return;
   if(drawdownPaused || equityFloorBroken) return;
   ResetDailyLossCounterIfNewDay();
   if(dayLockedLoss) return;
   if(InCooldown()) return;
   if(eff_OnlyOnePos && HasOpenPositionForSymbol()) return;

   double ma_curr, ma_prev3, bb_mid, macd_main_curr, macd_main_prev, rsi_curr;
   if(!GetIndicator(maHandle, 0, 1, ma_curr)) return;
   if(!GetIndicator(maHandle, 0, 3, ma_prev3)) return;
   if(!GetIndicator(bbHandle, 0, 1, bb_mid)) return;
   if(!GetIndicator(macdHandle, 0, 1, macd_main_curr)) return;
   if(!GetIndicator(macdHandle, 0, 2, macd_main_prev)) return;
   if(!GetIndicator(rsiHandle, 0, 1, rsi_curr)) return;

   double rangeHigh = LookbackHigh(LookbackBars);
   double rangeLow = LookbackLow(LookbackBars);
   if(rangeHigh <= 0 || rangeLow <= 0) return;

   double ask = symInfo.Ask(), bid = symInfo.Bid();
   double lot = ComputeLots();
   if(lot <= 0) return;

   // Stability guard - reduce lot after consecutive losses
   if(UseStabilityGuard && RiskMode == MODE_AGGRESSIVE && consecutiveLosses >= StabilityConsecutiveLosses)
   {
      lot = NormalizeLot(MathMax(lot * StabilityDownScale, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN)));
   }

   double deltaStopPx = eff_UseATR ? DynamicDistance(eff_ATR_DStop) : priceDeltaStop;
   double deltaLimitPx = eff_UseATR ? DynamicDistance(eff_ATR_DLimit) : priceDeltaLimit;

   bool buyCore = (ma_curr > bb_mid) && (ma_prev3 < bb_mid) && (macd_main_curr > macd_main_prev) && (rsi_curr > 20 && rsi_curr < 80);
   bool sellCore = (ma_curr < bb_mid) && (ma_prev3 > bb_mid) && (macd_main_curr < macd_main_prev) && (rsi_curr > 20 && rsi_curr < 80);

   bool buySignal = buyCore && ConfirmationFilters(true);
   bool sellSignal = sellCore && ConfirmationFilters(false);

   if(eff_BUY_lowRisk && !hasLowRiskBuy && buySignal)
   {
      double sl = BuyStopLoss(ask, rangeLow);
      if(OpenBuy(lot, sl)) hasLowRiskBuy = true;
   }
   if(eff_BUY_market && buySignal)
   {
      double sl = BuyStopLoss(ask, rangeLow);
      OpenBuy(lot, sl);
   }
   if(eff_BUY_stop && buySignal)
   {
      if(!(SkipIfPendingExists && HasPendingOfType(ORDER_TYPE_BUY_STOP)))
      {
         double price = ask + deltaStopPx;
         double sl = BuyStopLoss(price, rangeLow);
         PlacePending(ORDER_TYPE_BUY_STOP, lot, price, sl, price);
      }
   }
   if(eff_BUY_limit && sellSignal)
   {
      if(!(SkipIfPendingExists && HasPendingOfType(ORDER_TYPE_BUY_LIMIT)))
      {
         double price = bid - deltaLimitPx;
         double sl = BuyStopLoss(price, rangeLow);
         PlacePending(ORDER_TYPE_BUY_LIMIT, lot, price, sl, price);
      }
   }

   if(eff_SELL_lowRisk && !hasLowRiskSell && sellSignal)
   {
      double sl = SellStopLoss(bid, rangeHigh);
      if(OpenSell(lot, sl)) hasLowRiskSell = true;
   }
   if(eff_SELL_market && sellSignal)
   {
      double sl = SellStopLoss(bid, rangeHigh);
      OpenSell(lot, sl);
   }
   if(eff_SELL_stop && sellSignal)
   {
      if(!(SkipIfPendingExists && HasPendingOfType(ORDER_TYPE_SELL_STOP)))
      {
         double price = bid - deltaStopPx;
         double sl = SellStopLoss(price, rangeHigh);
         PlacePending(ORDER_TYPE_SELL_STOP, lot, price, sl, price);
      }
   }
   if(eff_SELL_limit && sellSignal)
   {
      if(!(SkipIfPendingExists && HasPendingOfType(ORDER_TYPE_SELL_LIMIT)))
      {
         double price = ask + deltaLimitPx;
         double sl = SellStopLoss(price, rangeHigh);
         PlacePending(ORDER_TYPE_SELL_LIMIT, lot, price, sl, price);
      }
   }
}

//+------------------------------------------------------------------+
bool IsNewBar()
{
   static datetime lastBarTime = 0;
   datetime t = iTime(_Symbol, TimeFrame, 0);
   if(t == 0 || t == lastBarTime) return false;
   lastBarTime = t;
   return true;
}

bool InTradingWindow()
{
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   if(dt.hour < effStartTime || dt.hour > effEndTime) return false;
   if(UseSessionFilter && (dt.hour < effMinHour || dt.hour > effMaxHour)) return false;
   return true;
}

void CheckEquityTakeProfit()
{
   if(eff_TPPct <= 0) return;
   double eq = AccountInfoDouble(ACCOUNT_EQUITY);
   double bal = AccountInfoDouble(ACCOUNT_BALANCE);
   double floatingPL = eq - bal;
   if(floatingPL >= eq * eff_TPPct / 100.0 && floatingPL > 0) CloseAllPositions("EquityTP");
}

void CheckMoneyTPSL()
{
   double profit = TotalProfit();
   if(All_Prof > 0 && profit >= All_Prof) CloseAllPositions("MoneyTP");
   if(All_Loss > 0 && profit <= -All_Loss) CloseAllPositions("MoneySL");
}

void UpdateLabels()
{
   if(MQLInfoInteger(MQL_TESTER) && !MQLInfoInteger(MQL_VISUAL_MODE)) return;
   string currency = " " + AccountInfoString(ACCOUNT_CURRENCY);
   double bal = AccountInfoDouble(ACCOUNT_BALANCE);
   double eq = AccountInfoDouble(ACCOUNT_EQUITY);
   double ddPct = (peakEquity > 0) ? (peakEquity - eq) / peakEquity * 100.0 : 0;
   string atState = (dayLockedLoss) ? StringFormat("DAY STOPPED %.2f", realizedPnLToday) : 
                    (InCooldown()) ? StringFormat("COOLDOWN %dm", (int)(cooldownUntil-TimeCurrent())/60) :
                    "Autotrading";
   color atColor = (dayLockedLoss) ? clrRed : (InCooldown()) ? clrGold : clrLime;
   DrawLabel("VibrixEA_AT", atState, 5, 15, 1, atColor);
   DrawLabel("VibrixEA_Bal", "Balance " + DoubleToString(bal,2)+currency, 5, 35, 1, clrWhite);
   DrawLabel("VibrixEA_PL", "P/L " + DoubleToString(bal-initBalance,2)+currency, 5, 55, 1, (bal>=initBalance?clrLime:clrRed));
}

void DrawLabel(string name, string text, int x, int y, int corner, color clr)
{
   if(ObjectFind(0,name)<0)
   { ObjectCreate(0,name,OBJ_LABEL,0,0,0); ObjectSetInteger(0,name,OBJPROP_CORNER,corner); ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,name,OBJPROP_FONTSIZE,10); ObjectSetString(0,name,OBJPROP_FONT,"Arial"); }
   ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
}

//+------------------------------------------------------------------+
bool InCooldown() { return eff_UseCool && cooldownUntil > 0 && TimeCurrent() < cooldownUntil; }

void ResetDailyLossCounterIfNewDay()
{
   MqlDateTime now; TimeToStruct(TimeCurrent(), now);
   datetime today = StringToTime(StringFormat("%04d.%02d.%02d", now.year, now.mon, now.day));
   if(today != lossesTodayDate) { lossesToday = 0; realizedPnLToday = 0.0; dayLockedLoss = false; lossesTodayDate = today; }
}

void RegisterLossClose(double profit)
{
   ResetDailyLossCounterIfNewDay();
   realizedPnLToday += profit;

   if(eff_DailyLossStopPct > 0 && !dayLockedLoss)
   {
      double bal = AccountInfoDouble(ACCOUNT_BALANCE);
      if(realizedPnLToday <= -bal * eff_DailyLossStopPct / 100.0) { dayLockedLoss = true; CloseAllPositions("DailyLossStop"); }
   }

   if(!eff_UseCool) return;

   if(profit < 0)
   {
      consecutiveLosses++; lossesToday++;
      datetime base = TimeCurrent() + eff_CoolMin * 60;
      if(consecutiveLosses >= eff_CoolStreak) base = MathMax(base, TimeCurrent() + eff_CoolStreakHrs * 3600);
      if(eff_CoolMaxDay > 0 && lossesToday >= eff_CoolMaxDay)
      { MqlDateTime t; TimeToStruct(TimeCurrent(), t); t.hour=0; t.min=0; base = MathMax(base, StructToTime(t)+86400); }
      cooldownUntil = MathMax(cooldownUntil, base);
   }
   else if(profit > 0) consecutiveLosses = 0;
}

bool HasOpenPositionForSymbol()
{
   for(int i = PositionsTotal()-1; i >= 0; i--)
      if(positionInfo.SelectByIndex(i) && positionInfo.Symbol() == _Symbol && positionInfo.Magic() == InpMagicNumber) return true;
   return false;
}

//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result)
{
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD) return;
   RefreshLowRiskFlags();
   if(trans.symbol != _Symbol || trans.deal == 0) return;
   if(!HistoryDealSelect(trans.deal)) return;
   if(HistoryDealGetInteger(trans.deal, DEAL_MAGIC) != (long)InpMagicNumber) return;
   long entry = HistoryDealGetInteger(trans.deal, DEAL_ENTRY);
   if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_INOUT && entry != DEAL_ENTRY_OUT_BY) return;
   double netPnL = HistoryDealGetDouble(trans.deal, DEAL_PROFIT) + HistoryDealGetDouble(trans.deal, DEAL_SWAP) + HistoryDealGetDouble(trans.deal, DEAL_COMMISSION);
   RegisterLossClose(netPnL);
}

//+------------------------------------------------------------------+
bool OpenBuy(double lot, double sl)
{
   double ask = symInfo.Ask(), tp = ComputeTakeProfitPrice(ask, true, lot);
   if(tp > 0 && tp <= ask) tp = 0;
   double stopLevel = GetStopsLevel();
   if(stopLevel > 0) { if(sl > 0 && ask - sl < stopLevel) sl = ask - stopLevel; if(tp > 0 && tp - ask < stopLevel) tp = ask + stopLevel; }
   sl = (sl > 0) ? NormalizeDouble(sl, _Digits) : 0;
   tp = (tp > 0) ? NormalizeDouble(tp, _Digits) : 0;
   return trade.Buy(lot, _Symbol, ask, sl, tp, InpTradeComment);
}

bool OpenSell(double lot, double sl)
{
   double bid = symInfo.Bid(), tp = ComputeTakeProfitPrice(bid, false, lot);
   if(tp > 0 && tp >= bid) tp = 0;
   double stopLevel = GetStopsLevel();
   if(stopLevel > 0) { if(sl > 0 && sl - bid < stopLevel) sl = bid + stopLevel; if(tp > 0 && bid - tp < stopLevel) tp = bid - stopLevel; }
   sl = (sl > 0) ? NormalizeDouble(sl, _Digits) : 0;
   tp = (tp > 0) ? NormalizeDouble(tp, _Digits) : 0;
   return trade.Sell(lot, _Symbol, bid, sl, tp, InpTradeComment);
}

bool PlacePending(ENUM_ORDER_TYPE type, double lot, double price, double sl, double entryForTP)
{
   bool isBuy = (type == ORDER_TYPE_BUY_STOP || type == ORDER_TYPE_BUY_LIMIT);
   double tp = ComputeTakeProfitPrice(entryForTP, isBuy, lot);
   if(tp > 0) { if(isBuy && tp <= price) tp = 0; if(!isBuy && tp >= price) tp = 0; }
   double stopLevel = GetStopsLevel();
   if(stopLevel > 0 && MathAbs(price - (isBuy?symInfo.Ask():symInfo.Bid())) < stopLevel) return false;
   price = NormalizeDouble(price, _Digits);
   sl = (sl > 0) ? NormalizeDouble(sl, _Digits) : 0;
   tp = (tp > 0) ? NormalizeDouble(tp, _Digits) : 0;
   switch(type)
   {
      case ORDER_TYPE_BUY_STOP: return trade.BuyStop(lot, price, _Symbol, sl, tp, ORDER_TIME_GTC, 0, InpTradeComment);
      case ORDER_TYPE_SELL_STOP: return trade.SellStop(lot, price, _Symbol, sl, tp, ORDER_TIME_GTC, 0, InpTradeComment);
      case ORDER_TYPE_BUY_LIMIT: return trade.BuyLimit(lot, price, _Symbol, sl, tp, ORDER_TIME_GTC, 0, InpTradeComment);
      case ORDER_TYPE_SELL_LIMIT: return trade.SellLimit(lot, price, _Symbol, sl, tp, ORDER_TIME_GTC, 0, InpTradeComment);
   }
   return false;
}
//+------------------------------------------------------------------+