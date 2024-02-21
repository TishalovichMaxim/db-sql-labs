--�������� ��� ���������� �� �������.

SELECT * FROM [authors];

--�������� ��� ���������� �������������� ����, ������� ���� ����� ����������.

SELECT DISTINCT [sb_book] FROM [subscriptions];

--�������� �� ������ �����, ������� �������� ����� � ����������, ���������� ����� ���� ����� ���������.

SELECT [sb_book], COUNT(*) AS [count] FROM [subscriptions] GROUP BY [sb_book];

-- �������� ������ � ��������� ���� ������ ����� ��������.

SELECT
	MIN([sb_start]) AS [first date],
	MAX([sb_start]) AS [last date]
FROM [subscriptions];

--�������� ������ ������� � �������� ���������� ������� (�.�. ��  ��).

SELECT [a_name] FROM [authors] ORDER BY [a_name] DESC;

--�������� �����, ���������� ����������� ������� ������ �������� �� ����������.

SELECT * FROM [books]
	WHERE [b_quantity] < (SELECT AVG(CAST([b_quantity] AS FLOAT)) FROM [books]);

--�������� �������������� � ���� ������ ���� �� ������ ��� ������ ���������� (������ ����� ������ ���������� ������� ��� ���� � ������ ������ ����� �� 31-� ������� (������������) ���� ����, ����� ���������� ������ ��������).

SELECT [sb_book] FROM [subscriptions]
WHERE YEAR([sb_start]) = YEAR((SELECT MIN([sb_start]) FROM [subscriptions]));

--�������� ������������� ������ (������) ��������, �������� � ���������� ������ ����� ����.

SELECT TOP 1 [sb_subscriber]
FROM [subscriptions]
GROUP BY [sb_subscriber] ORDER BY COUNT(*) DESC;

--�������� �������������� ���� ������ �������� ���������, ������� � ���������� ������ ����� ����.

WITH [subs_receives] ([sub_id], [count])
AS
(
	SELECT [sb_subscriber], COUNT(*)
	FROM [subscriptions]
	GROUP BY [sb_subscriber]
)

SELECT [sub_id] FROM [subs_receives]
WHERE [count] = (SELECT MAX([count]) FROM [subs_receives]);

--�������� ������������� ���������-�����������, �������� � ���������� ������ ����, ��� ����� ������ ��������.

WITH [subs_receives] ([sub_id], [count])
AS
(
	SELECT [sb_subscriber], COUNT(*)
	FROM [subscriptions]
	GROUP BY [sb_subscriber]
)

SELECT [sub_id] FROM [subs_receives] AS [ext]
WHERE [count] > (SELECT MAX([count]) FROM [subs_receives] as [int] WHERE [ext].[sub_id] <> [int].[sub_id]);

--��������, ������� � ������� ����������� ���� ���� � ����������.

SELECT AVG(CAST([b_quantity] AS FLOAT)) FROM [books];

--�������� � ����, ������� � ������� ������� �������� ��� ���������������� � ���������� (�������� ����������� ������� �������� �� ������ ���� ��������� ��������� ����� �� ������� ����).

SELECT AVG(CAST([registration_duration] AS FLOAT)) FROM
	(SELECT DATEDIFF(day, MIN([sb_start]), CAST(GETDATE() AS Date)) AS [registration_duration]
	FROM [subscriptions]
	GROUP BY [sb_subscriber]) AS [res];

--��������, ������� ���� ���� ���������� � �� ���������� � ���������� (���� ������ ����������� ��������� ���������� ���� sb_is_active (�.�. �Y� � �N�), � ����� �������� �������� �Y� � �N� ������ ���� ������������� � �Returned� � �Not returned�).

SELECT CASE
			WHEN [sb_is_active] = 'Y' THEN 'Returned'
			ELSE 'Not returned'
		END AS [returned],
		COUNT(*) FROM [subscriptions]
GROUP BY [sb_is_active];
