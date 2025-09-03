-- point & report function


-- 0. Safety (Check whether tables exist)
-- 이미 있다면 아무 일도 안 함
INSERT IGNORE INTO point (point_description, point_amount)
SELECT '강의평가 열람', -5 WHERE NOT EXISTS (SELECT 1 FROM point WHERE point_description='강의평가 열람');
INSERT IGNORE INTO point (point_description, point_amount)
SELECT '강의평가 작성', 15 WHERE NOT EXISTS (SELECT 1 FROM point WHERE point_description='강의평가 작성');
INSERT IGNORE INTO point (point_description, point_amount)
SELECT '초기 포인트', 10 WHERE NOT EXISTS (SELECT 1 FROM point WHERE point_description='초기 포인트');

-- 1. 포인트 관리 관련 기능
-- 1-1. 학생 포인트 잔액/내역 조회
-- 잔액 뷰
CREATE OR REPLACE VIEW v_student_point_balance AS
SELECT ph.stu_code,
       COALESCE(SUM(p.point_amount), 0) AS balance
FROM point_history ph
JOIN point p ON p.point_code = ph.point_code
GROUP BY ph.stu_code;

-- test case: 특정 학생 내역 (stu_code = 1인 학생)
SELECT ph.use_code, ph.date, p.point_description, p.point_amount
FROM point_history ph
JOIN point p ON p.point_code = ph.point_code
WHERE ph.stu_code = 1
ORDER BY ph.date DESC, ph.use_code DESC;

-- test case: 특정 학생 잔액 (stu_code = 1인 학생)
SELECT balance
FROM v_student_point_balance
WHERE stu_code = 1;

-- 1-2. 초기 포인트 10점 1회 부여 (관리자)
DELIMITER //
CREATE OR REPLACE PROCEDURE sp_grant_initial_points_once(IN in_stu BIGINT)
BEGIN
  IF NOT EXISTS (
      SELECT 1 FROM point_history ph
      JOIN point p ON p.point_code = ph.point_code
      WHERE ph.stu_code = in_stu
        AND p.point_description = '초기 포인트'
  ) THEN
    INSERT INTO point_history (stu_code, point_code, date)
    VALUES (
      in_stu,
      (SELECT point_code FROM point WHERE point_description='초기 포인트' LIMIT 1),
      CURDATE()
    );
  END IF;
END//
DELIMITER ;
-- 사용: 

CALL sp_grant_initial_points_once(1);

-- 1-3. 강의평 작성 완료 시 +15점 부여 (trigger 구문으로 작성해서 시스템 자동화 암시)
-- DELIMITER //
-- CREATE OR REPLACE TRIGGER trg_lecture_review_point
-- AFTER INSERT ON lecture_review
-- FOR EACH ROW
-- BEGIN
--   INSERT INTO point_history (stu_code, point_code, date)
--   VALUES (
--     NEW.stu_code,
--     (SELECT point_code FROM point WHERE point_description='강의평가 작성' LIMIT 1),
--     CURDATE()
--   );
-- END //
-- DELIMITER ;

-- test for the trigger statement




-- 1-4. 강의평 열람시 -5 차감 
DELIMITER //
CREATE OR REPLACE PROCEDURE sp_view_review_and_charge(IN in_stu BIGINT, IN in_review BIGINT)
BEGIN
	-- bal은 포인트 잔액, 일단 0으로 초기화되어 있음
  DECLARE bal INT DEFAULT 0;

  -- 잔액 확인 
  SELECT COALESCE(SUM(p.point_amount),0) -- coalesce 구문을 통해서 NULL이 아닌 첫 값을 select
    INTO bal
    FROM point_history ph
    JOIN point p ON p.point_code = ph.point_code
   WHERE ph.stu_code = in_stu;

	-- 차감 점수 5점보다 작으면 system 상에서 에러 구문 발생
  IF bal < 5 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '포인트 부족(열람 5점 필요)';
  END IF;

  START TRANSACTION;
    -- 5점 차감 기록
    INSERT INTO point_history (stu_code, point_code, date)
    VALUES (
      in_stu,
      (SELECT point_code FROM point WHERE point_description='강의평가 열람' LIMIT 1),
      CURDATE()
    );

    -- 강의평 반환
    SELECT lr.lecture_review_code, lr.lecture_code, lr.stu_code,
           lr.`load`, lr.difficulty, lr.teaching, lr.achievement,
           lr.lecture_review, lr.created_at
    FROM lecture_review lr
    WHERE lr.lecture_review_code = in_review;
  COMMIT;
