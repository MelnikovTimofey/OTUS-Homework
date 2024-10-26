-- Вариант 1
-- 1. Агрегатные функции
select
    sum(price * quantity) sum_income, -- общий доход от всех операций
    avg(price * quantity) avg_income, -- средний доход с одной сделки
    sum(quantity) sum_quantity, -- общее количество проданной продукции
    uniqExact(user_id) users -- уникальных пользователей, совершивших покупку
from transactions;

-- 2. Функции для работы с типами данных
select
    formatDateTime(transaction_date, '%F') transaction_date_str, -- `transaction_date` в формате `YYYY-MM-DD`
    toYYYYMM(transaction_date) transaction_month, -- год и месяц из `transaction_date`
    price,
    round(price) price_int, -- `price`, округленный до ближайшего целого числа
    toString(transaction_id) transaction_id_str-- преобразованный `transaction_id` в строку
from transactions
limit 100;

-- 3. User-Defined Functions (UDFs)
-- 3.1. Создайте простую UDF для расчета общей стоимости транзакции
create function getFullPrice as (price, quantity) -> price * quantity;

-- 3.2. Используйте созданную UDF для расчета общей цены для каждой транзакции
select
    transaction_id,
    getFullPrice(price, quantity) fill_price
from transactions
limit 100;

-- 3.3. Создайте UDF для классификации транзакций на «высокоценные» и «малоценные»
create function getTransactionCategory as (full_price) -> if(full_price < 30000, 'low', 'high');

-- 3.4. Примените UDF для категоризации каждой транзакции
select
    getTransactionCategory(getFullPrice(price, quantity)) transaction_category,
    count() count
from transactions
group by transaction_category;
