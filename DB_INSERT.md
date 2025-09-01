-- authorization
INSERT INTO authorization (auth_date, role) VALUES
('2025-01-01', 'ADMIN'),
('2025-01-02', 'STUDENT');


-- user
INSERT INTO user (auth_code, email, password, mobile, name) VALUES
(1, 'admin1@univ.ac.kr', 'pw1', '010-1111-1111', '관리자1'),
(2, 'student1@univ.ac.kr', 'pw2', '010-2222-2222', '학생1'),
(2, 'student2@univ.ac.kr', 'pw3', '010-3333-3333', '학생2');


-- college
INSERT INTO college (college_name) VALUES
('공과대학'),('문과대학'),('자연과학대학'),('예술대학'),('경영대학');

-- affiliation (학과/전공)
INSERT INTO affiliation (college_code, major_name) VALUES
(1, '컴퓨터공학과'),
(1, '전자공학과'),
(2, '영어영문학과'),
(3, '화학과'),
(5, '경영학과');

-- completion (이수구분)
INSERT INTO completion (division) VALUES
('MAJOR_REQUIRED'),
('MAJOR_ELECTIVE'),
('LIBERAL_ARTS');


-- semester
INSERT INTO semester (start_date, last_day_of_class, `year`) VALUES
('2025-03-01', '2025-06-30', '2025-01-01'),
('2025-09-01', '2025-12-15', '2025-01-01'),
('2026-03-01', '2026-06-30', '2026-01-01'),
('2026-09-01', '2026-12-15', '2026-01-01'),
('2027-03-01', '2027-06-30', '2027-01-01');

-- classroom
INSERT INTO classroom (building, room_num, capacity) VALUES
('IT관', 101, 50),
('IT관', 202, 80),
('문과관', 303, 40),
('자연대관', 404, 60),
('경영관', 505, 70);


-- professor
INSERT INTO professor (major_code, professor_name, mobile, email) VALUES
(1, '홍길동', '010-1111-9999', 'hong@univ.ac.kr'),
(2, '이순신', '010-2222-9999', 'lee@univ.ac.kr'),
(3, '김유신', '010-3333-9999', 'kim@univ.ac.kr'),
(4, '정약용', '010-4444-9999', 'jung@univ.ac.kr'),
(5, '안중근', '010-5555-9999', 'ahn@univ.ac.kr');

-- student
INSERT INTO student (major_code, user_code, grade, status) VALUES
(1, 2, 1, 'ENROLLED'),
(1, 3, 2, 'ENROLLED'),
(2, 2, 3, 'LEAVE'),
(3, 3, 4, 'GRADUATED'),
(5, 2, 1, 'ENROLLED');


-- subject
INSERT INTO subject (major_code, completion_type_code, subject_name, grade) VALUES
(1, 1, '자료구조', 3),
(1, 2, '운영체제', 3),
(2, 3, '전자회로', 2),
(3, 1, '영문법', 1),
(5, 2, '재무회계', 4);

-- administrator
INSERT INTO administrator (user_code, position) VALUES
(1, '학사과장'),
(1, '교무처장'),
(1, '행정실장'),
(1, '총무팀장'),
(1, '시설관리자');

-- lecture
INSERT INTO lecture (semester_code, subject_code, professor_code, classroom_code, admin_code, capacity, time, cancel, created_at, updated_at) VALUES
(1, 1, 1, 1, 1, 50, 1, 'N', '2025-01-01', '2025-01-01'),
(1, 2, 2, 2, 1, 40, 2, 'N', '2025-01-02', '2025-01-02'),
(2, 3, 3, 3, 2, 60, 3, 'N', '2025-01-03', '2025-01-03'),
(2, 4, 4, 4, 3, 70, 4, 'Y', '2025-01-04', '2025-01-04'),
(3, 5, 5, 5, 4, 80, 5, 'N', '2025-01-05', '2025-01-05');

