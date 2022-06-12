create or replace function
    mystery(n integer, m integer) returns integer
as $$
declare
    i integer;
    r integer := 1;
begin
    r := n;
    for i in 2..m loop
        r := r * n;
    end loop;
    return r;
end;
$$ language plpgsql;