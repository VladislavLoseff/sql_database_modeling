USE  master;
GO 
IF DB_ID (N'management_company') IS NOT NULL 
DROP DATABASE management_company;
GO

CREATE DATABASE management_company;
go
USE  management_company;
GO 

--создаем таблицу с данными клиентов компании
CREATE TABLE companyclients (client_id  int identity(1,1) not null  primary key,--not null primary key,
inn CHAR(10)  not null unique,
j_adress varchar(100) not null,
legal_form smallint,
email varchar(100) not null unique,
CONSTRAINT check_legal_form CHECK(legal_form in (1,2,3))
)
go


--создадим таблицу с договором клиента
CREATE TABLE clientcontract (contract_number int not null primary key,
sign_date date  not null,
contract_period int not null default 365, 
total_sum float not null,
invest_daclaration varchar(100) not null,
client_id int not null                 
constraint fc_clientcontr foreign key(client_id) references companyclients(client_id) 
ON DELETE CASCADE
ON UPDATE CASCADE

)
go


--создаем таблицу с данными о ценных бумагах
CREATE TABLE sec_paper (isin char(12) not null primary key,
trading_platform varchar(100),
issuer varchar(100) not null,
price int not null,
amount int not null
)
go

--создаем таблицу с данными о сделках в рамках договора
CREATE TABLE clientdeal (deal_id  int identity(1,1) not null  primary key,
direction smallint not null default 1,--направление сделки -1,1
sign_date date  not null,
transaction_amount float not null , 
total_papers int not null,
coupon_period int , --null для акций
perc_of_pay float, --null для акций
contract_id int not null,
isin char(12) not null,

CONSTRAINT check_direction CHECK(direction in (-1,1)),
constraint fc_contr foreign key(contract_id) references clientcontract(contract_number),
constraint fc_isin foreign key(isin) references sec_paper(isin) 
ON DELETE CASCADE
ON UPDATE CASCADE 
)
go

 
 --запретим обновлять поля в сделке
 drop trigger if exists clientdeal_trigger_upd 
go
CREATE TRIGGER clientdeal_trigger_upd ON clientdeal
for  UPDATE 
AS 
begin
RAISERROR('You can not update all fields, related to monetary part of deal! ', 16, 1);
rollback transaction;
end
 go
 
--в таблице с данными о ценных бумагах введем запрет на обновление всех полей, за исключением текущей цены
drop trigger if exists papers_trigger_upd 
go
CREATE TRIGGER papers_trigger_upd  ON sec_paper
for  UPDATE
AS 
begin
IF UPDATE(isin) and UPDATE(trading_platform) and UPDATE(issuer) and UPDATE(amount)
RAISERROR('You can not update all fields, instead except of current price! ', 16, 1);
if  UPDATE(price)
     update sec_paper
      set 
      price = (select price from inserted where inserted.isin = sec_paper.isin)--т.к.  идентиф
       where isin in (select isin from inserted where inserted.isin = sec_paper.isin) 
     end


 go
 --запрет на изменение всех полей sec_paper (кроме текущей цены), так как все остальные поля изменениям не подлежат

 --заполним созданные таблицы 
insert into companyclients(inn,j_adress,legal_form,email) values ('1749308428','Moscow, Paslannikov per., h.5,b.1',1,'catcomp@mail.ru')
, ('5828502174','Moscow, Gospitalny per., h.2',1,'anothercomp@mail.ru')
, ('4936799397','Moscow, Brigadirsky per., h.5,b.3',2,'insurancecomp@mail.ru'),
('4528573910','Moscow, Rubtsov per., h.4,b.1',3,'bigbussines@gmail.com') --новый клиент, пока контракт один заключили, сделок еще нет
;

