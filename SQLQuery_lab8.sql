
use master; 
go

use management_company1
go

drop function if exists get_year;
go
--создание пользовательской функции--
create function get_year(@sdate datetime)
returns int
as begin
return YEAR(@sdate)
end;
go




drop function if exists find_new_signs;
go
--создаем еще одну функцию с условием
create function find_new_signs(@sdate datetime)
returns bit--int
as 
begin
 declare @rez int
 if @sdate<'2023-01-01'
 set @rez=0
 else
 set @rez=1
 return @rez
 end 
 go


--создать хранимую процедуру, производящую выборку из некоторой таблицы и возвращающий результат выборки в виде курсора
drop procedure if exists proc_cursor
go
create procedure proc_cursor
@curs cursor varying output
as
set @curs=cursor
forward_only static for
select  sign_date,total_sum
from clientcontract;
open @curs;
go
--протестируем первую пользовательскую функцию
select dbo.get_year('2024-01-01')

--теперь сделаем чтобы выборка была с формированием столбца, определенного пользовательской функцией
drop procedure if exists proc_cursor2
go
create procedure proc_cursor2
@curs cursor varying output
as
set @curs=cursor
forward_only static for
select  sign_date,total_sum,dbo.get_year(sign_date)
from clientcontract;
open @curs;
go


----------------------------------
/*Создаем хранимую процедуру, вызывающую предыдущую процедуру и осуществляющую прокрутку возвращаемого курсора и выводящую сообщения,
сформированные из записей при выполнения условия, заданного еще одной пользовательской функцией */
drop procedure if exists proc3
go
create procedure proc3
as
    declare @ext_curs cursor;
    
    declare @sign_date date;
    declare @total_sum int;
	declare @year int;
 
    exec proc_cursor2 @curs = @ext_curs output;--возвращаемый курсор
 
    
    fetch next from @ext_curs into @sign_date, @total_sum,@year; --перемещаем курсор на первую строку для дальнейшего проход
    
	print 'our date'
 
    while (@@FETCH_STATUS = 0) --идет прокрутка
    begin
    if (dbo.find_new_signs(@sign_date) = 1)
            print 'Total sum of deal: ' +cast(@total_sum as nvarchar)+', date of sign:'+cast(@sign_date as varchar)+' year of sign, '+cast(@year as nvarchar)
			
    fetch next from @ext_curs into @sign_date, @total_sum,@year;
       
    end
 
    close @ext_curs;
    deallocate @ext_curs;
go
--немного отредактировать созданную процедуру, сделать ее получше и подумать над выводом текста
exec proc3  --вызываем созданную процедуру
go
------------------------------------
--создаем стандартную табличную функцию 

drop function if exists big_contracts
go

create function big_contracts()--данные вернет в виде таблицы если клиент внес больше 5000000
    
    returns @big table
    (
        contract_number int,
        sign_date datetime,
		total_sum int
    )
    as
    begin
    insert @big
    select contract_number, sign_date,total_sum 
    from clientcontract
    where total_sum>5000000
    return
    end;
go

--теперь создадим inline табличную функцию

drop function if exists big_contracts_inline
go

create function big_contracts_inline()--данные вернет в виде таблицы если клиент внес больше 5000000
    
    returns table
      as
    return (
        select contract_number, sign_date,total_sum 
        from clientcontract
        where total_sum>5000000
        );
    go


	
	--модифицировать хранимую процедуру из пункта 2 таким образом, чтобы выборка формировалась с помощью табличной функции--

	

	--создадим новые процедуры
drop procedure if exists proc4
go
create procedure proc4
@curs cursor varying output
as
set @curs=cursor
scroll static for
select  sign_date,total_sum
from dbo.big_contracts_inline();--данные из табличной функции
open @curs;
go


drop procedure if exists proc5
go
create procedure proc5
@curs cursor varying output
as
set @curs=cursor
scroll static for
select  sign_date,total_sum
from dbo.big_contracts();--данные из табличной функции
open @curs;
go

declare @another_curs cursor;
exec proc4 @curs = @another_curs OUTPUT;
fetch next from @another_curs;
while (@@FETCH_STATUS = 0)
begin
    fetch next from @another_curs;
end
close @another_curs;
deallocate @another_curs;
go