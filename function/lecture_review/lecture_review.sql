-- 1. 강의 평가
-- 1.1 강의 평점 부여 및 후기 작성
-- 반드시 강의를 수강한 이력이 있는 학생만 부여 가능 	
-- 수강 히스토리 이력을 보고 수강 이력이 있는 학생들만 강의평가가 작성 가능한 프로시저 생성
-- (2025.09.02) 강의 평가 프로시저 안에 포인트 +15점 기능 추가
DELIMITER //
CREATE OR REPLACE PROCEDURE add_lecture_review(
    IN p_lecture_code BIGINT,
    IN p_stu_code BIGINT,
    IN p_review VARCHAR(500),
    IN p_load INT,
    IN p_difficulty INT,
    IN p_teaching INT,
    IN p_achievement INT,
    IN p_created_at DATE,
    IN p_updated_at DATE 
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
   
   -- lecture review table에 작성된 강의 평가 data 삽입
   INSERT INTO lecture_review (
	    lecture_code, stu_code, lecture_review, `load`, difficulty, teaching, achievement, created_at, updated_at
	) VALUES 
	    (p_lecture_code, p_stu_code, p_review, p_load, p_difficulty, p_teaching, p_achievement, p_created_at, p_updated_at
	);
	
	-- 포인트 히스토리에 기록
	-- 강의 평가 작성시 +15점 부여
	INSERT INTO point_history (stu_code, point_code, date)
   VALUES (
   	p_stu_code,
   	2,
    	CURDATE()
  	); 	
END //
DELIMITER ;

-- test case
CALL add_lecture_review(1,1,'수업이  체계적이고 이해하기 쉽다. 
									하지만 교수님의 정치 성향이 마음에 들지 않았다. 
									뭘 더 써야 될지 모르겠다. 각자 판단하길 바란다.',3,2,5,5,'2025-01-15','2025-01-15');

-- 1.2 강의 평가 열람
-- 강의 평가 열람시 매번 -5점 차감
-- 포인트 잔액 계산
-- 강의 평가 내용 반환
DELIMITER //
CREATE OR REPLACE PROCEDURE lecture_review_access(
  IN in_stu BIGINT,        -- 열람하는 학생(stu_code)
  IN in_lecture BIGINT     -- 대상 강의(lecture_code)
)
BEGIN
  DECLARE bal INT DEFAULT 0;	-- bal은 balance의 줄임말
  DECLARE v_need INT DEFAULT 5;

  -- 포인트 잔액 확인 
  -- point history에서 point code 다 찾아서 colesce로 합산 
  SELECT COALESCE(SUM(p.point_amount),0)
    INTO bal
  FROM point_history ph
  JOIN point p ON p.point_code = ph.point_code
  WHERE ph.stu_code = in_stu;

	-- 5점보다 낮으면 강의 열람 중단
  IF bal < v_need THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = '포인트 부족(열람 5점 필요)';
  END IF;

  START TRANSACTION;
    -- 5점 차감 기록
    INSERT INTO point_history (stu_code, point_code, date)
    VALUES (in_stu, 1, CURDATE());

    -- 강의평 목록 반환(원하면 정렬 변경 가능)
    SELECT lr.lecture_review_code,
           lr.stu_code,
           lr.lecture_code,
           lr.`load`, lr.difficulty, lr.teaching, lr.achievement,
           lr.lecture_review,
           lr.created_at, lr.updated_at
    FROM lecture_review lr
    WHERE lr.lecture_code = in_lecture
    ORDER BY lr.created_at DESC, lr.lecture_review_code DESC;
  COMMIT;
END//
DELIMITER ;

-- test case for 강의 평가 열람
CALL lecture_review_access(1, 1);

-- 1.3 본인 강의 평가 조회
-- 학생1 이라는 이름을 가진 학생의 강의 평가 조회
SELECT 	se.year AS '작성 날짜',  
			sb.subject_name AS '강의이름', 
			lr.lecture_review AS '강의평가'
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

    -- 1) 권한 확인
    SELECT a.role INTO auth
      FROM authorization a
      JOIN user u ON a.auth_code = u.auth_code
     WHERE u.user_code = p_user_code;

    -- 2) 학생이면: 본인 리뷰인지 확인
    IF auth = 'STUDENT' THEN
        IF NOT EXISTS (
            SELECT 1
              FROM lecture_review lr
              JOIN student s ON lr.stu_code = s.stu_code
             WHERE lr.lecture_review_code = p_lecture_review_code
               AND s.user_code = p_user_code
        ) THEN
            SIGNAL SQLSTATE '45000'
               SET MESSAGE_TEXT = '본인이 작성한 리뷰만 삭제할 수 있습니다.';
        END IF;
    END IF;

    -- 3) 리뷰 작성자 stu_code 가져오기
    SELECT stu_code
      INTO v_stu_code
      FROM lecture_review
     WHERE lecture_review_code = p_lecture_review_code;

    IF v_stu_code IS NULL THEN
        SIGNAL SQLSTATE '45000'
           SET MESSAGE_TEXT = '해당 리뷰가 존재하지 않습니다.';
    END IF;

    -- 4) 리뷰 삭제
    DELETE FROM lecture_review
     WHERE lecture_review_code = p_lecture_review_code;

    -- 5) 포인트 -15 기록 
    INSERT INTO point_history (stu_code, point_code, date)
    VALUES (v_stu_code, 4, CURDATE());
END //

DELIMITER ;
-- 학생이 리뷰 삭제
CALL delete_lecture_review(2, 4); 
-- 관리자가 리뷰 삭제
CALL delete_lecture_review(1, 5);  