insert into clientcontract(contract_number,sign_date,contract_period,total_sum,invest_daclaration,client_id) values (2,'2023-11-12',1460,5000000,'not only using obligations',1)
,(5,'2023-10-01',1095,10000000,'actions<90%',2),
(7,'2024-02-12',365,15000000,'obligations>30%',3),
(1,'2022-06-12',730,5000000,'not only obligations',1),
 (13,'2021-03-01',1825,20000000,'actions<80%',2),
 (17,'2024-02-10',1460,55000000,'obligations>20%',1)
 ,
 (18,'2024-05-30',1460,35000000,'only actions',4); --контракт с новым клиентов заключили, сделки еще не провели

 
insert into sec_paper(isin,trading_platform,issuer,price,amount) values('ru1638429872','moex','sber',1000,50000),
('ru8739065119','moex','yandex',3000,400000),--облигация
('ru1197536784','moex','vtb',5000,600000),
('ru9066231178','moex','renessans',1500,450000),
('ru7409750984','moex','gazprombank',4000,1000000),
('ru9421759833','moex','tinkoff',5000,700000),
('ru8471251837','moex','x5',5000,1500000),--облигация
('us3752852299','nasdaq','google',10000,1500000),
('us9933567811','nasdaq','amazon',10000,2500000)

insert into clientdeal(direction,sign_date,transaction_amount,total_papers,coupon_period,perc_of_pay,contract_id,isin) values(-1,'2023-11-11',1000000,1000,NULL,NULL,2,'ru1638429872'),
(1,'2023-12-11',3000000,1000,24,12,2,'ru8739065119'),
(1,'2023-09-10',30000000,25000,NULL,NULL,5,'ru1197536784'),

(1,'2023-11-11',4000000,1000,NULL,NULL,1,'ru7409750984'),
(1,'2023-12-11',3000000,1000,36,8,17,'us9933567811'),
(1,'2023-09-10',30000000,15000,NULL,NULL,13,'ru1197536784'),
(1,'2023-11-11',1000000,1000,NULL,NULL,7,'ru9066231178'),
(1,'2022-12-11',30000000,1000,12,12,7,'ru8471251837'),
(1,'2023-09-10',30000000,9000,NULL,NULL,13,'ru7409750984'),
(1,'2024-11-11',1000000,1000,NULL,NULL,1,'ru9421759833'),
(1,'2023-12-11',30000000,1000,36,10,17,'ru8471251837'),
(-1,'2024-07-10',5000000,5000,NULL,NULL,17,'ru7409750984');

--создадим функцию, которая вычисляет количество дней со времени подписания контракта до текущего дня
drop function if exists passeddays
go

create function passeddays(@contract_date date)
    returns int
   as
  begin
  declare @current_date datetime = GETDATE();
  declare  @passed int;
  set @passed =datediff(day,@contract_date, @current_date );
  return @passed;
 end
go
 
 --смотрим, сколько дней по контракту осталось, а какие договоры закончились
 select contract_number,dbo.passeddays(sign_date) as daysleft
 from clientcontract
  
 --теперь создадим функцию для подсчета денег, полученных  в качестве процента по облигациям за первый купонный период

 drop function if exists percentspay
go
 create function percentspay(@perc_of_pay float,@transaction_amount float)
    returns int
   as
  begin
 
  declare  @total int
  if @perc_of_pay is not null --для облигаций
  set @total =@perc_of_pay*@transaction_amount/100.0
  else
  set @total=0
  return @total
 end
go

select contract_id,sum(dbo.percentspay(perc_of_pay,transaction_amount)) as percents
 from clientdeal
 group by contract_id


 drop function if exists dealstatus
go
 create function dealstatus(@coupon_period int,@sign_date date)
    returns bit
   as
  begin
  declare @current_date datetime = GETDATE();
  declare  @passed int;
  declare  @dstatus char;
  set @passed =datediff(month,@sign_date, @current_date )
  if @passed>@coupon_period
  set @dstatus=1 --done
  else 
   set @dstatus=0 --active
  return @dstatus;
 end
go

 --найдем завершенные сделки. Завершенными считаются сделки по облигациям после завершения купонного периода.
 select deal_id,dbo.dealstatus(coupon_period,sign_date) as deal_status
 from clientdeal
 
--создадим представления для запросов содержащих основную информацию

