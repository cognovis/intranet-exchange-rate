-- /packages/intranet-exchange-rate/sql/postgresql/update/upgrade-3.3.0.0.0-3.3.0.0.1.sql
--
-- ]project[ Exchange Rate Module
-- Copyright (c) 2003-2009 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
-- @author klaus.hofeditz@project-open.com

----------------------------------------------------

SELECT acs_log__debug('/packages/intranet-exchange-rate/sql/postgresql/upgrade/upgrade-3.3.0.0.0-3.3.0.0.1.sql','');

-- Fills ALL "holes" in the im_exchange_rates table.
-- Populate im_exchange_rates for the next 5 years
create or replace function im_exchange_rate_fill_holes_2009 (varchar)
returns integer as '
DECLARE
    p_currency                  alias for $1;
    v_max                       integer;
    v_start_date                date;
    v_rate                      numeric;
    row2                        RECORD;
    exists                      integer;
BEGIN
    RAISE NOTICE ''setting most recent exchange rates'';

	--  2008-12-28 | USD      | 1.000000 | f
	--  2008-12-28 | JPY      | 0.009240 | f
	--  2008-12-28 | EUR      | 1.482850 | f
	--  2008-12-28 | CAD      | 0.950060 | f
	--  2008-12-28 | AUD      | 0.872520 | f

	-- insert most recent exchange rates and set manual_p to 't' so that following filling routine uses this value 	

        select  count(*) into exists
        from im_exchange_rates
        where day='2008-12-29' and currency=p_currency;
        IF exists = 0 THEN
	CASE p_currency
		WHEN 'USD' THEN insert into im_exchange_rates (day, rate, currency, manual_p) values ('2008-12-29', 1.000000, 'USD', ''t'')
		WHEN 'JPY' THEN insert into im_exchange_rates (day, rate, currency, manual_p) values ('2008-12-29', 90.35500, 'JPY', ''t'')
		WHEN 'EUR' THEN insert into im_exchange_rates (day, rate, currency, manual_p) values ('2008-12-29', 0.708400, 'EUR', ''t'')
		WHEN 'CAD' THEN insert into im_exchange_rates (day, rate, currency, manual_p) values ('2008-12-29', 1.222500, 'CAD', ''t'')
		WHEN 'AUD' THEN insert into im_exchange_rates (day, rate, currency, manual_p) values ('2008-12-29', 1.448400, 'AUD', ''t'') 
        END IF;

    RAISE NOTICE ''im_exchange_rate_fill_holes: cur=%'', p_currency;

    v_start_date := to_date(''2008-12-30'', ''YYYY-MM-DD'');
    v_max := 365 * 5;

    -- Loop through all dates and check if there
    -- is a hole (no entry for a date)
    FOR row2 IN
        select  im_day_enumerator as day
        from    im_day_enumerator(v_start_date, v_start_date + v_max)
                LEFT OUTER JOIN (
                        select  *
                        from    im_exchange_rates
                        where   currency = p_currency
                ) ex on (im_day_enumerator = ex.day)
        where   ex.rate is null
    LOOP
        -- RAISE NOTICE ''im_exchange_rate_fill_holes: day=%'', row2.day;
        -- get the latest manually entered exchange rate
        select  rate
        into    v_rate
        from    im_exchange_rates
        where   day = (
                        select  max(day)
                        from    im_exchange_rates
                        where   day < row2.day
                                and currency = p_currency
                                and manual_p = ''t''
                      )
                and currency = p_currency;
        -- RAISE NOTICE ''im_exchange_rate_fill_holes: rate=%'', v_rate;
        -- use the latest exchange rate for the next few years...
        select  count(*) into exists
        from im_exchange_rates
        where day=row2.day and currency=p_currency;
        IF exists > 0 THEN
                update im_exchange_rates
                set     rate = v_rate,
                        manual_p = ''f''
                where   day = row2.day
                        and currency = p_currency;
        ELSE
        RAISE NOTICE ''im_exchange_rate_fill_holes: day=%, cur=%, rate=%, x=%'',row2.day, p_currency, v_rate, exists;
                insert into im_exchange_rates (
                        day, rate, currency, manual_p
                ) values (
                        row2.day, v_rate, p_currency, ''f''
                );
        END IF;

    END LOOP;

    return 0;
end;' language 'plpgsql';

select im_exchange_rate_fill_holes_2009 ('USD');
select im_exchange_rate_fill_holes_2009 ('JPY');
select im_exchange_rate_fill_holes_2009 ('EUR');
select im_exchange_rate_fill_holes_2009 ('CAD');
select im_exchange_rate_fill_holes_2009 ('AUD');

