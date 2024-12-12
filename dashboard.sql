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
    where s.medium != 'organic'
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


-- метрики (общие, на основе aggregate_last_paid_click)
-- без ограничения в 15 строк
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
    where s.medium != 'organic'
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
),

tab3 as (
    select
        to_char(campaign_date, 'YYYY-MM-DD') as campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from vk_ads
    group by
        to_char(campaign_date, 'YYYY-MM-DD'),
        utm_source,
        utm_medium,
        utm_campaign
    union
    select
        to_char(campaign_date, 'YYYY-MM-DD') as campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from ya_ads
    group by
        to_char(campaign_date, 'YYYY-MM-DD'),
        utm_source,
        utm_medium,
        utm_campaign
),

tab4 as (
    select
        t3.total_cost,
        t2.visitors_count,
        t2.leads_count,
        t2.purchases_count,
        t2.revenue
    from tab2 as t2
    left join tab3 as t3
        on
            t2.visit_date = t3.campaign_date
            and t2.utm_source = t3.utm_source
            and t2.utm_medium = t3.utm_medium
            and t2.utm_campaign = t3.utm_campaign
)

select
    round(sum(total_cost) / sum(visitors_count), 2) as cpu,
    round(sum(total_cost) / sum(leads_count), 2) as cpl,
    round(sum(total_cost) / sum(purchases_count), 2) as cppu,
    round((sum(revenue) - sum(total_cost)) / sum(total_cost) * 100, 2) as roi
from tab4;

-- метрики (по каналам, на основе aggregate_last_paid_click)
-- без ограничения в 15 строк
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
    where s.medium != 'organic'
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
),

tab3 as (
    select
        to_char(campaign_date, 'YYYY-MM-DD') as campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from vk_ads
    group by
        to_char(campaign_date, 'YYYY-MM-DD'),
        utm_source,
        utm_medium,
        utm_campaign
    union
    select
        to_char(campaign_date, 'YYYY-MM-DD') as campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from ya_ads
    group by
        to_char(campaign_date, 'YYYY-MM-DD'),
        utm_source,
        utm_medium,
        utm_campaign
),

tab4 as (
    select
        t2.utm_source,
        t3.total_cost,
        t2.visitors_count,
        t2.leads_count,
        t2.purchases_count,
        t2.revenue
    from tab2 as t2
    left join tab3 as t3
        on
            t2.visit_date = t3.campaign_date
            and t2.utm_source = t3.utm_source
            and t2.utm_medium = t3.utm_medium
            and t2.utm_campaign = t3.utm_campaign
)

select
    utm_source,
    round(sum(total_cost) / sum(visitors_count), 2) as cpu,
    round(sum(total_cost) / sum(leads_count), 2) as cpl,
    round(sum(total_cost) / sum(purchases_count), 2) as cppu,
    round((sum(revenue) - sum(total_cost)) / sum(total_cost), 2) as roi
from tab4
group by utm_source;

-- сколько дней необходимо для закрытия 90% лидов
with tab as (
    select
        visitor_id,
        max(visit_date) as visit_date
    from sessions
    where medium != 'organic'
    group by visitor_id
)

select
    percentile_cont(0.9) within group (
        order by
            date_part('day', l.created_at::timestamp - t.visit_date::timestamp)
    )
    as days_to_90_close
from tab as t
left join leads as l on t.visitor_id = l.visitor_id;
