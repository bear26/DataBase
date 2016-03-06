DROP TABLE IF EXISTS Addresses CASCADE;
CREATE TABLE Addresses(
	ad_id INT PRIMARY KEY,
	address VARCHAR(100) UNIQUE
);

DROP TABLE IF EXISTS Specialization CASCADE;
CREATE TABLE Specialization(
	spec_id INT PRIMARY KEY,
	spec_type VARCHAR(50) UNIQUE
);

DROP TABLE IF EXISTS EventsType CASCADE;
CREATE TABLE EventsType(
	type_id INT PRIMARY KEY,
	type VARCHAR(50) UNIQUE
);

DROP TABLE IF EXISTS Events CASCADE;
CREATE TABLE Events(
	ev_id INT PRIMARY KEY,
	event_name VARCHAR(100),
	type_id INT NOT NULL,
	event_ad_id INT NOT NULL,
	events_data DATE NOT NULL,

	FOREIGN KEY (type_id) REFERENCES EventsType(type_id) ON DELETE CASCADE,
	FOREIGN KEY (event_ad_id) REFERENCES Addresses(ad_id) ON DELETE CASCADE
);
CREATE INDEX eventInd ON Events(ev_id);
CREATE INDEX eventType ON Events(type_id);

DROP TABLE IF EXISTS Companies CASCADE;
CREATE TABLE Companies(
	comp_id INT PRIMARY KEY,
	comp_name VARCHAR(100) UNIQUE,
	comp_ad_id INT NOT NULL,
	reg_data DATE NOT NULL CHECK (reg_data < now()),

	FOREIGN KEY (comp_ad_id) REFERENCES Addresses(ad_id) ON DELETE CASCADE
);
CREATE INDEX nameComp ON Companies USING hash(comp_name);
CREATE INDEX compInd ON Companies(comp_id);

DROP TABLE IF EXISTS Peoples CASCADE;
CREATE TABLE Peoples(
	p_id INT PRIMARY KEY,
	p_name VARCHAR(100) NOT NULL,
	reg_ad_id INT NOT NULL,
	comp_id INT,
	birthday DATE NOT NULL CHECK (birthday < now()),

	FOREIGN KEY (reg_ad_id) REFERENCES Addresses(ad_id) ON DELETE CASCADE,
	FOREIGN KEY (comp_id) REFERENCES Companies(comp_id) ON DELETE CASCADE
);
CREATE INDEX peopleInd ON Peoples(p_id);

DROP TABLE IF EXISTS PeopleEvents CASCADE;
CREATE TABLE PeopleEvents(
	p_id INT,
	ev_id INT,

	PRIMARY KEY (p_id, ev_id),

	FOREIGN KEY (p_id) REFERENCES Peoples(p_id) ON DELETE CASCADE,
	FOREIGN KEY (ev_id) REFERENCES Events(ev_id) ON DELETE CASCADE
);

DROP TABLE IF EXISTS PeopleSkills CASCADE;
CREATE TABLE PeopleSkills(
	p_id INT,
	spec_id INT,

	PRIMARY KEY (p_id, spec_id),

	FOREIGN KEY (p_id) REFERENCES Peoples(p_id) ON DELETE CASCADE,
	FOREIGN KEY (spec_id) REFERENCES Specialization(spec_id) ON DELETE CASCADE
);

DROP TABLE IF EXISTS CompanySpecialization;
CREATE TABLE CompanySpecialization(
	comp_id INT NOT NULL,
	spec_id INT NOT NULL,

	PRIMARY KEY (comp_id, spec_id),

	FOREIGN KEY (comp_id) REFERENCES Companies(comp_id) ON DELETE CASCADE,
	FOREIGN KEY (spec_id) REFERENCES Specialization(spec_id) ON DELETE CASCADE
);

DROP FUNCTION IF EXISTS countPeopleInCompany(VARCHAR(100));
CREATE FUNCTION countPeopleInCompany(company_name VARCHAR(100)) RETURNS INT AS $$
DECLARE
	temp INT;
BEGIN
	SELECT count(*) INTO temp
	FROM Peoples
		NATURAL JOIN Companies
	WHERE comp_name=company_name;

	RETURN temp;
END;
$$ LANGUAGE plpgsql;

CREATE VIEW peoplesInCompany AS
	SELECT comp_name, count(comp_name) as countPeople
	FROM  Peoples
		NATURAL JOIN Companies
	GROUP BY comp_name;

CREATE VIEW peoplesSatisfy AS
	SELECT comp_name, string_agg(p_name, ', ') as s
	FROM
	(
	SELECT comp_id, p_id, count(p_id) as c1
	FROM companyspecialization
		CROSS JOIN peopleskills
	WHERE peopleskills.spec_id=companyspecialization.spec_id
	GROUP BY comp_id, p_id) as P
	CROSS JOIN (
	SELECT * FROM
		(SELECT comp_id, count(comp_id) as c2
	FROM companies
		NATURAL JOIN companyspecialization
	GROUP BY comp_id) as U) as T
		INNER JOIN peoples on P.p_id=peoples.p_id
		INNER JOIN companies on companies.comp_id=P.comp_id
	WHERE P.comp_id=T.comp_id and c1=c2
	GROUP BY comp_name;

