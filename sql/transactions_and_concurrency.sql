-- Section 5: Transactions and Concurrency
-- 1. Design a transaction flow for enrolling a user into a course.
-- 2. Explain how to handle concurrent assessment submissions safely.
-- 3. Describe how partial failures should be handled during assessment submission.
-- 4. Recommend suitable transaction isolation levels for enrollments and submissions.
-- 5. Explain how phantom reads could affect analytics queries and how to prevent them.

-- 1. Design a transaction flow for enrolling a user into a course.
-- Solution:
-- To enrolling a user into a course involves multiple steps and checks:
-- 1. Need to check if the course exists and it is active.
-- 2. Then check whether the course has lessons in it.
-- 3. we also need to check if the user is already enrolled in this course.
-- 4. If all the conditions are satisfied then only user can enroll into the course.
SELECT COUNT(*) FROM lms.Enrollments
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @user_id INT = 101;
    DECLARE @course_id INT = 10;
    -- Step 1: Validate course is active
    IF NOT EXISTS (
        SELECT 1 
        FROM lms.Courses 
        WHERE course_id = @course_id AND course_status = 'ACTIVE'
    )
    THROW 50000, 'Course is not active.', 1;
    -- Step 2: Validate course has lessons
    IF NOT EXISTS (
        SELECT 1 
        FROM lms.Lessons 
        WHERE course_id = @course_id
    )
    THROW 50001, 'Course has no lessons.', 1;
    -- Step 3: Check if user is already enrolled
    IF EXISTS (
        SELECT 1
        FROM lms.Enrollments
        WHERE user_id = @user_id AND course_id = @course_id
    )
    THROW 50002, 'User already enrolled.', 1;
    -- Step 4: Insert enrollment
    INSERT INTO lms.Enrollments (enrollment_id, user_id, course_id, enrollment_date, enrollment_status)
    VALUES (12001, @user_id, @course_id, GETDATE(), 'ACTIVE');
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    THROW;
END CATCH;

-- ======================================================================================================
-- 2. Explain how to handle concurrent assessment submissions safely.
-- Solution:
-- This problem arrises when same user is submitting same assignments two times at the same time.
-- We can prevent it by adding unique constraint to bot assessment_id and user_id that same user cannot submit a assignment multiple times.
-- I have already implemented it during creation of the table.
CONSTRAINT UQ_Assessment_User UNIQUE (assessment_id, user_id)

-- ======================================================================================================
-- 3. Describe how partial failures should be handled during assessment submission.
-- Assessment submission has multiple steps to be updated, where
-- 1. Inserting data to the Assessment_Submission table.
-- 2. Calculating and updating the analytical data of scores.
-- in this situation sometimes partial failures can happen so we can put all the operations in a single transaction and 
-- when any operation fails we can rollback the entire transaction.
-- Doing this ensures that no inconsistent data appear in the database.

-- ======================================================================================================
-- 4. Recommend suitable transaction isolation levels for enrollments and submissions.
-- * For Enrollments:
-- We need to prevent two users from enrolling simultaneously in an invalid state
-- and avoid duplicate enrollments and Ensure enrollment checks and inserts are fully isolated
-- So Recommended Isolation Level: SERIALIZABLE
-- This makes 2nd user wait until 1st user is completed his operation either commiting or rollback by putting a lock.

-- * For Assessment Submissions:
-- We need to ensure only committed data is read
-- So here recommended Isolation level: READ COMMIT
-- Which allows only committed data is read and with this lock duration also get reduced.
-- And when two duplicate submissions occur at the same time the unique constraint allows only 1 and 
-- the other fails due to constraint violation

-- ======================================================================================================
-- 5. Explain how phantom reads could affect analytics queries and how to prevent them.
-- Phantom reads occur when a transaction re-executes a query and gets different results 
-- due to another transaction inserting or deleting rows.
-- This can affect analytics queries that rely on consistent data sets.
-- To prevent phantom reads, use SERIALIZABLE isolation level or appropriate locking mechanisms.
/*
Isolation Level     Lock Type
READ COMMITTED      Row locks
REPEATABLE READ     Row + shared locks
SERIALIZABLE        Key-range locks
TABLOCK hint        Table lock
*/
