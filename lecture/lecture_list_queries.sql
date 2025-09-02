-- 강의 조회 쿼리문 

-- 학과 검색 
SELECT *
FROM v_lecture_search
WHERE major_name    = '컴퓨터공학과'
  AND cancel = 'N'
ORDER BY lecture_code;

-- 요일/시간 검색
SELECT v.*
FROM v_lecture_search v
WHERE v.cancel = 'N'
  AND EXISTS (
      SELECT 1 FROM lecture_time t
      WHERE t.lecture_code = v.lecture_code
        AND t.day_of_week  = 'TUE'
        AND t.start_time >= '09:00:00'
        AND t.end_time <= '12:00:00'
  )
ORDER BY v.subject_name, v.lecture_code;

-- 이수 구분 검색
SELECT *
FROM v_lecture_search
WHERE completion_division = 'MAJOR_REQUIRED'  -- 전필 
	AND cancel = 'N'
ORDER BY lecture_code;

-- 강의 검색 
SELECT *
FROM v_lecture_search
WHERE subject_name  = '자료구조'
	AND cancel = 'N'
ORDER BY lecture_code;

-- 학점 검색
SELECT *
FROM v_lecture_search
WHERE grade = '3'
	AND cancel = 'N'
ORDER BY lecture_code;	


-- 학과/이수구분/과목이름/교수이름/시간 검색 
SELECT v.*
FROM v_lecture_search v
WHERE v.major_name = '컴퓨터공학과'   -- 전공
  AND v.completion_division = 'MAJOR_ELECTIVE'  -- 전선
  AND v.cancel = 'N'
  AND (
       v.subject_name   LIKE '%운영%'
    OR v.professor_name LIKE '%이순신%'
  )
  AND EXISTS (
      SELECT 1 FROM lecture_time t
      WHERE t.lecture_code = v.lecture_code
        AND t.day_of_week  = 'TUE'
        AND t.start_time < '12:00:00'
        AND '10:00:00'  < t.end_time
  )
ORDER BY v.lecture_code;
