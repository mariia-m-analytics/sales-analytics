/*
У цьому завданні тобі потрібно отримати результуючий набір із такими стовпчиками:
| Continent | Revenue | Revenue from Mobile | Revenue from Desktop | % Revenue from Total | Account Count | Verified Account | Session Count |
*/

with revenues as(
SELECT sp.continent,SUM(p.price) as revenue,
       SUM(case when device='mobile' then p.price end) as revenue_from_mobile,
       SUM(case when device='desktop' then p.price end) as revenue_from_desktop
FROM DA.session_params as sp
JOIN DA.order as o
ON sp.ga_session_id=o.ga_session_id
JOIN DA.product as p
ON o.item_id=p.item_id
GROUP BY sp.continent
),
total_revenue as(
  SELECT continent,revenue as total_revenue_calc,
         revenue/SUM(revenue) over() as revenue_from_total
  FROM revenues
),
account as(
  SELECT continent,
         COUNT(distinct id) as account_count,
         COUNT(case when is_verified=1 then id end) as verified_account,
         COUNT(distinct acs.ga_session_id) as session_count
  FROM DA.account as ac
  JOIN DA.account_session as acs
  ON ac.id=acs.account_id
  JOIN DA.session_params as spar
  ON acs.ga_session_id=spar.ga_session_id
  GROUP BY continent
)


SELECT account.continent, revenues.revenue,
       revenues.revenue_from_mobile,
       revenues.revenue_from_desktop,
       total_revenue.revenue_from_total,
       account.account_count,
       account.verified_account,
       account.session_count
FROM account
LEFT JOIN revenues
ON account.continent=revenues.continent
LEFT JOIN total_revenue
ON revenues.continent=total_revenue.continent
ORDER BY account.continent, revenues.revenue desc
