#!/usr/bin/perl -w

use stock_data_access;

print ExecStockSQL("TEXT",
		   "select symbol from ".GetStockPrefix()."StocksSymbols");

