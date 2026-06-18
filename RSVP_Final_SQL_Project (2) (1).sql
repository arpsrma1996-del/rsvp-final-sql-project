USE imdb;

-- Segment 1

-- Q1
WITH table_counts AS (
    SELECT 'movie' AS table_name, COUNT(*) AS total FROM movie
    UNION ALL SELECT 'genre', COUNT(*) FROM genre
    UNION ALL SELECT 'ratings', COUNT(*) FROM ratings
    UNION ALL SELECT 'names', COUNT(*) FROM names
    UNION ALL SELECT 'director_mapping', COUNT(*) FROM director_mapping
    UNION ALL SELECT 'role_mapping', COUNT(*) FROM role_mapping
)
SELECT * FROM table_counts;

-- Q2
SELECT
COUNT(*) - COUNT(title) AS title_nulls,
COUNT(*) - COUNT(year) AS year_nulls,
COUNT(*) - COUNT(date_published) AS date_nulls,
COUNT(*) - COUNT(duration) AS duration_nulls,
COUNT(*) - COUNT(country) AS country_nulls,
COUNT(*) - COUNT(worlwide_gross_income) AS income_nulls,
COUNT(*) - COUNT(languages) AS languages_nulls,
COUNT(*) - COUNT(production_company) AS prod_nulls
FROM movie;

-- Q3
SELECT year, COUNT(*) AS total_movies
FROM movie
GROUP BY year
ORDER BY year;

SELECT EXTRACT(MONTH FROM date_published) AS month_num,
       COUNT(*) AS total_movies
FROM movie
GROUP BY month_num
ORDER BY month_num;

-- Q4
SELECT COUNT(*) AS total_movies
FROM movie
WHERE year = 2019
AND (country LIKE '%USA%' OR country LIKE '%India%');

-- Q5
SELECT DISTINCT genre FROM genre;

-- Q6
SELECT genre, COUNT(*) AS movie_count
FROM genre
GROUP BY genre
ORDER BY movie_count DESC
LIMIT 1;

-- Q7
WITH single_genre AS (
    SELECT movie_id
    FROM genre
    GROUP BY movie_id
    HAVING COUNT(*) = 1
)
SELECT COUNT(*) FROM single_genre;

-- Q8
SELECT g.genre, ROUND(AVG(m.duration),2) AS avg_duration
FROM movie m
JOIN genre g ON m.id = g.movie_id
GROUP BY g.genre;

-- Q9
WITH genre_counts AS (
    SELECT genre, COUNT(*) AS movie_count
    FROM genre
    GROUP BY genre
)
SELECT genre, movie_count,
       RANK() OVER (ORDER BY movie_count DESC) AS genre_rank
FROM genre_counts
WHERE genre = 'Thriller';

-- Q10
SELECT 
MIN(avg_rating), MAX(avg_rating),
MIN(total_votes), MAX(total_votes),
MIN(median_rating), MAX(median_rating)
FROM ratings;

-- Q11
WITH ranked_movies AS (
    SELECT m.title, r.avg_rating,
           RANK() OVER (ORDER BY r.avg_rating DESC) AS movie_rank
    FROM movie m
    JOIN ratings r ON m.id = r.movie_id
)
SELECT *
FROM ranked_movies
WHERE movie_rank <= 10;

-- Q12
SELECT median_rating, COUNT(*) AS movie_count
FROM ratings
GROUP BY median_rating
ORDER BY median_rating;

-- Q13
WITH prod_hits AS (
    SELECT m.production_company, COUNT(*) AS movie_count
    FROM movie m
    JOIN ratings r ON m.id = r.movie_id
    WHERE r.avg_rating > 8
      AND m.production_company IS NOT NULL
    GROUP BY m.production_company
)
SELECT *,
RANK() OVER (ORDER BY movie_count DESC) AS rank_
FROM prod_hits;

