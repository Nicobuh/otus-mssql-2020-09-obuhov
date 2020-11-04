USE WideWorldImporters
--1. Все товары, в названии которых есть "urgent" или название начинается с "Animal". Вывести: ИД товара, наименование товара.
--Таблицы: Warehouse.StockItems.
select
		StockItemID,StockItemName
from Warehouse.StockItems
where
	StockItemName like '%urgent%' or StockItemName like 'Animal%';

--2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders). Сделать через JOIN, с подзапросом задание принято не будет. Вывести: ИД поставщика, наименование поставщика.
--Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
SELECT   
  s.SupplierID,
  s.SupplierName
FROM 
			Purchasing.Suppliers s
	Left JOIN Purchasing.PurchaseOrders t 
					ON t.SupplierID = s.SupplierID
WHERE 
	t.PurchaseOrderID is null
ORDER BY s.SupplierID;

--3. Заказы (Orders) с ценой товара более 100$ либо количеством единиц товара более 20 штук и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
--Вывести:
--* OrderID
--* дату заказа в формате ДД.ММ.ГГГГ
--* название месяца, в котором была продажа
--* номер квартала, к которому относится продажа
--* треть года, к которой относится дата продажи (каждая треть по 4 месяца)
--* имя заказчика (Customer)
--Добавьте вариант этого запроса с постраничной выборкой, пропустив первую 1000 и отобразив следующие 100 записей. Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).
--Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
select s.OrderID,format(s.OrderDate,'dd.MM.yyyy') as Дата, month(s.OrderDate) as Месяц,
		datepart(qq,s.OrderDate) as Квартал,
		/*(case 
		when  month(s.OrderDate) between '1' and '4' then '1'		-- Альтернативное решение
		when  month(s.OrderDate) between '5' and '8' then '2'
		else '3'
		end)*/
		ceiling (convert(float, month(s.orderdate))/4) as Треть_года,
		t.UnitPrice,t.Quantity,t.PickingCompletedWhen, z.CustomerName
from Sales.Orders s, Sales.OrderLines t, Sales.Customers z
where
	s.OrderID=t.OrderID and
	z.CustomerID=s.CustomerID and
	(UnitPrice>100 or Quantity>20)and
	t.PickingCompletedWhen is not null
order by Квартал, Треть_года, Дата  --сортировка записей
offset 1000 rows fetch first 100 rows only; --постраничная выгрузка


--4. Заказы поставщикам (Purchasing.Suppliers), которые были исполнены в январе 2014 года с доставкой Air Freight или Refrigerated Air Freight (DeliveryMethodName).
--Вывести:
--* способ доставки (DeliveryMethodName)
--* дата доставки
--* имя поставщика
--* имя контактного лица принимавшего заказ (ContactPerson)
--Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
select 
	c.DeliveryMethodName as [способ доставки],
	b.ExpectedDeliveryDate as [дата доставки],
	a.SupplierName as [имя поставщика],
	d.FullName as [имя контактного лица]
from 
		Purchasing.Suppliers a,
		Purchasing.PurchaseOrders b,
		Application.DeliveryMethods c,
		Application.People d
where
	c.DeliveryMethodID=b.DeliveryMethodID and
	b.ContactPersonID=d.PersonID and
	a.SupplierID=b.SupplierID and
	DeliveryMethodName in ('Air Freight','Refrigerated Air Freight') and
	ExpectedDeliveryDate between '01.01.2014' and '31.01.2014'
Order by [дата доставки]; 



--5. Десять последних продаж (по дате) с именем клиента и именем сотрудника, который оформил заказ (SalespersonPerson).
select top(10) a.InvoiceDate as [Дата продажи],
					b.FullName as [Имя клиента],
					c.FullName as [Имя сотрудника]
from 
		Sales.Invoices a
		inner join Application.People b
				on AccountsPersonID=PersonID
		inner join Application.People c
				on SalespersonPersonID=c.PersonID
Order by InvoiceDate desc;



--6. Все ид и имена клиентов и их контактные телефоны, которые покупали товар Chocolate frogs 250g. Имя товара смотреть в Warehouse.StockItems.
select distinct a.PersonID, a.FullName, a.PhoneNumber
from 
				Application.People a
			join Sales.Invoices b
					on b.AccountsPersonID=a.PersonID
			join Warehouse.StockItemTransactions c
					on b.InvoiceID=c.InvoiceID
			join Warehouse.StockItems d
					on d.StockItemID=c.StockItemID and d.StockItemName in ('Chocolate frogs 250g')
Order by a.PersonID;


--7. Посчитать среднюю цену товара, общую сумму продажи по месяцам

--Вывести:
--* Год продажи
--* Месяц продажи
--* Средняя цена за месяц по всем товарам
--* Общая сумма продаж

--Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
select   
		year(b.InvoiceDate) as [Год продажи],
		month(b.InvoiceDate) as [Месяц продажи],
		avg(a.UnitPrice)as[Средняя цена],
		sum(a.Quantity) as [Количество],
		sum(a.UnitPrice) as [Общая стоимость]
from
			Sales.OrderLines a 
		join Sales.Invoices b 
					on a.OrderID=b.OrderID
Group by year(b.InvoiceDate),month(b.InvoiceDate)
Order by year(b.InvoiceDate),month(b.InvoiceDate);


--8. Отобразить все месяцы, где общая сумма продаж превысила 10 000

--Вывести:
--* Год продажи
--* Месяц продажи
--* Общая сумма продаж

--Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
select 
		year(b.InvoiceDate) as [Год продажи],
		month(b.InvoiceDate) as [Месяц продажи],
		sum(a.Quantity) as [Количество],
		sum(a.UnitPrice) as [Общая стоимость]
from
			Sales.OrderLines a
		join Sales.Invoices b
					on a.OrderID=b.OrderID
Group by year(b.InvoiceDate),month(b.InvoiceDate)
Having sum(a.UnitPrice)>10000
Order by year(b.InvoiceDate),month(b.InvoiceDate)

--9. Вывести сумму продаж, дату первой продажи и количество проданного по месяцам, по товарам, продажи которых менее 50 ед в месяц.
--Группировка должна быть по году, месяцу, товару.

--Вывести:
--* Год продажи
--* Месяц продажи
--* Наименование товара
--* Сумма продаж
--* Дата первой продажи
--* Количество проданного

--Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
select   year(b.InvoiceDate) as [Год продажи],
			MONTH(b.InvoiceDate) as [Месяц продажи],
			a.Description as [Наименование товара],
			min(b.InvoiceDate) as [Дата первой продажи],
			sum(a.Quantity) as [Количество проданного]
from 
			Sales.OrderLines a
			join Sales.Invoices b
						on a.OrderID=b.OrderID
Group by year(b.InvoiceDate),month(b.InvoiceDate), a.Description
Having sum(a.Quantity)<50
Order by year(b.InvoiceDate),month(b.InvoiceDate), a.Description
