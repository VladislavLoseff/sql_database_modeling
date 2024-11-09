use management_company1
go

DROP VIEW IF EXISTS clientsview
GO
/*создание представления на основе таблицы из прошлой лабораторной работы*/
CREATE VIEW clientsview  AS
SELECT *
FROM companyclients
WHERE legal_form=1
GO

select *
from clientsview
GO
/*теперь создадим представление на основе полей обеих связанных таблиц*/
DROP VIEW IF EXISTS twotablesview
GO


CREATE VIEW twotablesview  AS
SELECT cc.client_id,cc.inn,cco.total_sum,cco.sign_date,cco.contract_period
FROM companyclients AS cc JOIN clientcontract AS cco ON cc.client_id=cco.client_id
WHERE total_sum>5000000
--WITH CHECK OPTION
GO

SELECT *
FROM twotablesview

/*создание индекса и включение в него неключевых полей*/
--SELECT * FROM companyclients

DROP INDEX IF EXISTS client_ind ON companyclients


CREATE INDEX client_ind
ON companyclients(inn)
include(email,legal_form)
GO

select client_id,inn,email
from companyclients
where  inn='1749308428'
--
/*SET STATISTICS TIME ON
GO
SELECT * FROM companyclients
SET STATISTICS TIME OFF
GO*/

/*создание индексированного представления*/
/*CREATE UNIQUE CLUSTERED INDEX viewindex
ON clientsview(client_id,inn)
GO*/

--Set the options to support indexed views.
/*SET NUMERIC_ROUNDABORT OFF;
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, --из документации
   QUOTED_IDENTIFIER, ANSI_NULLS ON;*/

DROP VIEW IF EXISTS viewindex
GO

DROP VIEW IF EXISTS viewforindex
GO

CREATE VIEW viewforindex
   WITH SCHEMABINDING
   AS
      SELECT client_id,inn
      FROM dbo.companyclients --обязательно dbo. для пользовательских таблиц
GO


--DROP index  viewind1 on viewforindex
--GO


CREATE UNIQUE CLUSTERED INDEX viewind2
   ON viewforindex (client_id,inn);

   go


CREATE INDEX viewind1
   ON viewforindex (client_id,inn);
GO
DROP index  viewind1 on viewforindex
GO


DROP index  viewind2 on viewforindex
GO
--Невозможно создать индекс для представления "viewindex". Отсутствует уникальный кластеризованный индекс.-