-- course_book
INSERT INTO course_book (lecture_code, book_name, author, publisher) VALUES
(1, '알고리즘 기초', '김교수', '한빛미디어'),
(2, '운영체제 원리', '박교수', '교학사'),
(3, '전자회로 해설', '최교수', '대학서적'),
(4, '영문법의 이해', '이교수', '문과출판'),
(5, '재무회계 개론', '정교수', '경영출판');


-- applicant
INSERT INTO applicant (stu_code, lecture_code) VALUES
(1,1),(2,2),(3,3),(4,4),(5,5);

-- waitlist
INSERT INTO waitlist (lecture_code, stu_code, date) VALUES
(1,2,'2025-01-10'),
(2,3,'2025-01-11'),
(3,4,'2025-01-12'),
(4,5,'2025-01-13'),
(5,1,'2025-01-14');

-- basket
INSERT INTO basket (lecture_code, stu_code) VALUES
(1,1),(2,2),(3,3),(4,4),(5,5);

-- class_history
INSERT INTO class_history (stu_code, lecture_code) VALUES
(1,1),(2,2),(3,3),(4,4),(5,5);


-- point
INSERT INTO point (point_description, point_amount) VALUES
('회원가입 보너스', 100),
('강의평 작성', 50),
('출석 체크', 20),
('이벤트 참여', 200),
('추천인 보상', 150);

-- point_history
INSERT INTO point_history (stu_code, point_code, date) VALUES
(1,1,'2025-01-20'),
(2,2,'2025-01-21'),
(3,3,'2025-01-22'),
(4,4,'2025-01-23'),
(5,5,'2025-01-24');

-- notice
INSERT INTO notice (stu_code, notice_content, notice_date, notice_type) VALUES
(1,'대기자 등록됨','2025-01-10','WAITLIST_REGISTERED'),
(2,'수강신청 실패','2025-01-11','ENROLL_FAIL'),
(3,'신고 접수됨','2025-01-12','REPORT_RECEIVED'),
(4,'신고 처리 완료','2025-01-13','REPORTED'),
(5,'수강신청 성공','2025-01-14','WAITLIST_REGISTERED');

-- announcement
INSERT INTO announcement (admin_code, title, posted_date, content, image, public) VALUES
(1,'공지사항1','2025-01-01','내용1','img1.png','Y'),
(2,'공지사항2','2025-01-02','내용2','img2.png','Y'),
(3,'공지사항3','2025-01-03','내용3','img3.png','N'),
(4,'공지사항4','2025-01-04','내용4','img4.png','Y'),
(5,'공지사항5','2025-01-05','내용5','img5.png','N');


-- lecture_review
INSERT INTO lecture_review (lecture_code, stu_code, lecture_review, `load`, difficulty, teaching, achievement, created_at, updated_at) VALUES
(1,1,'수업이  체계적이고 이해하기 쉽다.',3,2,5,5,'2025-01-15','2025-01-15'),
(2,2,'교재가 어려웠지만 교수님 설명이 좋았다.',4,3,4,4,'2025-01-16','2025-01-16'),
(3,3,'실습 위주라서 도움이 많이 되었다.',5,4,5,5,'2025-01-17','2025-01-17'),
(4,4,'수업이 지루하고 과제가 많았다.',5,5,2,2,'2025-01-18','2025-01-18'),
(5,5,'현실적인 예제가 많아 좋았다.',3,3,4,5,'2025-01-19','2025-01-19');

-- report_type
INSERT INTO report_type (report_reason) VALUES
('욕설 포함'),
('허위 정보'),
('무의미한 글'),
('광고성 글'),
('기타');

-- lecture_review_report
INSERT INTO lecture_review_report (report_date, report_status, lecture_review_code, report_type_code) VALUES
('2025-01-20','Y',1,1),
('2025-01-21','N',2,2),
('2025-01-22','Y',3,3),
('2025-01-23','Y',4,4),
('2025-01-24','N',5,5);
