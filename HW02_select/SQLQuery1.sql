USE WideWorldImporters
--1. ��� ������, � �������� ������� ���� "urgent" ��� �������� ���������� � "Animal". �������: �� ������, ������������ ������.
--�������: Warehouse.StockItems.
select
		StockItemID,StockItemName
from Warehouse.StockItems
where
	StockItemName like '%urgent%' or StockItemName like 'Animal%';

--2. ����������� (Suppliers), � ������� �� ���� ������� �� ������ ������ (PurchaseOrders). ������� ����� JOIN, � ����������� ������� ������� �� �����. �������: �� ����������, ������������ ����������.
--�������: Purchasing.Suppliers, Purchasing.PurchaseOrders.
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

--3. ������ (Orders) � ����� ������ ����� 100$ ���� ����������� ������ ������ ����� 20 ���� � �������������� ����� ������������ ����� ������ (PickingCompletedWhen).
--�������:
--* OrderID
--* ���� ������ � ������� ��.��.����
--* �������� ������, � ������� ���� �������
--* ����� ��������, � �������� ��������� �������
--* ����� ����, � ������� ��������� ���� ������� (������ ����� �� 4 ������)
--* ��� ��������� (Customer)
--�������� ������� ����� ������� � ������������ ��������, ��������� ������ 1000 � ��������� ��������� 100 �������. ���������� ������ ���� �� ������ ��������, ����� ����, ���� ������ (����� �� �����������).
--�������: Sales.Orders, Sales.OrderLines, Sales.Customers.
select s.OrderID,format(s.OrderDate,'dd.MM.yyyy') as ����, month(s.OrderDate) as �����,
		datepart(qq,s.OrderDate) as �������,
		/*(case 
		when  month(s.OrderDate) between '1' and '4' then '1'		-- �������������� �������
		when  month(s.OrderDate) between '5' and '8' then '2'
		else '3'
		end)*/
		ceiling (convert(float, month(s.orderdate))/4) as �����_����,
		t.UnitPrice,t.Quantity,t.PickingCompletedWhen, z.CustomerName
from Sales.Orders s, Sales.OrderLines t, Sales.Customers z
where
	s.OrderID=t.OrderID and
	z.CustomerID=s.CustomerID and
	(UnitPrice>100 or Quantity>20)and
	t.PickingCompletedWhen is not null
order by �������, �����_����, ����  --���������� �������
offset 1000 rows fetch first 100 rows only; --������������ ��������


--4. ������ ����������� (Purchasing.Suppliers), ������� ���� ��������� � ������ 2014 ���� � ��������� Air Freight ��� Refrigerated Air Freight (DeliveryMethodName).
--�������:
--* ������ �������� (DeliveryMethodName)
--* ���� ��������
--* ��� ����������
--* ��� ����������� ���� ������������ ����� (ContactPerson)
--�������: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
select 
	c.DeliveryMethodName as [������ ��������],
	b.ExpectedDeliveryDate as [���� ��������],
	a.SupplierName as [��� ����������],
	d.FullName as [��� ����������� ����]
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
Order by [���� ��������]; 



--5. ������ ��������� ������ (�� ����) � ������ ������� � ������ ����������, ������� ������� ����� (SalespersonPerson).
select top(10) a.InvoiceDate as [���� �������],
					b.FullName as [��� �������],
					c.FullName as [��� ����������]
from 
		Sales.Invoices a
		inner join Application.People b
				on AccountsPersonID=PersonID
		inner join Application.People c
				on SalespersonPersonID=c.PersonID
Order by InvoiceDate desc;



--6. ��� �� � ����� �������� � �� ���������� ��������, ������� �������� ����� Chocolate frogs 250g. ��� ������ �������� � Warehouse.StockItems.
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


--7. ��������� ������� ���� ������, ����� ����� ������� �� �������

--�������:
--* ��� �������
--* ����� �������
--* ������� ���� �� ����� �� ���� �������
--* ����� ����� ������

--������� �������� � ������� Sales.Invoices � ��������� ��������.
select   
		year(b.InvoiceDate) as [��� �������],
		month(b.InvoiceDate) as [����� �������],
		avg(a.UnitPrice)as[������� ����],
		sum(a.Quantity) as [����������],
		sum(a.UnitPrice) as [����� ���������]
from
			Sales.OrderLines a 
		join Sales.Invoices b 
					on a.OrderID=b.OrderID
Group by year(b.InvoiceDate),month(b.InvoiceDate)
Order by year(b.InvoiceDate),month(b.InvoiceDate);


--8. ���������� ��� ������, ��� ����� ����� ������ ��������� 10 000

--�������:
--* ��� �������
--* ����� �������
--* ����� ����� ������

--������� �������� � ������� Sales.Invoices � ��������� ��������.
select 
		year(b.InvoiceDate) as [��� �������],
		month(b.InvoiceDate) as [����� �������],
		sum(a.Quantity) as [����������],
		sum(a.UnitPrice) as [����� ���������]
from
			Sales.OrderLines a
		join Sales.Invoices b
					on a.OrderID=b.OrderID
Group by year(b.InvoiceDate),month(b.InvoiceDate)
Having sum(a.UnitPrice)>10000
Order by year(b.InvoiceDate),month(b.InvoiceDate)

--9. ������� ����� ������, ���� ������ ������� � ���������� ���������� �� �������, �� �������, ������� ������� ����� 50 �� � �����.
--����������� ������ ���� �� ����, ������, ������.

--�������:
--* ��� �������
--* ����� �������
--* ������������ ������
--* ����� ������
--* ���� ������ �������
--* ���������� ����������

--������� �������� � ������� Sales.Invoices � ��������� ��������.
select   year(b.InvoiceDate) as [��� �������],
			MONTH(b.InvoiceDate) as [����� �������],
			a.Description as [������������ ������],
			min(b.InvoiceDate) as [���� ������ �������],
			sum(a.Quantity) as [���������� ����������]
from 
			Sales.OrderLines a
			join Sales.Invoices b
						on a.OrderID=b.OrderID
Group by year(b.InvoiceDate),month(b.InvoiceDate), a.Description
Having sum(a.Quantity)<50
Order by year(b.InvoiceDate),month(b.InvoiceDate), a.Description
