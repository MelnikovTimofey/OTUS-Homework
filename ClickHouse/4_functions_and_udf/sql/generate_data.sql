-- Создание таблицы транзакций
create table transactions (
    transaction_id UInt32,
    user_id UInt32,
    product_id UInt32,
    quantity UInt8,
    price Float32,
    transaction_date Date
) engine = MergeTree()
order by (transaction_id);

-- Генерация синтетических данных
insert into transactions
select rand()                           transaction_id,
       rand()                           user_id,
       rand()                           product_id,
       rand() % 255                     quantity,
       randNormal(30000, 10)            price,
       now() - randUniform(1, 1000000.) transaction_date
from numbers(10000000);
