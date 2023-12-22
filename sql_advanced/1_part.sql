*Найдите количество вопросов, которые набрали больше 300 очков или как минимум 100 раз были добавлены в «Закладки».
SELECT COUNT(p.id)
FROM stackoverflow.posts AS p
JOIN stackoverflow.post_types AS p_type ON p_type.id = p.post_type_id
WHERE type = 'Question' 
  AND (score > 300 OR favorites_count >= 100)

*Сколько в среднем в день задавали вопросов с 1 по 18 ноября 2008 включительно? Результат округлите до целого числа.
WITH avg AS  
(SELECT COUNT(p.ID) as count
FROM  stackoverflow.posts AS p
INNER JOIN stackoverflow.post_types AS p_type ON p.post_type_id  = p_type.id
WHERE creation_date::DATE BETWEEN '2008-11-01' AND '2008-11-18'
      AND type = 'Question'
GROUP BY creation_date::DATE)

SELECT ROUND(AVG(count))
FROM avg

*Сколько пользователей получили значки сразу в день регистрации? Выведите количество уникальных пользователей.
SELECT COUNT(DISTINCT u.id)
FROM stackoverflow.badges AS b
JOIN stackoverflow.users AS u ON u.id  = b.user_id
WHERE u.creation_date::date = b.creation_date::date

*Сколько уникальных постов пользователя с именем Joel Coehoorn получили хотя бы один голос?
SELECT COUNT(DISTINCT p.id)
FROM stackoverflow.posts AS p
JOIN stackoverflow.users AS u ON u.id  = p.user_id
JOIN  stackoverflow.votes AS v ON p.id = v.post_id 
WHERE u.display_name = 'Joel Coehoorn'

*Отберите 10 пользователей, которые поставили больше всего голосов типа Close. Отобразите таблицу из двух полей: идентификатором пользователя и количеством голосов. 
Отсортируйте данные сначала по убыванию количества голосов, потом по убыванию значения идентификатора пользователя.
SELECT user_id, COUNT(v.id)
FROM stackoverflow.votes AS v
JOIN stackoverflow.vote_types AS v_type ON v_type.id  = v.vote_type_id
WHERE name = 'Close'
GROUP BY user_id
ORDER BY COUNT(v.id) DESC, user_id DESC
LIMIT 10

*Отберите 10 пользователей по количеству значков, полученных в период с 15 ноября по 15 декабря 2008 года включительно.
WITH REQ AS 
(SELECT user_id,
       COUNT(id) AS count
FROM stackoverflow.badges
WHERE creation_date::DATE BETWEEN '2008-11-15' AND'2008-12-15'
GROUP BY user_id
ORDER BY count DESC
LIMIT 10)

SELECT *, 
       DENSE_RANK() OVER(ORDER BY count DESC)
FROM REQ

*Сколько в среднем очков получает пост каждого пользователя? Не учитывайте посты без заголовка, а также те, что набрали ноль очков.
SELECT title, user_id, score,
       ROUND(AVG(score) OVER(PARTITION BY user_id))
FROM stackoverflow.posts
WHERE title IS NOT NULL AND score != 0

*Отобразите заголовки постов, которые были написаны пользователями, получившими более 1000 значков. Посты без заголовков не должны попасть в список.
WITH bages as
(SELECT DISTINCT user_id,
        COUNT (id) OVER(PARTITION BY user_id) as count
FROM stackoverflow.badges)

SELECT title 
FROM stackoverflow.posts AS p
JOIN bages AS b ON p.user_id = b.user_id
WHERE count > 1000 AND title IS NOT NULL

*Напишите запрос, который выгрузит данные о пользователях из Канады (англ. Canada). Разделите пользователей на три группы в зависимости от количества просмотров их профилей:
- пользователям с числом просмотров больше либо равным 350 присвойте группу 1;
- пользователям с числом просмотров меньше 350, но больше либо равно 100 — группу 2;
- пользователям с числом просмотров меньше 100 — группу 3.
Отобразите в итоговой таблице идентификатор пользователя, количество просмотров профиля и группу. Пользователи с количеством просмотров меньше либо равным нулю не должны войти в итоговую таблицу.
SELECT id, 
       views,
       CASE
           WHEN views >= 350 THEN 1
           WHEN views BETWEEN 100 AND 349 THEN 2
           WHEN views < 100 THEN  3
       END
FROM stackoverflow.users
WHERE location LIKE '%Canada%' AND  views != 0

*Дополните предыдущий запрос. Отобразите лидеров каждой группы — пользователей, которые набрали максимальное число просмотров в своей группе. 
Выведите поля с идентификатором пользователя, группой и количеством просмотров. Отсортируйте таблицу по убыванию просмотров, а затем по возрастанию значения идентификатора.
WITH REQ AS
(SELECT id, 
       views,
       CASE
           WHEN views >= 350 THEN 1
           WHEN views BETWEEN 100 AND 349 THEN 2
           WHEN views < 100 THEN  3
       END AS G
FROM stackoverflow.users
WHERE location LIKE '%Canada%' AND  views != 0),

REQ2 AS (SELECT id, G, views,
       MAX(views) OVER(PARTITION BY G) AS max
FROM REQ)

SELECT id, G, views
FROM REQ2
WHERE max = views
ORDER BY views DESC, id 

*Для каждого пользователя, который написал хотя бы один пост, найдите интервал между регистрацией и временем создания первого поста. Отобразите: 
- идентификатор пользователя;
- разницу во времени между регистрацией и первым постом.
SELECT DISTINCT user_id, 
       MIN(p.creation_date) OVER(PARTITION BY user_id) - u.creation_date 
FROM stackoverflow.posts AS p
JOIN stackoverflow.users AS u ON u.id = p.user_id
