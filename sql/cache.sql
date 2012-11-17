create table CacheBeta (
       symbol char(16) not null references AllStockSymbols(symbol),
       beta number not null,
       field varchar(8) not null,
       startTime number not null,
       endTime number not null,
       constraint cb_pk primary key (symbol, field, startTime, endTime)
);

create table CacheCoeffVar (
       symbol char(16) not null references AllStockSymbols(symbol),
       coeffvar number not null,
       field varchar(8) not null,
       startTime number not null,
       endTime number not null,
       constraint ccv_pk primary key (symbol, field, startTime, endTime)
);

create table CacheCovarience (
       symbol1 char(16) not null references AllStockSymbols(symbol),
       symbol2 char(16) not null references AllStockSymbols(symbol),
       cov number not null,
       corr number not null,
       field1 varchar(8) not null,
       field2 varchar(8) not null,
       startTime number not null,
       endTime number not null,
       constraint ccov_pk primary key (symbol1, symbol2, field1, field2, startTime, endTime)
);


