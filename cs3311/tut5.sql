create or replace function  
    factorial(n int) returns int
as $$
BEGIN
    if (n = 0) then
        return 1;
    else 
        return n * factorial(n-1);
    end if;
end;
$$ language plpgsql;

create or replace function  
    factorial(n int) returns int
as $$
    select case when n = 0 then
        1
    else 
         n * select factorial(n-1)
$$ language sql;

-- q10 (sql function)
create or replace function hotelsIn(text) return setof Bars
as $$
    select * from Bars where address = $1
$$ language sql;

-- q11 (PLPGSQL looping through record)
create or replace function hotelsIn(location1 text) return setof Bars
as $$
declare
    r record; -- record any row in database
BEGIN
    for r in select * from Bars where address = location1 --list of row
    loop
        -- if r.name = "Some Bar" then 
        --     return next r;
        -- end if;
        return next r; -- append this row into my results
    end loop;
    return;
end;

-- trigger

-- INSERT -> add 1 to Course.numStudents OR reject if Couurse.numStudents > max
-- UPDATE -> if the student change courses then update Course.numStudents
-- DELETE -> remove 1 from Course.numStudents

-- insert student
create or replace function ins_stu() returns trigger as $$
BEGIN
    update Course set numStudents = numStudents + 1 where code = new.course;
    return new;
end;
$$ plpgsql;

-- delete student
create or replace function del_stu() returns trigger as $$
BEGIN
    update Course set numStudents = numStudents - 1 where code = old.course;
    return new;
end;
$$ plpgsql;

-- update student
create or replace function upd_stu() returns trigger as $$
BEGIN
    update Course set numStudents = numStudents + 1 where code = new.course;
    update Course set numStudents = numStudents - 1 where code = old.course;
    return new;
end;
$$ plpgsql;

-- quota check
create or replace function chk_quo() return trigger as $$
declare
    quata_filled boolean;
BEGIN
    select into quota_filled (numStudents >= quota)
    from Course where code = new.course;
    if (quota_filled) then
        raise exception 'class % is full', new.course;
    end if;
    return new;
end;
$$ language plpgsql;

create trigger student_insertion after insert on enrollement
    for each row execute procedure ins_stu();

create trigger quota_check before insert or update on enrollement
    for each row execute procedure chk_quo();

create trigger student_update after update on enrollement
    for each row execute procedure upd_stu();
    
create trigger student_deletion after update on enrollement
    for each row execute procedure del_stu();