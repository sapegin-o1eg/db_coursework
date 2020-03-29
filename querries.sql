USE linkedin;


-- view для отображения полных данных о пользователях
CREATE OR REPLACE VIEW
	user_info
AS 
	SELECT
		u.id,
		u.firstname,
		u.lastname,
		u.email,
		u.phone,
		p.gender,
		p.birthday,
		p.hometown,
		p.occupation,
		m.filename avatar_file
	FROM media m 
	RIGHT JOIN profiles p ON m.id = p.photo_id
	JOIN users u ON p.user_id = u.id;
	
SELECT * FROM user_info;


-- view для отображения всего медиа контента пользователей
CREATE OR REPLACE VIEW
	user_media
AS
	SELECT
		u.id,
		u.firstname,
		u.lastname,
		mt.name media_type,
		m.filename,
		m.`size`
	FROM users u
	JOIN media m ON m.user_id = u.id
	JOIN media_types mt ON mt.id = m.media_type_id;

SELECT * FROM user_media;

-- поиск id пользователя по его email
SELECT id, CONCAT_WS(' ', firstname, lastname) AS `user` FROM users u WHERE phone = 79781111111;


-- хранимая процедура для поиска id пользователя по его email
DELIMITER $$
DROP PROCEDURE IF EXISTS sp_select_by_phone$$
CREATE PROCEDURE sp_select_by_phone (
	IN _phone BIGINT,
	OUT user_id BIGINT UNSIGNED
)
BEGIN

	SELECT id INTO user_id FROM users WHERE phone = _phone;
END $$
DELIMITER ;

CALL sp_select_by_phone(79781111111, @id);
SELECT @id AS `Found user's id by phone`;


-- активные резюме пользователя
SELECT
	CONCAT_WS(' ', firstname, lastname ) AS `user`,
	c.job_titile AS cv_title,
	c.id AS cv_id
FROM users u
JOIN users_cvs uc ON u.id = uc.user_id
JOIN cvs c ON uc.cv_id = c.id
WHERE u.id = 1 AND uc.deleted = 0;

-- подробная информация о резюме с id = 16
-- образование
SELECT
	c.id,
	c.job_titile,
	ced.almamater,
	ced.started_at,
	ced.ended_at,
	ced.description
FROM cvs c
JOIN cvs_education ced ON c.id = ced.cv_id
WHERE c.id = 16 
ORDER BY ced.ended_at DESC;

-- опыт работы
SELECT
	c.id,
	c.job_titile,
	cex.job_name,
	cex.started_at,
	cex.ended_at,
	cex.description
FROM cvs c
JOIN cvs_experience cex ON c.id = cex.cv_id
WHERE c.id = 16
ORDER BY cex.ended_at DESC;

-- умения
SELECT
	c.id,
	c.job_titile,
	csk.id skill_id,
	csk.skill_name
FROM cvs c
JOIN cvs_skills csk
ON c.id = csk.cv_id
WHERE c.id = 16;

-- кем подтвержден скилл с id = 76
SELECT
	CONCAT_WS(' ', u.firstname, u.lastname) approved_by,
	csk.skill_name,
	sa.comment
FROM skill_approves sa 
JOIN users u ON sa.user_id = u.id
JOIN cvs_skills csk ON csk.id = sa.skill_id 
WHERE sa.skill_id = 76;


-- Сообщения к пользователю
SELECT
	CONCAT_WS(' ', u.firstname, u.lastname) `to`,
	body,
	created_at
FROM messages m
JOIN users u ON u.id = m.to_user_id 
WHERE u.id = 1;
  
-- Сообщения от пользователя
SELECT
	CONCAT_WS(' ', u.firstname, u.lastname) `from`,
	body,
	created_at
FROM messages m
JOIN users u ON u.id = m.from_user_id
WHERE u.id = 1;
   
-- Количество друзей у всех пользователей с сортировкой
SELECT
	firstname, lastname, COUNT(*) AS total_friends
FROM users u
JOIN connections ON
	(u.id = connections.initiator_user_id or u.id = connections.target_user_id)
WHERE connections.status = 'approved'
GROUP BY u.id
ORDER BY total_friends DESC;

-- количество пользователей в группах c сортировкой по убыванию
SELECT 
	c.name community_name,
	COUNT(*) members
FROM users_communities uc 
JOIN communities c ON uc.community_id = c.id
WHERE community_type = 'community'
GROUP BY c.id
ORDER BY members DESC;

-- количество пользователей в официальных группах организаций c сортировкой по убыванию
SELECT 
	c.name community_name,
	COUNT(*) members
