# Enhanced SuperTrend & VWAP Expert Advisor System

## Project Overview

This is a complete MQL5 trading system that combines SuperTrend and VWAP indicators with advanced Expert Advisor features. The project consists of three main components following MQL5 best practices.

## Project Structure

```
Enhanced_ST_VWAP_Project/
├── mql5/
│   ├── Experts/
│   │   └── Enhanced_ST_VWAP_EA.mq5          # Main Expert Advisor
│   ├── Include/
│   │   └── Enhanced_TradeAlgorithms.mqh     # Trade management functions
│   └── Indicators/
│       └── Enhanced_ST_VWAP_Indicator.mq5   # SuperTrend + VWAP Indicator
└── README.md
```

## Components Description

### 1. Enhanced_ST_VWAP_EA.mq5 (Expert Advisor)
The main trading robot that combines features from the EA Code Template with SuperTrend & VWAP signal logic.

**Key Features:**
- Advanced state management system (Ready, In Trade, Frozen, Cooldown, Arming)
- Multiple trading sessions support
- Comprehensive time and day filters
- Dynamic and fixed lot sizing options
- Smart trailing stops with break-even functionality
- Position modification limits
- Daily risk management (profit targets, loss limits, max trades)
- Enhanced error handling and retry logic

**Signal Processing:**
- Uses Enhanced_ST_VWAP_Indicator for signal generation
- VWAP filter confirmation for signal validation
- White/Blue/Gray trade classification support
- OnClose event filtering
- Minimum distance from VWAP requirement

### 2. Enhanced_TradeAlgorithms.mqh (Include File)
A comprehensive trading library providing position management and utility functions.

**Key Features:**
- Position opening/closing functions with retry logic
- Advanced lot size calculation (multiple modes)
- Position tracking with modification counters
- Break-even and trailing stop management
- Session time management
- State management utilities
- Trade statistics tracking

### 3. Enhanced_ST_VWAP_Indicator.mq5 (Indicator)
Advanced SuperTrend indicator combined with VWAP filter and performance dashboard.

**Key Features:**
- SuperTrend calculation using ATR multiplier
- VWAP calculation with daily reset option
- Signal filtering based on VWAP confirmation
- Real-time performance dashboard
- Win rate calculation and tracking
- Signal classification (White, Blue, Gray)
- Time window filtering
- Visual feedback with signal markers
- Alert system with sound and popup options

**Dashboard Information:**
- Current market state (Price, SuperTrend, VWAP, Direction)
- Signal statistics (Total, Bullish, Bearish, Accepted, Rejected)
- Performance metrics (Win rate, Last signal info, Averages)
- Technical information (Bars processed, Session status)

## Installation Instructions

1. **Copy files to MetaTrader 5 directory:**
   ```
   Copy Enhanced_TradeAlgorithms.mqh to: MQL5/Include/
   Copy Enhanced_ST_VWAP_Indicator.mq5 to: MQL5/Indicators/
   Copy Enhanced_ST_VWAP_EA.mq5 to: MQL5/Experts/
   ```

2. **Compile the indicator first:**
   - Open Enhanced_ST_VWAP_Indicator.mq5 in MetaEditor
   - Compile (F7)

3. **Compile the Expert Advisor:**
   - Open Enhanced_ST_VWAP_EA.mq5 in MetaEditor
   - Compile (F7)

## Configuration Guide

### Basic Setup
1. **Symbol and Timeframe:** Choose your trading symbol and indicator timeframe
2. **Position Sizing:** Select between dynamic (risk percentage) or fixed lot sizing
3. **Risk Management:** Set stop loss and take profit in points or money amounts
4. **Time Filters:** Configure trading hours and days

### SuperTrend & VWAP Settings
- **ATR Period:** Period for Average True Range calculation (default: 22)
- **Multiplier:** SuperTrend sensitivity multiplier (default: 3.0)
- **VWAP Filter:** Enable/disable VWAP confirmation for signals
- **Source Price:** Price type for SuperTrend calculation (default: PRICE_MEDIAN)

### Advanced Features
- **Break-Even:** Automatic break-even when profit reaches specified percentage
- **Trailing Stops:** Smart trailing stop system
- **Daily Limits:** Maximum trades, profit targets, loss limits per day
- **Session Management:** Multiple trading session support

### Dashboard Settings
- **Position:** Adjust dashboard position on chart
- **Colors:** Customize dashboard appearance
- **Font Settings:** Adjust font type and sizes
- **Performance Tracking:** Enable win rate and statistics tracking

## Signal Logic

### Buy Signals
Generated when:
1. SuperTrend changes from bearish to bullish
2. Price breaks above previous SuperTrend level
3. VWAP filter confirmation (if enabled)
4. Time window validation (if enabled)

### Sell Signals
Generated when:
1. SuperTrend changes from bullish to bearish  
2. Price breaks below previous SuperTrend level
3. VWAP filter confirmation (if enabled)
4. Time window validation (if enabled)

### Signal Filtering
- **OnClose Events:** Signals only generated on bar close (configurable)
- **VWAP Distance:** Minimum distance from VWAP required for signal validation
- **Time Windows:** Signals can be filtered by trading session times
- **Color Classification:** Signals classified as White, Blue, or Gray based on market conditions

## Risk Management Features

### Position Level
- Stop loss and take profit (points or money)
- Break-even automation
- Smart trailing stops
- Position modification limits

### Daily Level
- Maximum trades per day
- Daily profit targets
- Daily loss limits
- Automatic EA shutdown on limits

### System Level
- State management (prevents over-trading)
- Spread filtering
- Connection monitoring
- Data validation

## Monitoring and Alerts

### Dashboard Metrics
- Real-time signal statistics
- Win/loss ratios
- Average points per signal type
- Current market conditions

### Alert System
- Popup alerts for new signals
- Sound notifications
- Visual signal markers on chart
- Log file entries for debugging

## Troubleshooting

### Common Issues
1. **Indicator not loading:** Ensure Enhanced_ST_VWAP_Indicator.mq5 is compiled first
2. **No signals:** Check time filters and VWAP filter settings
3. **Positions not opening:** Verify account permissions and margin requirements
4. **Dashboard not showing:** Check dashboard enable setting and chart permissions

### Debug Mode
Enable "VerboseLogs" parameter for detailed logging information.

## Version History

**Version 5.00**
- Initial release combining SuperTrend & VWAP systems
- Complete EA framework with advanced features
- Comprehensive dashboard and statistics tracking
- Multi-session support and advanced risk management

## License

Enhanced SuperTrend & VWAP Expert Advisor System © 2025

## Support

For questions or issues, refer to the MQL5 community forums or MetaTrader documentation.