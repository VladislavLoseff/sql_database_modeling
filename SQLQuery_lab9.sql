USE  master;
GO 
IF DB_ID (N'management_company2') IS NOT NULL 
DROP DATABASE management_company2;
GO

CREATE DATABASE management_company2;
go
USE  management_company2;
GO 

CREATE TABLE companyclients (--client_id  int identity(1,1) not null  primary key,--not null primary key,
inn varchar(10)  not null primary key,
j_adress varchar(100) not null,
legal_form smallint,
email varchar(100) not null,
CONSTRAINT check_legal_form CHECK(legal_form in (1,2,3))
)
go

insert into companyclients values ('1749308428','Moscow, Paslannikov per., h.5,b.1',1,'catcomp@mail.ru')
insert into companyclients values ('5828502174','Moscow, Gospitalny per., h.2',1,'anothercomp@mail.ru')
insert into companyclients values ('4936799397','Moscow, brigadirsky per., h.5,b.3',2,'insurancecomp@mail.ru');

CREATE TABLE clientcontract (contract_number int not null primary key,
sign_date date  not null,
contract_period int not null default 365, --по умолчанию будет год
total_sum float not null,
invest_daclaration varchar(100) not null,
client_id int not null--default 1-- /*not null -- убираем для ограничения SET NULL и SET DEFAULT если не задано значение по умолчанию*/                  /*references companyclients(client_id)*/,
constraint fc_clientcontr foreign key(client_id) references companyclients(client_id)   --лучше так использовать создавать ограничения? чтобы потом было проще редактировать
ON DELETE CASCADE
ON UPDATE CASCADE

)
go


insert into clientcontract values (2,'2023-11-12',270,5000000,'only using obligations',1)
insert into clientcontract values (5,'2023-10-01',180,10000000,'actions<20%',2)
insert into clientcontract values (7,'2024-02-12',365,15000000,'obligations>70%',3);
---создание триггеров-----
/*select *
from companyclients*/
--insert
drop trigger if exists insert_trigger 
go
CREATE TRIGGER insert_trigger 
ON companyclients
FOR INSERT 
AS 
IF UPDATE(legal_form)
 PRINT 'column legal_form has modified, new data addition'
 go

 
 insert into companyclients(inn,j_adress,legal_form,email) values (4936799385,'Moscow, brigadirsky per., h.1,b.1',3,'ins@mail.ru');
 --сообщение возникает, все верно


 -----------триггер на запрет обновления столбца inn
drop trigger if exists update_trigger 
go
CREATE TRIGGER update_trigger 
ON companyclients
instead of  UPDATE 
AS 
IF UPDATE(inn)
RAISERROR('You can not update inn! ', 11, 111);--можно указать -1,-1 тогда будет выведена степень серьезности ошибки
--rollback transaction;
 go
 
 --Все работает, обновление запрещено
 update companyclients
 set inn=1000000000
 where inn=4936799397
 

 --попробуем триггер на insert для другой таблицы
drop trigger if exists insert_trigger2 
go
CREATE TRIGGER insert_trigger2 
ON clientcontract
FOR insert 
AS 
UPDATE clientcontract --при обновлении данной таблицы (в данном случае вставка)
set contract_period=contract_period+1
where contract_number in (select contract_number from inserted);
 go
insert into clientcontract values (811,'2024-02-10',365,1000000,'obligations>60%',3),(822,'2024-02-10',365,1000000,'obligations>60%',3);
/*--delete from clientcontract where contract_number=8
select *
from clientcontract*/

--все работатет. Например, по новым правилам, день заключения сделки должен учитываться в отчете и его прибавляем к кол-ву дней по договору

drop trigger if exists delete_trigger 
go
CREATE TRIGGER delete_trigger 
ON companyclients
FOR DELETE
AS 
 PRINT 'The data was deleted in table companyclients!'
 go

 delete from companyclients
 where inn=4936799385
 --все работает, возникает текст при удалении
 select *
 from companyclients

 
 --------------------------------------------------------------
 --создадим еще одну таблицу для этого задания чтобы связь была 1 к 1. 
 --есть таблица клиент, создадим таблицу с дополнительно информацией о клиенте

 CREATE TABLE client_add_inf (--number int  identity(1,1) not null primary key,
registr_date date  not null,
share_capital float, --default 10000
ceo varchar(100) not null,
inn varchar(10) not null primary key              
constraint fc_cl foreign key(inn) references companyclients(inn)  
ON DELETE CASCADE
ON UPDATE CASCADE)
go
insert into client_add_inf values ('2013-11-12',10000,'A. Sidorov','1749308428'),
('2009-08-11',10000,'A. Ivanov','5828502174'),('2013-11-12',10000,'E. Petrov','4936799397');
go


