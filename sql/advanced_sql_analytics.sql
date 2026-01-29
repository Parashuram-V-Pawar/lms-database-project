/*
Advanced SQL and Analytics
1. For each course, calculate:
   a. Total number of enrolled users
   b. Total number of lessons
   c.  Average lesson duration
2. Identify the top three most active users based on total activity count.
3. Calculate course completion percentage per user based on lesson activity.
4. Find users whose average Assessment score is higher than the course average.
5. List courses where lessons are frequently accessed but Assessments are never attempted.
6. Rank users within each course based on their total assessment score.
7. Identify the first lesson accessed by each user for every course.
8. Find users with activity recorded on at least five consecutive days.
9. Retrieve users who enrolled in a course but never submitted any assessment.
10. List courses where every enrolled user has submitted at least one assessment.
*/


-- 1. For each course, calculate:
--    a. Total number of enrolled users
--    b. Total number of lessons
--    c. Average lesson duration
SELECT 
	c.course_id, 
	c.course_title, 
	COUNT(DISTINCT e.user_id) AS Number_of_Enrolled_Users, 
	COUNT(DISTINCT l.lesson_id) AS Number_of_Lessons,
	CASE
		WHEN COUNT(DISTINCT l.lesson_id) = 0 THEN NULL
		ELSE c.course_duration * 1.0 /COUNT(DISTINCT l.lesson_id)
	END AS average_lesson_duration
FROM lms.Courses AS c 
LEFT JOIN lms.Enrollments AS e 
ON c.course_id = e.course_id
LEFT JOIN lms.Lessons AS l 
ON l.course_id = c.course_id
GROUP BY 
	c.course_id, 
	c.course_title, 
	c.course_duration;
GO

-- 2.  Identify the top three most active users based on total activity count.
SELECT 
	TOP(3) u.user_id, 
	u.user_name, 
	COUNT(*) AS Number_of_activities
FROM lms.Users AS u
JOIN lms.User_Activity as ua  
ON u.user_id = ua.user_id
GROUP BY 
	u.user_id, 
	u.user_name
ORDER BY COUNT(*) DESC;
GO

-- 3. Calculate course completion percentage per user based on lesson activity.
SELECT
	u.user_id,
	u.user_name,
	c.course_id,
	COUNT(DISTINCT l.lesson_id) AS total_lessons,
	COUNT(DISTINCT ua.lesson_id) AS lessons_completed,
	CASE
      	WHEN COUNT(DISTINCT l.lesson_id) = 0 THEN 0
      	ELSE
			(COUNT(DISTINCT ua.lesson_id)  * 100.0) / COUNT(DISTINCT l.lesson_id)	
   	END AS completion_percentage
FROM lms.Enrollments AS e
JOIN lms.Users AS u
   	ON u.user_id = e.user_id	
JOIN lms.Courses AS c
   	ON c.course_id = e.course_id	
LEFT JOIN lms.Lessons AS l
   	ON l.course_id = c.course_id	
LEFT JOIN lms.User_Activity AS ua
	ON ua.user_id = u.user_id
	AND ua.lesson_id = l.lesson_id
GROUP BY
	u.user_id,
	u.user_name,
	c.course_id
ORDER BY completion_percentage DESC;
GO

-- 4. Find users whose average Assessment score is higher than the course average.
WITH course_avg AS (
	SELECT
		l.course_id,
		AVG(s.marks_scored) AS AVG_Course_Score
	FROM lms.Assessment_Submission AS s
	JOIN lms.Lessons AS l
		ON l.lesson_id = s.lesson_id
	GROUP BY l.course_id
),
user_avg AS (
   	SELECT
      	u.user_id,
      	u.user_name,
      	l.course_id,
      	AVG(s.marks_scored) AS AVG_User_Score
   	FROM lms.Users AS u
   	JOIN lms.Assessment_Submission AS s
      	ON u.user_id = s.user_id
   	JOIN lms.Lessons AS l
      	ON l.lesson_id = s.lesson_id
   	GROUP BY
      	u.user_id,
      	u.user_name,
      	l.course_id
)
SELECT
	ua.user_id,
	ua.user_name,
	ua.course_id,
	c.course_title,
	ua.AVG_User_Score,
   	ca.AVG_Course_Score
