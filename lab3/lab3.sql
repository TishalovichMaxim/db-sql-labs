use [library]

--15. Показать всех авторов и количество книг (не экземпляров книг, а «книг как изданий») по каждому автору.

SELECT
	[authors].[a_id],
	[a_name],
	COUNT([b_id]) AS [books_count]
FROM
	[authors]
	LEFT JOIN [m2m_books_authors]
		ON [authors].[a_id] = [m2m_books_authors].[a_id]
GROUP BY
	[authors].[a_id],
	[a_name]

--16. Показать всех читателей, не вернувших книги, и количество невозвращённых книг по каждому такому читателю.

SELECT
	[s_id],
	[s_name],
	COUNT([sb_book]) AS [books_to_return]
FROM
	[subscribers]
	JOIN [subscriptions]
		ON [s_id] = [sb_subscriber]
WHERE
	[sb_is_active] = 'Y'
GROUP BY
	[s_id],
	[s_name]

--17. Показать читаемость жанров, т.е. все жанры и то количество раз, которое книги этих жанров были взяты читателями.

SELECT
	[genres].[g_id],
	[g_name],
	COUNT([sb_book]) AS [taken_books]
FROM
	[genres]
	LEFT JOIN [m2m_books_genres]
		ON [genres].[g_id] = [m2m_books_genres].[g_id]
	LEFT JOIN [subscriptions]
		ON [b_id] = [sb_book]
GROUP BY
	[genres].[g_id],
	[g_name]

--18. Показать самый читаемый жанр, т.е. жанр (или жанры, если их несколько), относящиеся к которому книги читатели брали чаще всего.

SELECT TOP 1 WITH TIES
	[genres].[g_id],
	[g_name],
	COUNT(*) as [books_count]
FROM
	[genres]
	JOIN [m2m_books_genres]
		ON [genres].[g_id] = [m2m_books_genres].[g_id]
	JOIN [subscriptions]
		ON [b_id] = [sb_book]
GROUP BY
	[genres].[g_id],
	[g_name]
ORDER BY
	[books_count] DESC

--19. Показать среднюю читаемость жанров, т.е. среднее значение от того, сколько раз читатели брали книги каждого жанра.

WITH [genres_readability] ([takes_count])
AS
(
	SELECT
		COUNT([sb_book])
	FROM
		[genres]
		LEFT JOIN [m2m_books_genres]
			ON [genres].[g_id] = [m2m_books_genres].[g_id]
		LEFT JOIN [subscriptions]
			ON [m2m_books_genres].[b_id] = [subscriptions].[sb_book]
	GROUP BY
		[genres].[g_id]
)

SELECT
	AVG(CAST([takes_count] AS FLOAT)) AS [average_readability]
FROM
	[genres_readability]
