/*Intermediate SQL Queries
1. List all users who are enrolled in more than three courses.
2. Find courses that currently have no enrollments.
3. Display each course along with the total number of enrolled users.
4. Identify users who enrolled in a course but never accessed any lesson.
5. Fetch lessons that have never been accessed by any user.
6. Show the last activity timestamp for each user.
7. List users who submitted an assessment but scored less than 50 percent of the maximum score.
8. Find assessments that have not received any submissions.
9. Display the highest score achieved for each assessment.
10. Identify users who are enrolled in a course but have an inactive enrollment status.
*/


-- 1. List all users who are enrolled in more than three courses.
-- * Why JOIN: I have used INNER JOIN so that i can retreive only matching rows based on statement.
-- * ASSUMPTIONS: Yes, I have assumed that each user has only enrolled to particular course one time.
SELECT u.user_id, u.user_name
FROM lms.Users as u 
JOIN lms.Enrollments as e 
ON u.user_id = e.user_id
GROUP BY u.user_id, u.user_name
HAVING count(*) > 3;
GO

-- 2. Find courses that currently have no enrollments.

SELECT c.course_id, c.course_title
FROM lms.Courses as c
WHERE NOT EXISTS (
    SELECT 1
    FROM lms.Enrollments as e 
    WHERE e.course_id = c.course_id
);
GO

-- 3. Display each course along with the total number of enrolled users.
SELECT c.course_title, COUNT(e.enrollment_id) AS Number_of_enrollments
FROM lms.Courses as c
LEFT JOIN lms.Enrollments as e 
ON c.course_id = e.course_id
GROUP BY c.course_title
ORDER BY Number_of_enrollments DESC;
GO


-- 4. Identify users who enrolled in a course but never accessed any lesson.
SELECT
    u.user_id,
    u.user_name,
    c.course_id,
    c.course_title
FROM lms.Enrollments AS e
JOIN lms.Users AS u
    ON u.user_id = e.user_id
JOIN lms.Courses AS c
    ON c.course_id = e.course_id
WHERE NOT EXISTS (
    SELECT 1
    FROM lms.User_Activity AS ua
    JOIN lms.Lessons AS l
        ON l.lesson_id = ua.lesson_id
    WHERE ua.user_id = e.user_id
      AND l.course_id = e.course_id
);
GO



-- 5. Fetch lessons that have never been accessed by any user.
SELECT l.lesson_title
FROM lms.Lessons as l 
LEFT JOIN lms.User_Activity as ua 
ON ua.lesson_id = l.lesson_id
WHERE ua.lesson_id is NULL;

-- 6. Show the last activity timestamp for each user.
SELECT u.user_id,u.user_name, MAX(ua.activity_date) as Last_activity
FROM lms.Users as u 
LEFT JOIN lms.User_Activity as ua 
ON u.user_id = ua.user_id
GROUP BY u.user_id, u.user_name;
GO

-- 7. List users who submitted an assessment but scored less than 50 percent of the maximum score.
SELECT u.user_id, u.user_name, assessment.assessment_id, marks_scored
FROM lms.Users as u 
JOIN lms.Assessment_Submission as submit 
ON u.user_id = submit.user_id
LEFT JOIN lms.Assessments as assessment
ON assessment.lesson_id = submit.lesson_id
WHERE marks_scored < (assessment.max_score * 0.5);

-- 8. Find assessments that have not received any submissions.
-- * JOIN USED: LEFT ANTI JOIN
SELECT assessment.assessment_id, assessment.assessment_name
FROM lms.Assessments as assessment
LEFT JOIN lms.Assessment_Submission as submit
ON submit.lesson_id = assessment.lesson_id
WHERE submit.lesson_id IS NULL

-- 9. Display the highest score achieved for each assessment.
SELECT assessment.assessment_id, assessment.assessment_name, MAX(submit.marks_scored)
FROM lms.Assessments as assessment
LEFT JOIN lms.Assessment_Submission as submit
ON submit.lesson_id = assessment.lesson_id
GROUP BY assessment.assessment_id, assessment.assessment_name;

-- 10. Identify users who are enrolled in a course but have an inactive enrollment status.
SELECT u.user_id, e.course_id, u.user_name
FROM lms.Users as u 
JOIN lms.Enrollments as e 
ON u.user_id = e.user_id
WHERE enrollment_status = 'INACTIVE';