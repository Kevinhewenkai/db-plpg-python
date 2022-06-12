create table Suppliers (
    sid integer primary key,
    sname text,
    address text
);

create table Parts (
    pid integer primary key,
    pname text,
    colour text
);

create table Catalog (
    sid integer REFERENCES Suppliers(sid),
    pid integer REFERENCES Parts(pid),
    cost real,
    primary key (sid, pid)

)

--q12 supplier who supply red part
select s.name 
from Suppliers s join Catalog c on (s.sid = c.sid)
    join Parts p on (p.pid = c.pid)
where p.colour = "red";

-- q13 Find the sids of suppliers who supply some red or green part.
select s.name 
from Suppliers s join Catalog c on (s.sid = c.sid)
    join Parts p on (p.pid = c.pid)
where p.colour = "red" or p.colour = "green";

-- q14 Find the sids of suppliers who supply some red part or whose address is 221 Packer Street.
select s.name 
from Suppliers s join Catalog c on (s.sid = c.sid)
    join Parts p on (p.pid = c.pid)
where p.colour = "red" or s.address = "221 Packer Street";

-- q15 supply red AND green part
(
select s.name 
from Suppliers s join Catalog c on (s.sid = c.sid)
    join Parts p on (p.pid = c.pid)
--where p.colour = "red" and p.colour = "green";
where p.colour = "red" )
INTERSECT
(
select s.name 
from Suppliers s join Catalog c on (s.sid = c.sid)
    join Parts p on (p.pid = c.pid)
--where p.colour = "red" and p.colour = "green";
where p.colour = "green" );

-- q16 Find the sids of suppliers who supply every part. (IMPORTANT - SQL division)
-- For each supplier
--      Get all parts they supply
--      If parts == all parts available, add to list

-- For each supplier s
--  Set(all available parts) - set(parts that s supplies) = 0 -> add to the list
-- every time see each/every
--  Select [ ] from [ ] where  not exists [ALL EXCEPT SPECIFIC]
select s.name from Suppliers s where
NOT exists 
(   select p.pid from Parts p
    except
    select c.pid from Catalog c where c.sid = s.sid
);

--q19 Find the sids of suppliers who supply every red part OR supply every green part.
(select s.name from Suppliers s where
NOT EXISTS
    (   select p.pid from Parts p where p.colour = "Red"
        except
        select c.pid from Catalog c where c.sid = s.sid
    )
)
UNION
    (select s.name from Suppliers s where
    (   select p.pid from Parts p where p.colour = "Green"
        except
        select c.pid from Catalog c where c.sid = s.sid
    )
)

-- q20 Find pairs of sids such that the supplier with
-- the first sid charges more for some part than the supplier with the second sid.
select c1.sid, c2.sid
from Catalog c2, Catalog c2
where c1.sid != c2.sid and c1.cost > c2.cost and c1.pid = c2.pid


-- q21 Find the pids of parts that are supplied by at least two different suppliers.
Select C.pid 
from Catalog C
where exists(
    select c1.sid
    from Catalog c1
    where c1.pid = c.pid and c1.sid != c.sid
)

-- q22 Find the pids of the most expensive part(s) supplied by suppliers named "Yosemite Sham".
create view
    YosemiteSuppliers(pid, cost)
as
    select c.pid, c.cost
    from Catalog c join Suppliers s on (s.sid = c.sid)
    where s.sname = "Yosemite Sham"

Select pid from YosemiteSuppliers
    where cost = (select max(y1.cost) from YosemiteSuppliers y1);


-- Find the pids of parts supplied by every supplier at a price less than 200 dollars
-- (if any supplier either does not supply the part or charges more than 200 dollars for it, 
-- the part should not be selected).
select c.pid
from Catalog c
where c.cost < 200
group by c.pid
having count(*) = select(count(*) from supplier)

--select(count(*) from supplier) -> count the number of suppliers