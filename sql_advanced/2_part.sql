*1.Выведите общую сумму просмотров у постов, опубликованных в каждый месяц 2008 года. 
Если данных за какой-либо месяц в базе нет, такой месяц можно пропустить. Результат отсортируйте по убыванию общего количества просмотров.
SELECT DATE_TRUNC('MONTH', creation_date::DATE)::DATE,
       SUM(views_count)
FROM stackoverflow.posts
WHERE EXTRACT(YEAR FROM creation_date::date) = 2008
GROUP BY DATE_TRUNC('MONTH', creation_date::date)
ORDER BY SUM(views_count) DESC


*2.Выведите имена самых активных пользователей, которые в первый месяц после регистрации (включая день регистрации) дали больше 100 ответов. Вопросы, которые задавали пользователи, не учитывайте. 
Для каждого имени пользователя выведите количество уникальных значений user_id. Отсортируйте результат по полю с именами в лексикографическом порядке.
SELECT display_name,
       COUNT(DISTINCT p.user_id)
FROM stackoverflow.users AS u
JOIN stackoverflow.posts AS p ON p.user_id = u.id
JOIN stackoverflow.post_types AS pt ON pt.id = p.post_type_id 
WHERE pt.type = 'Answer'
        AND
        DATE_TRUNC('day', p.creation_date) >= DATE_TRUNC('day', u.creation_date)
          AND DATE_TRUNC('day', p.creation_date) <= DATE_TRUNC('day', u.creation_date) + INTERVAL '1 month'
GROUP BY display_name
HAVING COUNT(p.id) > 100
ORDER BY display_name


*3.Выведите количество постов за 2008 год по месяцам. 
  Отберите посты от пользователей, которые зарегистрировались в сентябре 2008 года и сделали хотя бы один пост в декабре того же года. Отсортируйте таблицу по значению месяца по убыванию.
WITH req AS
(SELECT DISTINCT u.id
FROM stackoverflow.users u 
JOIN stackoverflow.posts p ON u.id = p.user_id
WHERE  DATE_TRUNC('MONTH', u.creation_date)::DATE BETWEEN '2008-09-01' AND '2008-09-30'
AND DATE_TRUNC('MONTH', p.creation_date) BETWEEN '2008-12-01' AND '2008-12-31')

SELECT DATE_TRUNC('MONTH', p.creation_date)::date, COUNT(p.id)
FROM stackoverflow.posts p
JOIN req ON req.id = p.user_id 
GROUP BY DATE_TRUNC('MONTH', p.creation_date)::date
ORDER BY DATE_TRUNC('MONTH', p.creation_date)::date DESC


*4.Используя данные о постах, выведите несколько полей:
- идентификатор пользователя, который написал пост;
- дата создания поста;
- количество просмотров у текущего поста;
- сумма просмотров постов автора с накоплением.
Данные в таблице должны быть отсортированы по возрастанию идентификаторов пользователей, а данные об одном и том же пользователе — по возрастанию даты создания поста.
SELECT p.user_id,
       creation_date,
       views_count,
       SUM(views_count) OVER(PARTITION BY user_id ORDER BY views_count, creation_date)
FROM stackoverflow.posts p 


*5.Сколько в среднем дней в период с 1 по 7 декабря 2008 года включительно пользователи взаимодействовали с платформой? 
Для каждого пользователя отберите дни, в которые он или она опубликовали хотя бы один пост. Нужно получить одно целое число — не забудьте округлить результат.
WITH ad AS
(SELECT p.user_id,
       COUNT(DISTINCT(CAST(DATE_TRUNC('day', p.creation_date) AS date))) AS active_days
FROM stackoverflow.posts AS p
WHERE p.creation_date::date BETWEEN '01-12-2008'::date AND '07-12-2008'::date 
GROUP BY p.user_id)

SELECT ROUND(AVG(active_days))
FROM ad


*6.На сколько процентов менялось количество постов ежемесячно с 1 сентября по 31 декабря 2008 года? Отобразите таблицу со следующими полями:
Номер месяца.
Количество постов за месяц.
Процент, который показывает, насколько изменилось количество постов в текущем месяце по сравнению с предыдущим.
Если постов стало меньше, значение процента должно быть отрицательным, если больше — положительным. Округлите значение процента до двух знаков после запятой.

  WITH 
REQ AS (SELECT EXTRACT('MONTH' FROM creation_date::date) as month,
       COUNT(id) AS posts
FROM stackoverflow.posts
where creation_date::date BETWEEN '2008-09-01' AND '2008-12-31'
group by EXTRACT('MONTH' FROM creation_date::date))

SELECT *,
       ROUND(((posts::numeric/LAG(posts, 1, NULL) OVER(ORDER BY month))-1)*100, 2)
from req


*7. Найдите пользователя, который опубликовал больше всего постов за всё время с момента регистрации. Выведите данные его активности за октябрь 2008 года в таком виде:
номер недели;
дата и время последнего поста, опубликованного на этой неделе.
WITH
REQ AS 
(SELECT user_id, COUNT(id)
FROM stackoverflow.posts
GROUP BY user_id
ORDER BY COUNT(id) DESC
LIMIT 1),

REQ2 AS
(SELECT EXTRACT(WEEK FROM creation_date::DATE) AS week,
        MAX(creation_date) OVER(PARTITION BY EXTRACT(WEEK FROM creation_date::DATE)) as date
FROM stackoverflow.posts AS p
JOIN REQ ON REQ.user_id = p.user_id
WHERE creation_date::DATE BETWEEN '2008-10-01' AND '2008-10-31')


SELECT * 
FROM REQ2 
GROUP BY week, date

