-- coursework
-- Социальная сеть для установления деловых контактов
-- Группы выполняют 2 функции - сообщества по интересам и группы организаций
-- В группах можно подтверждать официальный статус
-- В группах организаций можно размещать вакансии
-- Пользователи могут размещать резюме
-- Резюме содержит описание, опыт работы, образование, умения
-- Умения пользователей могут быть подтверждены другими пользователями сети
-- Пользователи могут рекомендовать других пользователей



DROP DATABASE IF EXISTS linkedin;
CREATE DATABASE IF NOT EXISTS linkedin;
USE linkedin;


-- Создание структуры БД
DROP TABLE IF EXISTS users;
CREATE TABLE users (
	`id` SERIAL PRIMARY KEY,
    `firstname` VARCHAR(50) COMMENT 'имя',
    `lastname` VARCHAR(50) COMMENT 'фамилия',
    `email` VARCHAR(120) UNIQUE COMMENT 'почтовый адрес',
    `pwd` VARCHAR(35) COMMENT 'хеш пароля',
    `phone` BIGINT COMMENT 'телефон',
    INDEX users_phone_idx(phone),
    INDEX users_firstname_lastname_idx(firstname, lastname)
) COMMENT 'таблица пользователей';


DROP TABLE IF EXISTS `profiles`;
CREATE TABLE `profiles` (
	`user_id` SERIAL PRIMARY KEY,
    `gender` ENUM('M', 'F'),
    `birthday` DATE,
	`photo_id` BIGINT UNSIGNED NULL,
    `created_at` DATETIME DEFAULT NOW(),
    `hometown` VARCHAR(100),
    `occupation` VARCHAR(100) COMMENT 'текущая должность',
    FOREIGN KEY (user_id) REFERENCES users(id)
    	ON UPDATE RESTRICT
    	ON DELETE CASCADE
) COMMENT 'профили';


DROP TABLE IF EXISTS cvs;
CREATE TABLE cvs (
	id SERIAL PRIMARY KEY,
	job_titile VARCHAR(150),
	created_at DATETIME DEFAULT NOW(),
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
	
) COMMENT 'резюме';


DROP TABLE IF EXISTS users_cvs;
CREATE TABLE users_cvs (
	user_id BIGINT UNSIGNED NOT NULL,
	cv_id BIGINT UNSIGNED NOT NULL,
	deleted BIT NOT NULL DEFAULT 0,
  
	PRIMARY KEY (user_id, cv_id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (cv_id) REFERENCES cvs(id)
) COMMENT 'пользовательские резюме';

DROP TABLE IF EXISTS cvs_experience;
CREATE TABLE cvs_experience (
	id SERIAL,
	cv_id BIGINT UNSIGNED NOT NULL,
	job_name VARCHAR(150),
	started_at DATE,
	ended_at DATE,
	description TEXT,
	
	FOREIGN KEY (cv_id) REFERENCES cvs(id)
) COMMENT 'опыт работы';

DROP TABLE IF EXISTS cvs_education;
CREATE TABLE cvs_education (
	id SERIAL,
	cv_id BIGINT UNSIGNED NOT NULL,
	almamater VARCHAR(150),
	started_at DATE,
	ended_at DATE,
	description TEXT,
	
	FOREIGN KEY (cv_id) REFERENCES cvs(id)
) COMMENT 'образование';

DROP TABLE IF EXISTS cvs_skills;
CREATE TABLE cvs_skills (
	id SERIAL,
	cv_id BIGINT UNSIGNED NOT NULL,
	skill_name VARCHAR(150),
	
	FOREIGN KEY (cv_id) REFERENCES cvs(id)
) COMMENT 'умения';

DROP TABLE IF EXISTS media_types;
CREATE TABLE media_types (
	id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    created_at DATETIME DEFAULT NOW(),
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS communities;
CREATE TABLE communities(
	id SERIAL PRIMARY KEY,
	name VARCHAR(150),
	community_type ENUM('organization', 'community'),
	official BIT DEFAULT 0,

	INDEX communities_name_idx(name)
);

DROP TABLE IF EXISTS users_communities;
CREATE TABLE users_communities(
	user_id BIGINT UNSIGNED NOT NULL,
	community_id BIGINT UNSIGNED NOT NULL,
  
	PRIMARY KEY (user_id, community_id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (community_id) REFERENCES communities(id)
);

DROP TABLE IF EXISTS vacancies;
CREATE TABLE vacancies (
	id SERIAL PRIMARY KEY,
	description TEXT,
    organization_id BIGINT UNSIGNED NOT NULL,
    created_at DATETIME DEFAULT NOW(),
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX organization_id_idx(organization_id),
    FOREIGN KEY (organization_id) REFERENCES communities(id)
);

DROP TABLE IF EXISTS messages;
CREATE TABLE messages (
	id SERIAL PRIMARY KEY,
	from_user_id BIGINT UNSIGNED NOT NULL,
    to_user_id BIGINT UNSIGNED NOT NULL,
    body TEXT,
    created_at DATETIME DEFAULT NOW(),
    delivered BIT DEFAULT 0,
    is_read BIT DEFAULT 0,
    
    INDEX messages_from_user_id(from_user_id),
    INDEX messages_to_user_id(to_user_id),
    FOREIGN KEY (from_user_id) REFERENCES users(id),
    FOREIGN KEY (to_user_id) REFERENCES users(id)
);

DROP TABLE IF EXISTS connections;
CREATE TABLE connections (
	initiator_user_id BIGINT UNSIGNED NOT NULL,
    target_user_id BIGINT UNSIGNED NOT NULL,
    `status` ENUM('requested', 'approved', 'unfriended', 'declined'),
	requested_at DATETIME DEFAULT NOW(),
	confirmed_at DATETIME,
	
    PRIMARY KEY (initiator_user_id, target_user_id),
	INDEX (initiator_user_id),
    INDEX (target_user_id),
    FOREIGN KEY (initiator_user_id) REFERENCES users(id),
    FOREIGN KEY (target_user_id) REFERENCES users(id)
);

DROP TABLE IF EXISTS recommendations;
CREATE TABLE recommendations (
	recommender_id BIGINT UNSIGNED NOT NULL,
    recommended_user_id BIGINT UNSIGNED NOT NULL,
    recommended_to BIGINT UNSIGNED NOT NULL,
    comment TEXT,
	
    PRIMARY KEY (recommender_id, recommended_user_id),
	INDEX recommender_id_idx(recommender_id),
    INDEX recommended_user_id_idx(recommended_user_id),
    INDEX recommended_to_idx(recommended_to),
    FOREIGN KEY (recommender_id) REFERENCES users(id),
    FOREIGN KEY (recommended_user_id) REFERENCES users(id),
    FOREIGN KEY (recommended_to) REFERENCES users(id)
);

DROP TABLE IF EXISTS media;
CREATE TABLE media (
	id SERIAL PRIMARY KEY,
    media_type_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
  	body text,
    filename VARCHAR(255),
    size INT,
	metadata JSON,
    created_at DATETIME DEFAULT NOW(),
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX (user_id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (media_type_id) REFERENCES media_types(id)
);

DROP TABLE IF EXISTS skill_approves;
CREATE TABLE skill_approves (
    user_id BIGINT UNSIGNED NOT NULL,
    skill_id BIGINT UNSIGNED NOT NULL,
    created_at DATETIME DEFAULT NOW(),
    comment TEXT,

	PRIMARY KEY (user_id, skill_id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (skill_id) REFERENCES cvs_skills(id)
);

ALTER TABLE profiles ADD FOREIGN KEY (photo_id) REFERENCES media(id);




