-- создание БД для сущностей рестрона "Твои мечты"
create database your_dreams comment 'БД ресторана "Твои мечты"';

-- переход в БД "Твои мечты"
use your_dreams;

-- создаем таблицу со списком блюд
create or replace table dich
(
    code UInt32 comment 'Уникальный код блюда (первичный ключь)',
    name String comment 'Название блюда отображаемое в меню',
    price UInt32 comment 'Цена блюда (в рублях)',
    weight UInt16 comment 'Вес блюда в граммах',
    calorie_content UInt16 comment 'Пищевая энергетическая ценность (ккал/100 г)',
    description Nullable(String) comment 'Описание блюда (формируется в меню мелким шрифтом после названия)',
    category Enum8('breakfast' = 1, 'lenten menu' = 2, 'snack' = 3, 'salad' = 4, 'paste' = 5, 'soup' = 6, 'main course' =  7, 'garnish' = 8, 'dessert' = 9) comment 'Тип блюда'
)
engine=ReplacingMergeTree()
order by (code);

-- CRUD
-- Create (insert)
insert into dich
(code,
 name,
 price,
 weight,
 calorie_content,
 description,
 category)
values (0, 'Овсяноблин', 500, 250, 140,
        'Овсяноблин - не только очень полезный и питательный вид завтрака, но и очень вкусный', 'breakfast'),
       (1, 'Лобио из красной фасоли', 300, 200, 69,
        'Этот рецепт не оставит равнодушными любителей фасоли', 'lenten menu'),
       (2, 'Креветки Ян Примус', 650, 100, 100, 'Креветки прекрасно сочетаются с пивом – просто попробуйте!', 'snack'),
       (3, 'Мангольд по-корейски', 480, 350, 80, 'Делается она не сложно, получается необычно и очень вкусно', 'salad'),
       (4, 'Фунчоза с овощами', 670, 200, 350,
        'Макароны вполне могут быть диетическими, если знать, как их правильно готовить', 'paste'),
       (5, 'Борщ', 500, 250, 49, 'Бабушкины традиции', 'soup'),
       (6, 'Вареники с капустой', 700, 350, 79,
        'Вареники с капустой богат такими витаминами и минералами, как: витамином C - 20 %, кобальтом - 31 %, молибденом - 11 %',
        'main course'),
       (7, 'Гречка', 200, 100, 100, 'Eдинственный представитель круп в низкокалорийной десятке', 'garnish'),
       (8, 'Мильфей', 560, 200, 460,
        'Десерт французской кухни на основе слоёного теста с кремом в виде пирожного или торта', 'dessert');

-- Read (select)
select
    *
from dich
where calorie_content < 100;

-- Update (alter table)
alter table dich update price = 500 where code = 3;

select
    code,
    name,
    price
from dich
where code=3;

-- Delete (alter table)
alter table dich delete where code=4;

select
    *
from dich
where code=4;

-- Delete (lightweight delete)
delete from dich where code=5;

select
    *
from dich
where code=5;

-- Добавить несколько новых полей, удалить пару старых
-- Добавление полей
alter table dich add column ingredient_codes Array(UInt32) comment 'Коды ингридиентов блюда';
alter table dich add column spicy Bool Default 0 comment 'Флаг осторторы блюда';
-- Удаление полей
alter table dich drop column description;
alter table dich drop column calorie_content;

select
    *
from dich;

-- Заселектить таблицу (любую) из sample dataset
select *
from file('sample_data/Menu.csv', 'CSVWithNames', 'id UInt32, name String,sponsor String,event String,venue String,place String,physical_description String,occasion String, notes String, call_number String, keywords String, language String,date String, location String, location_type String, currency String, currency_symbol String, status String, page_count UInt16, dish_count UInt16');

-- Материализовать таблицу из п.5
CREATE OR REPLACE TABLE menu
(
    id UInt32,
    name String,
    sponsor String,
    event String,
    venue String,
    place String,
    physical_description String,
    occasion String,
    notes String,
    call_number String,
    keywords String,
    language String,
    date DateTime64,
    location String,
    location_type String,
    currency String,
    currency_symbol String,
    status String,
    page_count UInt16,
    dish_count UInt16
) ENGINE = MergeTree
ORDER BY id
PARTITION BY toYYYYMM(date);

insert into menu
select
    *
from file('sample_data/Menu.csv', 'CSVWithNames', 'id UInt32, name String,sponsor String,event String,venue String,place String,physical_description String,occasion String, notes String, call_number String, keywords String, language String,date String, location String, location_type String, currency String, currency_symbol String, status String, page_count UInt16, dish_count UInt16')
settings max_partitions_per_insert_block=100000;

-- Поработать с партами
-- Сделать detach
alter table menu detach partition '190001';

select
    *
from menu
where date >= '1900-01-01' and date < '1900-02-01';

-- Сделать attach
alter table menu attach partition '190001';

select
    *
from menu
where date >= '1900-01-01' and date < '1900-02-01';

-- Сделать drop
alter table menu drop partition '190002';

select
    *
from menu
where date >= '1900-02-01' and date < '1900-03-01';

