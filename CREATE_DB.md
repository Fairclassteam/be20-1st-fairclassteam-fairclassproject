-- 기존 테이블이 있으면 모두 삭제 (외래키 제약 때문에 역순 삭제)
DROP TABLE IF EXISTS lecture_review_report;
DROP TABLE IF EXISTS lecture_review;
DROP TABLE IF EXISTS report_type;
DROP TABLE IF EXISTS course_book;
DROP TABLE IF EXISTS point_history;
DROP TABLE IF EXISTS point;
DROP TABLE IF EXISTS applicant;
DROP TABLE IF EXISTS waitlist;
DROP TABLE IF EXISTS basket;
DROP TABLE IF EXISTS class_history;
DROP TABLE IF EXISTS lecture;
DROP TABLE IF EXISTS classroom;
DROP TABLE IF EXISTS subject;
DROP TABLE IF EXISTS completion;
DROP TABLE IF EXISTS professor;
DROP TABLE IF EXISTS student;
DROP TABLE IF EXISTS affiliation;
DROP TABLE IF EXISTS college;
DROP TABLE IF EXISTS semester;
DROP TABLE IF EXISTS notice;
DROP TABLE IF EXISTS announcement;
DROP TABLE IF EXISTS administrator;
DROP TABLE IF EXISTS user;
DROP TABLE IF EXISTS authorization;

-- 0) 기초 테이블  ------------------------------------------------------------

CREATE TABLE authorization (
  auth_code   BIGINT NOT NULL AUTO_INCREMENT,
  auth_date   DATE        NOT NULL,
  role        VARCHAR(50) NOT NULL,
  PRIMARY KEY (auth_code)
) ENGINE=INNODB;

CREATE TABLE user (
	user_code	BIGINT	NOT NULL AUTO_INCREMENT,
	auth_code	BIGINT	NOT NULL ,
	email	varchar(255)	NOT NULL,
	password	varchar(255)	NOT NULL,
	mobile	varchar(255)	NOT NULL,
	name	varchar(255)	NOT NULL,
	PRIMARY KEY (user_code),
  FOREIGN KEY (auth_code) 
  REFERENCES authorization(auth_code)
)ENGINE=INNODB;

CREATE TABLE college (
  college_code INT NOT NULL AUTO_INCREMENT,
  college_name VARCHAR(255) NOT NULL,
  PRIMARY KEY (college_code)
) ENGINE=INNODB;

CREATE TABLE affiliation (
  major_code BIGINT NOT NULL AUTO_INCREMENT,
  college_code INT NOT NULL,
  major_name VARCHAR(255) NOT NULL,
  PRIMARY KEY (major_code),
  FOREIGN KEY (college_code) 
  REFERENCES college(college_code)
) ENGINE=INNODB;

CREATE TABLE completion (
  completion_type_code BIGINT NOT NULL AUTO_INCREMENT,
  --  - MAJOR_REQUIRED : 전공필수
  --  - MAJOR_ELECTIVE : 전공선택
  --  - LIBERAL_ARTS   : 교양
  division ENUM('MAJOR_REQUIRED','MAJOR_ELECTIVE','LIBERAL_ARTS') NOT NULL,
  PRIMARY KEY (completion_type_code)
) ENGINE=InnoDB;


CREATE TABLE semester (
  semester_code   BIGINT  NOT NULL AUTO_INCREMENT,
  start_date      TIMESTAMP  NOT NULL,
  last_day_of_class TIMESTAMP NOT NULL,
  `year`          DATE       NOT NULL,
  PRIMARY KEY (semester_code)
) ENGINE=INNODB;

CREATE TABLE classroom (
  classroom_code BIGINT   NOT NULL AUTO_INCREMENT,
  building       VARCHAR(255) NOT NULL,
  room_num       INT          NOT NULL,
  capacity       INT          NOT NULL,
  PRIMARY KEY (classroom_code)
) ENGINE=INNODB;

-- 1) 인사/학생/교수 ------------------------------------------------------
CREATE TABLE professor (
  professor_code BIGINT NOT NULL AUTO_INCREMENT,
  major_code     BIGINT NOT NULL,
  professor_name VARCHAR(255) NOT NULL,
  mobile         VARCHAR(255) NOT NULL,
  email          VARCHAR(255) NOT NULL,
  PRIMARY KEY (professor_code),
  FOREIGN KEY (major_code) REFERENCES affiliation(major_code)
) ENGINE=INNODB;