--основная информация о контрактах, клиентах, количестве внесенных средств
DROP VIEW IF EXISTS clientsview
GO
CREATE VIEW clientsview  AS
 select cc.client_id,cc.legal_form,cc.j_adress,cc.email,cl.tot_sum,cl.numb_of_contracts
 from companyclients as cc
 join (select client_id, sum(total_sum) as tot_sum,count(contract_number) as numb_of_contracts
from clientcontract 
group by client_id) as cl on cl.client_id=cc.client_id
GO

--создадим представления для таблицы со сделками, отдельно для акций и облигаций
--представление для облигаций
 DROP VIEW IF EXISTS obligationsview
GO
CREATE VIEW obligationsview  AS
 select *
 from clientdeal
 where coupon_period is not NULL and  perc_of_pay is not  NULL 
GO

--представление для акций
 DROP VIEW IF EXISTS actionsview
GO
CREATE VIEW actionsview  AS
 select *
 from clientdeal
 where coupon_period is NULL and perc_of_pay is NULL
GO


--Теперь  создадим представления  данные для ценных бумаг. Часто требуется отделить российские ценные бумаги от иностраннх
 DROP VIEW IF EXISTS rupapers
GO
CREATE VIEW rupapers  AS
 select *
 from sec_paper
 where trading_platform='moex'
GO
select *
from rupapers

 DROP VIEW IF EXISTS foreignpapers
GO
CREATE VIEW foreignpapers  AS
 select *
 from sec_paper
 where trading_platform!='moex'
GO
select *
from foreignpapers


--создадим триггер на вставку для представлений по ценным бумагам
drop trigger if exists insert_viewpapers_trigger; 
go

create trigger insert_viewpapers_trigger
    on foreignpapers
    instead of insert
    as
	begin 
	insert into foreignpapers(isin,trading_platform,issuer,price,amount)
	select isin,trading_platform,issuer,price,amount from inserted      --вставка значений с использованием select
	end
	go

	insert into foreignpapers(isin,trading_platform,issuer,price,amount) values ('us1843000231','nasdaq','netflix',2000,20000)


--создадим индексы на часто используемые поля при поиске 
DROP INDEX IF EXISTS client_ind ON companyclients
CREATE INDEX client_ind
ON companyclients(inn)
include(email,legal_form)
GO

DROP INDEX IF EXISTS contract_ind ON clientcontract
CREATE INDEX contract_ind
ON clientcontract(sign_date)
include(contract_period)
GO

DROP INDEX IF EXISTS deal_ind ON clientdeal
CREATE INDEX deal_ind
ON clientdeal(sign_date)
GO

--4 часть --обязательные запросы

--выберем ценные бумаги, которые использовались в сделках,  исключив повторы 
select distinct(isin)
from clientdeal

--выбор, упорядочивание и именование полей (создание псевдонимов для полей и таблиц/представлений)

select contract_number as number, contract_period as days_amount, total_sum
from clientcontract
where total_sum>15000000
order by total_sum

--соединение таблиц

--Выделим основную информацию
select cl.client_id,cl.legal_form,cl.email,cc.contract_number,cc.contract_period,cc.total_sum from companyclients as cl
right join clientcontract as cc on cc.client_id=cl.client_id

select cl.contract_number,cl.contract_period,cl.total_sum,cd.transaction_amount,cd.direction ,sp.isin, sp.issuer from clientcontract as cl
full outer join clientdeal as cd on cl.contract_number=cd.contract_id
full outer join sec_paper as sp on sp.isin=cd.isin

--информация о контракте для нового клиента войдет, а в полях со сделкой будет NULL

select cl.contract_number,cl.contract_period,cl.total_sum,cd.transaction_amount,cd.direction from clientcontract as cl 
left join  clientdeal as cd on cl.contract_number=cd.contract_id
--теперь left join относительно clientcontract, поэтому данные о новом   клиенте, пока не совершившем сделки на основании его поктракта, войдут в результат


