-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Хост: 127.0.0.1:3306
-- Время создания: Мар 23 2025 г., 02:03
-- Версия сервера: 8.0.30
-- Версия PHP: 7.2.34

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- База данных: `дэмо_1`
--

DELIMITER $$
--
-- Процедуры
--
CREATE DEFINER=`root`@`%` PROCEDURE `CalculatePartnerDiscount` (IN `partner_id` INT, OUT `discount` DECIMAL(5,2))   BEGIN
    DECLARE total_quantity INT;
    SELECT SUM(`кол_во`) INTO total_quantity FROM `история_продаж` WHERE `id_парнер` = partner_id;
    IF total_quantity > 100000 THEN SET discount = 10.00;
    ELSEIF total_quantity > 50000 THEN SET discount = 5.00;
    ELSE SET discount = 0.00;
    END IF;
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `CancelOverdueRequests` ()   BEGIN
    UPDATE `заявка`
    SET `id_статус` = (SELECT `id` FROM `статус` WHERE `название` = 'Отменена')
    WHERE `id_статус` = (SELECT `id` FROM `статус` WHERE `название` = 'Создана')
    AND DATEDIFF(CURRENT_DATE, `дата_создания`) > 3
    AND `дата_предоплаты` IS NULL;
END$$

--
-- Функции
--
CREATE DEFINER=`root`@`%` FUNCTION `CalculateMaterialQuantity` (`product_type_id` INT, `material_type_id` INT, `product_quantity` INT, `param1` DECIMAL(10,2), `param2` DECIMAL(10,2)) RETURNS INT DETERMINISTIC BEGIN
    DECLARE coef DECIMAL(10,2);
    DECLARE defect_rate DECIMAL(10,2);
    DECLARE base_material_per_unit DECIMAL(10,2);
    DECLARE total_material DECIMAL(10,2);

    -- Проверка входных данных
    IF product_quantity < 0 OR param1 <= 0 OR param2 <= 0 THEN
        RETURN -1;
    END IF;

    -- Получаем коэффициент типа продукции (преобразуем varchar в decimal)
    SELECT CAST(REPLACE(`коэффиц_типа`, ',', '.') AS DECIMAL(10,2)) INTO coef 
    FROM `тип_продукции` 
    WHERE `id` = product_type_id;
    IF coef IS NULL THEN
        RETURN -1;
    END IF;

    -- Получаем процент брака материала (преобразуем varchar в decimal)
    SELECT CAST(REPLACE(`процент_брака`, ',', '.') AS DECIMAL(10,2)) INTO defect_rate 
    FROM `тип_материала` 
    WHERE `id` = material_type_id;
    IF defect_rate IS NULL THEN
        RETURN -1;
    END IF;

    -- Расчет
    SET base_material_per_unit = param1 * param2 * coef;
    SET total_material = base_material_per_unit * product_quantity * (1 + defect_rate / 100);
    RETURN ROUND(total_material);
END$$

CREATE DEFINER=`root`@`%` FUNCTION `GetAvailableProductQuantity` (`product_id` INT) RETURNS INT DETERMINISTIC BEGIN
    DECLARE available_qty INT;
    SELECT `кол_во_всего` - `кол_во_зарезерв` INTO available_qty
    FROM `склад` WHERE `id_продукция` = product_id;
    IF available_qty IS NULL THEN RETURN 0; END IF;
    RETURN available_qty;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Структура таблицы `users`
--

