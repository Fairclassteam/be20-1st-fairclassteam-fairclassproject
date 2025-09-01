CREATE OR REPLACE VIEW v_lecture_search AS
SELECT
  l.lecture_code,
  l.semester_code,
  l.capacity,
  l.cancel,
  s.subject_code,
  s.subject_name,
  s.grade,  -- 학점
  ct.division AS completion_division,  -- 전필/전선/교양
  a.major_code,
  a.major_name,
  c.college_name,
  p.professor_name,
  cr.building,
  cr.room_num,
  se.start_date,
  se.last_day_of_class,
  lt.schedule_text
FROM lecture l
JOIN subject      s  ON s.subject_code = l.subject_code
JOIN completion   ct ON ct.completion_type_code = s.completion_type_code
JOIN professor    p  ON p.professor_code = l.professor_code
JOIN classroom    cr ON cr.classroom_code = l.classroom_code
JOIN semester     se ON se.semester_code = l.semester_code
JOIN affiliation  a  ON a.major_code = s.major_code
JOIN college      c  ON c.college_code = a.college_code
LEFT JOIN (
  SELECT
    t.lecture_code,
    GROUP_CONCAT(
      CONCAT(t.day_of_week, ' ',
             TIME_FORMAT(t.start_time, '%H:%i'), '-', TIME_FORMAT(t.end_time, '%H:%i'))
      ORDER BY FIELD(t.day_of_week,'MON','TUE','WED','THU','FRI','SAT'), t.start_time
      SEPARATOR ', '
    ) AS schedule_text
  FROM lecture_time t
  GROUP BY t.lecture_code
) lt ON lt.lecture_code = l.lecture_code;