select *
 from companyclients

 select *
 from client_add_inf

 --теперь создадим представление
DROP VIEW IF EXISTS triggersview
GO

--создаем view  из двух таблиц

CREATE VIEW triggersview  AS
SELECT cc.inn,cc.j_adress,cc.legal_form,cc.email,ci.registr_date,ci.share_capital,ci.ceo
FROM companyclients AS cc JOIN client_add_inf AS ci ON cc.inn=ci.inn
--WHERE 
GO
 
 select *
 from triggersview
--создание триггера . внутри триггера работаем непосредственно с таблицами
drop trigger if exists delete_view_trigger ; 
go

CREATE TRIGGER delete_view_trigger 
on dbo.triggersview 
instead of delete
as
begin
delete from companyclients 
where inn in (select inn from deleted)

/*delete from companyclients 
where inn in (select inn from deleted)*/

 end
go
 
 --удаление каскадное в таблицах

 delete from dbo.triggersview where inn='2387354901'
 select *
 from triggersview


 --все верно сработало

 /*SET IDENTITY_INSERT companyclients OFF
 go
 SET IDENTITY_INSERT client_add_inf OFF
 go*/
/*ON dbo.triggersview 
instead of DELETE --с представлениями только используются instead of
AS 
 PRINT 'The data was deleted from view!'
 go
 */

 /*
 SET IDENTITY_INSERT companyclients OFF
 go
 SET IDENTITY_INSERT client_add_inf OFF
 go


drop trigger if exists insert_view_trigger; 
go

create trigger insert_view_trigger
    on triggersview
    instead of insert
    as
    begin

	declare @inn char(10)
	select @inn = inn from inserted
		declare @legal_form int
	declare @client_id int
	select @client_id = client_id from inserted
	select @legal_form= legal_form from inserted
		declare @registr_date date
	select @registr_date = registr_date from inserted
			declare @ceo varchar(100)
	select @ceo = ceo from inserted


         insert into companyclients(inn,j_adress,legal_form,email) 
            values (@inn,'no data',@legal_form,'no data' )
			
			               
                 
        insert into client_add_inf(registr_date,share_capital,ceo,client_id)
            values                   (@registr_date,10000,@ceo,@client_id)
                
    end
go
insert into triggersview values(2387304921,3,'2020-01-01','M. Gorky')
*/


/*drop trigger if exists insert_view_trigger; 
go

create trigger insert_view_trigger
    on triggersview
    instead of insert
    as
    begin
	declare @client_id int
	declare @curs cursor
	set @curs=cursor forward_only for
	select inn,j_adress,legal_form,email,registr_date,share_capital,ceo from inserted;
	
	declare @inn char(10)
		declare @j_adress varchar(100)
			declare @legal_form int
			declare @email varchar(100)
	
			declare @registr_date date
			declare @share_capital float
				declare @ceo varchar(100)
	
	open @curs
	fetch next from @curs into @inn,@j_adress,@legal_form,@email,@registr_date,@share_capital,@ceo 
	while @@fetch_status=0
	begin

         insert into companyclients(inn,j_adress,legal_form,email) 
            values (@inn,@j_adress,@legal_form, @email )
			set @client_id=scope_identity();
			
			               
                 
        insert into client_add_inf(registr_date,share_capital,ceo,client_id)
            values(@registr_date,@share_capital,@ceo,@client_id);
			fetch next from @curs into @inn,@j_adress,@legal_form,@email,@registr_date,@share_capital,@ceo
			end
			close @curs
			deallocate @curs
                
    end
go

insert into triggersview values(2387304921,'tverskaya 1',3,'comp@mail.ru','2020-01-01',10000,'M. Gorky',5),(2387354921,'tverskaya 3',2,'c@mail.ru','2020-01-01',100,'S Esenin',6);
go
*/

