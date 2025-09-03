-- 장바구니 테스트
USE fairclass;

-- 테스트 학생 고정
SET @stu := 1;

-- 해당 학생 데이터만 초기화
DELETE FROM applicant     WHERE stu_code=@stu;
DELETE FROM waitlist      WHERE stu_code=@stu;
DELETE FROM class_history WHERE stu_code=@stu;
DELETE FROM basket        WHERE stu_code=@stu;

-- 기대: 성공 (장바구니에 (1,2) 추가)
CALL sp_basket_add(@stu, 2);
-- 확인
SELECT * FROM basket WHERE stu_code=@stu ORDER BY basket_code;

-- 이미 장바구니에 있음 (테스트 통과)
CALL sp_basket_add(@stu, 2);

-- 이미 수강신청된 강의 (테스트 통과)
INSERT INTO applicant(stu_code, lecture_code, applied_at) VALUES (@stu, 3, NOW());
CALL sp_basket_add(@stu, 3);
DELETE FROM applicant WHERE stu_code=@stu AND lecture_code=3;

-- 동시간대 겹침 (테스트 통과)----------------------------------------
-- @stu 더미 데이터에서 (1학기,화 10:30 - 11:45) 장바구니에 갖고 있음 
INSERT INTO subject(major_code, completion_type_code, subject_name, grade)
VALUES (1, 2, '겹침테스트A', 3);
SET @subA := LAST_INSERT_ID();

INSERT INTO lecture(semester_code, subject_code, professor_code, classroom_code, admin_code,
                    capacity, time, cancel, created_at, updated_at)
VALUES (1, @subA, 1, 1, 1, 50, 101, 'N', CURDATE(), CURDATE());
SET @lecA := LAST_INSERT_ID();

INSERT INTO lecture_time(lecture_code, day_of_week, start_time, end_time)
VALUES (@lecA, 'TUE', '11:30:00', '12:20:00');

CALL sp_basket_add(@stu, @lecA);
-- ----------------------------------------------------------------

-- 검증 시 더미 데이터 삭제 -----------------------------------------------
-- START TRANSACTION;
-- 
-- -- 학생 장바구니/신청/대기/이력에서 지우기
-- DELETE FROM basket        WHERE lecture_code IN (@lecA, @lecB);
-- DELETE FROM applicant     WHERE lecture_code IN (@lecA, @lecB);
-- DELETE FROM waitlist      WHERE lecture_code IN (@lecA, @lecB);
-- DELETE FROM class_history WHERE lecture_code IN (@lecA, @lecB);
-- 
-- -- 강의 시간표
-- DELETE FROM lecture_time  WHERE lecture_code IN (@lecA, @lecB);
-- 
-- -- 강의 자체
-- DELETE FROM lecture       WHERE lecture_code IN (@lecA, @lecB);
-- 
-- -- 과목
-- DELETE FROM subject       WHERE subject_code IN (@lecA, @lecB);
-- 
-- COMMIT;
-- 
-- -- 검증
-- SELECT COUNT(*) AS left_lectures
-- FROM lecture l JOIN subject s ON s.subject_code=l.subject_code
-- WHERE s.subject_name IN ('겹침테스트A','경계테스트B');
-- ------------------------------------------------------------------------
