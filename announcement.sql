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

 -- 공지사항 작성
DELIMITER //
CREATE PROCEDURE sp_add_announcement (
    IN p_admin_code BIGINT,
    IN p_title VARCHAR(255),
    IN p_content TEXT,
    IN p_image VARCHAR(255),
    IN p_public ENUM('Y','N')
)
BEGIN
    -- 관리자 권한 체크
    IF EXISTS (SELECT 1 FROM administrator WHERE admin_code = p_admin_code) THEN
        INSERT INTO announcement (admin_code, title, content, image, posted_date, public)
        VALUES (p_admin_code, p_title, p_content, p_image, NOW(), p_public);
    ELSE
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '권한이 없습니다: 관리자만 공지사항을 작성할 수 있습니다.';
    END IF;
END //
DELIMITER ;

 -- 공지사항 삭제(soft delete)
DELIMITER //
CREATE PROCEDURE sp_delete_announcement (
    IN p_admin_code BIGINT,
    IN p_announcement_code BIGINT
)
BEGIN
    -- 관리자 권한 체크
    IF EXISTS (SELECT 1 FROM administrator WHERE admin_code = p_admin_code) THEN
        UPDATE announcement
        SET public = 'N'
        WHERE announcement_code = p_announcement_code;
    ELSE
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '권한이 없습니다: 관리자만 공지사항을 삭제할 수 있습니다.';
    END IF;
END //
DELIMITER ;

 -- 공지사항 수정
DELIMITER //
CREATE PROCEDURE sp_update_announcement (
    IN p_admin_code BIGINT,
    IN p_announcement_code BIGINT,
    IN p_title VARCHAR(255),
    IN p_content TEXT,
    IN p_image VARCHAR(255)
)
BEGIN
    -- 관리자 권한 체크
    IF EXISTS (SELECT 1 FROM administrator WHERE admin_code = p_admin_code) THEN
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



