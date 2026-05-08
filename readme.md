# H457 Group EA v3.13 - Documentation

## Overview

H457 Group EA v3.13 is an MQL5 intraday scalper trading BTCUSD on a 15-minute timeframe. The EA uses a multi-indicator approach with AI confidence scoring to generate trading signals.

---

## Version History

- **v3.13**: FIX - DDPct override bug, ProfitMode now controls DD

---

## Core Parameters

### General Settings
| Parameter | Default | Description |
|-----------|---------|-------------|
| `EAName` | "H457 Group EA - BTC" | EA identifier |
| `InpMagicNumber` | 2024 | Magic number for order identification |
| `StartTime` / `EndTime` | 0 / 23 | Trading window hours |
| `TimeFrame` | PERIOD_M15 | Primary chart timeframe |

### Order Types
The EA can execute market and pending orders for both buy and sell:
- **Market**: `BUY_market`, `SELL_market`
- **Stop**: `BUY_stop`, `SELL_stop`
- **Limit**: `BUY_limit`, `SELL_limit`
- **Low Risk**: Lower risk variants with special handling

---

## Risk Modes

The EA provides preset risk configurations:

| Mode | Description |
|------|-------------|
| `MODE_CUSTOM` | User-defined parameters |
| `MODE_CONSERVATIVE` | Lowest risk configuration |
| `MODE_MODERATE` | Balanced risk/reward |
| `MODE_AGGRESSIVE` | Highest risk, highest reward potential |

### Aggressive Mode Specifics
When `RiskMode = MODE_AGGRESSIVE`, parameters are auto-adjusted based on `ProfitMode`:
- **PROFIT_CONTEST**: Lots=0.03, DD=6%, AI Weight=60
- **PROFIT_BALANCED**: Lots=0.12, DD=10%, AI Weight=55
- **PROFIT_MAX**: Lots=0.08, DD=12%, AI Weight=40
- **PROFIT_ULTRA**: Lots=0.15, DD=18%, AI Weight=50

---

## Profit Modes

| Mode | Target | Drawdown |
|------|--------|----------|
| `PROFIT_CONTEST` | Low DD, high win rate | ~6% |
| `PROFIT_BALANCED` | Medium DD, medium profit | ~10% |
| `PROFIT_MAX` | Higher DD, max profit | ~12% |
| `PROFIT_ULTRA` | 5-10% monthly target | ~18% |

---

## Technical Indicators

### Core Indicators (Entry Signal)
| Indicator | Period | Purpose |
|----------|--------|---------|
| MA (Moving Average) | 10 | Trend direction |
| Bollinger Bands | 17 | Volatility channel |
| MACD | 10/19/13 (fast/slow/signal) | Momentum |
| RSI | 12 | Overbought/oversold |
| ATR | 14 | Stop loss sizing |

### Confirmation Indicators
| Indicator | Purpose |
|-----------|---------|
| Stochastic | Momentum confirmation (optional) |
| ADX | Trend strength (optional) |
| HTF EMA | Higher timeframe trend filter |
| MTF MACD | Multi-timeframe momentum |
| Volume | Unusual volume detection |

---

## Trading Logic

### Core Buy Signal
```
ma_curr > bb_mid AND
ma_prev3 < bb_mid AND
macd_main_curr > macd_main_prev AND
rsi_curr > 20 AND rsi_curr < 80
```

### Core Sell Signal
```
ma_curr < bb_mid AND
ma_prev3 > bb_mid AND
macd_main_curr < macd_main_prev AND
rsi_curr > 20 AND rsi_curr < 80
```

### Entry Execution Flow
1. Check if new bar (if `UseClosedCandle = true`)
2. Verify trading window (time-based)
3. Check drawdown/equity protection
4. Verify cooldown status
5. Check position limit (`OnlyOneOpenPosition`)
6. Calculate lot size
7. Apply confirmation filters
8. Execute orders based on enabled types

---

## Stop Loss Calculation

### Dynamic SL Methods
1. **ATR-based** (`UseATR_Distance = true`):
   - SL Distance = `ATR × ATR_SL_Multiplier`
   - Fallback: Last bar range

2. **Fixed Points**:
   - `MaxStopLoss_Points` (default 40000)

### Stop Distances
| Parameter | Points | Description |
|-----------|--------|-------------|
| `DeltaStop` | 30000 | Pending stop order distance |
| `DeltaLimit` | 15000 | Pending limit order distance |
| `MinSL` | 10000 | Minimum stop loss |

---

## Take Profit

### Dynamic TP Calculation
```
TargetProfit = Balance × TakeProfitPercentOfBalance
PriceDistance = TargetProfit / (Lot × ContractSize × Point)
```

### Fixed Risk-Reward (optional)
- `RiskRewardRatio = 2.0` (default)
- Enabled via `UseFixedRR = true`

---

## Money Management

