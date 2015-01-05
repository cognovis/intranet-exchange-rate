SELECT acs_log__debug('/packages/intranet-exchange-rate/sql/postgresql/upgrade/upgrade-4.1.0.0.0-4.1.0.0.1.sql','');

create or replace function im_exchange_rate (date, char(3), char(3))
returns float as '
DECLARE
    p_day alias for $1;
    p_from_cur alias for $2;
    p_to_cur alias for $3;

    v_from_rate float;
    v_to_rate float;
BEGIN
    -- Exchange rate of From-Currency to Dollar
    select rate
    into v_from_rate
    from im_exchange_rates
    where currency = p_from_cur
    and day = (select max(day) from im_exchange_rates where day <= p_day and currency = p_from_cur);

    -- Exchange rate of Dollar to To-Currency
    select rate
    into v_to_rate
    from im_exchange_rates
    where currency = p_to_cur
    and day = (select max(day) from im_exchange_rates where day <= p_day and currency = p_from_cur);

    return v_from_rate / v_to_rate;
end;' language 'plpgsql';