-----------------------------------
/*drop trigger if exists insert_view_trigger; 
go

create trigger insert_view_trigger
on triggersview
    instead of insert
    as
    begin
	----
	with tw(inn,j_adress,legal_form,email,registr_date,share_capital,ceo) as (select inn,j_adress,legal_form,email,registr_date,share_capital,ceo from inserted)
	---
	insert into companyclients(inn,j_adress,legal_form,email)
            select inn,j_adress,legal_form,email
                from tw ;
          
		  with tw2(inn,j_adress,legal_form,email,registr_date,share_capital,ceo) as (select inn,j_adress,legal_form,email,registr_date,share_capital,ceo from inserted)

        insert into client_add_inf(registr_date,share_capital,ceo,inn)
            select   registr_date,share_capital,ceo,inn                
				from tw2;
 
       /* insert into companyclients(inn,j_adress,legal_form,email)
            select inn,j_adress,legal_form,email
                from inserted 
              
        insert into client_add_inf(registr_date,share_capital,ceo,inn)
            select                    
					registr_date,
					share_capital,
					ceo,
                    (select inn from companyclients as c where c.inn =inserted.inn)
					 from inserted 
                 */                 
    end
go


insert into dbo.triggersview values('2387304926','tverskaya 99',3,'company@mail.ru','2020-01-01',10000,'M. Gorky')--,('2387354923','tverskaya 5',2,'cc@mail.ru','2020-01-01',100,'S Esenin');
go
---------------------------------------


select *
from client_add_inf

*/


drop trigger if exists insert_view_trigger2; 
go

create trigger insert_view_trigger2
    on triggersview
    instead of insert
    as
    begin
	declare @client_id int
	declare @curs cursor
	set @curs=cursor forward_only for
	select inn,j_adress,legal_form,email,registr_date,share_capital,ceo from inserted;
	
	declare @inn char(10)
		declare @j_adress varchar(100)
			declare @legal_form smallint
			declare @email varchar(100)
	
			declare @registr_date date
			declare @share_capital float
				declare @ceo varchar(100)
	
	open @curs
	fetch next from @curs into @inn,@j_adress,@legal_form,@email,@registr_date,@share_capital,@ceo 
	while @@fetch_status=0
	begin

         insert into companyclients(inn,j_adress,legal_form,email) 
            values (@inn,@j_adress,@legal_form, @email )
			              
                 
        insert into client_add_inf(registr_date,share_capital,ceo,inn)
            values(@registr_date,@share_capital,@ceo,@inn);
			fetch next from @curs into @inn,@j_adress,@legal_form,@email,@registr_date,@share_capital,@ceo
			end
			close @curs
			deallocate @curs
                
    end
go

insert into triggersview values('2387304920','tverskaya 1',3,'comp@mail.ru','2020-01-01',10000,'M. Gorky'),('2387354901','tverskaya 3',2,'c@mail.ru','2020-01-01',100,'S Esenin');
go




--очистить перед новым запуском
select *
from triggersview
--все работает. происходит вставка как каждой по отдельности строки, так и нескольких строк

----------------------------------------


----------------------------------------


 ---------------теперь обновление view------------------
 --тут все исправить
drop trigger if exists update_view_trigger; 
go
 create trigger update_view_trigger
    on dbo.triggersview 
    instead of update
    as 
    begin
   if UPDATE(inn)  or UPDATE(legal_form) or UPDATE(registr_date)
    RAISERROR('We can not update inn, registr_date, legal_form and client_id',16,10)
	
      if  UPDATE(ceo)
     update client_add_inf
      set 
      ceo = (select ceo from inserted where inserted.inn = client_add_inf.inn)--т.к.  идентиф
       where inn in (select inn  from inserted where inserted.inn = client_add_inf.inn) 
     end
go

update dbo.triggersview set registr_date='2021-06-06' where inn='4936799397'--Не обновляется
update dbo.triggersview set ceo='V Oblomov' where inn='4936799397' --работает все верно

select *
from dbo.triggersview
 --сработало верно, произошло обновление
 --данный триггер работает


 select *
 from clientcontract