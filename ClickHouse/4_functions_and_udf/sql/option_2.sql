-- Вариант 2
-- Применение EUDF (конвертация цены из RUB в USD)
select
    user_id,
    sum(price) price_rub,
    toUSD(price_rub) price_usd
from transactions
group by user_id;
