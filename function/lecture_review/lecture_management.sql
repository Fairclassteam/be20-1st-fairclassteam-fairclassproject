-- 2. 강의 관리 

-- 2-1 강의 등록 (관리자)
-- 강의 테이블에 학기 번호, 과목 번호, 교수 번호, 강의실 번호, 관리자 번호, 정원, 강의 시간, 
-- 폐강 여부, 등록 날짜, 수정 날짜를 입력하여 강의 등록
INSERT INTO lecture (semester_code, subject_code, professor_code, classroom_code, admin_code, capacity, time, cancel, created_at, updated_at) VALUES
(1, 1, 1, 1, 1, 40, 1, 'N', '2025-01-01', '2025-01-01'),
(1, 2, 2, 2, 1, 40, 2, 'N', '2025-01-02', '2025-01-02'),
(2, 3, 3, 3, 2, 40, 3, 'N', '2025-01-03', '2025-01-03'),
(2, 4, 4, 4, 3, 40, 4, 'Y', '2025-01-04', '2025-01-04'),
(3, 5, 5, 5, 4, 40, 5, 'N', '2025-01-05', '2025-01-05');

-- 2-2 강의 수정(관리자)
--  강의 학기 수정, 강의 학기 수정 시 수정 날짜도 변경
UPDATE lecture l
  JOIN semester s ON l.semester_code = s.semester_code
   SET l.semester_code = 2,
       updated_at = CURDATE()
 WHERE lecture_code = 1;
  
SELECT * FROM lecture;

-- 강의 폐강 여부
UPDATE lecture
SET cancel = 'Y',
    updated_at = CURDATE()
WHERE lecture_code = 1;