CREATE VIEW peopleInCampus AS
	SELECT p_id, p_name
	FROM Peoples
		NATURAL JOIN Addresses
	WHERE address='Санкт-Петербург пер. Вяземский 5/7';

INSERT INTO Addresses(ad_id, address) VALUES
	(1, 'Санкт-Петербург пер. Вяземский 5/7'),
	(2, 'Санкт-Петербург Кронверский Проспект 49'),
	(3, 'Санкт-Петербург улица Ленина 1'),
	(4, 'Пискаревский проспект 2');

INSERT INTO Specialization(spec_id, spec_type) VALUES
	(1, 'Java'),
	(2, 'C++'),
	(3, 'DB'),
	(4, 'Machine Learning');

INSERT INTO EventsType(type_id, type) VALUES
	(1, 'День рождения'),
	(2, 'Семинар'),
	(3, 'Корпоратив'),
	(4, 'Рождество');

INSERT INTO Events(ev_id, event_name, type_id, event_ad_id, events_data) VALUES
	(1, 'День рождения у Миши', 1, 1, '2016-2-5'),
	(2, 'Корпоратив в честь Нового года', 3, 3, '2015-12-26'),
	(3, 'Семинар по Машинному обучению', 2, 2, '2016-2-1'),
	(4, 'Семинар по Haskell', 2, 2, '2016-2-20');

INSERT INTO Companies(comp_id, comp_name, comp_ad_id, reg_data) VALUES
	(1, 'Yandex', 4, '1997-9-23'),
	(2, 'Университет ИТМО', 2, '1900-1-1');

INSERT INTO Peoples(p_id, p_name, reg_ad_id, comp_id, birthday) VALUES
	(1, 'Иван', 1, NULL, '1995-2-2'),
	(2, 'Петр', 1, 1, '1994-3-3'),
	(3, 'Дмитрий', 1, 1, '1991-4-4'),
	(4, 'Андрей', 1, 2, '1990-5-5');

INSERT INTO PeopleEvents(p_id, ev_id) VALUES
	(1, 1),
	(1, 4),
	(4, 4),
	(3, 2),
	(3, 1),
	(1, 2),
	(4, 2);

INSERT INTO PeopleSkills(p_id, spec_id) VALUES
	(1, 1),
	(1, 2),
	(1, 3),
	(1, 4),
	(2, 1),
	(2, 2),
	(2, 3),
	(3, 1),
	(4, 2),
	(4, 4);

INSERT INTO CompanySpecialization(comp_id, spec_id) VALUES
	(1, 1),
	(1, 2),
	(2, 1),
	(2, 2),
	(2, 3),
	(2, 4);

BEGIN;
INSERT INTO Addresses(ad_id, address) VALUES
	(5, 'Москва улица Новый Арбат 2');
INSERT INTO EventsType(type_id, type) VALUES
	(5, 'Вечиринка');
INSERT INTO Events(ev_id, event_name, type_id, event_ad_id, events_data) VALUES
	(5, 'Вечиринка на Новом Арбате', 5, 5, '2016-1-25');
INSERT INTO PeopleEvents(p_id, ev_id) VALUES
	(1, 5),
	(2, 5),
	(3, 5),
	(4, 5);
COMMIT;

--1) Люди, которые придут на некоторое событие
SELECT p_id, p_name
FROM Peoples
	NATURAL JOIN PeopleEvents
	NATURAL JOIN Events
WHERE event_name='Вечиринка на Новом Арбате';

--2) Узнать все события какого то типа
SELECT ev_id, event_name, events_data
FROM Events
	NATURAL JOIN EventsType
WHERE type='Семинар';

--3) Компании которые имеют некоторою специализацию
SELECT comp_name
FROM Companies
	NATURAL JOIN CompanySpecialization
	NATURAL JOIN Specialization
WHERE spec_type='DB';

--4) Люди без работы
SELECT *
FROM Peoples
WHERE comp_id is NULL;

--5) События и сколько людей в них участвует
SELECT events_data, event_name, count(event_name) as count_people
FROM Peoples
	NATURAL JOIN PeopleEvents
	NATURAL JOIN Events
GROUP BY event_name, events_data ORDER BY count_people DESC;

--6) навыки людей
SELECT p_name, string_agg(spec_type, ',') as skills
FROM Peoples
	NATURAL JOIN PeopleSkills
	NATURAL JOIN Specialization
GROUP BY p_name;

--7) По компании список людей которые подходят компании(люди имеют все специализации, которые нужны в компании)
SELECT p_id, p_name
FROM
	(
	SELECT p_id, p_name, count(p_name) as count
	FROM Peoples
		NATURAL JOIN PeopleSkills
	WHERE	spec_id IN (
		SELECT spec_id
		FROM Companies
			NATURAL JOIN CompanySpecialization
		WHERE comp_name='Yandex')
	GROUP BY p_id, p_name) as P
WHERE count IN (
	SELECT count(*)
	FROM Companies
		NATURAL JOIN CompanySpecialization
	WHERE comp_name='Yandex'
);
