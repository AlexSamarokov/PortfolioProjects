

-- Вычислил НДС каждого товара в таблице products и рассчитал цену без учёта НДС.
-- Для товаров из списка налог составляет 10%. Для остальных товаров НДС — 20%.


SELECT product_id,
       name,
       price,
       CASE
       WHEN name IN ('сахар', 'сухарики', 'сушки', 'семечки',
                     'масло льняное', 'виноград', 'масло оливковое',
                     'арбуз', 'батон', 'йогурт', 'сливки', 'гречка', 
                     'овсянка', 'макароны', 'баранина', 'апельсины',
                     'бублики', 'хлеб', 'горох', 'сметана', 'рыба копченая', 
                     'мука', 'шпроты', 'сосиски', 'свинина', 'рис', 
                     'масло кунжутное', 'сгущенка', 'ананас', 'говядина', 
                     'соль', 'рыба вяленая', 'масло подсолнечное', 'яблоки', 
                     'груши', 'лепешка', 'молоко', 'курица', 'лаваш', 'вафли',
                     'мандарины') THEN round(price / 110 * 10, 2)
        ELSE round(price / 120 * 20, 2)
        END as tax,
        CASE
        WHEN name IN ('сахар', 'сухарики', 'сушки', 'семечки',
                     'масло льняное', 'виноград', 'масло оливковое',
                     'арбуз', 'батон', 'йогурт', 'сливки', 'гречка', 
                     'овсянка', 'макароны', 'баранина', 'апельсины',
                     'бублики', 'хлеб', 'горох', 'сметана', 'рыба копченая', 
                     'мука', 'шпроты', 'сосиски', 'свинина', 'рис', 
                     'масло кунжутное', 'сгущенка', 'ананас', 'говядина', 
                     'соль', 'рыба вяленая', 'масло подсолнечное', 'яблоки', 
                     'груши', 'лепешка', 'молоко', 'курица', 'лаваш', 'вафли',
                     'мандарины') THEN round(price - price / 110 * 10, 2)
        ELSE round(price - price / 120 * 20, 2)
        END as price_before_tax
FROM   products
ORDER BY price_before_tax desc, product_id;
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Посчитал число пользователей, попавших в каждую возрастную группу.

-- В расчётах не учитывал пользователей, у которых не указана дата рождения.



SELECT 
        CASE 
        --WHEN date_part('year', age(birth_date))::integer >= 36 then '36+'
        --WHEN date_part('year', age(birth_date))::integer >=30 then '30-35'
        --WHEN date_part('year', age(birth_date))::integer >=25 then '25-29'
        --ELSE '18-24'
        WHEN date_part('year', age(birth_date)) BETWEEN 18 AND 24 THEN '18-24'
        WHEN date_part('year', age(birth_date)) BETWEEN 25 AND 29 THEN '25-29'
        WHEN date_part('year', age(birth_date)) BETWEEN 30 AND 35 THEN '30-35'
        WHEN date_part('year', age(birth_date)) >= 36 THEN '36+'        
        END AS group_age,
        COUNT(user_id) AS users_count
FROM    users
WHERE  birth_date IS NOT NULL
GROUP BY group_age
ORDER BY group_age;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- По данным из таблицы orders рассчитал средний размер заказа по выходным и будням.


SELECT 
        CASE
        --WHEN date_part('isodow', creation_time) IN (6, 7) THEN 'weekend'
        --WHEN date_part('isodow', creation_time) BETWEEN 1 AND 5 THEN 'weekdays'
        --WHEN date_part('isodow', creation_time) NOT IN (6, 7) THEN 'weekdays'
        WHEN TO_CHAR(creation_time, 'Dy') IN ('Sat', 'Sun') THEN 'weekend'
        --WHEN TO_CHAR(creation_time, 'Dy') NOT IN ('Sat', 'Sun') THEN 'weekdays'     
        ELSE 'weekdays'   
        END AS week_part,
        ROUND(AVG(array_length(product_ids, 1)), 2) AS avg_order_size
FROM    orders
GROUP BY week_part
ORDER BY avg_order_size;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Для каждого пользователя в таблице user_actions посчитал общее количество
-- оформленных заказов и долю отменённых заказов.
-- В результат включил только тех пользователей, которые оформили больше трёх
-- заказов и у которых показатель cancel_rate составляет не менее 0.5.


SELECT  user_id,
        ROUND(COUNT(DISTINCT order_id) FILTER (WHERE action = 'cancel_order')::decimal  / COUNT(DISTINCT order_id), 2) AS cancel_rate,
        COUNT(DISTINCT order_id) AS orders_count
FROM    user_actions
GROUP BY user_id
HAVING  COUNT(DISTINCT order_id) > 3 AND ROUND(COUNT(DISTINCT order_id) FILTER (WHERE action = 'cancel_order')::decimal / COUNT(DISTINCT order_id), 2) >= 0.5
ORDER BY user_id;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Для каждого дня недели в таблице user_actions посчитал:

-- Общее количество оформленных заказов.
-- Общее количество отменённых заказов.
-- Общее количество неотменённых заказов (т.е. доставленных).
-- Долю неотменённых заказов в общем числе заказов (success rate).

