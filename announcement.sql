 -- 공지사항 목록조회
SELECT announcement_code,
       title,
       posted_date,
       public
FROM announcement
WHERE public = 'Y'
ORDER BY posted_date DESC;

 -- 공지사항 상세조회
SELECT *
FROM announcement
WHERE announcement_code = 3;

 -- 프로시져 삭제
DROP PROCEDURE sp_add_announcment;
SHOW PROCEDURE STATUS WHERE Db = 'fairclass';

 -- 공지사항 작성
DELIMITER //
CREATE PROCEDURE sp_add_announcement (
    IN p_user_code BIGINT,
    IN p_title VARCHAR(255),
    IN p_content TEXT,
    IN p_image VARCHAR(255),
    IN p_public ENUM('Y','N')
)
BEGIN
    -- 관리자 권한 체크
    IF EXISTS (SELECT 1 FROM administrator WHERE user_code = p_user_code) THEN
        INSERT INTO announcement (admin_code, title, content, image, posted_date, public)
        VALUES (p_user_code, p_title, p_content, p_image, NOW(), p_public);
    ELSE
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '권한이 없습니다: 관리자만 공지사항을 작성할 수 있습니다.';
    END IF;
END //
DELIMITER ;
 -- 테스트 케이스(공지사항 작성)
CALL sp_add_announcement(
    1,                          -- p_user_code (여기서는 admin_code와 같음)
    '테스트 공지',               -- p_title
    '테스트 내용입니다',         -- p_content
    'test.png',                 -- p_image
    'Y'                         -- p_public
);

SELECT * FROM announcement ORDER BY posted_date DESC;

 -- 관리자 아닌 계정
CALL sp_add_announcement(
    2,                        -- 존재하지 않는 admin_code
    '잘못된 공지',               -- p_title
    '학생이 작성하려는 내용',    -- p_content
    NULL,                       -- p_image
    'Y'                         -- p_public
);


DROP PROCEDURE sp_delete_announcement;

 -- 공지사항 삭제(soft delete)
-- 관리자만 공지 비공개(삭제) 처리

DROP PROCEDURE sp_set_announcement_visibility;

DELIMITER //

CREATE OR REPLACE PROCEDURE fairclass.sp_set_announcement_visibility (
  IN p_user_code BIGINT,          -- 요청자 user_code
  IN p_announcement_code BIGINT,  -- 대상 공지 PK
  IN p_public ENUM('Y','N')       -- 'Y' = 공개, 'N' = 비공개
)
BEGIN
  DECLARE v_admin_code BIGINT;

  -- 1) user_code → administrator 매핑 (관리자 여부 확인)
  SELECT a.admin_code
    INTO v_admin_code
  FROM fairclass.administrator a
  WHERE a.user_code = p_user_code
  LIMIT 1;

  IF v_admin_code IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = '권한이 없습니다: 관리자만 공지 공개 여부를 변경할 수 있습니다.';
  END IF;

  -- 2) 지정한 공개 여부로 상태 변경 (같으면 변경 없음)
  UPDATE fairclass.announcement
     SET public     = p_public
   WHERE announcement_code = p_announcement_code
     AND public <> p_public;
END//

DELIMITER ;


 
 -- 테스트케이스(공지사항 삭제)
CALL fairclass.sp_set_announcement_visibility(2, 4,'N');


SELECT announcement_code, title, public 
FROM announcement
WHERE announcement_code = 4;
 
 
CALL fairclass.sp_set_announcement_visibility(2, 4);

SELECT announcement_code, title, public 
FROM announcement
WHERE announcement_code = 3;

 
  

 
 
 
 
 
 
 -- 공지사항 수정
DELIMITER //
CREATE PROCEDURE sp_update_announcement (
    IN p_user_code BIGINT,
    IN p_announcement_code BIGINT,
    IN p_title VARCHAR(255),
    IN p_content TEXT,
    IN p_image VARCHAR(255)
)
BEGIN
    -- 관리자 권한 체크
    IF EXISTS (SELECT 1 FROM administrator WHERE user_code = p_user_code) THEN
        UPDATE announcement
        SET title = p_title,
            content = p_content,
            image = p_image,
            posted_date = NOW()
        WHERE announcement_code = p_announcement_code;
    ELSE
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '권한이 없습니다: 관리자만 공지사항을 수정할 수 있습니다.';
    END IF;
END //
DELIMITER ;

 -- 테스트크케이스(수정)
CALL sp_update_announcement(
    1,                      -- 관리자 user_code
    5,                      -- 수정할 공지번호
    '수정된 제목',           -- 새 제목
    '수정된 내용',           -- 새 내용
    'update.png'            -- 새 이미지
);


SELECT announcement_code, title, content, image, posted_date
FROM announcement
WHERE announcement_code = 5;



 -- 공지사항 목록 조회(프로시저)
DROP PROCEDURE IF EXISTS sp_get_announcements;

DELIMITER //
CREATE PROCEDURE sp_get_announcements ()
BEGIN
    SELECT announcement_code,
           title,
           posted_date,
           public
    FROM announcement
    WHERE public = 'Y'
    ORDER BY posted_date DESC;
END //
DELIMITER ;


 -- 공지사항 상세 조회(프로시저)
DROP PROCEDURE IF EXISTS sp_get_announcement_detail;

DELIMITER //
CREATE PROCEDURE sp_get_announcement_detail (
    IN p_announcement_code BIGINT
)
BEGIN
    SELECT *
    FROM announcement
    WHERE announcement_code = p_announcement_code;
END //
DELIMITER ;

