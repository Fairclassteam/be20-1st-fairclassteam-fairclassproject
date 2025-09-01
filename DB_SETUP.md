-- 1) 'fairclass' 라는 사용자 계정을 생성 (모든 호스트에서 접속 허용, 비밀번호는 'fairclass')
CREATE USER 'fairclass'@'%' IDENTIFIED BY 'fairclass'; 

-- 2) mysql 시스템 데이터베이스 사용
USE mysql;

-- 3) user 테이블 전체 조회
SELECT * FROM user;	

-- 4) 'fairclass' 라는 이름의 데이터베이스 생성
CREATE DATABASE fairclass;
fairclass
-- 5) 현재 MySQL 서버에 존재하는 모든 데이터베이스 목록 확인
SHOW DATABASES;

-- 6) 'fairclass'@'%' 사용자가 가지고 있는 권한 목록 확인
SHOW GRANTS FOR 'fairclass'@'%';

-- 7) 'fairclass' DB 전체에 대해 'fairclass' 계정에게 모든 권한 부여
GRANT ALL PRIVILEGES ON fairclass.* TO 'fairclass'@'%';	
fairclass
-- 8) 앞으로 실행할 SQL 작업의 대상 데이터베이스를 'fairclass'로 변경
USE fairclass;

