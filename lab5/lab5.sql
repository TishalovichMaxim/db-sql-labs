USE [library]

GO
--1. Создать представление, позволяющее получать список читателей с количеством находящихся у каждого читателя на руках книг,
-- но отображающее только таких читателей, по которым имеются задолженности, т.е. на руках у читателя есть хотя бы одна книга,
-- которую он должен был вернуть до наступления текущей даты.
CREATE VIEW [debtors]
AS
WITH [debtors_ids] ([id])
AS
(
	SELECT
		[sb_subscriber]
	FROM
		[subscriptions]
	WHERE
		[sb_is_active] = 'Y'
		AND [sb_finish] >= GETDATE()
)
SELECT
	[s_id],
	[s_name]
FROM
	[subscribers]
	JOIN [subscriptions]
		ON [s_id] = [sb_subscriber]
WHERE
	[sb_subscriber] IN (SELECT * FROM [debtors_ids])
GROUP BY
	[s_id], [s_name]

GO

--4 Создать представление, через которое невозможно получить информацию о том,
-- какая конкретно книга была выдана читателю в любой из выдач.

CREATE VIEW [obscured_subscriptions]
AS
	SELECT
		[sb_id],
		[sb_subscriber],
		[s_name],
		[sb_start],
		[sb_finish]
		[sb_is_active]
	FROM
		[subscriptions]
		JOIN [subscribers]
			ON [sb_subscriber] = [s_id]

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
                                                AND [sb_start] > DATEADD(MM, -6, GETDATE())) > 100
                                            OR DATEADD(DD, 3, [sb_start]) >= [sb_finish])

    IF @violations_count  > 0
    BEGIN
        ROLLBACK TRANSACTION
        RAISERROR('This violates task 13 rules...', 16, 1)
    END

END

GO

--14 Создать триггер, не позволяющий выдать книгу читателю, у которого на руках находится пять и более книг,
-- при условии, что суммарное время, оставшееся до возврата всех выданных ему книг, составляет менее одного месяца.

CREATE OR ALTER TRIGGER [trg_task_14]
ON [subscriptions]
AFTER INSERT, UPDATE
AS
BEGIN
    DECLARE @violations_count INT =     (SELECT 
                                            COUNT([sb_id])
                                        FROM
                                            [inserted]
                                        WHERE
                                            (
                                                SELECT
                                                    COUNT([sb_book])
                                                FROM
                                                    [subscriptions]
                                                WHERE
                                                    [sb_subscriber] = [inserted].[sb_subscriber]
                                                    AND [sb_is_active] = 'Y'
                                            ) >= 5
                                            AND 
                                            (
                                                SELECT
                                                    (SUM(DATEDIFF(dd, [sb_start], [sb_finish])))
                                                FROM
                                                    [subscriptions]
                                                WHERE
                                                    [sb_subscriber] = [inserted].[sb_subscriber]
                                                    AND [sb_is_active] = 'Y'
                                            ) < 31

    IF @violations_count > 0
    BEGIN
        ROLLBACK TRANSACTION
        RAISERROR('This violates task 14 rules...', 16, 1)
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
                DATEADD(mm, 6, [sb_start]) <= GETDATE()
        )
END

GO
