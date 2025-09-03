-- 1. 회원가입

INSERT INTO user (auth_code, email, password, mobile, name)
	VALUES (
  		2,									 	 -- 권한
  		'student1@univ.ac.kr', 			 -- 아이디(이메일)
  		'pw2',                  		 -- 비밀번호
  		'010-2222-2222',               -- 휴대폰 번호
  		'학생1'                       -- 이름           
);


-- 2. 로그인

SET @input_email = 'student1@univ.ac.kr';
SET @input_password = 'pw2';

-- 2-1. 이메일과 비밀번호가 일치하는 레코드가 있는지 확인

SELECT * 
FROM user
WHERE email = @input_email AND password = @input_password;


-- 3. 회원정보 수정 (전화번호 수정)

UPDATE user
SET mobile = '010-9999-8888'
WHERE email = 'student1@univ.ac.kr';


-- 4. 비밀번호 찾기

SELECT password
FROM user
WHERE email = 'student1@univ.ac.kr';


-- 4-1. 비밀번호 재설정

UPDATE user
SET password = 'pw2'
WHERE email = 'student1@univ.ac.kr';


-- 5. 회원 탈퇴

DELETE FROM user
WHERE email = 'student1@univ.ac.kr';