FROM user_avg AS ua
JOIN course_avg AS ca
    ON ca.course_id = ua.course_id
JOIN lms.Courses AS c
    ON c.course_id = ua.course_id
WHERE ua.AVG_User_Score > ca.AVG_Course_Score;
GO

-- 5. List courses where lessons are frequently accessed but Assessments are never attempted.
SELECT DISTINCT
    c.course_id,
    c.course_title
FROM lms.Courses AS c
JOIN lms.Lessons AS l
    ON c.course_id = l.course_id
WHERE EXISTS (
    SELECT 1
    FROM lms.User_Activity AS ua
    WHERE ua.lesson_id = l.lesson_id
)
AND NOT EXISTS (
    SELECT 1
    FROM lms.Assessment_Submission AS s
    WHERE s.lesson_id = l.lesson_id
);

-- 6. Rank users within each course based on their total assessment score.
SELECT 
	u.user_id,
	u.user_name,
	c.course_title,
	COALESCE(SUM(submit.marks_scored),0),
	DENSE_RANK() OVER(PARTITION BY c.course_id ORDER BY COALESCE(SUM(submit.marks_scored),0) DESC) AS Rank
FROM lms.Users AS u
JOIN lms.Enrollments AS e 
    ON u.user_id = e.user_id
JOIN lms.Courses AS c
    ON c.course_id = e.course_id
LEFT JOIN lms.Lessons AS l
    ON l.course_id = c.course_id
LEFT JOIN lms.Assessment_Submission AS submit
    ON submit.user_id = u.user_id
    AND submit.lesson_id = l.lesson_id
GROUP BY u.user_id, u.user_name, c.course_id, c.course_title
ORDER BY c.course_id, Rank;
GO

-- 7. Identify the first lesson accessed by each user for every course.
WITH first_activity AS (
    SELECT
        ua.user_id,
        ua.lesson_id,
        ua.activity_date,
        ROW_NUMBER() OVER (
            PARTITION BY ua.user_id
            ORDER BY ua.activity_date ASC
        ) AS row_number
    FROM lms.User_Activity AS ua
)
SELECT 
	fa.user_id,
	u.user_name, 
	fa.lesson_id, 
	fa.activity_date
FROM first_activity AS fa
LEFT JOIN  lms.Users AS u
ON u.user_id = fa.user_id
WHERE row_number = 1;

-- 8. Find users with activity recorded on at least five consecutive days.
WITH ActivityDates AS (
    SELECT DISTINCT
        user_id,
        CAST(activity_date AS DATE) AS activity_date
    FROM lms.User_Activity
),
Streaks AS (
    SELECT
        user_id,
        activity_date,
        DATEADD(
            DAY,
            -ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY activity_date),
            activity_date
        ) AS streak_group
    FROM ActivityDates
)
SELECT
    user_id,
    MIN(activity_date) AS streak_start,
    MAX(activity_date) AS streak_end,
    COUNT(*) AS consecutive_days
FROM Streaks
GROUP BY user_id, streak_group
HAVING COUNT(*) >= 5
ORDER BY user_id;
GO

-- 9. Retrieve users who enrolled in a course but never submitted any assessment.
SELECT
    e.user_id,
    e.course_id
FROM lms.Enrollments e
WHERE NOT EXISTS (
    SELECT 1
    FROM lms.Lessons l
    JOIN lms.Assessment_Submission s
        ON s.lesson_id = l.lesson_id
       AND s.user_id = e.user_id
    WHERE l.course_id = e.course_id
);
GO

-- 10. List courses where every enrolled user has submitted at least one assessment.
SELECT
    e.course_id
FROM lms.Enrollments e
WHERE EXISTS (
    SELECT 1
    FROM lms.Lessons l
    JOIN lms.Assessment_Submission s
        ON s.lesson_id = l.lesson_id
       AND s.user_id = e.user_id
    WHERE l.course_id = e.course_id
);
GO

SELECT * FROM lms.Enrollments
