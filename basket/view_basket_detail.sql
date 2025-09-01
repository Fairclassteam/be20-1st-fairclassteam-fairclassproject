-- 장바구니 상세조회 view
CREATE OR REPLACE VIEW v_basket_detail AS
SELECT
  b.basket_code,
  b.stu_code,
  v.*              -- v_lecture_search에 담긴 강의/과목/교수/시간표 등
FROM basket b
JOIN v_lecture_search v ON v.lecture_code = b.lecture_code;

-- 장바구니 담기
USE fairclass;

DROP PROCEDURE IF EXISTS sp_basket_add;

DELIMITER //
CREATE PROCEDURE sp_basket_add(IN p_stu_code BIGINT,IN p_lecture_code BIGINT)
BEGIN
  DECLARE v_semester BIGINT;
  DECLARE v_new_credits INT;          		-- 추가하려는 강의 학점 
  DECLARE v_curr_credits INT DEFAULT 0; 	-- 장바구니 총 학점 
  DECLARE v_max INT DEFAULT 18;       		-- 최대학점(고정)

-- 강의 유효/취소
  IF NOT EXISTS (
      SELECT 1 FROM lecture
      WHERE lecture_code = p_lecture_code AND cancel = 'N'
  ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = '유효하지 않거나 취소된 강의입니다.';
  END IF;

-- 이미 담았거나/중복수강 금지
  IF EXISTS (
      SELECT 1 FROM basket
      WHERE stu_code = p_stu_code AND lecture_code = p_lecture_code
  ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = '이미 장바구니에 담긴 강의입니다.';
  END IF;

  IF EXISTS (
      SELECT 1 FROM applicant
      WHERE stu_code = p_stu_code AND lecture_code = p_lecture_code
  ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = '이미 수강신청된 강의입니다.';
  END IF;

  IF EXISTS (
      SELECT 1 FROM class_history
      WHERE stu_code = p_stu_code AND lecture_code = p_lecture_code
  ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = '이미 이수한 강의입니다.';
  END IF;

  -- 학기/학점 
  SELECT l.semester_code
    INTO v_semester
  FROM lecture l
  WHERE l.lecture_code = p_lecture_code;

  SELECT s.grade
    INTO v_new_credits
  FROM lecture l
  JOIN subject s ON s.subject_code = l.subject_code
  WHERE l.lecture_code = p_lecture_code;

-- 현재 장바구니 학점
  SELECT COALESCE(SUM(s2.grade), 0)
    INTO v_curr_credits
  FROM basket b
  JOIN lecture l2 ON l2.lecture_code = b.lecture_code
  JOIN subject s2 ON s2.subject_code = l2.subject_code
  WHERE b.stu_code = p_stu_code
    AND l2.semester_code = v_semester;

  -- 최대학점 체크 
IF v_curr_credits + v_new_credits > v_max THEN
 SIGNAL SQLSTATE '45000'
   SET MESSAGE_TEXT = '최대학점 18점 초과입니다.';
END IF;

-- 동시간대 겹침 금지 
  IF EXISTS (
    SELECT 1
    FROM lecture_time t_new
    WHERE t_new.lecture_code = p_lecture_code
      AND EXISTS (
        SELECT 1
        FROM basket b
        JOIN lecture l_old    ON l_old.lecture_code = b.lecture_code
        JOIN lecture_time t_old ON t_old.lecture_code = l_old.lecture_code
        WHERE b.stu_code = p_stu_code
          AND l_old.semester_code = v_semester
          AND t_old.day_of_week = t_new.day_of_week
          AND t_old.start_time < t_new.end_time
          AND t_new.start_time < t_old.end_time
      )
  ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = '동시간대에 겹치는 강의가 장바구니에 있습니다.';
  END IF;

-- 담기 
  INSERT INTO basket(lecture_code, stu_code)
  VALUES (p_lecture_code, p_stu_code);
END //

DELIMITER ;

-- 테스트 
-- CALL fairclass.sp_basket_add(1, 5);
-- SELECT * FROM fairclass.basket WHERE stu_code=1 ORDER BY basket_code;


-- 장바구니 삭제 

DELIMITER //

DROP PROCEDURE IF EXISTS fairclass.sp_basket_remove
CREATE PROCEDURE fairclass.sp_basket_remove(IN p_stu_code BIGINT, IN p_lecture_code BIGINT)
BEGIN
  DECLARE v_basket BIGINT;
  DECLARE v_stu    BIGINT;
  DECLARE v_lec    BIGINT;

-- 장바구니 제거 대상 행 조회 (있으면 키 값 저장)
  SELECT basket_code, stu_code, lecture_code
    INTO v_basket, v_stu, v_lec
  FROM fairclass.basket
  WHERE stu_code = p_stu AND lecture_code = p_lec;

-- 대상 행 없으면 오류 
  IF v_basket IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '장바구니에서 해당 강의를 찾을 수 없습니다.';
  END IF;

-- 삭제 
  DELETE FROM fairclass.basket
  WHERE basket_code = v_basket;

-- 삭제된 정보 반환 
  SELECT v_basket AS removed_basket_code, v_lec AS lecture_code, v_stu AS stu_code;
END//
DELIMITER ;
-- 사용: CALL fairclass.sp_basket_remove(1, 2);

