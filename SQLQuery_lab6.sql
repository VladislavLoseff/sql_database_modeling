USE  master;
GO 
IF DB_ID (N'management_company1') IS NOT NULL 
DROP DATABASE management_company1;
GO

CREATE DATABASE management_company1;
go
USE  management_company1;
GO 
CREATE TABLE client (client_id int identity(1,1) not null  primary key,
inn CHAR(10)  not null,
j_adress varchar(100) not null,
legal_form smallint,
email varchar(100) not null)
go

insert into client values (1749308428,'Moscow, Paslannikov per., h.5,b.1',1,'catcomp@mail.ru')
insert into client values (5828502174,'Moscow, Gospitalny per., h.2',1,'anothercomp@mail.ru')
insert into client values (4936799397,'Moscow, brigadirsky per., h.5,b.3',2,'insurancecomp@mail.ru')

select *
from client;
--все работает. С использованием identity был создан суррогатный первичный ключ

--теперь используем guid
CREATE TABLE client1 (client_id  uniqueidentifier rowguidcol default newid() primary key,
inn CHAR(10)  not null,
j_adress varchar(100) not null,
legal_form smallint,
email varchar(100) not null)
go

insert into client1 values (newid(),1749308428,'Moscow, Paslannikov per., h.5,b.1',1,'catcomp@mail.ru')
insert into client1 values (newid(),5828502174,'Moscow, Gospitalny per., h.2',1,'anothercomp@mail.ru')
insert into client1 values (newid(),4936799397,'Moscow, brigadirsky per., h.5,b.3',2,'insurancecomp@mail.ru')
go
--уже получились автоматически сгенерированные значения
select *
from client1;

--теперь будем использовать sequence

CREATE TABLE client2 (client_id  int not null primary key,
inn CHAR(10)  not null,
j_adress varchar(100) not null,
legal_form smallint,
email varchar(100) not null)
go

--создаем sequence
CREATE SEQUENCE mysequence
    START WITH 2
	INCREMENT BY 2;
	GO



insert into client2 values (NEXT VALUE FOR mysequence,1749308428,'Moscow, Paslannikov per., h.5,b.1',1,'catcomp@mail.ru')
insert into client2 values (NEXT VALUE FOR mysequence,5828502174,'Moscow, Gospitalny per., h.2',1,'anothercomp@mail.ru')
insert into client2 values (NEXT VALUE FOR mysequence,4936799397,'Moscow, brigadirsky per., h.5,b.3',2,'insurancecomp@mail.ru')
go

select *
from client2;
--все работает

--можем потом удалить эти созданные таблицы
--теперь создадим две таблицы и протестируем на них различные варианты действия для ограничения ссылочной целостности
-- а также добавим поля с ограничениями check и default
CREATE TABLE companyclients (client_id  int identity(1,1) not null  primary key,--not null primary key,
inn CHAR(10)  not null,
j_adress varchar(100) not null,
legal_form smallint,
email varchar(100) not null,
CONSTRAINT check_legal_form CHECK(legal_form in (1,2,3))
)
go

--создадим таблицу с договором клиента
CREATE TABLE clientcontract (contract_number int not null primary key,
sign_date date  not null,
contract_period int not null default 365, --по умолчанию будет год
total_sum float not null,
invest_daclaration varchar(100) not null,
client_id int not null--default 1-- /*not null -- убираем для ограничения SET NULL и SET DEFAULT если не задано значение по умолчанию*/                  /*references companyclients(client_id)*/,
constraint fc_clientcontr foreign key(client_id) references companyclients(client_id)   --лучше так использовать создавать ограничения? чтобы потом было проще редактировать
ON DELETE CASCADE
ON UPDATE CASCADE
--по умолчанию будет no action

/*ON DELETE SET NULL
ON UPDATE SET NULL*/
/*ON DELETE SET DEFAULT--надо добавить значения по умолчанию 
ON UPDATE SET DEFAULT */

)
go

--insert into companyclients values (1749308428,'Moscow, Paslannikov per., h.5,b.1',5,'catcomp@mail.ru');
--тут возникает ошибка из-за ограничения check, так как в legal_form указали 5. Все как и должно быть

insert into companyclients values (1749308428,'Moscow, Paslannikov per., h.5,b.1',1,'catcomp@mail.ru')
insert into companyclients values (5828502174,'Moscow, Gospitalny per., h.2',1,'anothercomp@mail.ru')
insert into companyclients values (4936799397,'Moscow, brigadirsky per., h.5,b.3',2,'insurancecomp@mail.ru');

