--Показать всю информацию об авторах.

SELECT * FROM [authors];

--Показать без повторений идентификаторы книг, которые были взяты читателями.

SELECT DISTINCT [sb_book] FROM [subscriptions];

--Показать по каждой книге, которую читатели брали в библиотеке, количество выдач этой книги читателям.

SELECT [sb_book], COUNT(*) AS [count] FROM [subscriptions] GROUP BY [sb_book];

-- Показать первую и последнюю даты выдачи книги читателю.

SELECT
	MIN([sb_start]) AS [first date],
	MAX([sb_start]) AS [last date]
FROM [subscriptions];

--Показать список авторов в обратном алфавитном порядке (т.е. «Я  А»).

SELECT [a_name] FROM [authors] ORDER BY [a_name] DESC;

--Показать книги, количество экземпляров которых меньше среднего по библиотеке.

SELECT * FROM [books]
	WHERE [b_quantity] < (SELECT AVG(CAST([b_quantity] AS FLOAT)) FROM [books]);

--Показать идентификаторы и даты выдачи книг за первый год работы библиотеки (первым годом работы библиотеки считать все даты с первой выдачи книги по 31-е декабря (включительно) того года, когда библиотека начала работать).

SELECT [sb_book] FROM [subscriptions]
WHERE YEAR([sb_start]) = YEAR((SELECT MIN([sb_start]) FROM [subscriptions]));

--Показать идентификатор одного (любого) читателя, взявшего в библиотеке больше всего книг.

SELECT TOP 1 [sb_subscriber]
FROM [subscriptions]
GROUP BY [sb_subscriber] ORDER BY COUNT(*) DESC;

--Показать идентификаторы всех «самых читающих читателей», взявших в библиотеке больше всего книг.

WITH [subs_receives] ([sub_id], [count])
AS
(
	SELECT [sb_subscriber], COUNT(*)
	FROM [subscriptions]
	GROUP BY [sb_subscriber]
)

SELECT [sub_id] FROM [subs_receives]
WHERE [count] = (SELECT MAX([count]) FROM [subs_receives]);

--Показать идентификатор «читателя-рекордсмена», взявшего в библиотеке больше книг, чем любой другой читатель.

WITH [subs_receives] ([sub_id], [count])
AS
(
	SELECT [sb_subscriber], COUNT(*)
	FROM [subscriptions]
	GROUP BY [sb_subscriber]
)

SELECT [sub_id] FROM [subs_receives] AS [ext]
WHERE [count] > (SELECT MAX([count]) FROM [subs_receives] as [int] WHERE [ext].[sub_id] <> [int].[sub_id]);

--Показать, сколько в среднем экземпляров книг есть в библиотеке.

SELECT AVG(CAST([b_quantity] AS FLOAT)) FROM [books];

--Показать в днях, сколько в среднем времени читатели уже зарегистрированы в библиотеке (временем регистрации считать диапазон от первой даты получения читателем книги до текущей даты).

SELECT AVG(CAST([registration_duration] AS FLOAT)) FROM
	(SELECT DATEDIFF(day, MIN([sb_start]), CAST(GETDATE() AS Date)) AS [registration_duration]
	FROM [subscriptions]
	GROUP BY [sb_subscriber]) AS [res];

--Показать, сколько книг было возвращено и не возвращено в библиотеку (СУБД должна оперировать исходными значениями поля sb_is_active (т.е. «Y» и «N»), а после подсчёта значения «Y» и «N» должны быть преобразованы в «Returned» и «Not returned»).

SELECT CASE
			WHEN [sb_is_active] = 'Y' THEN 'Returned'
			ELSE 'Not returned'
		END AS [returned],
		COUNT(*) FROM [subscriptions]
GROUP BY [sb_is_active];
