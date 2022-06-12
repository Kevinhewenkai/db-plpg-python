--question1
create or replace view Q1(pid, firstname, lastname) as 
select pid, firstname, lastname from person p 
except
(
    (
        select p.pid, p.firstname, p.lastname from person p 
        join staff s on (s.pid = p.pid)
    )
    UNION
    (
        select p.pid, p.firstname, p.lastname from person p 
        join client c on (c.pid = p.pid)
    )
)
order by pid asc;

--question2
create or replace view Q2(pid, firstname, lastname) as
select pid, firstname, lastname from person p1
except
(
    select p.pid, firstname, lastname 
    from person p 
    join client c on (p.pid = c.pid)
    join insured_by i on (i.cid = c.cid)
    join policy p1 on (i.pno = p1.pno and p1.status = 'E')
)
order by pid asc;

--question3

create  or replace view 
    brandPremium(brand, vid, pno, premium)
as
select i.brand, p.id, p.pno , sum(r.rate)
from policy p
    join insured_item i on (i.id = p.id)
    join coverage c on (c.pno = p.pno)
    join rating_record r on (c.coid = r.coid)
where p.expirydate < now()::date or (p.effectivedate <= now()::date AND p.expirydate >= now()::date)
 AND r.status = 'A' AND p.status = 'E'
 
group by i.brand, p.id, p.pno;

create or replace view Q3(brand, vid, pno, premium) as
select b1.brand, b1.vid, b1.pno, b1.premium
from brandPremium b1
where b1.premium in (select max(b2.premium) over (PARTITION BY b2.brand) from brandPremium b2)
order by brand, vid, pno;


-- question4
-- List all the staff members who have not sell, rate or underwrite any policies that are/were 
--eventually enforced. Note that policy.sid records the staff who sold the policy (i.e., the agent). 
--Order the result by pid (i.e., Persion id) in ascending order.
create or replace view Q4(pid, firstname, lastname) as 
select p.pid, p.firstname, p.lastname
from person p, staff s
--, policy po, underwritten_by u, rated_by r
where p.pid = s.pid 
and 
s.sid not in (
    select p1.sid 
    from policy p1 
    where p1.status = 'E') 
and 
s.sid not in (
    select u.sid 
    from underwritten_by u 
        join underwriting_record ur on (u.urid = ur.urid) 
        join policy p2 on (ur.pno = p2.pno) 
    where p2.status = 'E'
    )
and 
s.sid not in (
    select r.sid 
    from rated_by r 
        join rating_record r2 on (r.rid = r2.rid) 
        join coverage c on (c.coid = r2.coid) 
        join policy p3 on (p3.pno = c.pno) 
    where p3.status = 'E'
    );

--question 5
-- For each suburb (by suburb name) in NSW, compute the number of enforced policies that have been 
-- sold to the policy holders living in the suburb (regardless of the policy effective and expiry
--  dates). Order the result by Number of Policies (npolicies), then by suburb, in ascending order. 
--  Exclude suburbs with no sold policies. Furthermore, suburb names are output in all uppercase.
create or replace view Q5(suburb, npolicies) as 
select upper(p.suburb), count(distinct p1.pno) -- can't upper
from person p
    join client c on (p.pid = c.pid)
    join insured_by i on (i.cid = c.cid)
    join policy p1 on (p1.pno = i.pno)
where p1.status = 'E'
group by p.suburb
order by count(distinct p1.pno), p.suburb;

-- question 6 
--Find all past and current enforced policies which are rated, 
--underwritten, and sold by the same staff member, and not involved any 
--others at all. Order the result by pno in ascending order.
create or replace view Q6(pno, ptype, pid, firstname, lastname) as
select p.pno, p.ptype, ps.pid, ps.firstname, ps.lastname
from person ps
    join staff s on (ps.pid = s.pid)
    join policy p on (p.sid = s.sid and p.status = 'E')
