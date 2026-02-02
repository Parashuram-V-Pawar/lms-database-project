-- Section 6: Database Design and Architecture
-- 1. Propose schema changes to support course completion certificates.
-- 2. Describe how you would track video progress efficiently at scale.
-- 3. Discuss normalization versus denormalization trade-offs for user activity data.
-- 4. Design a reporting-friendly schema for analytics dashboards.
-- 5. Explain how this schema should evolve to support millions of users.


-- 1. Propose schema changes to support course completion certificates.
-- Solution:
-- To generate course completion certificate we can create new table for storing the details of course completion.
-- As who completed course, which course, when the course was completed, what was the score, whether he is certified or not.
-- Then we can create one more table to store certificate information for certified students which contains details such as,
-- certificate number, when the certificate was issued.
-- In first table we can also add a unique constraint for user_id and course_id so that one user can get certified once per course.


-- 2. Describe how you would track video progress efficiently at scale.
-- Solution:
-- To track video progress efficiently at scale we can updated the previous record with current video completion status,
-- instead of creating one more new record for same user for same video.
-- Doing this will reduce data entries and consume less storage space and makes query lookups faster.

-- 3. Discuss normalization versus denormalization trade-offs for user activity data.


--  4. Design a reporting-friendly schema for analytics dashboards.
-- Solution:
-- What we can do here is we can create a summary table for user activity table which stores no_od lesson completed in course,
-- number of assessments submitted and average score of users submitting assessments and date of last activity by user.
-- Doing this we can easily get to know the status of certain user in particular course.
CREATE TABLE lms.analytics_user_course_summary (
    user_id CHAR(9) NOT NULL,
    course_id CHAR(5) NOT NULL,
    total_lessons_completed INT NOT NULL,
    total_assessments_taken INT NOT NULL,
    average_score FLOAT NOT NULL,
    last_activity_date DATETIME NOT NULL,
    PRIMARY KEY (user_id, course_id),
    FOREIGN KEY (user_id) REFERENCES lms.Users(user_id),
    FOREIGN KEY (course_id) REFERENCES lms.Courses(course_id)
);
GO


--  5. Explain how this schema should evolve to support millions of users.
-- Solution:
-- To support millions of users, consider the following strategies:
-- 1. Partition large tables e.g user activity tables based on user_id or course_id to improve query performance.
-- 2. Implement indexing strategies on frequently queried columns to speed up data retrieval.
-- 3. Use caching mechanisms for frequently accessed data to reduce database load.
-- 4. Regularly archive historical data to separate storage to keep the main tables lean.
-- 5. Monitor database performance and scale resources e.g., read replicas, sharding as needed to handle increased load.
-- 6. Optimize queries and use materialized views for complex analytics to improve response times./*