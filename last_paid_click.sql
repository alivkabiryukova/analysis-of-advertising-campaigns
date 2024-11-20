with tab as (
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
)

select
    t.visitor_id,
    t.visit_date,
    s.source as utm_source,
    s.medium as utm_medium,
    s.campaign as utm_campaign,
    l.lead_id,
    l.created_at,
    l.amount,
    l.closing_reason,
    l.status_id
from tab as t
left join sessions as s
    on
        t.visitor_id = s.visitor_id
        and t.visit_date = s.visit_date
left join leads as l on t.visitor_id = l.visitor_id
order by 8 desc nulls last, 2, 3, 4, 5
limit 10;
