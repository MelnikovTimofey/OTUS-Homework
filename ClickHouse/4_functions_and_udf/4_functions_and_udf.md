# Cоздание и наполнение таблицы транзакций
Создание таблицы транзакций
```sql
create table transactions (
    transaction_id UInt32,
    user_id UInt32,
    product_id UInt32,
    quantity UInt8,
    price Float32,
    transaction_date Date
) engine = MergeTree()
order by (transaction_id);
```
Генерация синтетических данных
```sql
insert into transactions
select rand()                           transaction_id,
       rand()                           user_id,
       rand()                           product_id,
       rand() % 255                     quantity,
       randNormal(30000, 10)            price,
       now() - randUniform(1, 1000000.) transaction_date
from numbers(10000000);
```
# Вариант #1
Aгрегатные функции, функции, работающие с типами данных, и функции, определяемые пользователем (UDF) в ClickHouse.
1. Агрегатные функции
    ```sql
    select
        sum(price * quantity) sum_income, -- общий доход от всех операций
        avg(price * quantity) avg_income, -- средний доход с одной сделки
        sum(quantity) sum_quantity, -- общее количество проданной продукции
        uniqExact(user_id) users -- уникальных пользователей, совершивших покупку
    from transactions;
    ```

2. Функции для работы с типами данных
   ```sql
   select
       formatDateTime(transaction_date, '%F') transaction_date_str, -- `transaction_date` в формате `YYYY-MM-DD`
       toYYYYMM(transaction_date) transaction_month, -- год и месяц из `transaction_date`
       price,
       round(price) price_int, -- `price`, округленный до ближайшего целого числа
       toString(transaction_id) transaction_id_str-- преобразованный `transaction_id` в строку
   from transactions
   limit 100;
   ```
3. User-Defined Functions (UDFs)
   1. Создайте простую UDF для расчета общей стоимости транзакции
      ```sql
      create function getFullPrice as (price, quantity) -> price * quantity;
      ```
   2. Используйте созданную UDF для расчета общей цены для каждой транзакции
      ```sql
      select
          transaction_id,
          getFullPrice(price, quantity) full_price
      from transactions
      limit 100;
      ```
   3. Создайте UDF для классификации транзакций на «высокоценные» и «малоценные»
      ```sql
      create function getTransactionCategory as (full_price) -> if(full_price < 30000, 'low', 'high');
      ```
   4. Примените UDF для категоризации каждой транзакции
      ```sql
      select
          getTransactionCategory(getFullPrice(price, quantity)) transaction_category,
          count() count
      from transactions
      group by transaction_category;
      ```
# Вариант #2
Применить исполняемые пользовательские функции (EUDF) в ClickHouse.
1. Настройка конфигурации с директорией с настройками функций
   ```xml
   <clickhouse>
       <user_defined_executable_functions_config>functions/*.xml</user_defined_executable_functions_config>
   </clickhouse>
   ```
2. Определение функции конвертирования RUB в USD
   ```python
   #!/usr/bin/python3
   import sys
   import requests
   
   dollar_value = requests.get('https://www.cbr-xml-daily.ru/daily_json.js').json()['Valute']['USD']['Value']
   
   if __name__ == '__main__':
       for line in sys.stdin:
           convert_to_dollar = float(line) / dollar_value
           print(convert_to_dollar)
           sys.stdout.flush()
   ```
3. Определение настройки EUDF
   ```xml
   <functions>
       <function>
           <type>executable</type>
           <name>toUSD</name>
           <return_type>Float64</return_type>
           <argument>
               <type>Float64</type>
               <name>price_rub</name>
           </argument>
           <format>TabSeparated</format>
           <command>to_usd.py</command>
       </function>
   </functions>
   ```
4. Применение EUDF (конвертация цены из RUB в USD)
   ```sql
   select
       user_id,
       sum(price) price_rub,
       toUSD(price_rub) price_usd
   from transactions
   group by user_id;
   ```
# Файлы
1. [Генерация данных](sql/generate_data.sql)
2. [Вариант #1](sql/option_1.sql)
3. [Вариант #2](sql/option_2.sql)