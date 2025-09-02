-- 신청 내역과 대기열을 날짜 순으로 정렬 (뷰 생성)
CREATE OR REPLACE VIEW applicant_dated AS
SELECT *
FROM applicant
ORDER BY applied_at ASC;
-- 대기열 날짜순으로 정렬
CREATE OR REPLACE VIEW waitlist_dated AS
SELECT *
FROM waitlist
ORDER BY `date` ASC;

-- 1. 수강 신청 취소 
-- '학생1'의 신청 취소 
DELETE 
  FROM applicant 
 WHERE stu_code = 1;
-- 수강 취소하면 대기열 첫번째 순서를 수강 신청
DELIMITER //

CREATE OR REPLACE TRIGGER Application_delete
AFTER DELETE ON applicant
FOR EACH ROW
BEGIN
    DECLARE v_stu_code BIGINT;
    -- 삭제된 강의코드에 대해 대기열에서 가장 먼저 신청한 학생 찾기
    SELECT w.stu_code INTO v_stu_code
      FROM waitlist w
     WHERE w.lecture_code = OLD.lecture_code
     ORDER BY w.date ASC
     LIMIT 1;

    -- 대기열 학생이 존재하면 applicant로 이동
    IF v_stu_code IS NOT NULL THEN
        INSERT INTO applicant(lecture_code, stu_code, applied_at)
        VALUES (OLD.lecture_code, v_stu_code, NOW());

        -- 대기열에서 제거
        DELETE FROM waitlist 
         WHERE lecture_code = OLD.lecture_code 
           AND stu_code = v_stu_code;
    END IF;
END;
//

DELIMITER ;


-- 2.수강 히스토리 조회
-- 수강 시기, 개강일, 종강일, 강의명, 학생이름  
SELECT DATE_FORMAT(se.year, '%Y') AS 수강년도, se.start_date AS 개강일 , se.last_day_of_class  AS 종강일 , sb.subject_name AS 강의명, u.`name` 이름
  FROM applicant a
  JOIN student s ON a.stu_code = s.stu_code
  JOIN lecture l ON l.lecture_code = a.lecture_code
  JOIN user u ON u.user_code  = s.user_code
  JOIN subject sb ON l.subject_code = sb.subject_code	
  JOIN semester se ON l.semester_code = se.semester_code
 WHERE u.`name` = '학생1';

 -- 3.수강 신청 및 대기자 자동 수강 신청
DROP PROCEDURE IF EXISTS Application_class;
DELIMITER //
CREATE PROCEDURE Application_class(
    IN p_stu_code BIGINT,
    IN p_lecture_code BIGINT
)
BEGIN
    DECLARE p_capacity INT;
    DECLARE p_now INT;

    START TRANSACTION;

    --  장바구니에 신청하려는 강의가 있는지 확인 
    IF NOT EXISTS (
        SELECT 1
        FROM basket
        WHERE stu_code = p_stu_code
          AND lecture_code = p_lecture_code
        FOR UPDATE
    ) THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '장바구니에 강의가 없습니다.';
    END IF;
    -- 신청된 강의인지 검증
    IF EXISTS (
        SELECT 1 FROM applicant
        WHERE stu_code = p_stu_code AND lecture_code = p_lecture_code
    ) THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '이미 신청된 강의입니다.';
    END IF;
	 -- 대기열에 등록된 강의인지 검증
    IF EXISTS (
        SELECT 1 FROM waitlist
        WHERE stu_code = p_stu_code AND lecture_code = p_lecture_code
    ) THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '이미 대기열에 등록된 강의입니다.';
    END IF;

    -- 강의 정원 파악하고 현재 신청 인원 파악
    SELECT capacity INTO p_capacity
    FROM lecture
    WHERE lecture_code = p_lecture_code
    FOR UPDATE;

    SELECT COUNT(*) INTO p_now
    FROM applicant
    WHERE lecture_code = p_lecture_code
    FOR UPDATE;

    -- 신청 인원이 정원 이하면 신청, 정원보다 많으면 대기열에 등록 대기열은 10명까지 
    IF p_now < p_capacity THEN
        INSERT INTO applicant(stu_code, lecture_code, applied_at)
        VALUES (p_stu_code, p_lecture_code, NOW());
    ELSE
        IF (SELECT COUNT(*) FROM waitlist WHERE lecture_code=p_lecture_code FOR UPDATE) >= 10 THEN 
		  ROLLBACK; 
		  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='대기열이 가득 찼습니다.'; END IF;

        INSERT INTO waitlist(lecture_code, stu_code, `date`)
        VALUES (p_lecture_code, p_stu_code, NOW());
    END IF;
    -- 신청 과목은 장바구니에서 제거
    DELETE 
	   FROM basket
     WHERE stu_code = p_stu_code
      AND lecture_code = p_lecture_code;
    COMMIT;
END //

DELIMITER ;
-- 신청 Application_class
call Application_class(1,4);
call Application_class(2,3);
call Application_class(5,3);

-- 강의 코드 2번에 대한 조회
SELECT *
FROM applicant_dated
WHERE lecture_code = 2;
-- 4.수강신청 대기 조회
-- 대기열을 비율로 볼 수 있는 뷰 생성
CREATE OR REPLACE VIEW waitlist_public AS
SELECT
    w.lecture_code,
    s.subject_name,
    w.stu_code,
    -- 대기열 구간
    CASE
        WHEN ROW_NUMBER() OVER (PARTITION BY w.lecture_code ORDER BY w.date ASC)
             <= CEIL(0.2 * COUNT(*) OVER (PARTITION BY w.lecture_code))
        THEN '상위 20%'
        
        WHEN ROW_NUMBER() OVER (PARTITION BY w.lecture_code ORDER BY w.date ASC)
             <= CEIL(0.4 * COUNT(*) OVER (PARTITION BY w.lecture_code))
        THEN '상위 40%'
        
        WHEN ROW_NUMBER() OVER (PARTITION BY w.lecture_code ORDER BY w.date ASC)
             <= CEIL(0.8 * COUNT(*) OVER (PARTITION BY w.lecture_code))
        THEN '상위 80%'
        
        ELSE '상위 100%'
    END AS wait_group
FROM waitlist w
JOIN lecture l ON w.lecture_code = l.lecture_code
JOIN `subject` s ON l.subject_code = s.subject_code;
-- 학생 2의 1번 강의 대기열에 대해 조회
SELECT *
FROM waitlist_public
WHERE lecture_code =1 AND stu_code =2;
-- 5.대기 취소
-- 학생 1의 대기열 취소
SELECT *
  FROM applicant 
 WHERE stu_code = 2 ;