FROM users_communities uc 
JOIN communities c ON uc.community_id = c.id
WHERE c.community_type = 'organization' AND c.official = 1
GROUP BY c.id
ORDER BY members DESC;

-- в скольких группах состоят пользователи
SELECT
	CONCAT_WS(' ', u.firstname, u.lastname) `user`,
	COUNT(*) joined_groups
FROM users u
JOIN users_communities uc ON u.id = uc.user_id
JOIN communities c ON uc.community_id = c.id
WHERE c.community_type = 'community'
GROUP BY u.id
ORDER BY COUNT(*) DESC;

-- вакансии организаций
SELECT
	c.name org_name,
	v.description
FROM communities c
JOIN vacancies v ON c.id = v.organization_id
WHERE c.community_type = 'organization';

-- рекоммендованные пользователи
SELECT
	u1.id,
	CONCAT_WS(' ', u1.firstname, u1.lastname) recommended_user,
	CONCAT_WS(' ', u2.firstname, u2.lastname) recommended_by,
	r.comment
FROM users u1
JOIN recommendations r
ON u1.id = r.recommended_user_id
JOIN users u2 ON r.recommender_id = u2.id
ORDER BY u1.id;

-- 3 самых рекомендуемых пользователя
SELECT
	CONCAT_WS(' ', u.firstname, u.lastname) recommended_user,
	COUNT(*) recommendations_count
FROM users u
JOIN recommendations r
ON u.id = r.recommended_user_id
GROUP BY u.id
ORDER BY COUNT(*) DESC
LIMIT 3;

-- процедура для добавления пользователя
DELIMITER $$
DROP PROCEDURE IF EXISTS sp_add_user$$
CREATE PROCEDURE sp_add_user (
	firstname VARCHAR(50),
	lastname VARCHAR(50),
	email VARCHAR(120),
	pwd VARCHAR(35),
	phone BIGINT,
	gender ENUM('M', 'F'),
    birthday DATE,
    hometown VARCHAR(100),
    occupation VARCHAR(100),
    OUT tran_result VARCHAR(200)
)
BEGIN
	DECLARE `_rollback` BIT DEFAULT 0;
	DECLARE code VARCHAR(100);
	DECLARE error_string VARCHAR(100);

	DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
	BEGIN
		SET `_rollback` = 1;
		GET stacked DIAGNOSTICS CONDITION 1
		code = RETURNED_SQLSTATE, error_string = MESSAGE_TEXT;
		SET tran_result := CONCAT('Error occered. Code: ', code, '. Text: ', error_string);
	END;
	
	START TRANSACTION;

	INSERT INTO users (`firstname`, `lastname`, `email`, `pwd`, `phone`) VALUES
		(firstname, lastname, email, pwd, phone);
	INSERT INTO profiles (`user_id`, `gender`, `birthday`, `hometown`, `occupation`) VALUES
		(LAST_INSERT_ID(), gender, birthday, hometown, occupation);
	
	IF `_rollback` THEN
		ROLLBACK;
	ELSE
		COMMIT;
		SET `tran_result` = 'OK';
	END IF;

END $$
DELIMITER ;


CALL sp_add_user('Олег',
				'Сапегин',
				'myownemail@gmail.com',
				'940c63b604a26688b6f9d862a521492a',
				79789999999,
				'M',
				'1986-07-06',
				'Симферополь',
				'Junior Python Developer',
				@tran_result);
SELECT @tran_result;

-- триггеры
-- проверки данных
DELIMITER $$
DROP TRIGGER IF EXISTS tr_ins_chech_user_info$$
CREATE TRIGGER tr_ins_chech_user_info BEFORE INSERT ON profiles
FOR EACH ROW
BEGIN
	IF (NEW.birthday > NOW() OR NEW.birthday IS NULL) THEN
		SIGNAL SQLSTATE '45000' SET 
		MESSAGE_TEXT = "Insert canceled. Birthday must be defined and cannot be in the future.";
	END IF;
END$$

DROP TRIGGER IF EXISTS tr_upd_chech_user_info$$
CREATE TRIGGER tr_upd_chech_user_info BEFORE UPDATE ON profiles
FOR EACH ROW
BEGIN
	IF (NEW.birthday > NOW() OR NEW.birthday IS NULL) THEN
		SIGNAL SQLSTATE '45000' SET 
		MESSAGE_TEXT = "Update canceled. Birthday must be defined and cannot be in the future.";
	END IF;
END$$
DELIMITER ;
