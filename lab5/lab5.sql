USE [library]

GO

--1. Создать представление, позволяющее получать список читателей с количеством находящихся у каждого читателя на руках книг,
-- но отображающее только таких читателей, по которым имеются задолженности, т.е. на руках у читателя есть хотя бы одна книга,
-- которую он должен был вернуть до наступления текущей даты.

CREATE OR ALTER VIEW [debtors]
AS
SELECT
	[s_id],
	[s_name],
	(
		SELECT
			COUNT([sb_book])
		FROM
			[subscriptions]
		WHERE
			[sb_subscriber] = [s_id]
	) AS [n_books]
FROM
	[subscribers]
	JOIN [subscriptions]
		ON [s_id] = [sb_subscriber]
WHERE
    [sb_is_active] = 'Y'
    AND [sb_finish] < GETDATE()
GROUP BY
	[s_id], [s_name]

GO

--4 Создать представление, через которое невозможно получить информацию о том,
-- какая конкретно книга была выдана читателю в любой из выдач.

CREATE OR ALTER VIEW [obscured_subscriptions]
AS
	SELECT
		[sb_id],
		[sb_subscriber],
		[sb_start],
		[sb_finish]
		[sb_is_active]
	FROM
		[subscriptions]

GO

--13 Создать триггер, не позволяющий добавить в базу данных информацию о выдаче книги, если выполняется хотя бы одно из условий:
-- дата выдачи или возврата приходится на воскресенье;
-- читатель брал за последние полгода более 100 книг;
-- промежуток времени между датами выдачи и возврата менее трёх дней.

CREATE OR ALTER TRIGGER [trg_task_13]
ON [subscriptions]
AFTER INSERT, UPDATE
AS
BEGIN
    DECLARE @violations_count INT =  (SELECT 
                                            COUNT([sb_id])
                                        FROM
                                            [inserted]
                                        WHERE
                                            DATEPART(DW, [sb_finish]) = 1
                                            OR DATEPART(DW, [sb_start]) = 1
                                            OR (SELECT COUNT([sb_id])
                                                FROM [subscriptions]
                                                WHERE [sb_subscriber] = [inserted].[sb_subscriber]
                                                AND [sb_start] > DATEADD(mm, -6, GETDATE())) > 100
                                            OR DATEDIFF(dd, [sb_start], [sb_finish]) < 3)

    IF @violations_count  > 0
    BEGIN
        ROLLBACK TRANSACTION
        RAISERROR('This violates task 13 rules...', 16, 1)
    END

END

GO

GO

--15. Создать триггер, допускающий регистрацию в библиотеке только таких авторов, имя которых не содержит никаких символов кроме букв, цифр, знаков - (минус), ' (апостроф) и пробелов (не допускается два и более идущих подряд пробела).

CREATE OR ALTER TRIGGER [trg_task_15]
ON [authors]
AFTER INSERT, UPDATE
AS
BEGIN
    DECLARE @violations_count INT =     (
                                        SELECT
                                            COUNT([a_id])
                                        FROM
                                            [inserted]
                                        WHERE
                                            PATINDEX('%[^ A-Za-z0-9-'']%', [a_name]) != 0
                                            OR PATINDEX('%  %', [a_name]) != 0
                                        )

    IF @violations_count > 0
    BEGIN
        ROLLBACK TRANSACTION
        RAISERROR('This violates task 15 rules...', 16, 1)
    END
END

GO

--17. Создать триггер, меняющий дату выдачи книги на текущую,
-- если указанная в INSERT- или UPDATE-запросе дата выдачи книги меньше текущей на полгода и более.

CREATE OR ALTER TRIGGER [trg_task_17]
ON [subscriptions]
AFTER INSERT, UPDATE
AS
BEGIN
    UPDATE
        [subscriptions]
    SET
        [sb_start] = GETDATE()
    WHERE
        [sb_id] IN (
            SELECT
                [sb_id]
            FROM
                [inserted]
            WHERE
                DATEDIFF(mm, [sb_start], GETDATE()) >= 6
        )
END

GO
