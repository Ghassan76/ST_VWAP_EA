//+------------------------------------------------------------------+
//|                                                 test_compile.mq5 |
//|                                                     Test compile |
//+------------------------------------------------------------------+
#property copyright "Test"
#property version   "1.00"

#include "Enhanced_ST_VWAP_Project/mql5/Include/Enhanced_TradeAlgorithms.mqh"

// Test basic compilation
int OnInit()
{
    InitializeEnhancedAlgorithms();
    Print("Test compilation successful");
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
    CleanupEnhancedAlgorithms();
}

void OnTick()
{
    // Basic test
}