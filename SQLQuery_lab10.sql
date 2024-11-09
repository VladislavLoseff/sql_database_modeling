/*use master
go
use management_company1
go*/
USE  master;
GO 
IF DB_ID (N'mc') IS NOT NULL 
DROP DATABASE mc;
GO
--создадим лучше еще одну таблицу для данных примеров, чтобы при выполнении прошлых лаб при очистке данных не приходилось заново все вставлять
CREATE DATABASE mc;
go
USE  mc;
GO 
CREATE TABLE companyclients (client_id  int identity(1,1) not null  primary key,--not null primary key,
inn CHAR(10)  not null,
j_adress varchar(100) not null,
legal_form smallint,
email varchar(100) not null,
CONSTRAINT check_legal_form CHECK(legal_form in (1,2,3))
)
go
insert into companyclients values (1749308428,'Moscow, Paslannikov per., h.5,b.1',1,'catcomp@mail.ru')
insert into companyclients values (5828502174,'Moscow, Gospitalny per., h.2',1,'anothercomp@mail.ru')
insert into companyclients values (4936799397,'Moscow, brigadirsky per., h.5,b.3',2,'insurancecomp@mail.ru');
go
select *
from companyclients




---------------------------------------------
/*пример грязного чтения . в рамках одной транзакции произошли изменения и если level read uncommitted

то если данная транзакция не закончится и запустить еще select, то будет грязное чтение. А при  committed дождется выполнения данной транзакции перед чтением другой
*/
--или здесь еще нужно добавить uncommitted, хотя скорее для запроса в следующем файле, так как по отношению к тому запросу происходит грязное чтение

begin transaction
select *
from companyclients
insert into companyclients values (9749308539,'Moscow, Paslannikov per., h.7',1,'crc@mail.ru')
/*update companyclients
set legal_form=3
where inn=1749308428*/
--delete from companyclients where contract_number=1749308428
waitfor delay '00:00:10'
go
commit transaction


select *
from companyclients


delete from companyclients where client_id=9
--------------------------------------------

--------------------------------------------
--можно использовать и прошлый пример
--set transaction isolation level read committed 
begin transaction
select *
from companyclients

update companyclients
set legal_form=1
where inn=5828502174
waitfor delay '00:00:10'
go
commit transaction

--select * 
--from companyclients
-------------------------------------------------------
--следующий уровень изоляции транзакций -- repeatable read. Он защищает от грязного и невоспроизводимого чтения , но возможно фантомное чтение
--смоделируем невоспроизводимое и фантомное чтение, посмотрим разницу commited и repeatable read
--set transaction isolation level read uncommitted
--set transaction isolation level read committed
set transaction isolation level repeatable read
begin transaction
select * 
from companyclients
waitfor delay '00:00:10'
select * 
from companyclients
commit transaction
--то есть два чтения в рамках одной транзакции

--Сначала запускаем данную транзакция и во время ее работы изменяем данные. 
--если ставим уровень, который защищает от невоспроизводимо чтения, то изменения вступят в силу только после повторного чтения и завершения транзакции
--при этом если вставить значение, то уже будет фантомное чтение, от него защищает serializable
--проверим что тперь уже изменения есть, когда транзакция предыдущая завершмлась
select * 
from companyclients

/*Теперь разберем проблему с фантомным чтением.

*/
--set transaction isolation level read uncommitted
--set transaction isolation level read committed
--set transaction isolation level repeatable read
set transaction isolation level serializable
begin transaction
select * 
from companyclients
where legal_form=1
waitfor delay '00:00:10'
select * 
from companyclients
where legal_form=1
commit transaction
--можно использовать и прошлый пример
--запускаем транзакцию. Во время задержки вставляем значение. Если у нас уровень изоляции транзакции не serializable
-- то произойдет фантомное чтение,  значение добавится после завершения транзакции с повторным чтением. при serializable
--изменения в данных при повторном чтении в рамках данной транзакции не будет


/*
грязное чтение(update insert delete)
невоспроизводимое чтение(проблемы возникают при update и delete)
фантомное чтение(проблемы возникают при insert)
*/