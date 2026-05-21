/*
Порахувати середню ціну товарів у кожній категорії.
Зробити сортування категорій за середньою ціною у порядку спадання (від найдорожчої до найдешевшої).
Набір даних повинен мати такий вигляд:
| category       | average_price |
!!!можна використати лише табл prodact
*/

SELECT p.category AS category, AVG(p.price) AS  average_price
FROM `data-analytics-mate.DA.order` AS o
JOIN data-analytics-mate.DA.session AS s
ON o.ga_session_id=s.ga_session_id
JOIN data-analytics-mate.DA.product AS p
ON o.item_id=p.item_id
GROUP BY p.category
ORDER BY AVG(p.price) DESC
