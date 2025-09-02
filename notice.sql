 -- 알림  조회 (단순sql)
SELECT notice_code,
       notice_content,
       notice_type,
       notice_date
FROM notice
WHERE stu_code = 4
ORDER BY notice_date DESC;


-- 알림  조회(저장 프로시저)

DELIMITER //
CREATE PROCEDURE sp_get_student_notices (
    IN p_stu_code BIGINT
)
BEGIN
    SELECT notice_code,
           notice_content,
           notice_type,
           notice_date
    FROM notice
    WHERE stu_code = p_stu_code
    ORDER BY notice_date DESC;
END //
DELIMITER ;

-- 알림 삭제(단순sql)
-- 특정 알림 삭제
DELETE FROM notice
WHERE notice_code = 5
  AND stu_code = 2;   -- 본인 알림만 삭제 가능

 -- 전체 알림 삭제 (학생 본인 것만)
DELETE FROM notice
WHERE stu_code = 2;



-- 알림 삭제(저장 프로시저)
DELIMITER //
CREATE PROCEDURE sp_delete_student_notice (
    IN p_stu_code BIGINT,
    IN p_notice_code BIGINT
)
BEGIN
    DELETE FROM notice
    WHERE notice_code = p_notice_code
      AND stu_code = p_stu_code;
END //
DELIMITER ;




-- 1) 대기자 등록 완료 (대기열에 한 줄 추가되면 알림 생성)


DELIMITER //

CREATE OR REPLACE TRIGGER trg_waitlist_after_insert
AFTER INSERT ON waitlist
FOR EACH ROW
BEGIN
  INSERT INTO notice (notice_title, notice_content, user_code, created_at)
  VALUES (
    '대기자 등록 완료',
    NEW.stu_code,
    NOW()
  );
END//

DELIMITER ;

                                                -- 신고자 접수 알림(피신고자도 같이)


DELIMITER //

CREATE OR REPLACE PROCEDURE sp_report_review(
  IN in_stu BIGINT,        -- 신고자 stu_code
  IN in_review BIGINT,     -- 신고 대상 리뷰 코드(lecture_review.lecture_review_code)
  IN in_report_type INT    -- 신고 사유 코드(report_type.report_type_code)
)
BEGIN
  DECLARE v_target_stu BIGINT;  -- 피신고자(리뷰 작성자)

  -- 0) 자기 글 신고 금지 (원치 않으면 이 블록 삭제)
  IF EXISTS (
    SELECT 1
    FROM lecture_review
    WHERE lecture_review_code = in_review
      AND stu_code = in_stu
  ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = '본인 강의평가는 신고할 수 없습니다';
  END IF;

  -- 1) 피신고자(리뷰 작성자) 조회
  SELECT lr.stu_code
    INTO v_target_stu
  FROM lecture_review lr
  WHERE lr.lecture_review_code = in_review;

  -- 2) 신고 테이블 기록
  INSERT INTO lecture_review_report
        (report_date, report_status, lecture_review_code, report_type_code)
  VALUES (CURDATE(),   'N',          in_review,           in_report_type);

  -- 3) 알림 2건 생성
  -- 3-1) 신고자에게: 접수 알림
  INSERT INTO notice (stu_code, notice_content, notice_date, notice_type)
  VALUES (
    in_stu,
    CONCAT('신고가 접수되었습니다. 대상 리뷰#', in_review),
    CURDATE(),
    'REPORT_RECEIVED'     -- 필요시 코드값으로 바꿔도 됨
  );

  -- 3-2) 피신고자에게: 신고 당함 알림
  INSERT INTO notice (stu_code, notice_content, notice_date, notice_type)
  VALUES (
    v_target_stu,
    CONCAT('귀하의 강의후기(리뷰#', in_review, ')에 대한 신고가 접수되었습니다.'),
    CURDATE(),
    'REPORTED'
  );
END//

DELIMITER ;



 -- 테스트 케이스
CALL sp_report_review(2, 3, 1);

 SELECT * FROM lecture_review_report ORDER BY report_date DESC LIMIT 5;
SELECT * FROM notice ORDER BY notice_date DESC, stu_code LIMIT 10;
 
                                                  -- 포인트 적립시 알림 
 
 
DELIMITER //

CREATE OR REPLACE TRIGGER trg_lecture_review_after_insert
AFTER INSERT ON lecture_review
FOR EACH ROW
BEGIN
  /* +15 적립 (원장 기록) */
  INSERT INTO point_history (stu_code, point_code, date)
  VALUES (
    NEW.stu_code,
    (SELECT point_code FROM point WHERE point_description='강의평가 작성' LIMIT 1),
    CURDATE()
  );

  /* 알림 */
  INSERT INTO notice (notice_title, notice_content, user_code, created_at)
  VALUES (
    '강의후기 작성 포인트 +15',
    '후기 작성으로 포인트 15점이 적립되었습니다.',
    NEW.stu_code,
    NOW()
  );
END//

DELIMITER ;


                                                -- 강의 열람시 포인트 차감 알림

DELIMITER //

CREATE OR REPLACE PROCEDURE sp_view_review_and_charge(
  IN in_stu    BIGINT,   -- 열람하는 학생(stu_code)
  IN in_review BIGINT    -- 열람 대상 리뷰(review_code) - 필요 시 로깅용
)
BEGIN
  DECLARE bal INT DEFAULT 0;

  START TRANSACTION;

  /* 현재 잔액 계산 (동시성 보호용 FOR UPDATE) */
  SELECT COALESCE(SUM(p.point_amount), 0)
    INTO bal
  FROM point_history ph
  JOIN point p ON p.point_code = ph.point_code
  WHERE ph.stu_code = in_stu
  FOR UPDATE;

  /* 잔액 부족 시 차단 */
  IF bal < 5 THEN
    ROLLBACK;
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = '포인트 부족(열람 5점 필요)';
  END IF;

  /* -5 차감 (원장 기록) */
  INSERT INTO point_history (stu_code, point_code, date)
  VALUES (
    in_stu,
    (SELECT point_code FROM point WHERE point_description = '강의평가 열람' LIMIT 1),
    CURDATE()
  );

  /* 알림 */
  INSERT INTO notice (notice_title, notice_content, user_code, created_at)
  VALUES (
    '강의평가 열람 포인트 -5',
    '강의평가 열람으로 포인트 5점이 차감되었습니다.',
    in_stu,
    NOW()
  );

  COMMIT;
END//

DELIMITER ;







--