-- Новые колонки назвал соответственно created_orders, canceled_orders, actual_orders и success_rate.

-- Все расчёты проводил за период с 24 августа по 6 сентября 2022 года включительно,
-- чтобы во временной интервал попало равное количество разных дней недели.


SELECT  DATE_PART('isodow', time)::int AS weekday_number,
        TO_CHAR(time, 'Dy') AS weekday,
        COUNT(DISTINCT order_id) FILTER (WHERE action = 'create_order') AS created_orders,
        COUNT(DISTINCT order_id) FILTER (WHERE action = 'cancel_order') AS canceled_orders,
        COUNT(DISTINCT order_id) FILTER (WHERE action = 'create_order') - COUNT(DISTINCT order_id) FILTER (WHERE action = 'cancel_order') AS actual_orders,
        ROUND((COUNT(DISTINCT order_id) FILTER (WHERE action = 'create_order') - COUNT(DISTINCT order_id) FILTER (WHERE action = 'cancel_order'))::DECIMAL 
        / COUNT(DISTINCT order_id) FILTER (WHERE action = 'create_order'), 3) AS success_rate
FROM    user_actions
WHERE  time >= '2022-08-24' AND time < '2022-09-07'
GROUP BY weekday_number, weekday
ORDER BY weekday_number;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- Из таблицы couriers вывел всю информацию о курьерах, которые в сентябре 2022 года
-- доставили 30 и более заказов.

WITH
september_orders AS (SELECT courier_id
                     FROM   courier_actions
                     WHERE  action = 'deliver_order'
                       AND  DATE_PART('year', time) = 2022
                       AND  DATE_PART('month', time) = 9
                       --AND  time >= '2022-09-01'
                       --AND  time < '2022-10-01'
                     GROUP BY courier_id
                     HAVING COUNT(DISTINCT order_id) >= 30)

SELECT courier_id,
       birth_date,
       sex
FROM   couriers
WHERE  courier_id IN (SELECT *
                      FROM   september_orders)
ORDER BY courier_id;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Рассчитал средний размер заказов, отменённых пользователями мужского пола.

WITH
canceled_orders AS (SELECT order_id
                    FROM   user_actions
                    WHERE  action = 'cancel_order'
                      AND  user_id IN (SELECT user_id
                                       FROM   users
                                       WHERE  sex = 'male'))
SELECT ROUND(AVG(array_length(product_ids, 1)), 3) AS avg_order_size
FROM   orders
WHERE  order_id IN (SELECT *
                    FROM   canceled_orders);

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Посчитал возраст каждого пользователя в таблице users.


WITH
last_date AS (SELECT MAX(time) AS last_actual_date
              FROM   user_actions), 
                    
users_age AS (SELECT user_id,
                     DATE_PART('year', AGE((SELECT *
                                                FROM last_date), birth_date)) AS age
                FROM users)
                
SELECT user_id,
       COALESCE(age, (SELECT ROUND(AVG(age))
                      FROM   users_age))::integer AS age
FROM   users_age
ORDER BY user_id;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Для каждого заказа, в котором больше 5 товаров, рассчитал время, затраченное на его доставку. 

WITH
delivered_orders AS (SELECT order_id
                     FROM   orders
                     WHERE  array_length(product_ids, 1) > 5
                       AND  order_id NOT IN (SELECT order_id
                                             FROM   user_actions
                                             WHERE  action = 'cancel_order'))
                
SELECT   order_id,
         MIN(time) AS time_accepted,
         MAX(time) AS time_delivered,
         EXTRACT(epoch FROM (MAX(time) - MIN(time))/60)::integer AS delivery_time
FROM     courier_actions
WHERE    order_id IN (SELECT *
                      FROM   delivered_orders)
GROUP BY order_id
ORDER BY order_id;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Для каждой даты в таблице user_actions посчитал количество первых заказов, совершённых пользователями.


WITH
first_orders_by_users AS (SELECT DATE(MIN(time)) AS date,
                                 user_id
                          FROM   user_actions
                          WHERE  order_id NOT IN (SELECT  order_id
                                                  FROM    user_actions
                                                  WHERE   action = 'cancel_order')
                          GROUP BY user_id)
                
SELECT   date,
         COUNT(user_id) AS first_orders
FROM     first_orders_by_users
GROUP BY date
ORDER BY date;


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Определил 10 самых популярных товаров в таблице orders.

-- Самыми популярными товарами будем считал те, которые встречались в заказах чаще всего.


SELECT product_id,
       times_purchased
FROM   (SELECT unnest(product_ids) as product_id,
               count(*) as times_purchased
        FROM   orders
        WHERE  order_id not in (SELECT order_id
                                FROM   user_actions
                                WHERE  action = 'cancel_order')
        GROUP BY product_id
        ORDER BY times_purchased desc limit 10) t
ORDER BY product_id

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Из таблицы orders вывел id и содержимое заказов, которые включают хотя бы один
-- из пяти самых дорогих товаров, доступных в сервисе.