### Lot Sizing Modes
| Mode | Formula |
|------|---------|
| Fixed | `Lots` parameter |
| AutoLot | `(FreeMargin × AutoLot) / 10000` |
| Linear Compound | `Lots × (Balance / ReferenceBalance)` |
| Fixed Risk | Risk % per trade based on SL distance |

### Lot Constraints
- `MaxLotCap`: 5.0 (default)
- Auto-scale down when equity < 95% of initial

---

## Risk Protection

### Drawdown Protection
- **MaxDrawdownPercent**: 6% (default)
- **ResumeRecoveryPercent**: 30%
- When DD reached: Pause trading until equity recovers

### Equity Floor
- `EquityFloorPct`: 90%
- Hard stop if equity falls below floor

### Daily Loss Limit
- `DailyLossStopPct`: 1.5% (Aggressive mode)
- Locks trading for rest of day

### Cooldown System
After losing trades:
- `Cooldown_AfterLossMinutes`: 60 min
- After streak: `Cooldown_StreakHours`: 6 hrs
- Max losses per day: 5

### Stability Guard (Aggressive)
- After 3+ consecutive losses: Reduce lot by 50%

---

## AI Confidence Engine

### Scoring Components (weighted)
| Component | Weight Default | Calculation |
|-----------|---------------|-------------|
| Volatility | 1.0 | Based on ATR vs range |
| Momentum | 1.0 | MACD histogram change |
| Trend Stability | 1.0 | EMA alignment over N bars |
| RSI Positioning | 1.0 | Distance from 50 |
| ADX Power | 1.0 | ADX above threshold |

### Approval Threshold
```
Approved = Score >= (AI_Threshold × AI_Weight / 100)
```

Default: Weight=60%, Threshold=70%

---

## Confirmation Filters

### Active Filters (default)
| Filter | Purpose |
|--------|---------|
| HTF Trend | Price must be beyond EMA on H4 |
| Volume | Volume > 1.2× average |
| MTF MACD | MACD direction aligns on H1 |
| Candle Structure | Body ≥ 50% of total range |
| ATR Contraction | ATR < 1.3× average |
| Trend Alignment | Price above/below MA on H1 |
| Volatility Regime | Filter high volatility periods |

### Optional Filters
- Stochastic (oversold/overbought levels)
- MACD Cross
- ADX threshold (default: 22)

### Basic Filters
- Max spread: 300 points
- Session filter (hours 0-8, 13-17)

---

## Trailing & Breakeven

### Breakeven
- Trigger: `BreakevenTrigger_Pips` (default 300)
- Lock at: `BreakevenOffset_Pips` (default 30)

### Grid Trailing
- Step: 200 pips
- Lock: 100 pips

---

## Partial Close

When TP hit:
- Close `PartialClosePercent` (50%) of position
- Move SL to entry for remaining

---

## Auto-Compounding

| Mode | Behavior |
|------|----------|
| `COMPOUND_OFF` | Fixed lot |
| `COMPOUND_LINEAR` | Scale with balance |
| `COMPOUND_FIXED_RISK` | Risk % of balance per trade |

Base balance: 10,000 (or initial balance)
Risk per trade: 1%

---

## Special Features

### AGR (Aggressive) Parameters
Enhanced settings when `AGR_Enable = true`:
- Custom ATR multipliers for SL/TP
- Daily loss stop
- AI weight/threshold tuning

### Logging
- `VerboseLogs`: Detailed trade logging
- `LogAIScores`: AI decision transparency
- `LogBlockedSignals`: Filter rejection reasons
- Permission log interval: 300 seconds

---

## Initialization Flow

1. Apply risk mode presets
2. Initialize trade object with magic number
3. Validate symbol and refresh rates
4. Calculate effective parameters
5. Create indicator handles (MA, BB, MACD, RSI, ATR, etc.)
6. Record initial balance and peak equity

---

## Key Functions

| Function | Purpose |
|----------|---------|
| `OnTick()` | Main trading logic loop |
| `OnTradeTransaction()` | Track closed positions for P&L |
| `ConfirmationFilters()` | All entry filters |
| `AI_ConfidenceScore()` | Weighted signal scoring |
| `ComputeLots()` | Dynamic lot sizing |
| `UpdateDrawdownState()` | DD pause/resume logic |
| `BreakevenAndGridHandler()` | SL management |

---

## Display Labels

The EA displays on chart:
- Trading status (Active/Cooldown/Day Stopped)
- Balance
- P/L since start

---

## Common Issues & Solutions

1. **No trades**: Check trading window hours, spread limits, cooldown
2. **DD pauses**: Normal behavior - waits for recovery
3. **Equity floor hit**: Hard stop - restart EA required
4. **Lots = 0**: Margin insufficient or auto-scale down triggered

---

## Optimization Tips

1. Start with PROFIT_CONTEST mode for live trading
2. Increase AI_Weight for more selective trading
3. Enable filters gradually to find optimal combination
4. Monitor AGR parameters in aggressive mode
5. Use cooldown to prevent over-trading

---

*Generated for H457 Group EA v3.13*
