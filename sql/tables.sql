CREATE TABLE Users (
       name VARCHAR(100) NOT NULL PRIMARY KEY,
       password VARCHAR(100) NOT NULL, -- this should really be hashed value of password, ask group what they think
       constraint passwd_not_null CHECK (password LIKE '__%')
);

create sequence portfolio_id_seq start with 1 increment by 1;

CREATE TABLE Portfolios (
       id number NOT NULL PRIMARY KEY,
       user_name VARCHAR(100) NOT NULL REFERENCES Users(name),
       assets number not null,     
       portfolio_name VARCHAR(100), -- user supplied name for porfolio, optional
       constraint positive_portfolio_balance check (assets >= 0)
);

CREATE TABLE AllStockSymbols (
       symbol char(16) not null primary key,
       count number not null,
       first number not null,
       last number not null
);

-- need writable table for new stocks we might add, nice to have all in one table
--INSERT INTO AllStockSymbols (symbol, count, first, last) (SELECT * from CS339.StocksSymbols);

-- table for new stacks, CS339.StocksDaily too big for copy
CREATE TABLE NewStocksDaily (
       symbol char(16) not null references AllStockSymbols(symbol),
       timestamp number not null,
       open number not null,
       high number not null,
       low number not null,
       close number not null,
       volume number not null,
       constraint pk_asd primary key (symbol, timestamp)
);

-- current holdings, select * from holdings where sell_date is null and sell_price is null
-- 
CREATE TABLE Holdings (
       portfolio number NOT NULL REFERENCES Portfolios(id),
       symbol char(16) NOT NULL REFERENCES AllStockSymbols(symbol),
       shares number NOT NULL, -- number of shares of stock
       constraint pk_holdings primary key (portfolio, symbol),
       constraint holdings_postive_shares check (shares >= 0)
);

-- View for a unified stock data;
CREATE VIEW all_stockdailys as SELECT timestamp,symbol,open,close,low,high
							FROM ((SELECT timestamp, symbol,open,close,low,high 
									FROM cs339.stocksdaily) 
							UNION
									(SELECT timestamp, symbol, open,close,low,high 
									FROM newstocksdaily));


-- trigger for auto increment functionality for portfolio id
create or replace trigger portfolio_insert
before insert on Portfolios
for each row
begin
	select portfolio_id_seq.nextval into :new.id from dual;
end;
/

create table BuyHistory (
       portfolio number NOT NULL REFERENCES Portfolios(id),	
       symbol char(16) NOT NULL REFERENCES AllStockSymbols(symbol),
       shares number NOT NULL, -- number of shares of stock
       timestamp number NOT NULL,
       constraint buyhistory_pk primary key (portfolio, symbol, timestamp)
);

create table SellHistory (
       portfolio number NOT NULL REFERENCES Portfolios(id),	
       symbol char(16) NOT NULL REFERENCES AllStockSymbols(symbol),
       shares number NOT NULL, -- number of shares of stock
       timestamp number NOT NULL,
       constraint sellhistory_pk primary key (portfolio, symbol, timestamp)
);

-- shortcut to get unix timestamp
create view UnixTime as SELECT (sysdate - to_date('01-JAN-1970','DD-MON-YYYY')) * (86400) as dt FROM dual;

-- add buy row when inserting a new value
create or replace trigger holdings_insert
after insert on Holdings
for each row
begin
	insert into BuyHistory (portfolio, symbol, shares, timestamp) values (:NEW.portfolio, :NEW.symbol, :NEW.shares, (select dt from UnixTime));
-- also subtract cash from portfolio once I know how to do that
end;
/

-- add buy row when shares increase
create or replace trigger holdings_update_buy
after update on Holdings
for each row
when (NEW.shares > OLD.shares)
begin
	insert into BuyHistory (portfolio, symbol, shares, timestamp) values (:NEW.portfolio, :NEW.symbol, :NEW.shares - :OLD.shares, (select dt from UnixTime));
-- also subtract cash from portfolio once I know how to do that
end;
/

-- add sell row when shares decrease
create or replace trigger holdings_update_sell
after update on Holdings
for each row
when (NEW.shares < OLD.shares)
begin
	insert into SellHistory (portfolio, symbol, shares, timestamp) values (:NEW.portfolio, :NEW.symbol, :OLD.shares - :NEW.shares, (select dt from UnixTime));
-- also subtract cash from portfolio once I know how to do that
end;
/

-- also need table for caching portfolio stats like coefficient of variation and Beta

