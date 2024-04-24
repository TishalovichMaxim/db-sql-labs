use [library]

GO

-- 1. Создать хранимую функцию, получающую на вход идентификатор читателя и
-- возвращающую список идентификаторов книг, которые он уже прочитал и вернул
-- в библиотеку.

CREATE OR ALTER FUNCTION [GetSubscriberReturnedBooks](@s_id INT)
RETURNS TABLE
AS
RETURN
    SELECT
        [sb_book] AS [book_id]
    FROM
        [subscriptions]
    WHERE
        [sb_is_active] = 'N'
        AND [sb_subscriber] = @s_id

GO

-- 3. Создать хранимую функцию, получающую на вход идентификатор читателя
-- и возвращающую 1, если у читателя на руках сейчас менее десяти книг,
-- и 0 в противном случае.

CREATE OR ALTER FUNCTION [UserHasBooks](@s_id INT)
RETURNS INT
AS
BEGIN
    DECLARE @books_count INT =
                        (SELECT
                            COUNT([sb_id])
                        FROM
                            [subscriptions]
                        WHERE
                            [sb_is_active] = 'Y'
                            AND [sb_subscriber] = @s_id)

	DECLARE @result INT = 0

    IF @books_count < 10
	BEGIN
        SET @result = 1
	END

	RETURN @result
END

GO

-- 4. Создать хранимую функцию, получающую на вход год издания книги и
-- возвращающую 1, если книга издана менее ста лет назад, и 0 в противном случае.

CREATE OR ALTER FUNCTION [OverHundredYearsOld](@publishing_year INT)
RETURNS INT
BEGIN
    DECLARE @curr_year INT = DATEPART(yy, GETDATE())

	DECLARE @result INT = 0

    IF @curr_year - @publishing_year < 100
	BEGIN
        SET @result = 1
	END

	RETURN @result
END

GO

-- 5. Создать хранимую процедуру, обновляющую все поля типа DATE (если такие есть)
-- всех записей указанной таблицы на значение текущей даты.

CREATE OR ALTER PROCEDURE [UpdateDates](@table_name NVARCHAR(150))
AS
BEGIN
	DECLARE @column_name NVARCHAR(150)

	DECLARE @there_are_date_columns INT = 0

	DECLARE
		[columns_cursor]
	CURSOR FOR
		SELECT
			[COLUMN_NAME]
		FROM
			[INFORMATION_SCHEMA].[COLUMNS]
		WHERE
			[TABLE_NAME] = @table_name
			AND [DATA_TYPE] = 'date'

	OPEN [columns_cursor]
	
	FETCH NEXT FROM [columns_cursor] INTO
		@column_name

	DECLARE @update_sql NVARCHAR(1000) = CONCAT(
									N'UPDATE [',
										@table_name, 
									N'] SET '
									)

	IF @@FETCH_STATUS = 0
	BEGIN
		SET @there_are_date_columns = 1
	END

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @update_sql = CONCAT(@update_sql, @column_name, N' = GETDATE(),')
		FETCH NEXT FROM [columns_cursor] INTO
			@column_name
	END

    CLOSE [columns_cursor]
    DEALLOCATE [columns_cursor]

	IF @there_are_date_columns = 0
	BEGIN
		RETURN
	END

	SET @update_sql = SUBSTRING(@update_sql, 1, LEN(@update_sql) - 1)
	
	EXEC [sp_executesql] @update_sql
END

GO

-- 9. Создать хранимую процедуру, автоматически создающую и наполняющую данными
-- таблицу «arrears», в которой должны быть представлены идентификаторы и имена
-- читателей, у которых до сих пор находится на руках хотя бы одна книга,
-- по которой дата возврата установлена в прошлом относительно текущей даты.

CREATE OR ALTER PROCEDURE [CreateArrears]
AS
BEGIN
    DROP TABLE IF EXISTS [arrears]

    CREATE TABLE [arrears](
        [s_id] INT,
        [s_name] VARCHAR(100)
    )

    INSERT INTO
        [arrears]
    SELECT
        [s_id],
        [s_name]
    FROM
        [subscribers]
        JOIN [subscriptions]
            ON [s_id] = [sb_subscriber]
    WHERE 
        [sb_is_active] = 'Y'
        AND [sb_finish] < GETDATE()
    GROUP BY
        [s_id], [s_name]

END

GO