WITH
top_5_expensive_goods AS (SELECT   product_id
                          FROM     products
                          ORDER BY price DESC
                          LIMIT 5),
                         
ids AS (SELECT order_id,
               unnest(product_ids) AS product_id,
               product_ids
        FROM   orders)

SELECT   DISTINCT order_id, product_ids
FROM     ids
WHERE    product_id IN (SELECT *
                        FROM top_5_expensive_goods)
ORDER BY order_id


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Для каждого пользователя рассчитал следующие показатели:

-- общее число заказов — колонку назовите orders_count
-- среднее количество товаров в заказе — avg_order_size
-- суммарную стоимость всех покупок — sum_order_value
-- среднюю стоимость заказа — avg_order_value
-- минимальную стоимость заказа — min_order_value
-- максимальную стоимость заказа — max_order_value


WITH
canceled_orders AS (SELECT order_id
                    FROM   user_actions
                    WHERE  action = 'cancel_order'),
                    
t1 AS   (SELECT user_id,
                order_id,
                product_ids,
                array_length(product_ids, 1) AS order_size
         FROM   user_actions
                LEFT JOIN orders
                USING (order_id)
         WHERE  order_id NOT IN (SELECT *
                                 FROM   canceled_orders)
         ORDER BY user_id),

t2 AS   (SELECT order_id,
                SUM(price) AS order_value
        FROM    (SELECT order_id,
                        unnest(product_ids) AS product_id,
                        product_ids
                 FROM   orders
                 WHERE  order_id NOT IN (SELECT *
                                         FROM   canceled_orders)
                 ORDER BY order_id) AS T
                 LEFT JOIN products
                 USING (product_id)
         GROUP BY order_id) 
                 
SELECT  user_id,
        COUNT(user_id) AS orders_count,
        ROUND(AVG(order_size), 2) AS avg_order_size,
        SUM(order_value) AS sum_order_value,
        ROUND(AVG(order_value), 2) AS avg_order_value,
        MIN(order_value) AS min_order_value,
        MAX(order_value) AS max_order_value
FROM t1
        LEFT JOIN t2
        USING(order_id)
GROUP BY user_id
ORDER BY user_id
LIMIT 1000;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Посчитал ежедневную выручку сервиса.

WITH t1 as (SELECT  creation_time::DATE AS date,
                    order_id,
                    unnest(product_ids) AS product_id,
                    product_ids
                    FROM    orders
                    WHERE   order_id NOT IN (SELECT order_id
                                             FROM   user_actions
                                             WHERE  action = 'cancel_order')) 
                                     
SELECT  date,
        SUM(price) AS revenue
FROM    t1
        LEFT JOIN products
        USING(product_id)
GROUP BY date
ORDER BY date;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- По таблицам courier_actions , orders и products определил 10 самых популярных товаров, доставленных в сентябре 2022 года.


WITH t1 as (SELECT  DISTINCT order_id,
                    unnest(product_ids) AS product_id,
                    product_ids
                    FROM    orders
                    WHERE   order_id IN (SELECT order_id
                                         FROM   courier_actions
                                         WHERE  action = 'deliver_order'
                                           AND  date_part('year', time) = 2022
                                           AND  date_part('month', time) = 9)) 
                                     
SELECT   name,
         count(*) as times_purchased
FROM     t1
         LEFT JOIN products
         USING(product_id)
GROUP BY name
ORDER BY times_purchased DESC
LIMIT 10;


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Посчитал среднее значение cancel_rate для каждого пола,


WITH
t1 AS  (SELECT  user_id,
                sex,
                COUNT(DISTINCT order_id) FILTER (WHERE action = 'cancel_order')::decimal  / COUNT(DISTINCT order_id) AS cancel_rate,
                COUNT(DISTINCT order_id) AS orders_count
        FROM    user_actions
                LEFT JOIN users
                USING(user_id)
        GROUP BY user_id, sex
        ORDER BY user_id)

SELECT  COALESCE(sex, 'unknown') as sex,
        ROUND(AVG(cancel_rate), 3) as avg_cancel_rate
FROM    t1
GROUP BY sex
ORDER BY sex;


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Выяснил, кто заказывал и доставлял самые большие заказы.

with order_id_large_size as (SELECT order_id
                             FROM   orders
                             WHERE  array_length(product_ids, 1) = (SELECT max(array_length(product_ids, 1))
                                                                    FROM   orders))
SELECT DISTINCT order_id,
                user_id,
                date_part('year', age((SELECT max(time)
                                       FROM   user_actions), users.birth_date))::integer as user_age,
                courier_id, date_part('year', age((SELECT max(time)
                                                   FROM   user_actions), couriers.birth_date))::integer as courier_age
FROM   (SELECT order_id,
               user_id
        FROM   user_actions
        WHERE  order_id in (SELECT *
                            FROM   order_id_large_size)) t1
        LEFT JOIN (SELECT order_id,
                          courier_id
                   FROM   courier_actions
                   WHERE  order_id in (SELECT *
                                       FROM   order_id_large_size)) t2 using(order_id)
        LEFT JOIN users using(user_id)
        LEFT JOIN couriers using(courier_id)
ORDER BY order_id