END //
DELIMITER ;
-- 사용: CALL sp_view_review_and_charge(1, 3);

-- 2. 신고 관리
-- 2-1. 신고 사유 선택 목록
SELECT report_type_code, report_reason
FROM report_type
ORDER BY report_type_code;

-- 2-2. 강의평 신고 등록
-- student code, report type 
DELIMITER //
CREATE OR REPLACE PROCEDURE sp_report_review(
  IN in_stu BIGINT,
  IN in_review BIGINT,
  IN in_report_type INT
)
BEGIN
  -- 자기 글은 신고 불가(원하면 주석 해제)
  IF EXISTS (
    SELECT 1 FROM lecture_review
    WHERE lecture_review_code = in_review AND stu_code = in_stu
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '본인 강의평은 신고할 수 없습니다';
  END IF;

	-- 강의 평가 신고 table에 신고 data 삽입
  INSERT INTO lecture_review_report (report_date, report_status, lecture_review_code, report_type_code)
  VALUES (CURDATE(), 'N', in_review, in_report_type);	-- report status Y or N으로 관리

 
END //
DELIMITER ;

-- test case
CALL sp_report_review(1, 3, 2);

-- 2-3. 신고 내용 조회
-- 전체(최신 우선)
SELECT r.report_code, r.report_date, r.report_status,
       rt.report_reason,
       lr.lecture_review_code, lr.lecture_code,
       lr.lecture_review,
       lr.stu_code AS writer_stu_code
FROM lecture_review_report r
JOIN report_type rt ON rt.report_type_code = r.report_type_code
JOIN lecture_review lr ON lr.lecture_review_code = r.lecture_review_code
ORDER BY r.report_date DESC, r.report_code DESC; -- 최신 date 우선

-- 미처리만 (선택 사항, GPT가 추천했으나 핵심 기능이 아니라고 판단)
-- SELECT r.*
-- FROM lecture_review_report r
-- WHERE r.report_status = 'N'
-- ORDER BY r.report_date DESC, r.report_code DESC;

-- 2-4. 신고처리 및 패널티 부여
DELIMITER //
CREATE OR REPLACE PROCEDURE sp_apply_report_penalty(
  IN in_report_code BIGINT,
  IN in_penalty_point_code INT
)
BEGIN
  -- 신고 대상 강의평 작성자 찾기
  DECLARE target_stu BIGINT;

  SELECT lr.stu_code
    INTO target_stu
  FROM lecture_review_report r
  JOIN lecture_review lr ON lr.lecture_review_code = r.lecture_review_code
  WHERE r.report_code = in_report_code
  FOR UPDATE;

  IF target_stu IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '잘못된 report_code';
  END IF;

  START TRANSACTION;
    -- 신고 처리 상태 갱신
    UPDATE lecture_review_report
    SET report_status = 'Y'
    WHERE report_code = in_report_code;

    -- 패널티 부여(음수 포인트)
    INSERT INTO point_history (stu_code, point_code, date)
    VALUES (target_stu, in_penalty_point_code, CURDATE());

   
  COMMIT;
END //
DELIMITER ;

-- test case
CALL sp_apply_report_penalty(1, (SELECT point_code FROM point WHERE point_description='신고 패널티' LIMIT 1));


