/*
Запит повинен виводити такі стовпчики:
date — дата;
country — країна;
send_interval — інтервал відправлення;
is_verified — перевірено акаунт чи ні;
is_unsubscribed — підписник відписався;
account_cnt — кількість створених акаунтів;
sent_msg — кількість відправлених листів;
open_msg — кількість відкритих листів;
visit_msg — кількість переходів по листах;
total_country_account_cnt — загальна кількість створених підписників по країні;
total_country_sent_cnt — загальна кількість відправлених листів по країні;
rank_total_country_account_cnt — рейтинг країн за кількістю створених підписників;
rank_total_country_sent_cnt — рейтинг країн за кількістю відправлених листів.
*/
 with account_c as(
  SELECT date,
         spar.country,
         COUNT(distinct id) as account_count,
         NULL AS sent_msg,
         NULL AS open_msg,
         NULL AS visit_msg,
         ac.send_interval,
         ac.is_verified,
         ac.is_unsubscribed
  FROM DA.account as ac
  JOIN DA.account_session as acs
  ON ac.id=acs.account_id
  JOIN DA.session_params as spar
  ON acs.ga_session_id=spar.ga_session_id
  JOIN data-analytics-mate.DA.session as ses
  ON spar.ga_session_id=ses.ga_session_id
 GROUP BY date,
          spar.country,
          ac.send_interval,
          ac.is_verified,
          ac.is_unsubscribed
),
/*CTE: massage
   Агрегація country
   Рахуємо кількість відправлених, відкритих та відвіданих email-повідомлень по країнах */
massage as(
  SELECT DATE_ADD(se.date, INTERVAL es.sent_date DAY) as sent_date,
         sp.country,
         NULL AS account_count,
         COUNT(DISTINCT es.id_message) AS sent_msg,
         COUNT(DISTINCT eo.id_message) AS open_msg,
         COUNT(DISTINCT ev.id_message) AS visit_msg,
         aco.send_interval,
         aco.is_verified,
         aco.is_unsubscribed
  FROM data-analytics-mate.DA.email_sent es
  JOIN DA.account_session s
  ON es.id_account = s.account_id
  JOIN data-analytics-mate.DA.account aco
  ON s.account_id=aco.id
  JOIN data-analytics-mate.DA.session se
  ON s.ga_session_id = se.ga_session_id
  JOIN DA.session_params sp
  ON se.ga_session_id = sp.ga_session_id
  LEFT JOIN data-analytics-mate.DA.email_open eo
  ON es.id_message = eo.id_message
  LEFT JOIN data-analytics-mate.DA.email_visit ev  
  ON es.id_message = ev.id_message
  GROUP BY sent_date,
           sp.country,
           aco.send_interval,
           aco.is_verified,
           aco.is_unsubscribed
),
/* СTE: final_union
   Об'єднуємо основні метрики по акаунтам і по емейлам в одну таблицю*/
final_union as (
  SELECT
  date,
  country,
  account_count,
  sent_msg,
  open_msg,
  visit_msg,
  send_interval,
  is_verified,
  is_unsubscribed
FROM account_c


UNION ALL


SELECT
  sent_date AS date,
  country,
  account_count,
  sent_msg,
  open_msg,
  visit_msg,
  send_interval,
  is_verified,
  is_unsubscribed
FROM massage
),
-- в fact_un агрегуємо дані, щоб позбутися дубюючих рядків
fact_un AS (
  SELECT
    date,
    country,
    send_interval,
    is_verified,
    is_unsubscribed,
    SUM(account_count) as account_count,
    SUM(sent_msg) as sent_msg,
    SUM(open_msg) as open_msg,
    SUM(visit_msg) as visit_msg
  FROM final_union
  GROUP BY
    date,
    country,
    send_interval,
    is_verified,
    is_unsubscribed
),
/* CTE: total
   Агрегація country
   Загальна кількість акаунтів та відправлених листів по країнах + метрики по акаунтам і по емейлам */
total as(
  SELECT *,
    SUM(account_count) OVER (PARTITION BY country) as total_country_account_cnt,
    SUM(sent_msg) OVER (PARTITION BY country) as total_country_sent_cnt
  FROM fact_un
),
t_rank as (
  SELECT *,--все з total +
         -- Ранг країни за кількістю акаунтів
     DENSE_RANK() OVER (ORDER BY total_country_account_cnt DESC) as rank_total_country_account_cnt,
    -- Ранг країни за кількістю відправлених листів
    DENSE_RANK() OVER (ORDER BY total_country_sent_cnt DESC) as rank_total_country_sent_cnt
  FROM total
)
/*Фінальний SELECT
Базова таблиця t_rank */
SELECT --метрики по акаунтам і по емейлам
    date,
    country,
    account_count,
    send_interval,
    is_verified,
    is_unsubscribed,
    sent_msg,
    open_msg,
    visit_msg,
    -- Загальна кількість акаунтів по країні
    total_country_account_cnt,
    -- Ранг країни за кількістю акаунтів
    rank_total_country_account_cnt,
    -- Загальна кількість відправлених листів по країні
    total_country_sent_cnt,
    -- Ранг країни за кількістю відправлених листів
    rank_total_country_sent_cnt
FROM t_rank
WHERE rank_total_country_account_cnt <= 10 or rank_total_country_sent_cnt
<= 10