-- Q14
SELECT g.genre, COUNT(*) AS movie_count
FROM movie m
JOIN genre g ON m.id = g.movie_id
JOIN ratings r ON m.id = r.movie_id
WHERE YEAR(m.date_published)=2017
AND MONTH(m.date_published)=3
AND m.country LIKE '%USA%'
AND r.total_votes > 1000
GROUP BY g.genre;

-- Q15
SELECT m.title, r.avg_rating, g.genre
FROM movie m
JOIN ratings r ON m.id = r.movie_id
JOIN genre g ON m.id = g.movie_id
WHERE m.title LIKE 'The%'
AND r.avg_rating > 8;

-- Q16
SELECT COUNT(*)
FROM movie m
JOIN ratings r ON m.id = r.movie_id
WHERE m.date_published BETWEEN '2018-04-01' AND '2019-04-01'
AND r.median_rating = 8;

-- Q17
SELECT m.country, SUM(r.total_votes) AS total_votes
FROM movie m
JOIN ratings r ON m.id = r.movie_id
WHERE m.country LIKE '%Germany%'
   OR m.country LIKE '%Italy%'
GROUP BY m.country;

-- Q18
SELECT 
COUNT(*) - COUNT(name),
COUNT(*) - COUNT(height),
COUNT(*) - COUNT(date_of_birth),
COUNT(*) - COUNT(known_for_movies)
FROM names;

-- Q19
WITH top_genres AS (
    SELECT g.genre
    FROM genre g
    JOIN ratings r ON g.movie_id = r.movie_id
    WHERE r.avg_rating > 8
    GROUP BY g.genre
    ORDER BY COUNT(*) DESC
    LIMIT 3
)
SELECT n.name, COUNT(*) AS movie_count
FROM director_mapping d
JOIN names n ON d.name_id = n.id
JOIN movie m ON d.movie_id = m.id
JOIN ratings r ON m.id = r.movie_id
JOIN genre g ON m.id = g.movie_id
WHERE r.avg_rating > 8
AND g.genre IN (SELECT genre FROM top_genres)
GROUP BY n.name
ORDER BY movie_count DESC
LIMIT 3;

-- Q20
SELECT n.name, COUNT(*) AS movie_count
FROM role_mapping rm
JOIN names n ON rm.name_id = n.id
JOIN movie m ON rm.movie_id = m.id
JOIN ratings r ON m.id = r.movie_id
WHERE rm.category = 'actor'
AND r.median_rating >= 8
GROUP BY n.name
ORDER BY movie_count DESC
LIMIT 2;

-- Q21
WITH prod_votes AS (
    SELECT m.production_company,
           SUM(r.total_votes) AS votes
    FROM movie m
    JOIN ratings r ON m.id = r.movie_id
    GROUP BY m.production_company
)
SELECT *,
RANK() OVER (ORDER BY votes DESC) AS rank_
FROM prod_votes;

-- Q22
WITH actor_stats AS (
    SELECT n.name,
           COUNT(*) AS movie_count,
           SUM(r.total_votes) AS total_votes,
           SUM(r.avg_rating*r.total_votes)/SUM(r.total_votes) AS avg_rating
    FROM role_mapping rm
    JOIN names n ON rm.name_id = n.id
    JOIN movie m ON rm.movie_id = m.id
    JOIN ratings r ON m.id = r.movie_id
    WHERE rm.category='actor'
    AND m.country LIKE '%India%'
    GROUP BY n.name
    HAVING COUNT(*)>=5
)
SELECT *,
RANK() OVER (ORDER BY avg_rating DESC, total_votes DESC) AS rank_
FROM actor_stats;

-- Q23
WITH actress_stats AS (
    SELECT n.name,
           COUNT(*) AS movie_count,
           SUM(r.total_votes) AS total_votes,
           SUM(r.avg_rating*r.total_votes)/SUM(r.total_votes) AS avg_rating
    FROM role_mapping rm
    JOIN names n ON rm.name_id = n.id
    JOIN movie m ON rm.movie_id = m.id
    JOIN ratings r ON m.id = r.movie_id
    WHERE rm.category='actress'
    AND m.languages LIKE '%Hindi%'
    GROUP BY n.name
    HAVING COUNT(*)>=3
)
SELECT *,
RANK() OVER (ORDER BY avg_rating DESC) AS rank_
FROM actress_stats;

