use master
go

use mc
go


----------------------------------------------------------
--в результате грязного чтения будут изменения внесенные незавершенной транзакцией
set transaction isolation level read uncommitted --возможны все проблемы
begin transaction
select * 
from companyclients
commit transaction -- наверно явно не обязательо прописывать . просто для примера
----------------------------------
--
set transaction isolation level read committed --невозможно грязное чтение, можно попробовать для первого примера и как раз видна разница
select *                                                        --когда там происходит delay, то ничего не обновляется и не запускается здесь. уровень по умолчанию
from companyclients       
--отрабатывает уже когда задержка закончилась и на прошлой транзакции все обновилось


--------------------------------
--set transaction isolation level repeatable read
--изменение данных. пример для невоспроизводимого чтение
update companyclients
set legal_form=1
where client_id=2
   -- при update и 
   -- при update и delete

   -----------------------
   --теперь для фантомного чтения. То есть в момент выполнения транзакции должна быть ставка данных 
   --которая видна при повторном чтении в рамках той же транзакции

   
   insert into companyclients values (9993679939,'Moscow, tolmachevsky per., h.5,b.3',2,'ins@mail.ru');
   delete from companyclients where inn=9993679939


   /*
   insert into clientcontract values (91,'2023-11-10',365,100000,'only using obligations',3)
      delete from clientcontract where contract_number=91*/