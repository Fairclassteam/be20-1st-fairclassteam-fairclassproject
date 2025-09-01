
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
WHERE notice_code = 10
  AND stu_code = 1001;   -- 본인 알림만 삭제 가능

 -- 전체 알림 삭제 (학생 본인 것만)
DELETE FROM notice
WHERE stu_code = 1001;



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









--