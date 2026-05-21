/*
Для кожного континенту:
підрахуй загальний дохід (revenue);
визнач дохід від покупок, зроблених з мобільних пристроїв, та обчисли його відсоток (revenue_from_mobile_percent).
Відсортуй результати за загальним доходом у спадному порядку.
Представ результати у форматі таблиці зі стовпцями continent, revenue та revenue_from_mobile_percent
*/


SELECT sp.continent AS continent, sum(p.price) AS revenue,
SUM(case when sp.device='mobile' then p.price end)/sum(p.price)*100 AS revenue_from_mobile_percent
FROM data-analytics-mate.DA.order AS o
JOIN data-analytics-mate.DA.product AS p
ON o.item_id=p.item_id
JOIN data-analytics-mate.DA.session_params AS sp
ON o.ga_session_id=sp.ga_session_id
GROUP BY sp.continent
ORDER BY revenue desc;
