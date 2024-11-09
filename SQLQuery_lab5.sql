USE  master;
GO 
IF DB_ID (N'Management_company') IS NOT NULL 
DROP DATABASE Management_company;
GO

CREATE DATABASE Management_company
ON (NAME=management_data,FILENAME="C:\data\management.mdf",SIZE=50,MAXSIZE=1000, FILEGROWTH=5)
LOG ON (NAME=management_log,FILENAME="C:\data\managementlog.ldf",SIZE=5MB,MAXSIZE=50MB, FILEGROWTH=5MB);
GO


USE  Management_company;
GO 
CREATE TABLE client (inn CHAR(10) not null primary key,
j_adress varchar(100) not null,
legal_form smallint,
email varchar(100) not null)

insert into client(inn,j_adress,legal_form,email) values (1254678532,'st tverskaya, h 5 ',1,'firstmail@mail.ru'),
(1654698539,'st tverskaya, h 10 ',2,'secondmail@mail.ru');

--все работает нормально
--select *
--from client;

use Management_company;
GO
ALTER DATABASE Management_company
ADD FILEGROUP MyFileGroup;
GO
ALTER DATABASE Management_company
ADD FILE(NAME=testdata,filename="C:\data\managementtestdata.ndf",size=5MB,MAXSIZE=100MB,FILEGROWTH=5MB)
TO FILEGROUP MyFileGroup;

--сделайте созданную файловую группу группой по умолчанию
ALTER DATABASE Management_company MODIFY FILEGROUP MyFileGroup DEFAULT;
GO
---  
--use Management_company;
GO
CREATE TABLE securitypaper (isin CHAR(12) not null primary key,
tradingplace varchar(100),
issure varchar(100) not null ,
currentprice float  not null,
volume int not null) --ON MyFileGroup -- новую таблицу нужно было записывать в новую файловую группу. Но раз она по умолчанию то наверно не обязательно 

insert into securitypaper(isin,tradingplace,issure,currentprice,volume) values ('RU1254678532','usa_place','sber',1400,5000),
('RU1654698539','europe_place','gazprom',1300,2000);

--select *
--from securitypaper;
--удаляем созданную вручную файловую группу. То есть сначала удаляем таблицу, потом файл, потом filegroup
DROP TABLE IF EXISTS securitypaper;
--То есть таблица удалилась, а файл не удаляется так как он явл единственным в файловой группе default Из-за этого последние 2 команды не работают. Изменим ее как 
--в статье от microsoft и тогда удалим, сделав [Primary] DEFAULT. 
--USE Management_company;
GO
ALTER DATABASE Management_company MODIFY FILEGROUP [Primary] DEFAULT;
GO
--USE Management_company;
GO
ALTER DATABASE Management_company REMOVE FILE testdata;
GO 
--USE Management_company;
GO
ALTER DATABASE Management_company REMOVE FILEGROUP MyFileGroup;
GO

--файловая группа удалилась , теперь файла из тестовой группы нет в соответствующей директории
--7
CREATE SCHEMA company;
GO

ALTER SCHEMA company TRANSFER client;
GO
DROP TABLE company.client;--а если company.client то подчеркнута красным,почему так, хотя команда отработала. Делал как в примере со схемой Sprockets.NineProngs из документации. 
--Таблица удалилась

GO
DROP SCHEMA company;
GO

