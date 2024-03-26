USE [library]

--9. Удалить информацию обо всех выдачах книг, произведённых после 20-го числа любого месяца любого года.

DELETE FROM
	[subscriptions]
WHERE
	DATEPART(DD, [sb_start]) > 20

--10. Добавить в базу данных жанры «Политика», «Психология», «История».

MERGE INTO
	[genres]
USING
	(VALUES
	('Политика'),
	('Психология'),
	('История')) AS [new_genres] ([g_name])
ON
	[genres].[g_name] = [new_genres].[g_name]
WHEN NOT MATCHED THEN
	INSERT ([g_name]) VALUES ([new_genres].[g_name]);

--11. Создать таблицу “subscribers_tmp” с такой же структурой, как у таблицы “subscribers”.
--Поместить в таблицу “subscribers_tmp” информацию о десяти случайных подписчиках.
--Скопировать (без повторений) содержимое таблицы “subscribers_tmp” в таблицу “subscribers”;
--в случае совпадения первичных ключей добавить к существующему имени читателя слово « [OLD]».

DROP TABLE IF EXISTS [subscribers_tmp]

CREATE TABLE [subscribers_tmp]
(
	[s_id] int NOT NULL IDENTITY (1, 1),
	[s_name] nvarchar(150) NOT NULL
)

ALTER TABLE [subscribers_tmp] 
 ADD CONSTRAINT [PK_subscribers_tmp]
	PRIMARY KEY CLUSTERED ([s_id] ASC)

INSERT INTO
	[subscribers_tmp]
	([s_name])
VALUES
	(N'Петров П.П.'),
	(N'Сидоров С.С.'),
	(N'Тишалович М.А.'),
	(N'Фамилия1 М.А.'),
	(N'Фамилия2 М.А.'),
	(N'Фамилия3 М.А.'),
	(N'Фамилия4 М.А.'),
	(N'Фамилия5 М.А.'),
	(N'Фамилия6 М.А.'),
	(N'Фамилия7 М.А.')

SET IDENTITY_INSERT [dbo].[subscribers] ON

MERGE INTO 
	[subscribers]
USING
	[subscribers_tmp]
ON
	[subscribers].[s_id] = [subscribers_tmp].[s_id]
WHEN MATCHED 
	THEN UPDATE SET [s_name] = CONCAT([subscribers].[s_name], ' [OLD]')
WHEN NOT MATCHED
	THEN INSERT ([s_id], [s_name]) VALUES ([subscribers_tmp].[s_id], [subscribers_tmp].[s_name]);

SET IDENTITY_INSERT [dbo].[subscribers] OFF

--12. Добавить в базу данных читателей с именами «Сидоров С.С.», «Иванов И.И.», «Орлов О.О.»;
--если читатель с таким именем уже существует, добавить в конец имени нового читателя порядковый номер в квадратных скобках 
--(например, если при добавлении читателя «Сидоров С.С.» выяснится, что в базе данных уже есть четыре таких читателя,
--имя добавляемого должно превратиться в «Сидоров С.С. [5]»).

INSERT INTO
	[subscribers]
SELECT
	CASE
		WHEN (SELECT COUNT(*) FROM [subscribers] WHERE [s_name] = [new].[s_name]) > 0
			THEN
				CONCAT([s_name], ' [', (SELECT COUNT(*) FROM [subscribers] WHERE [s_name] = [new].[s_name]),']')
			ELSE
				[s_name]
	END
FROM
	(VALUES
	(N'Сидоров С.С.'),
	(N'Иванов И.И.'),
	(N'Орлов О.О')) AS [new] ([s_name])

--13. Обновить все имена авторов, добавив в конец имени « [+]», если в библиотеке есть более трёх книг этого автора,
--или добавив в конец имени « [-]» в противном случае.

WITH [authors_to_n_books] ([a_id], [n_books])
AS
(
	SELECT
		[authors].[a_id],
		(CASE WHEN
			SUM([b_quantity]) IS NULL
		THEN
			0
		ELSE
			SUM([b_quantity])
		END)
	FROM
		[authors]
		LEFT JOIN [m2m_books_authors]
			ON [authors].[a_id] = [m2m_books_authors].[a_id]
		LEFT JOIN [books]
			ON [m2m_books_authors].[b_id] = [books].[b_id]
	GROUP BY
		[authors].[a_id]
)

UPDATE
	[authors]
SET
	[a_name] = CONCAT(
		[a_name],
		CASE
			WHEN
				(SELECT
					[n_books]
				FROM
					[authors_to_n_books]
				WHERE
					[a_id] = [authors].[a_id])
				> 3
			THEN
				N' [+]'
			ELSE
				N' [-]'
		END
		)
