# PA03-online-store

## Таблиці
Було створено 5 таблиць як систему для замовлень в інтернет магазині. Дані були згенеровані для таблиць customers, order_items,
order_log, orders та products. Поля customer_id, product_id, order_id, order_item_id та log_id мають тип
serial і є primary key. Присутні foreign key зв'язки: order_items посилається на orders та 
products, а orders посилається на customers.

## Task 1 - calculate_order_total
Ця функція розраховує загальну суму замовлення, використовуючи дані з таблиці order_items. Сума обчислюється формулою
quantity * price. Для обробки відсутності позицій для замовлення застосовано coalesce, щоб при значенні null повертати 0.

## Task 2 - create_order
Ця процедура створює нове замовлення для клієнтів. Перед створенням, перевіряє, чи є клієнт в таблиці customers.
Якщо його не існує, висвічується помилка(exception). Вставляє новий рядок у таблицю orders, де total_amount зі значенням 0 
та order_date встановлений на поточний момент часу.

## Task 3 - add_product_to_order
Ця процедура додає товар до замовлення. Виконуються такі перевірки : кількість має бути більшою за 0,
замовлення має існувати в таблиці orders, товар має існувати в таблиці products, залишок товару має бути
достатнім. 

## Task 4 - trg_update_order_total
Тригерна функція update_order_tota() та сам тригер trg_update_order_total спрацьовують після insert, delete або 
update в таблиці order_items. Функція визначає order_id зміненого рядка з new або old і викликає calculate_order_total
щоб оновити total_amount у таблиці orders для потрібного замовлення.

## Task 5 - trg_order_audit_log
Тригерна ф-ція order_audit_log та сам тригер trg_order_audit_log спрацьовують після insert на таблиці orders.
Створення замовлення записується у таблицю аудиту order_log. 

## Тестування 
Для перевірки було створено нового покупця, новий товар, замовлення через процедуру, додавання товару до замовлення
через процедуру. Також, перевірка на спрацювання тригерів ( оновлення суми замовлення, зменшення залишку товару та 
перевірка наявності записів у лог).

## Query Analysis
Аналіз виконання запиту explain analyze для пошуку товарів у замовленні №1 : 
``` sql
Hash Join  (cost=27.09..41.32 rows=7 width=274) (actual time=0.074..0.081 rows=2 loops=1)
  Hash Cond: (p.product_id = oi.product_id)
  ->  Seq Scan on products p  (cost=0.00..13.00 rows=300 width=222) (actual time=0.018..0.020 rows=5 loops=1)
  ->  Hash  (cost=27.00..27.00 rows=7 width=28) (actual time=0.040..0.041 rows=2 loops=1)
        Buckets: 1024  Batches: 1  Memory Usage: 9kB
        ->  Seq Scan on order_items oi  (cost=0.00..27.00 rows=7 width=28) (actual time=0.024..0.027 rows=2 loops=1)
              Filter: (order_id = 1)
              Rows Removed by Filter: 3
Planning Time: 0.274 ms
Execution Time: 0.120 ms
```
## Explanation
Спочатку сканується таблиця order_items через seq scan (послідовно), із фільтром order_id = 1.
З 5 рядків знайдено 2, інші 3 відкинуто. Після цього будується тимчасова хеш-таблиця на 9kB,
і таблиця products теж сканується повністю через seq scan. Фінальне зʼєднання двох таблиць oi.product_id = p.product_id
виконується через hash join, тому що даних занадто мало для того ж index scan.
