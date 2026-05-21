/*
У цьому завданні:
Вирахуй відсоток подій page_title, що містять слово YouTube (зі стовпчика event_params.key) серед всіх, де є записи про події.
Виведи цей відсоток у розрізі континентів.
*/

 SELECT
  sp.continent,
  SUM(CASE WHEN LOWER(ep.value.string_value) LIKE '%youtube%' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS percent_page_title,
  SUM(CASE WHEN LOWER(ep.value.string_value) LIKE '%youtube%' THEN 1 ELSE 0 END) AS youtube_event_cnt,
  COUNT(*) AS event_cnt
FROM DA.event_params AS p,
  UNNEST(p.event_params) AS ep
JOIN DA.session_params AS sp
  ON p.ga_session_id = sp.ga_session_id
WHERE ep.key = 'page_title'
GROUP BY sp.continent
