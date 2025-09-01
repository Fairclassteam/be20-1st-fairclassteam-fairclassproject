-- 1. 강의 평가
-- 1.1 강의 평점 부여 및 후기 작성
-- 반드시 강의를 수강한 이력이 있는 학생만 부여 가능 	
-- 수강 히스토리 이력을 보고 수강 이력이 있는 학생들만 강의평가가 작성 가능한 프로시저 생성
DELIMITER //
CREATE OR REPLACE PROCEDURE add_lecture_review(
    IN p_lecture_code BIGINT,
    IN p_stu_code BIGINT,
    IN p_review VARCHAR(500),
    IN p_load INT,
    IN p_difficulty INT,
    IN p_teaching INT,
    IN p_achievement INT
)
BEGIN 
   -- 학생이 강의를 수강했는지 확인 
   if (SELECT COUNT(*) FROM class_history WHERE lecture_code = p_lecture_code) = 0 then
       SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '수강한 강의 이력이 존재하지 않아 작성할 수 없습니다.';
   END if;
   
   -- 리뷰는 최소 50자 이상으로 작성
   if CHAR_LENGTH(p_review) < 50 then
   	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '강의 후기는 50자 이상으로 작성해야합니다.';
   END if;
   
   INSERT INTO lecture_review (
	    lecture_code, stu_code, lecture_review, `load`, difficulty, teaching, achievement, created_at, updated_at
	) VALUES 
	    (p_lecture_code, p_stu_code, p_review, p_load, p_difficulty, p_teaching, p_achievement
	);
END //
DELIMITER ;
CALL add_lecture_review(1,1,'수업이  체계적이고 이해하기 쉽다.',3,2,5,5,'2025-01-15','2025-01-15');
CALL add_lecture_review(2,2,'교재가 어려웠지만 교수님 설명이 좋았다.',4,3,4,4,'2025-01-16','2025-01-16');
CALL add_lecture_review(3,3,'실습 위주라서 도움이 많이 되었다.',5,4,5,5,'2025-01-17','2025-01-17');
CALL add_lecture_review(4,4,'수업이 지루하고 과제가 많았다.',5,5,2,2,'2025-01-18','2025-01-18');
CALL add_lecture_review(5,5,'현실적인 예제가 많아 좋았다.',3,3,4,5,'2025-01-19','2025-01-19');  
-- 수강 히스토리에 6번 강의는 없으므로 SQL 오류 (1644): 수강한 강의 이력이 존재하지 않아 작성할 수 없습니다. 출력
-- 수강 히스토리에 강의 내역이 있지만 강의 후기가 50자가 안되므로 오류 출력
CALL add_lecture_review(6,5,'예제가 많아 좋았다.',5,5,5,5);

-- 1.2 강의 평가 열람
SELECT *
  FROM lecture_review;

INSERT INTO point_history(stu_code, point_code, DATE) 
VALUES (1,1,CURDATE());

-- 1.3 본인 강의 평가 조회
-- 학생1 이라는 이름을 가진 학생의 강의 평가 조회
SELECT DATE_FORMAT(se.year, '%Y') AS 작성년도, se.start_date AS 개강일 , se.last_day_of_class  AS 종강일 , sb.subject_name AS 강의이름, lr.lecture_review AS 강의평가
  FROM lecture_review lr
  JOIN student s ON lr.stu_code = s.stu_code
  JOIN lecture l ON l.lecture_code = lr.lecture_code
  JOIN user u ON u.user_code  = s.user_code
  JOIN subject sb ON l.subject_code = sb.subject_code	
  JOIN semester se ON l.semester_code = se.semester_code
 WHERE u.`name` = '학생1';

-- 1.4 강의 평가 삭제
DELIMITER //
CREATE OR REPLACE PROCEDURE delete_lecture_review(
    IN p_user_code BIGINT,
    IN p_lecture_review_code BIGINT
)
BEGIN
    DECLARE auth VARCHAR(20);
    DECLARE v_stu_code BIGINT;

    -- 1) 학생인지 권한인지 확인
    SELECT role INTO auth 
    FROM authorization a
    JOIN user u ON a.auth_code = u.auth_code
    WHERE u.user_code = p_user_code;
    -- 2) 학생일 경우 → 본인이 쓴 리뷰만 삭제 가능
    IF auth = 'STUDENT' THEN
        IF NOT EXISTS (
            SELECT 1
            FROM lecture_review lr
            JOIN student s ON lr.stu_code = s.stu_code
            WHERE lr.lecture_review_code = p_lecture_review_code
              AND s.user_code = p_user_code) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '본인이 작성한 리뷰만 삭제할 수 있습니다.';
        END IF;
    END IF;
    -- 3) 관리자일 경우 → 해당 리뷰가 신고되었는지 확인
    IF auth = 'ADMIN' THEN
        IF NOT EXISTS (
            SELECT 1
            FROM lecture_review_report r
            WHERE r.lecture_review_code = p_lecture_review_code) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '신고 접수된 리뷰만 삭제할 수 있습니다.';
        END IF;
    END IF;
    -- 4) 리뷰 작성자 확인 (학생 or 관리자)
    SELECT stu_code INTO v_stu_code
    FROM lecture_review
    WHERE lecture_review_code = p_lecture_review_code;
    -- 5) 리뷰 삭제( 
    DELETE FROM lecture_review
    WHERE lecture_review_code = p_lecture_review_code;
    -- 6) 포인트 -15 기록
    INSERT INTO point_history (stu_code, point_code, date)
    VALUES (v_stu_code, 3, CURDATE());
END //
DELIMITER ;
-- 학생이 리뷰 삭제
CALL delete_lecture_review(2, 4); 
-- 관리자가 리뷰 삭제
CALL delete_lecture_review(1, 5);  