CREATE TABLE student (
  stu_code   BIGINT NOT NULL AUTO_INCREMENT,
  major_code BIGINT NOT NULL,
  user_code  BIGINT NOT NULL,
  grade      INT    NOT NULL,
  status     ENUM('ENROLLED','LEAVE','GRADUATED') NOT NULL,  -- 예: ENROLLED/LEAVE/GRADUATED 등
  PRIMARY KEY (stu_code),
  FOREIGN KEY (major_code) REFERENCES affiliation(major_code),
  FOREIGN KEY (user_code)  REFERENCES user(user_code)
) ENGINE=INNODB;

-- 2) 과목/강의/교재 ----------------------------------------------------------

CREATE TABLE subject (
  subject_code         BIGINT       NOT NULL AUTO_INCREMENT,
  major_code           BIGINT       NOT NULL,
  completion_type_code BIGINT       NOT NULL,
  subject_name         VARCHAR(255) NOT NULL,
  grade                INT          NOT NULL,
  PRIMARY KEY (subject_code),
  FOREIGN KEY (major_code) REFERENCES affiliation(major_code),
  FOREIGN KEY (completion_type_code) REFERENCES completion(completion_type_code)
) ENGINE=INNODB;

CREATE TABLE administrator (
  admin_code BIGINT NOT NULL AUTO_INCREMENT,
  user_code  BIGINT NOT NULL,
  position   VARCHAR(255) NOT NULL,
  PRIMARY KEY (admin_code),
  FOREIGN KEY (user_code) REFERENCES user(user_code)
) ENGINE=INNODB;

CREATE TABLE lecture (
  lecture_code    BIGINT       NOT NULL AUTO_INCREMENT,
  semester_code   BIGINT       NOT NULL,
  subject_code    BIGINT       NOT NULL,
  professor_code  BIGINT       NOT NULL,
  classroom_code  BIGINT       NOT NULL,
  admin_code      BIGINT       NOT NULL,
  capacity        INT          NOT NULL,
  time            INT          NOT NULL,
  cancel          ENUM('Y','N') NOT NULL,
  created_at      DATE         NULL,
  updated_at      DATE         NULL,
  PRIMARY KEY (lecture_code),
  FOREIGN KEY (semester_code)  REFERENCES semester(semester_code),
  FOREIGN KEY (subject_code)   REFERENCES subject(subject_code),
  FOREIGN KEY (professor_code) REFERENCES professor(professor_code),
  FOREIGN KEY (classroom_code) REFERENCES classroom(classroom_code),
  FOREIGN KEY (admin_code)     REFERENCES administrator(admin_code)
) ENGINE=INNODB;

CREATE TABLE course_book (
  book_code    BIGINT       NOT NULL AUTO_INCREMENT,
  lecture_code BIGINT       NOT NULL,
  book_name    VARCHAR(255) NULL,
  author       VARCHAR(255) NULL,
  publisher    VARCHAR(255) NULL,
  PRIMARY KEY (book_code),
  FOREIGN KEY (lecture_code) REFERENCES lecture(lecture_code)
) ENGINE=INNODB;

-- 3) 수강신청/대기/장바구니/수강이력 ----------------------------------------

CREATE TABLE applicant (
  stu_code     BIGINT NOT NULL,
  lecture_code BIGINT NOT NULL,
  applied_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (stu_code, lecture_code),
  FOREIGN KEY (stu_code)     REFERENCES student(stu_code),
  FOREIGN KEY (lecture_code) REFERENCES lecture(lecture_code)
) ENGINE=INNODB;

CREATE TABLE waitlist (
  waitlist_code BIGINT NOT NULL AUTO_INCREMENT,
  lecture_code  BIGINT NOT NULL,
  stu_code      BIGINT NOT NULL,
  date          DATE   NOT NULL,
  PRIMARY KEY (waitlist_code),
  FOREIGN KEY (lecture_code) REFERENCES lecture(lecture_code),
  FOREIGN KEY (stu_code)     REFERENCES student(stu_code)
) ENGINE=INNODB;

