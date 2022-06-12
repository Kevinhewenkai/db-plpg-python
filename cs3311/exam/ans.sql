-- COMP3311 21T1 Exam SQL Answer Template
--
-- * Don't change view/function names and view/function arguments;
-- * Only change the SQL code for view/function bodies as commented below;
-- * and do not remove the ending semicolon of course.
--
-- * You may create additional views, if you wish;
-- * but you are NOT allowed to create tables.
--


-- Q1. 

create or replace view Q1(name, total) as
-- replace the SQL code below:
select a.name, count(ai.movie_id)
from public.actor a
    left outer join public.acting ai on (a.id = ai.actor_id)
group by a.name
order by count(ai.movie_id) desc, a.name asc
;


-- Q2. 

create or replace view highest (year, name, mark) as
select m.year, d.name, avg(r.imdb_score)::numeric(3,1)
from public.movie m 
    join public.director d on (d.id = m.director_id)
    join public.rating r on (m.id = r.movie_id)
where r.num_voted_users>100000 and m.year is not NULL and d.name is not NULL
group by m.year, d.name
;

create or replace view Q2(year, name) as
-- replace the SQL code below:
select m.year, d.name
from public.movie m 
    join public.director d on (d.id = m.director_id)
    join public.rating r on (m.id = r.movie_id)
where (r.imdb_score = (select max(h.mark) from highest h where h.year = m.year))
order by m.year asc, d.name asc
;


-- Q3. 

create or replace view Q3 (title, name) as
-- replace the SQL code below:
select m.title, d.name
from public.movie m 
    join public.director d on (d.id = m.director_id)
    join public.acting ai on (ai.movie_id = m.id)
    join public.actor a on (a.id = ai.actor_id)
where d.name = a.name
order by m.title asc, d.name asc
;


-- Q4. 
-- all actors that subsequently become directors
-- Do not include those that started acting and directing in a same year. 
-- The query output is a list of actor names in ascending order.
create or replace view Q4Helper (name, minYear, maxYear) as
select a.name, min(m.year), max(m1.year)
from public.actor a, public.director d, public.movie m , public.movie m1
    join public.acting ai on (ai.movie_id = m1.id)
where a.name = d.name and m.director_id = d.id and  ai.actor_id = a.id
group by a.name
;

create or replace view Q4 (name) as
-- replace the SQL code below:
select name from Q4Helper
where maxYear <> minYear
order by name asc
;


-- Q5. 
create or replace view helper(actor1, actor2, num) as
select a1.name, a2.name, count(ai2.movie_id)
    from public.acting ai2, public.actor a1, public.actor a2
    where not EXISTS(
    (
        select ai.movie_id
        from public.acting ai
        where ai.actor_id = a1.id
    ) 
    except
    (
        select ai1.movie_id
        from public.acting ai1
        where ai1.actor_id = a2.id
    )
    ) 
    and 
    EXISTS(
        select ai3.movie_id 
        from public.acting ai3 
        where ai2.movie_id = ai3.movie_id and ai2.actor_id <> ai3.actor_id
    )
    group by a1.name, a2.name
;

create or replace view Q5(actor1, actor2) as
-- replace the SQL code below:
select h.actor1, h.actor2 from helper h where actor1 <> actor2
order by h.num desc, h.actor1 asc, h.actor2 asc
;


-- Q6. 

create or replace function
    experiencedActor(_m int, _n int) returns setof actor
as $$ 
declare
    first_movie public.yeartype;
    last_movie public.yeartype;
    exp_year integer;
begin
    select min(m.year), max(year) into first_movie, last_movie
    from public.movie m
        join public.acting ai on (m.id = ai.movie_id)
    group by ai.actor_id;

    return (
            select a.id, a.name, a.facebook_likes
            from actor a

            )
end;
$$ language plpgsql;


-- Q7.
-- Define your trigger (or triggers) below
create or replace function five_genre() returns trigger
as $$
    declare num integer;
    begin   
    select count(g.genre) into num 
    from public.genre g 
    where g.movie_id = new.movie_id;

    if (num >= 5) then
        raise exception 'A movie must have at most 5 genres';
    end if;

    return new;
    end;
$$ language plpgsql;

create or replace function five_keyword() returns trigger
as $$
    declare 
        num integer;
    begin   
    select count(g.keyword) into num 
    from public.keyword k
    where k.movie_id = new.movie_id;

    if (num >= 5) then
        raise exception 'A movie must have at most 5 keywords';
    end if;

    return new;
    end;
$$ language plpgsql;

create trigger five_genre
before insert on public.genre
for each row execute procedure five_genre();

create trigger five_keyword
before insert on public.keyword
for each row execute procedure five_keyword();
