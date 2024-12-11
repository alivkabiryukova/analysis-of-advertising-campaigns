--ТРАФИК
-- количество уникальных посетителей
select count(distinct visitor_id)
from sessions;

-- количество уникальных лидов
select count(distinct lead_id)
from leads;

-- количество лидов, совершивших оплату
select count(distinct lead_id) filter (where status_id = 142)
from leads;

-- для воронки трафика
select
    'count_visitor' as field,
    count(distinct visitor_id) as traffic_funnel
from sessions
union
select
    'count_lead' as field,
    count(distinct lead_id) as traffic_funnel
from leads
union
select
    'count_payment' as field,
    count(distinct lead_id) filter (where status_id = 142) as traffic_funnel
from leads
order by traffic_funnel desc;

-- конверсия из клика в лид (общая)
-- конверсия из лида в оплату (общая)
with tab1 as (
    select
        s.source as utm_source,
        s.medium as utm_medium,
        s.campaign as utm_campaign,
        l.status_id,
        l.amount,
        to_char(s.visit_date, 'YYYY-MM-DD') as visit_date,
        row_number()
            over (
                partition by s.visitor_id
                order by s.visit_date desc
            )
        as row_date
    from sessions as s
    left join leads as l
        on
            s.visitor_id = l.visitor_id
            and s.visit_date <= l.created_at
    where s.medium in (
        'cpc', 'cpm',
        'cpa', 'youtube', 'cpp', 'tg', 'social'
    )
),

tab2 as (
    select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        count(*) as visitors_count,
        count(status_id) filter (
            where status_id is not null
        )
        as leads_count,
        count(status_id) filter (
            where status_id = 142
        )
        as purchases_count,
        sum(amount) as revenue
    from tab1
    where row_date = 1
    group by
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign
)

select
    round(sum(leads_count) / sum(visitors_count) * 100, 2) as visitor_lead,
    round(sum(purchases_count) / sum(leads_count) * 100, 2) as lead_payment
from tab2;

-- количество уникальных посетителей по источникам (топ 5)
select
    source,
    count(distinct visitor_id) as count_visitor
from sessions
group by 1
order by 2 desc
limit 5;

--ФИНАНСОВЫЕ МЕТРИКИ
-- потрачено на рекламные кампании
with tab as (
    select sum(daily_spent) as total_cost
    from vk_ads
    union
    select sum(daily_spent) as total_cost
    from ya_ads
)

select sum(total_cost) as total_cost
from tab;

-- доход от рекламных кампаний
select sum(amount) as sum_amount
from leads;

-- доход от 1 лида
select sum(amount) / count(lead_id) as income_one_lead
from leads;

-- результат кампаний
with tab1 as (
    select sum(daily_spent) as total_cost
    from vk_ads
    union
    select sum(daily_spent) as total_cost
    from ya_ads
),

tab2 as (
    select sum(total_cost) as total_cost
    from tab1
)

select sum(amount) - (select t.total_cost from tab2 as t) as result
from leads;

-- метрики (общие, на основе aggregate_last_paid_click, без ограничения в 15 строк)
select
    round(sum(total_cost) / sum(visitors_count), 2) as cpu,
    round(sum(total_cost) / sum(leads_count), 2) as cpl,
    round(sum(total_cost) / sum(purchases_count), 2) as cppu,
    round((sum(revenue) - sum(total_cost)) / sum(total_cost), 2) as roi
from cost_calculation;

-- метрики (по каналам, на основе aggregate_last_paid_click, без ограничения в 15 строк)
select
    utm_source,
    round(sum(total_cost) / sum(visitors_count), 2) as cpu,
    round(sum(total_cost) / sum(leads_count), 2) as cpl,
    round(sum(total_cost) / sum(purchases_count), 2) as cppu,
    round((sum(revenue) - sum(total_cost)) / sum(total_cost), 2) as roi
from cost_calculation
group by utm_source;

-- сколько дней необходимо для закрытия 90% лидов
with tab1 as (
    select
        visitor_id,
        max(visit_date) as visit_date
    from sessions
    where
        medium in (
            'cpc', 'cpm',
            'cpa', 'youtube', 'cpp', 'tg', 'social'
        )
    group by 1
),

tab2 as (
    select
        date_part(
            'day', l.created_at::timestamp - t.visit_date::timestamp
        ) as days_to_close
    from tab1 as t
    left join leads as l on t.visitor_id = l.visitor_id
)

select
    percentile_cont(0.9) within group (
        order by days_to_close
    ) as days_to_90_close
from tab2;