--условия выбора записей (null/like/between/in/exists
--выберем контракты, заключенные недавно и отсортируем их  в порядке убывания
select *
from clientcontract
where sign_date between '2024-01-01' and '2024-06-01'                   --between
order by total_sum desc


--посмотрим, какие ценные бумаги американской фондовой биржи из представленной таблицы уже использовались в сделках
select *
from sec_paper 
where isin like 'us%' and isin in (select isin from clientdeal)         --in,like
order by price desc

--посмотрим,сколько в процентах управляющая компания вложила денег в акции относительно всех средств. очень большой % допускать опасно и нужно вкладываться в облигации
select sum(transaction_amount)/(select sum(total_sum) from clientcontract )*100 as percent_spent_on_actions
from clientdeal
where coupon_period is NULL and perc_of_pay is NULL                                                       --условия на акции

--exists и псевдонимы таблиц
--найдем все договоры, на основе которых пока не были заключены сделки
select *
from clientcontract as cc
where not exists (select * from clientdeal as cd where cc.contract_number=cd.contract_id)

--сортировка записей order by -asc desc
--группировка записей, использование аггрегирующих функций (sum/avg/count/min/max)

select contract_id,sum(transaction_amount) as total_spent,count(contract_id) as total_count, avg(transaction_amount) as mean_amount  
from clientdeal
group by contract_id
order by total_spent asc

--/min/max
select contract_id,min(sign_date) as min_date, max(sign_date) as max_date 
from clientdeal
group by contract_id
order by contract_id asc

--клиенты, заключившие больше одного контракта
select client_id,count(client_id) as contracts_count
from clientcontract
group by client_id
having count(client_id)>1

--найдем количество денег от каждого клиента уже было вложено в сделки в соответствии с договором
select client_id,sum(transaction_amount) as total_cost,count(transaction_amount) as count_of_deals
from clientdeal as cd 
full outer join (select contract_number,cc.client_id from clientcontract as cc left join companyclients as cl on cc.client_id=cl.client_id) as cn on cd.contract_id=cn.contract_number
group by client_id
having count(transaction_amount)>=1                                                                                                                                                       --можно убрать, тогда будет 4 клиент, который пока без сделок
order by sum(transaction_amount) desc

--union/inion all/except/intersect

--крупные и длительные контракты
select *
from clientcontract
where contract_period >740 --длительные контракты
union 
select *
from clientcontract
where total_sum>6000000 --крупные контракты

--крупные и длительные контракты с использованием union all
select *
from clientcontract
where contract_period >740
union all
select *
from clientcontract
where total_sum>6000000

--одновременно крупные и длительные контракты
select *
from clientcontract
where contract_period >740
intersect
select *
from clientcontract
where total_sum>6000000

--длительные контракты, не считая крупных
select *
from clientcontract
where contract_period >740
except
select *
from clientcontract
where total_sum>6000000

--обновление данных в price для ценной бумаги
update sec_paper
set  price=3000 where issuer='netflix'

update companyclients
set  j_adress='Moscow, Paslannikov per., h.5,b.9' where client_id=1

--прибыль от акций по каждой сделки
select cd.deal_id,cd.transaction_amount,cd.total_papers,cd.contract_id,cd.isin,sp.price, sp.amount,(cd.total_papers)*sp.price-cd.transaction_amount as result
from clientdeal as cd
join sec_paper as sp on cd.isin=sp.isin
where coupon_period is null

--прибыль от акций для каждого клиента на текущий момент
select client_id,sum(s.result) as actions_profit
from clientcontract
join
(select cd.contract_id,sum((cd.total_papers)*sp.price-cd.transaction_amount) as result
from clientdeal as cd
join sec_paper as sp on cd.isin=sp.isin
where coupon_period is null
group by contract_id) as s on clientcontract.contract_number=s.contract_id
group by client_id
--прибыль от облигаций для каждого клиента
select client_id,sum(s.percents) as obligations_profit
from clientcontract
join
(select contract_id,sum(dbo.percentspay(perc_of_pay,transaction_amount)) as percents
 from clientdeal
 group by contract_id)  as s on clientcontract.contract_number=s.contract_id
group by client_id

