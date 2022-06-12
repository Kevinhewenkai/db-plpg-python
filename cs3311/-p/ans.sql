-- COMP3311 21T1 Exam SQL Answer Template
--
-- * Don't change view names and view arguments;
-- * Only change the SQL code for view as commented below;
-- * and do not remove the ending semicolon of course.
--
-- * You may create additional views, if you wish;
-- * but you are not allowed to create tables.
--


-- Q1. Find the brewers whose beers John likes.

create or replace view Q1(brewer) as
-- replace the SQL code below:
select b.name
from Brewers b
    join Beers be on (be.brewer = b.id)
    join Likes l on (l.beer = be.id)
    join Drinkers d on (l.drinker = d.id)
where  d.name = 'John' and l.drinker = d.id
order by b.name asc
;


-- Q2. How many beers does each brewer make?

create or replace view Q2(brewer, nbeers) as
-- replace the SQL code below:
select br.name, count(b.id) as nbeers
from Beers b
    join Brewers br on (br.id = b.brewer)
group by br.name
order by br.name
;


-- Q3. Beers sold at bars where John drinks.

create or replace view Q3(beer) as
-- replace the SQL code below:
select distinct b.name
from Beers b 
    join Sells s on (s.beer = b.id)
    join Frequents f on (f.bar = s.bar)
    join Drinkers d on (f.drinker = d.id)
where d.name = 'John'
order by b.name asc
;


-- Q4. What is the most expensive beer?
create or replace view expensive(beer, cost) as
select s.beer, s.price
from Sells s
;

create or replace view Q4(beer) as
-- replace the SQL code below:
select b.name
from Beers b
    join Sells s on (s.beer = b.id)
where s.price = (select max(e.cost) from expensive e)
order by b.name
;


-- Q5. Find the average price of common beers
--      ("common" = served in more than two hotels).
create or replace view common(beer, price) as
select s.beer, avg(s.price)
from Sells s 
where exists (
    select s1.beer
    from Sells s1
    where s.beer = s1.beer and s.bar != s1.bar
)
group by s.beer
;

create or replace view Q5(beer, "AvgPrice") as
-- replace the SQL code below:
select b.name, c.price::numeric(3,2)
from common c
    join Beers b on (b.id = c.beer)
order by b.name asc
;

create or replace view Bar_min_price as
select b.id, b.name as bar, min(s.price)::numeric(5,2) as min_price
from   Bars b
         join Sells s on (b.id=s.bar)
group  by b.id, b.name
;

-- Q6. Name of cheapest beer at each bar?

create or replace view Q6(bar, beer) as
-- replace the SQL code below:
select m.bar, b.name
from Bar_min_price m
    join Sells s on (s.bar = m.id)
    join Beers b on (b.id = s.beer)
where s.price = m.min_price
order by m.bar asc, b.name asc
;