CREATE TABLE `users` (
  `id` int NOT NULL,
  `username` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `role` varchar(20) DEFAULT 'user'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `users`
--

INSERT INTO `users` (`id`, `username`, `password`, `role`) VALUES
(1, 'admin', '1234', 'admin'),
(2, 'user', 'userpass', 'user');

-- --------------------------------------------------------

--
-- Структура таблицы `материал`
--

CREATE TABLE `материал` (
  `id` int NOT NULL,
  `название` varchar(100) NOT NULL,
  `кол_во_упаковка` int NOT NULL,
  `описание` varchar(100) NOT NULL,
  `изображение` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `стоимость` decimal(10,2) NOT NULL,
  `id_тип_материала` int NOT NULL,
  `id_поставщик` int NOT NULL,
  `id_ед_измериния` int NOT NULL,
  `id_склад` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Структура таблицы `менеджеры`
--

CREATE TABLE `менеджеры` (
  `id` int NOT NULL,
  `фамилия` varchar(100) NOT NULL,
  `имя` varchar(100) NOT NULL,
  `отчество` varchar(100) NOT NULL,
  `почта` varchar(100) NOT NULL,
  `телефон` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Структура таблицы `место_продаж`
--

CREATE TABLE `место_продаж` (
  `id` int NOT NULL,
  `название` varchar(100) NOT NULL,
  `id_парнеры` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Структура таблицы `доступ`
--

CREATE TABLE `доступ` (
  `id` int NOT NULL,
  `дата` date NOT NULL,
  `id_сотрудники` int NOT NULL,
  `id_оборудование` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Структура таблицы `история_изм_стоимости`
--

CREATE TABLE `история_изм_стоимости` (
  `id` int NOT NULL,
  `дата` date NOT NULL,
  `новая_стоимость` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Структура таблицы `история_поставки`
--

CREATE TABLE `история_поставки` (
  `id` int NOT NULL,
  `название` varchar(100) NOT NULL,
  `дата` date NOT NULL,
  `кол_во` int NOT NULL,
  `id_материал` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Структура таблицы `история_продаж`
--

CREATE TABLE `история_продаж` (
  `id` int NOT NULL,
  `дата` varchar(100) NOT NULL,
  `кол_во` int NOT NULL,
  `общая_стоимость` decimal(10,2) DEFAULT NULL,
  `id_парнер` int NOT NULL,
  `id_продукция` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `история_продаж`
--

INSERT INTO `история_продаж` (`id`, `дата`, `кол_во`, `общая_стоимость`, `id_парнер`, `id_продукция`) VALUES
(1, '23.03.2023', 15500, NULL, 1, 1),
(2, '18.12.2023', 12350, NULL, 1, 3),
(3, '07.06.2024', 37400, NULL, 1, 4),
(4, '02.12.2022', 35000, NULL, 2, 2),
(5, '17.05.2023', 1250, NULL, 2, 5),
(6, '07.06.2024', 1000, NULL, 2, 3),
(7, '01.07.2024', 7550, NULL, 2, 1),
(8, '22.01.2023', 7250, NULL, 3, 1),
(9, '05.07.2024', 2500, NULL, 3, 2),
(10, '20.03.2023', 59050, NULL, 4, 4),
(11, '12.03.2024', 37200, NULL, 4, 3),
(12, '14.05.2024', 4500, NULL, 4, 5),
(13, '19.09.2023', 50000, NULL, 5, 3),
(14, '10.11.2023', 670000, NULL, 5, 4),
(15, '15.04.2024', 35000, NULL, 5, 1),
(16, '12.06.2024', 25000, NULL, 5, 2);

-- --------------------------------------------------------

--
-- Структура таблицы `история_рейтинга`
--

CREATE TABLE `история_рейтинга` (
  `id` int NOT NULL,
  `значение` decimal(10,2) NOT NULL,
  `дата_изменения` date NOT NULL,
  `id_партнер` int NOT NULL,
  `id_менеджер` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Структура таблицы `история_склада`
--

CREATE TABLE `история_склада` (
  `id` int NOT NULL,
  `id_склад` int NOT NULL,
  `дата` datetime NOT NULL,
  `тип_действия` varchar(50) NOT NULL,
  `кол_во_изменение` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Структура таблицы `партнеры`
--

CREATE TABLE `партнеры` (
  `id` int NOT NULL,
  `название_компании` varchar(100) NOT NULL,
  `юр_адрес` varchar(200) NOT NULL,
  `инн` varchar(50) NOT NULL,
  `фамилия` varchar(100) NOT NULL,
  `имя` varchar(100) NOT NULL,
  `отчество` varchar(100) NOT NULL,
  `телефон` varchar(60) NOT NULL,
  `почта` varchar(100) NOT NULL,
  `логотип` varchar(255) DEFAULT NULL,
  `рейтинг` decimal(10,2) NOT NULL,
  `id_тип_партнера` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `партнеры`
--

INSERT INTO `партнеры` (`id`, `название_компании`, `юр_адрес`, `инн`, `фамилия`, `имя`, `отчество`, `телефон`, `почта`, `логотип`, `рейтинг`, `id_тип_партнера`) VALUES
(1, 'База Строитель', '652050, Кемеровская область, город Юрга, ул. Лесная, 15', '2222455179', 'Иванова', 'Александра', 'Ивановна', '493 123 45 67', 'aleksandraivanova@ml.ru', NULL, '7.00', 1),
(2, 'Паркет 29', '164500, Архангельская область, город Северодвинск, ул. Строителей, 18', '3333888520', 'Петров', 'Василий', 'Петрович', '987 123 56 78', 'vppetrov@vl.ru', NULL, '7.00', 2),
(3, 'Стройсервис', '188910, Ленинградская область, город Приморск, ул. Парковая, 21', '4440391035', 'Соловьев', 'Андрей', 'Николаевич', '812 223 32 00', 'ansolovev@st.ru', NULL, '7.00', 3),
(4, 'Ремонт и отделка', '143960, Московская область, город Реутов, ул. Свободы, 51', '1111520857', 'Воробьева', 'Екатерина', 'Валерьевна', '444 222 33 11', 'ekaterina.vorobeva@ml.ru', NULL, '5.00', 4),
(5, 'МонтажПро', '309500, Белгородская область, город Старый Оскол, ул. Рабочая, 122', '5552431140', 'Степанов', 'Степан', 'Сергеевич', '912 888 33 33', 'stepanov@stepan.ru', NULL, '10.00', 1);

-- --------------------------------------------------------

--
-- Структура таблицы `перемещение_сотрудников`
--

CREATE TABLE `перемещение_сотрудников` (
  `id` int NOT NULL,
  `id_сотрудники` int NOT NULL,
  `дата_время` datetime NOT NULL,
  `id_дверь` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Структура таблицы `потсавщик`
--

CREATE TABLE `потсавщик` (
  `id` int NOT NULL,
  `название` varchar(100) NOT NULL,
  `инн` varchar(100) NOT NULL,
  `id_тип_поставщика` int NOT NULL,
  `id_история_поставки` int NOT NULL,
  `id_менеджер` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Структура таблицы `продукция`
--

CREATE TABLE `продукция` (
  `id` int NOT NULL,
  `артикул` varchar(100) NOT NULL,
  `описание` varchar(100) DEFAULT NULL,
  `изображение` varchar(255) DEFAULT NULL,
  `мин_стоимость` varchar(100) NOT NULL,
  `длина` decimal(10,2) DEFAULT NULL,
  `ширина` decimal(10,2) DEFAULT NULL,
  `высота` decimal(10,2) DEFAULT NULL,
  `вес_без_упаковки` decimal(10,2) DEFAULT NULL,
  `вес_с_упаковкой` decimal(10,2) DEFAULT NULL,
  `номер_стандарта` varchar(100) DEFAULT NULL,
  `себестоимость` decimal(10,2) DEFAULT NULL,
  `время_изготовления` int DEFAULT NULL,
  `id_тип_продукции` int NOT NULL,
  `id_материал` int DEFAULT NULL,
  `id_производство` int DEFAULT NULL,
  `id_история_из_стоимости` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `продукция`
--

INSERT INTO `продукция` (`id`, `артикул`, `описание`, `изображение`, `мин_стоимость`, `длина`, `ширина`, `высота`, `вес_без_упаковки`, `вес_с_упаковкой`, `номер_стандарта`, `себестоимость`, `время_изготовления`, `id_тип_продукции`, `id_материал`, `id_производство`, `id_история_из_стоимости`) VALUES
(1, '8758385', '3 Ясень темный однополосная 14 мм', NULL, '4456,90', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 3, NULL, NULL, NULL),
(2, '8858958', 'Инженерная доска Дуб Французская елка однополосная 12 мм', NULL, '7330,99', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 3, NULL, NULL, NULL),
(3, '7750282', 'Ламинат Дуб дымчато-белый 33 класс 12 мм', NULL, '1799,33', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL),
(4, '7028748', 'Ламинат Дуб серый 32 класс 8 мм с фаской', NULL, '3890,41', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL),
(5, '5012543', 'Пробковое напольное клеевое покрытие 32 класс 4 мм', NULL, '5450,59', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 4, NULL, NULL, NULL),
(6, '67876rty', 'vf dcwsdcsw', NULL, '100', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL),
(7, '', NULL, NULL, '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Структура таблицы `производство`
--

CREATE TABLE `производство` (
  `id` int NOT NULL,
  `номер_цеха` int NOT NULL,
  `id_сотрудника` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Структура таблицы `ед_измериния`
--

CREATE TABLE `ед_измериния` (
  `id` int NOT NULL,
  `название` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `ед_измериния`
--

INSERT INTO `ед_измериния` (`id`, `название`) VALUES
(1, 'кв.м'),
(2, 'шт');

-- --------------------------------------------------------

--
-- Структура таблицы `заявка`
--

CREATE TABLE `заявка` (
  `id` int NOT NULL,
  `стоимость` decimal(10,2) NOT NULL,
  `дата_создания` date NOT NULL,
  `дата_предоплаты` date DEFAULT NULL,
  `срок_изготовления` int NOT NULL,
  `кол_во` int NOT NULL,
  `id_парнет` int NOT NULL,
  `id_менеджер` int NOT NULL,
  `id_продукция` int NOT NULL,
  `id_статус` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Триггеры `заявка`
--
DELIMITER $$
CREATE TRIGGER `ReserveMaterialsOnPrepayment` AFTER UPDATE ON `заявка` FOR EACH ROW BEGIN
    IF NEW.`дата_предоплаты` IS NOT NULL AND OLD.`дата_предоплаты` IS NULL THEN
        UPDATE `склад`
        SET `кол_во_зарезерв` = `кол_во_зарезерв` + NEW.`кол_во`
        WHERE `id_продукция` = NEW.`id_продукция`
        AND `кол_во_всего` >= `кол_во_зарезерв` + NEW.`кол_во`;

        INSERT INTO `история_склада` (`id_склад`, `дата`, `тип_действия`, `кол_во_изменение`)
        VALUES (
            (SELECT `id` FROM `склад` WHERE `id_продукция` = NEW.`id_продукция`),
            NOW(),
            'Резерв',
            NEW.`кол_во`
        );
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Структура таблицы `оборудование`
--

CREATE TABLE `оборудование` (
  `id` int NOT NULL,
  `название` varchar(100) NOT NULL,
  `описание` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Структура таблицы `склад`
--

CREATE TABLE `склад` (
  `id` int NOT NULL,
  `кол_во_всего` int NOT NULL,
  `кол_во_зарезерв` int NOT NULL,
  `id_материал` int NOT NULL,
  `id_продукция` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Структура таблицы `сотрудники`
--

CREATE TABLE `сотрудники` (
  `id` int NOT NULL,
  `фамилия` varchar(100) NOT NULL,
  `имя` varchar(100) NOT NULL,
  `отчество` varchar(100) NOT NULL,
  `дата_рождения` date NOT NULL,
  `серия` int NOT NULL,
  `номер` int NOT NULL,
  `реквизты_карты` varchar(100) NOT NULL,
  `наличие_семьи` varchar(100) NOT NULL,
  `состояние_здоровья` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Структура таблицы `статус`
--

CREATE TABLE `статус` (
  `id` int NOT NULL,
  `название` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Структура таблицы `тип_материала`
--

CREATE TABLE `тип_материала` (
  `id` int NOT NULL,
  `название` varchar(100) NOT NULL,
  `процент_брака` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `тип_материала`
--

INSERT INTO `тип_материала` (`id`, `название`, `процент_брака`) VALUES
(1, 'Тип материала 1', '0,00'),
(2, 'Тип материала 2', '0,01'),
(3, 'Тип материала 3', '0,00'),
(4, 'Тип материала 4', '0,01'),
(5, 'Тип материала 5', '0,00');

-- --------------------------------------------------------

--
-- Структура таблицы `тип_партнера`
--

CREATE TABLE `тип_партнера` (
  `id` int NOT NULL,
  `название` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `тип_партнера`
--

INSERT INTO `тип_партнера` (`id`, `название`) VALUES
(1, 'ЗАО'),
(2, 'ООО'),
(3, 'ПАО'),
(4, 'ОАО');

-- --------------------------------------------------------

--
-- Структура таблицы `тип_поставщика`
--

CREATE TABLE `тип_поставщика` (
  `id` int NOT NULL,
  `название` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `тип_поставщика`
--

INSERT INTO `тип_поставщика` (`id`, `название`) VALUES
(1, 'Производитель'),
(2, 'Дистрибьютор');

-- --------------------------------------------------------

--
-- Структура таблицы `тип_продукции`
--

CREATE TABLE `тип_продукции` (
  `id` int NOT NULL,
  `название` varchar(100) NOT NULL,
  `коэффиц_типа` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `тип_продукции`
--

INSERT INTO `тип_продукции` (`id`, `название`, `коэффиц_типа`) VALUES
(1, 'Ламинат', '2,35'),
(2, 'Массивная доска', '5,15'),
(3, 'Паркетная доска', '4,34'),
(4, 'Пробковое покрытие', '1,5');

--
-- Индексы сохранённых таблиц
--

--
-- Индексы таблицы `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- Индексы таблицы `материал`
--
ALTER TABLE `материал`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_тип_материала` (`id_тип_материала`,`id_поставщик`,`id_ед_измериния`,`id_склад`),
  ADD KEY `id_ед_измериния` (`id_ед_измериния`),
  ADD KEY `id_склад` (`id_склад`),
  ADD KEY `id_поставщик` (`id_поставщик`);

--
-- Индексы таблицы `менеджеры`
--
ALTER TABLE `менеджеры`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `место_продаж`
--
ALTER TABLE `место_продаж`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_парнеры` (`id_парнеры`);

--
-- Индексы таблицы `доступ`
--
ALTER TABLE `доступ`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_сотрудники` (`id_сотрудники`,`id_оборудование`),
  ADD KEY `id_оборудование` (`id_оборудование`);

--
-- Индексы таблицы `история_изм_стоимости`
--
ALTER TABLE `история_изм_стоимости`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `история_поставки`
--
ALTER TABLE `история_поставки`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_материал` (`id_материал`);

--
-- Индексы таблицы `история_продаж`
--
ALTER TABLE `история_продаж`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_парнер` (`id_парнер`,`id_продукция`),
  ADD KEY `id_продукция` (`id_продукция`);

--
-- Индексы таблицы `история_рейтинга`
--
ALTER TABLE `история_рейтинга`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_партнер` (`id_партнер`,`id_менеджер`),
  ADD KEY `id_менеджер` (`id_менеджер`);

--
-- Индексы таблицы `история_склада`
--
ALTER TABLE `история_склада`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_склад` (`id_склад`);

--
-- Индексы таблицы `партнеры`
--
ALTER TABLE `партнеры`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_тип_партнера` (`id_тип_партнера`);

--
-- Индексы таблицы `перемещение_сотрудников`
--
ALTER TABLE `перемещение_сотрудников`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_сотрудники` (`id_сотрудники`);

--
-- Индексы таблицы `потсавщик`
--
ALTER TABLE `потсавщик`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_тип_поставщика` (`id_тип_поставщика`,`id_история_поставки`,`id_менеджер`),
  ADD KEY `id_менеджер` (`id_менеджер`),
  ADD KEY `id_история_поставки` (`id_история_поставки`);

--
-- Индексы таблицы `продукция`
--
ALTER TABLE `продукция`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_тип_продукции` (`id_тип_продукции`,`id_материал`,`id_производство`,`id_история_из_стоимости`),
  ADD KEY `id_материал` (`id_материал`),
  ADD KEY `id_история_из_стоимости` (`id_история_из_стоимости`),
  ADD KEY `id_производство` (`id_производство`);

--
-- Индексы таблицы `производство`
--
ALTER TABLE `производство`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_сотрудника` (`id_сотрудника`);

--
-- Индексы таблицы `ед_измериния`
--
ALTER TABLE `ед_измериния`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `заявка`
--
ALTER TABLE `заявка`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_парнет` (`id_парнет`,`id_менеджер`,`id_продукция`,`id_статус`),
  ADD KEY `id_продукция` (`id_продукция`),
  ADD KEY `id_статус` (`id_статус`),
  ADD KEY `id_менеджер` (`id_менеджер`);

--
-- Индексы таблицы `оборудование`
--
ALTER TABLE `оборудование`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `склад`
--
ALTER TABLE `склад`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_материал` (`id_материал`,`id_продукция`),
  ADD KEY `id_продукция` (`id_продукция`);

--
-- Индексы таблицы `сотрудники`
--
ALTER TABLE `сотрудники`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `статус`
--
ALTER TABLE `статус`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `тип_материала`
--
ALTER TABLE `тип_материала`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `тип_партнера`
--
ALTER TABLE `тип_партнера`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `тип_поставщика`
--
ALTER TABLE `тип_поставщика`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `тип_продукции`
--
ALTER TABLE `тип_продукции`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT для сохранённых таблиц
--

--
-- AUTO_INCREMENT для таблицы `users`
--
ALTER TABLE `users`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT для таблицы `материал`
--
ALTER TABLE `материал`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT для таблицы `менеджеры`
--
ALTER TABLE `менеджеры`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT для таблицы `место_продаж`
--
ALTER TABLE `место_продаж`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT для таблицы `доступ`
--
ALTER TABLE `доступ`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT для таблицы `история_изм_стоимости`
--
ALTER TABLE `история_изм_стоимости`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT для таблицы `история_поставки`
--
ALTER TABLE `история_поставки`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT для таблицы `история_продаж`
--
ALTER TABLE `история_продаж`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT для таблицы `история_рейтинга`
--
ALTER TABLE `история_рейтинга`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT для таблицы `история_склада`
--
ALTER TABLE `история_склада`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT для таблицы `партнеры`
--
ALTER TABLE `партнеры`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT для таблицы `перемещение_сотрудников`
--
ALTER TABLE `перемещение_сотрудников`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT для таблицы `потсавщик`
--
ALTER TABLE `потсавщик`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT для таблицы `продукция`
--
ALTER TABLE `продукция`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT для таблицы `производство`
--
ALTER TABLE `производство`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT для таблицы `ед_измериния`
--
ALTER TABLE `ед_измериния`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT для таблицы `заявка`
--
ALTER TABLE `заявка`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT для таблицы `оборудование`
--
ALTER TABLE `оборудование`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT для таблицы `склад`
--
ALTER TABLE `склад`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT для таблицы `сотрудники`
--
ALTER TABLE `сотрудники`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT для таблицы `статус`
--
ALTER TABLE `статус`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT для таблицы `тип_материала`
--
ALTER TABLE `тип_материала`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT для таблицы `тип_партнера`
--
ALTER TABLE `тип_партнера`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT для таблицы `тип_поставщика`
--
ALTER TABLE `тип_поставщика`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT для таблицы `тип_продукции`
--
ALTER TABLE `тип_продукции`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- Ограничения внешнего ключа сохраненных таблиц
--

--
-- Ограничения внешнего ключа таблицы `материал`
--
ALTER TABLE `материал`
  ADD CONSTRAINT `материал_ibfk_1` FOREIGN KEY (`id_ед_измериния`) REFERENCES `ед_измериния` (`id`),
  ADD CONSTRAINT `материал_ibfk_2` FOREIGN KEY (`id_тип_материала`) REFERENCES `тип_материала` (`id`),
  ADD CONSTRAINT `материал_ibfk_3` FOREIGN KEY (`id_склад`) REFERENCES `склад` (`id`),
  ADD CONSTRAINT `материал_ibfk_4` FOREIGN KEY (`id_поставщик`) REFERENCES `потсавщик` (`id`);

--
-- Ограничения внешнего ключа таблицы `место_продаж`
--
ALTER TABLE `место_продаж`
  ADD CONSTRAINT `место_продаж_ibfk_1` FOREIGN KEY (`id_парнеры`) REFERENCES `партнеры` (`id`);

--
-- Ограничения внешнего ключа таблицы `доступ`
--
ALTER TABLE `доступ`
  ADD CONSTRAINT `доступ_ibfk_1` FOREIGN KEY (`id_сотрудники`) REFERENCES `сотрудники` (`id`),
  ADD CONSTRAINT `доступ_ibfk_2` FOREIGN KEY (`id_оборудование`) REFERENCES `оборудование` (`id`);

--
-- Ограничения внешнего ключа таблицы `история_поставки`
--
ALTER TABLE `история_поставки`
  ADD CONSTRAINT `история_поставки_ibfk_1` FOREIGN KEY (`id_материал`) REFERENCES `материал` (`id`);

--
-- Ограничения внешнего ключа таблицы `история_продаж`
--
ALTER TABLE `история_продаж`
  ADD CONSTRAINT `история_продаж_ibfk_1` FOREIGN KEY (`id_продукция`) REFERENCES `продукция` (`id`),
  ADD CONSTRAINT `история_продаж_ibfk_2` FOREIGN KEY (`id_парнер`) REFERENCES `партнеры` (`id`);

--
-- Ограничения внешнего ключа таблицы `история_рейтинга`
--
ALTER TABLE `история_рейтинга`
  ADD CONSTRAINT `история_рейтинга_ibfk_1` FOREIGN KEY (`id_партнер`) REFERENCES `партнеры` (`id`),
  ADD CONSTRAINT `история_рейтинга_ibfk_2` FOREIGN KEY (`id_менеджер`) REFERENCES `менеджеры` (`id`);

--
-- Ограничения внешнего ключа таблицы `история_склада`
--
ALTER TABLE `история_склада`
  ADD CONSTRAINT `история_склада_ibfk_1` FOREIGN KEY (`id_склад`) REFERENCES `склад` (`id`);

--
-- Ограничения внешнего ключа таблицы `партнеры`
--
ALTER TABLE `партнеры`
  ADD CONSTRAINT `партнеры_ibfk_1` FOREIGN KEY (`id_тип_партнера`) REFERENCES `тип_партнера` (`id`);

--
-- Ограничения внешнего ключа таблицы `перемещение_сотрудников`
--
ALTER TABLE `перемещение_сотрудников`
  ADD CONSTRAINT `перемещение_сотрудников_ibfk_1` FOREIGN KEY (`id_сотрудники`) REFERENCES `сотрудники` (`id`);

--
-- Ограничения внешнего ключа таблицы `потсавщик`
--
ALTER TABLE `потсавщик`
  ADD CONSTRAINT `потсавщик_ibfk_1` FOREIGN KEY (`id_тип_поставщика`) REFERENCES `тип_поставщика` (`id`),
  ADD CONSTRAINT `потсавщик_ibfk_2` FOREIGN KEY (`id_менеджер`) REFERENCES `менеджеры` (`id`),
  ADD CONSTRAINT `потсавщик_ibfk_3` FOREIGN KEY (`id_история_поставки`) REFERENCES `история_поставки` (`id`);

--
-- Ограничения внешнего ключа таблицы `продукция`
--
ALTER TABLE `продукция`
  ADD CONSTRAINT `продукция_ibfk_1` FOREIGN KEY (`id_тип_продукции`) REFERENCES `тип_продукции` (`id`),
  ADD CONSTRAINT `продукция_ibfk_2` FOREIGN KEY (`id_материал`) REFERENCES `материал` (`id`),
  ADD CONSTRAINT `продукция_ibfk_3` FOREIGN KEY (`id_история_из_стоимости`) REFERENCES `история_изм_стоимости` (`id`),
  ADD CONSTRAINT `продукция_ibfk_4` FOREIGN KEY (`id_производство`) REFERENCES `производство` (`id`);

--
-- Ограничения внешнего ключа таблицы `производство`
--
ALTER TABLE `производство`
  ADD CONSTRAINT `производство_ibfk_1` FOREIGN KEY (`id_сотрудника`) REFERENCES `сотрудники` (`id`);

--
-- Ограничения внешнего ключа таблицы `заявка`
--
ALTER TABLE `заявка`
  ADD CONSTRAINT `заявка_ibfk_1` FOREIGN KEY (`id_продукция`) REFERENCES `продукция` (`id`),
  ADD CONSTRAINT `заявка_ibfk_2` FOREIGN KEY (`id_статус`) REFERENCES `статус` (`id`),
  ADD CONSTRAINT `заявка_ibfk_3` FOREIGN KEY (`id_менеджер`) REFERENCES `менеджеры` (`id`),
  ADD CONSTRAINT `заявка_ibfk_4` FOREIGN KEY (`id_парнет`) REFERENCES `партнеры` (`id`);

--
-- Ограничения внешнего ключа таблицы `склад`
--
ALTER TABLE `склад`
  ADD CONSTRAINT `склад_ibfk_1` FOREIGN KEY (`id_продукция`) REFERENCES `продукция` (`id`),
  ADD CONSTRAINT `склад_ibfk_2` FOREIGN KEY (`id_материал`) REFERENCES `материал` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