insert into clientcontract values (2,'2023-11-12',270,5000000,'only using obligations',1)
insert into clientcontract values (5,'2023-10-01',180,10000000,'actions<20%',2)
insert into clientcontract values (7,'2024-02-12',365,15000000,'obligations>70%',3);

/*select *
from clientcontract;*/

--зададим условия no action
--delete from companyclients where client_id=2; --поскольку стоит no action, то выполнение было прервано и возникла ошибка

--теперь раскомментируем условие cascade и заново запустим скрипт
/*delete from companyclients where client_id=2;
select *
from companyclients;*/
/*select *
from clientcontract;*/
--Все сработало, произошло каскадное удаление строк таблицы clientcontract, где client_id=2 и это foreign key по отношению к таблице companyclients


--теперь зададим условие SET NULL 
/*delete from companyclients where client_id=2;

select *
from clientcontract;*/
--все работает как и должно быть. Только пришлось снимать ограничения not null в первичных ключах и в constraint

--для set default зададим значения по умолчанию
/*delete from companyclients where client_id=2;
select *
from clientcontract;*/--если значение по умолчанию не задано, то будет null. Зададим значение по умолчанию, чтобы оно совпадало со значением pk род. таблицы



/*****************************************************************/
/***тут можно заполнить все для итоговой 11 лабы***/
--пока есть таблицы companyclients и clientcontract, заполним их значениями еще и добавим новые таблицы

--при заполнении лучше у таблицы перечислить столбцы. И изменить другие данные
--insert into companyclients values (1749308428,'Moscow, Starokirochny per., h.3,b.2',3,'catcomp@mail.ru')
--insert into companyclients values (5828502174,'Moscow, Technichesky per., h.8',1,'anothercomp@mail.ru')
--insert into companyclients values (4936799397,'Moscow, Rubtsov per., h.12,b.1',3,'insurancecomp@mail.ru');

--insert into clientcontract values (2,'2023-11-12',270,5000000,'only using obligations',4)
--insert into clientcontract values (5,'2023-10-01',180,10000000,'actions<20%',5)
--insert into clientcontract values (7,'2024-02-12',365,15000000,'obligations>70%',6);


--создаем таблицу с данными о ценных бумагах
CREATE TABLE sec_paper (isin char(12) not null primary key,
trading_platform varchar(100),
issuer varchar(100) not null,
price int not null,
amount int not null
)
go

insert into sec_paper(isin,trading_platform,issuer,price,amount) values('ru1638429872','moex','sber',1000,5000)
insert into sec_paper(isin,trading_platform,issuer,price,amount) values('ru8739065119','moex','yandex',3000,4000)
insert into sec_paper(isin,trading_platform,issuer,price,amount) values('ru1197536784','moex','vtb',5000,6000)
--теперь создаем сделку
/*
CREATE TABLE clientdeal (deal_id  int identity(1,1) not null  primary key,
direction smallint not null default 1,--направление сделки -1,1
sign_date date  not null,
transaction_amount float not null , 
total_papers int not null,
coupon_period int , --null для акций
perc_of_pay float, --null для акций
contract_id int not null,
isin char(12) not null
constraint fc_contr foreign key(contract_id) references clientcontract(contract_number)  ,
constraint fc_isin foreign key(isin) references sec_paper(isin) 
ON DELETE CASCADE
ON UPDATE CASCADE --подумать еще над ограничениями
)
go

insert into clientdeal(direction,sign_date,transaction_amount,total_papers,coupon_period,perc_of_pay,contract_id,isin) 
values(-1,'2023-11-11',1000000,1000,NULL,NULL,2,'ru1638429872')--deal_id не указываем т.к. он формируется с identity
insert into clientdeal(direction,sign_date,transaction_amount,total_papers,coupon_period,perc_of_pay,contract_id,isin) 
values(1,'2023-12-11',3000000,1000,2,12,2,'ru8739065119')
insert into clientdeal(direction,sign_date,transaction_amount,total_papers,coupon_period,perc_of_pay,contract_id,isin) 
values(1,'2023-09-10',30000000,5000,NULL,NULL,5,'ru1197536784')

--далее добавить индексы, представления , функции и т.д. Навесить больше возможностей и добавить новые данные*/