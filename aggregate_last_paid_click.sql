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
)

select
    t2.visit_date,
    t2.utm_source,
    t2.utm_medium,
    t2.utm_campaign,
    t2.visitors_count,
    t3.total_cost,
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
order by
    t2.revenue desc nulls last,
    t2.visit_date asc,
    t2.visitors_count desc,
    t2.utm_source asc,
    t2.utm_medium asc,
    t2.utm_campaign asc
limit 15;