CREATE TABLE basket (
  basket_code  BIGINT NOT NULL AUTO_INCREMENT,
  lecture_code BIGINT NOT NULL,
  stu_code     BIGINT NOT NULL,
  PRIMARY KEY (basket_code),
  FOREIGN KEY (lecture_code) REFERENCES lecture(lecture_code),
  FOREIGN KEY (stu_code)     REFERENCES student(stu_code)
) ENGINE=INNODB;

CREATE TABLE class_history (
  history_code BIGINT NOT NULL AUTO_INCREMENT,
  stu_code     BIGINT NOT NULL,
  lecture_code BIGINT NOT NULL,
  PRIMARY KEY (history_code, stu_code),
  FOREIGN KEY (stu_code)     REFERENCES student(stu_code),
  FOREIGN KEY (lecture_code) REFERENCES lecture(lecture_code)
) ENGINE=INNODB;

-- 4) 포인트/공지/알림 --------------------------------------------------------

-- 포인트 발생값
CREATE TABLE POINT   (
  point_code        INT          NOT NULL AUTO_INCREMENT,
  point_description VARCHAR(255) NULL,
  point_amount      INT          NULL,
  PRIMARY KEY (point_code)
) ENGINE=INNODB;

CREATE TABLE point_history (
  use_code   INT    NOT NULL AUTO_INCREMENT,
  stu_code   BIGINT NOT NULL,
  point_code INT    NOT NULL,
  date       DATE   NOT NULL,
  PRIMARY KEY (use_code),
  FOREIGN KEY (stu_code)   REFERENCES student(stu_code),
  FOREIGN KEY (point_code) REFERENCES point(point_code)
) ENGINE=INNODB;

CREATE TABLE notice (
  notice_code    BIGINT       NOT NULL AUTO_INCREMENT,
  stu_code       BIGINT       NOT NULL,
  notice_content VARCHAR(255) NOT NULL,
  notice_date    DATE         NOT NULL,
  notice_type    ENUM('WAITLIST_REGISTERED','ENROLL_FAIL','REPORT_RECEIVED','REPORTED') NOT NULL,
  PRIMARY KEY (notice_code),
  FOREIGN KEY (stu_code) REFERENCES student(stu_code)
) ENGINE=INNODB;

CREATE TABLE announcement (
  announcement_code BIGINT       NOT NULL AUTO_INCREMENT,
  admin_code        BIGINT       NOT NULL,
  title             VARCHAR(255) NULL,
  posted_date       DATE         NULL,
  content           VARCHAR(255) NULL,
  image             VARCHAR(255) NULL,
  public            ENUM('Y','N') NOT NULL,
  PRIMARY KEY (announcement_code),
  FOREIGN KEY (admin_code) REFERENCES administrator(admin_code)
) ENGINE=INNODB;

-- 5) 강의평/신고 -------------------------------------------------------------

CREATE TABLE lecture_review (
  lecture_review_code BIGINT       NOT NULL AUTO_INCREMENT,
  lecture_code        BIGINT       NOT NULL,
  stu_code            BIGINT       NOT NULL,
  lecture_review      VARCHAR(500) NOT NULL,
  `load`              INT          NOT NULL,
  difficulty          INT          NOT NULL,
  teaching            INT          NOT NULL,
  achievement         INT          NOT NULL,
  created_at          DATE         NOT NULL,
  updated_at          DATE         NOT NULL,
  PRIMARY KEY (lecture_review_code),
  FOREIGN KEY (lecture_code) REFERENCES lecture(lecture_code),
  FOREIGN KEY (stu_code)     REFERENCES student(stu_code)
) ENGINE=INNODB;

CREATE TABLE report_type (
  report_type_code INT          NOT NULL AUTO_INCREMENT,
  report_reason    VARCHAR(255) NOT NULL,
  PRIMARY KEY (report_type_code)
) ENGINE=INNODB;

CREATE TABLE lecture_review_report (
  report_code         BIGINT       NOT NULL AUTO_INCREMENT,
  report_date         DATE         NOT NULL,
  report_status       ENUM('Y','N') NOT NULL,
  lecture_review_code BIGINT       NOT NULL,
  report_type_code    INT          NOT NULL,
  PRIMARY KEY (report_code),
  FOREIGN KEY (lecture_review_code) REFERENCES lecture_review(lecture_review_code),
  FOREIGN KEY (report_type_code)    REFERENCES report_type(report_type_code)
) ENGINE=INNODB;