-- Q24
SELECT m.title,
CASE
WHEN r.avg_rating > 8 THEN 'Superhit'
WHEN r.avg_rating >= 7 THEN 'Hit'
WHEN r.avg_rating >= 5 THEN 'One-time-watch'
ELSE 'Flop'
END AS category
FROM movie m
JOIN ratings r ON m.id=r.movie_id
JOIN genre g ON m.id=g.movie_id
WHERE g.genre='Thriller'
AND r.total_votes>=25000
ORDER BY r.avg_rating DESC;

-- Q25
WITH genre_duration AS (
    SELECT g.genre, AVG(m.duration) AS avg_duration
    FROM movie m
    JOIN genre g ON m.id=g.movie_id
    GROUP BY g.genre
)
SELECT genre,
avg_duration,
SUM(avg_duration) OVER (ORDER BY genre) AS running_total,
AVG(avg_duration) OVER (ORDER BY genre) AS moving_avg
FROM genre_duration;

-- Q26
WITH top_genres AS (
    SELECT genre
    FROM genre
    GROUP BY genre
    ORDER BY COUNT(*) DESC
    LIMIT 3
)
SELECT *
FROM (
    SELECT g.genre, m.year, m.title, m.worlwide_gross_income,
           RANK() OVER (PARTITION BY m.year ORDER BY m.worlwide_gross_income DESC) AS rank_
    FROM movie m
    JOIN genre g ON m.id=g.movie_id
    WHERE g.genre IN (SELECT genre FROM top_genres)
) t
WHERE rank_<=5;

-- Q27
WITH multilingual_hits AS (
    SELECT production_company, COUNT(*) AS movie_count
    FROM movie m
    JOIN ratings r ON m.id=r.movie_id
    WHERE r.median_rating>=8
    AND POSITION(',' IN languages)>0
    GROUP BY production_company
)
SELECT *,
RANK() OVER (ORDER BY movie_count DESC) AS rank_
FROM multilingual_hits;

-- Q28
SELECT *
FROM (
    SELECT n.name,
           COUNT(*) AS movie_count,
           SUM(r.total_votes) AS total_votes,
           SUM(r.avg_rating*r.total_votes)/SUM(r.total_votes) AS avg_rating,
           RANK() OVER (ORDER BY SUM(r.avg_rating*r.total_votes)/SUM(r.total_votes) DESC) AS rank_
    FROM role_mapping rm
    JOIN names n ON rm.name_id=n.id
    JOIN movie m ON rm.movie_id=m.id
    JOIN ratings r ON m.id=r.movie_id
    JOIN genre g ON m.id=g.movie_id
    WHERE rm.category='actress'
    AND g.genre='Drama'
    AND r.avg_rating>8
    GROUP BY n.name
) t
WHERE rank_<=3;

-- Q29
WITH base AS (
    SELECT d.name_id, n.name, m.date_published, m.duration,
           r.avg_rating, r.total_votes,
           DATEDIFF(m.date_published,
           LAG(m.date_published) OVER (PARTITION BY d.name_id ORDER BY m.date_published)) AS gap_days
    FROM director_mapping d
    JOIN names n ON d.name_id=n.id
    JOIN movie m ON d.movie_id=m.id
    JOIN ratings r ON m.id=r.movie_id
)
SELECT name_id, name,
COUNT(*) AS movie_count,
AVG(gap_days) AS avg_gap,
AVG(avg_rating) AS avg_rating,
SUM(total_votes) AS total_votes,
MIN(avg_rating) AS min_rating,
MAX(avg_rating) AS max_rating,
SUM(duration) AS total_duration
FROM base
GROUP BY name_id, name
ORDER BY movie_count DESC
LIMIT 9;