where
not exists (
    select ur.pno
    from underwriting_record ur 
        join underwritten_by ub on (ur.urid = ub.urid)
    where ur.pno = p.pno and ub.sid <> s.sid
)
and 
not exists (
    select c.pno
    from coverage c
        join rating_record rr on (c.coid = rr.coid)
        join rated_by rb on (rb.rid = rr.rid)
    where c.pno = p.pno and rb.sid <> s.sid
)
order by p.pno;

--question7
--The company would like to speed up the turnaround time of approving a 
-- policy and wants to find the enforced policy with the longest time 
-- between the first rater rating a coverage of the policy (regardless of 
-- the rating status), and the last underwriter approving the policy. Find 
-- such a policy (or policies if there is more than one policy with the 
-- same longest time) and output the details as specified below. Order the 
-- result by pno in ascending order.

create or replace view duration(pno, ptype, effectivedate, expirydate, agreedvalue, dur) as
select p.pno, p.ptype, p.effectivedate, p.expirydate, p.agreedvalue, (ub.wdate - rb.rdate)
from policy p 
    join underwriting_record u on (p.pno = u.pno)
    join underwritten_by ub on (u.urid = ub.urid)
    join coverage c on (p.pno = c.pno)
    join rating_record rr on (c.coid = rr.coid)
    join rated_by rb on (rr.rid = rb.rid)
where p.status = 'E';

create or replace view Q7(pno, ptype, effectivedate, expirydate, agreedvalue) as
select d.pno, d.ptype, d.effectivedate, d.expirydate, d.agreedvalue
from duration d
where d.dur = (select max(d1.dur) from duration d1)
order by d.pno;

--question8
-- List the staff members (their firstname, a space and then the lastname 
-- as one column called name) who have successfully sold policies (i.e., 
-- enforced policies) that only cover one brand of vehicle. Order the result 
-- by pid in ascending order.
create or replace view Q8(pid, name, brand) as 
select distinct ps.pid, concat(ps.firstname, ' ', ps.lastname), i.brand
from policy p
    join insured_item i on (p.id = i.id)
    join staff s on (s.sid = p.sid)
    join person ps on (ps.pid = s.pid)
where p.status = 'E' and not exists (
    select p1.sid 
    from policy p1
    join insured_item i1 on (i1.id = p1.id)
    where p1.sid = p.sid and i.brand <> i1.brand
)
order by ps.pid;

--question 9
-- List clients (their firstname, a space and then the lastname as one
-- column called name) who hold policies that cover all brands of 
-- vehicles recorded in the database. Ignore the policy status and 
-- include the past and current policies. Order the result by pid 
-- in ascending order.
create or replace view clientAndBrand(pid, name, brand) as
select ps.pid, concat(ps.firstname, ' ', ps.lastname), ii.brand
from policy p
    join insured_item ii on (p.id = ii.id)
    join insured_by ib on (p.pno = ib.pno)
    join client c on (c.cid = ib.cid)
    join person ps on (c.pid = ps.pid)
where p.status = 'E';

create or replace view nameAndBrand(pid, name, nbrand) as
select c.pid, c.name, count(distinct brand) from clientAndBrand c group by name, c.pid;

create or replace view Q9(pid, name) as
select n.pid, n.name
from nameAndBrand n
where  n.nbrand = (select count (distinct brand) from insured_item)
order by n.pid;

--question 10
-- Create a function that returns the total number of (distinct) staff 
-- that have worked (i.e., sells, rates, underwrites) on the given 
-- policy (ignore its status).
create or replace function staffcount(pno integer) returns integer
as $$
declare 
    total integer;
    ref integer;
BEGIN
ref := pno;
if (pno <= 0) then
    return 0;
end if;
select count(sid) into total from 
((   select p.sid
    from policy p
    join underwriting_record ur on (p.pno = ur.pno)                              
    join underwritten_by ub on (ur.urid = ub.urid)                               
    join coverage c on (c.pno = p.pno)                                           
    join rating_record rr on (c.coid = rr.coid)                                  
    join rated_by rb on (rr.rid = rb.rid)
    where p.pno = ref
)
UNION

(   select rb.sid
    from policy p
    join underwriting_record ur on (p.pno = ur.pno)                              
    join underwritten_by ub on (ur.urid = ub.urid)                               
    join coverage c on (c.pno = p.pno)                                           
    join rating_record rr on (c.coid = rr.coid)                                  
    join rated_by rb on (rr.rid = rb.rid)
    where p.pno = ref
)
UNION

(   select ub.sid 
    from policy p
    join underwriting_record ur on (p.pno = ur.pno)                              
    join underwritten_by ub on (ur.urid = ub.urid)                               
    join coverage c on (c.pno = p.pno)                                           
    join rating_record rr on (c.coid = rr.coid)                                  
    join rated_by rb on (rr.rid = rb.rid)
    where p.pno = ref
)) as tmp;
    return total;
end;
$$ language plpgsql;
   
-- question11
-- Create a stored procedure that will start renewing an existing policy in the database.
create or replace procedure renew(pno integer)
as $$
declare
old_stat character varying(2);
old_eff date;
old_exp date;
new_pno integer;
new_ptype char(1);
new_status character varying(2);
new_eff date;
new_exp date;
new_agr real;
new_com character varying(80);
new_sid integer;
new_id integer;
new_coid integer;
new_cname character varying(30);
new_maxamount real;
new_comments character varying(80);
ref integer;
tuple coverage;
begin
    ref := pno;
    new_status := "D";
    select (max(p.pno) + 1) into new_pno from policy p;
    select p.ptype, now()::date, (now()::date + p.expirydate - p.effectivedate), p.agreedvalue,
    p.comments, p.sid, p.id, p.status, p.effective, p.expirydate
    into new_ptype, new_eff, new_exp, new_agr, new_com, new_sid, new_id, old_stat, old_eff, old_exp
    from policy p 
    where p.pno = ref;
    -- if (not found) then
    --     return;
    -- end if;
    if (
        old = "E" and 
        (old_eff >= now()::date AND old_exp <= now()::date)
    ) then
        update policy p set p.expirydate = now()::date where p.pno = ref;
    end if;
    for tuple in 
        select * from coverage c where c.pno = ref
    loop
        select max(c1.coid) into new_coid from coverage c1;
        INSERT INTO coverage VALUES (new_coid, c.cname, c.maxamount, c.comments, new_pno);
    end loop;
        INSERT INTO policy VALUES (new_pno, new_ptype, new_status, new_eff, new_exp, new_agr, 
                                    new_com, new_sid, new_id);
end;
$$ language plpgsql;

-- question12 
--  A staff member can purchase an insurance policy from the company, but none of
--  the insured parties of the policy can be the agent, a rater, or an underwriter of that 
--  policy. Create a trigger (or triggers) to enforce this constraint while allowing a staff 
--  member to purchase a policy.
create trigger checkStaff before insert
on client for each row execute procedure checkStaff();

create or replace function checkStaff() returns trigger as $$
declare 
staffId integer;
policyId integer;

begin 
    select s.sid, i.pno into staffId, policyId 
    from staff s 
        join insured_by i on (new.cid = i.cid)
    where new.pid = s.pid;
    
    if staffId in (select p1.sid from policy p1 where p1.pno = policyId) then
        raise exception 'staff is the agent';
    end if;

    if staffId in (
        select u.sid 
        from underwritten_by u 
            join underwriting_record ur on (u.urid = ur.urid and ur.pno = policyId) 
        ) then
        raise exception 'staff is the underwriter';
    end if;
        
    if staffId in (
        select r.sid 
        from rated_by r 
            join rating_record r2 on (r.rid = r2.rid) 
            join coverage c on (c.coid = r2.coid and policyId = c.pno) 
        ) then
        raise exception 'staff is the rater';
    end if;
end;
$$ language plpgsql;