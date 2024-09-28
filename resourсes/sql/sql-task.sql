-- 1. Вывести к каждому самолету класс обслуживания и количество мест этого класса
SELECT airplanes.aircraft_code,
       airplanes.model,
       seats.fare_conditions,
       count(seats.seat_no)
FROM bookings.aircrafts airplanes
         INNER JOIN bookings.seats seats
                    ON airplanes.aircraft_code = seats.aircraft_code
GROUP BY airplanes.model, airplanes.aircraft_code, seats.fare_conditions
ORDER BY airplanes.aircraft_code;

-- 2. Найти 3 самых вместительных самолета (модель + кол-во мест)
SELECT airplanes.model,
       count(seats.seat_no)
FROM bookings.aircrafts airplanes
         INNER JOIN bookings.seats seats
                    ON airplanes.aircraft_code = seats.aircraft_code
GROUP BY airplanes.model
ORDER BY count(seats.seat_no) DESC
LIMIT 3;

-- 3.	Найти все рейсы, которые задерживались более 2 часов
SELECT *
FROM bookings.flights
WHERE status = 'Delayed'
  AND actual_departure - scheduled_departure > INTERVAL '2 hours';

-- 4.	Найти последние 10 билетов, купленные в бизнес-классе (fare_conditions = 'Business'), с указанием имени пассажира и контактных данных
SELECT t.passenger_name, t.contact_data
FROM bookings.tickets t
         JOIN bookings.ticket_flights tf ON t.ticket_no = tf.ticket_no
WHERE tf.fare_conditions = 'Business'
ORDER BY t.ticket_no DESC
LIMIT 10;

-- 5.	Найти все рейсы, у которых нет забронированных мест в бизнес-классе (fare_conditions = 'Business')
SELECT f.flight_id, f.flight_no, f.scheduled_departure, f.scheduled_arrival
FROM bookings.flights f
WHERE f.flight_id NOT IN (SELECT tf.flight_id
                          FROM bookings.ticket_flights tf
                          WHERE tf.fare_conditions = 'Business');

-- 6.	Получить список аэропортов (airport_name) и городов (city), в которых есть рейсы с задержкой по вылету
SELECT DISTINCT ad.airport_name, ad.city
FROM bookings.airports_data ad
         JOIN bookings.flights f ON ad.airport_code = f.departure_airport
WHERE f.status = 'Delayed'
  AND f.scheduled_departure < f.actual_departure;


-- 7.	Получить список аэропортов (airport_name) и количество рейсов, вылетающих из каждого аэропорта, отсортированный по убыванию количества рейсов
SELECT ad.airport_name, COUNT(*) AS num_flights
FROM bookings.airports_data ad
         JOIN bookings.flights f ON ad.airport_code = f.departure_airport
GROUP BY ad.airport_name
ORDER BY 2 DESC;

-- 8.	Найти все рейсы, у которых запланированное время прибытия (scheduled_arrival) было изменено и новое время прибытия (actual_arrival) не совпадает с запланированным
SELECT *
FROM bookings.flights
WHERE scheduled_arrival != actual_arrival
  AND actual_arrival IS NOT NULL;

-- 9.	Вывести код, модель самолета и места не эконом класса для самолета "Аэробус A321-200" с сортировкой по местам
SELECT airplanes.aircraft_code,
       airplanes.model,
       seats.seat_no
FROM bookings.aircrafts airplanes
         INNER JOIN bookings.seats seats
                    ON airplanes.aircraft_code = seats.aircraft_code
WHERE airplanes.model = 'Аэробус A321-200'
  AND NOT seats.fare_conditions = 'Economy'
ORDER BY seats.seat_no;

-- 10. Вывести города в которых больше 1 аэропорта (код аэропорта, аэропорт, город)
SELECT airports.airport_code,
       airports.airport_name,
       airports.city
FROM bookings.airports airports
WHERE airports.city
          IN (SELECT airports.city
              FROM airports
              GROUP BY airports.city
              HAVING count(airports.city) > 1);

-- 11.	Найти пассажиров, у которых суммарная стоимость бронирований превышает среднюю сумму всех бронирований
SELECT p.passenger_name, SUM(b.total_cost) AS total_spent
FROM bookings.bookings b
         JOIN bookings.passengers p ON b.passenger_id = p.passenger_id
GROUP BY p.passenger_name
HAVING SUM(b.total_cost) > (SELECT AVG(total_cost) FROM bookings.bookings);


-- 12. Найти ближайший вылетающий рейс из Екатеринбурга в Москву, на который еще не завершилась регистрация
SELECT flights.*
FROM bookings.flights_v flights
WHERE flights.departure_city = 'Екатеринбург'
  AND flights.arrival_city = 'Москва'
  AND bookings.now() < (flights.scheduled_departure - INTERVAL '40 minute')
ORDER BY flights.scheduled_departure
LIMIT 1;

-- 13. Вывести самый дешевый и дорогой билет и стоимость ( в одном результирующем ответе)
(SELECT tickets.ticket_no, tickets.amount AS cost
 FROM bookings.ticket_flights tickets
 WHERE tickets.amount = (SELECT min(bookings.ticket_flights.amount)
                         FROM bookings.ticket_flights)
 LIMIT 1)
UNION
(SELECT tickets.ticket_no, tickets.amount AS cost
 FROM bookings.ticket_flights tickets
 WHERE tickets.amount = (SELECT max(bookings.ticket_flights.amount)
                         FROM bookings.ticket_flights)
 LIMIT 1);

-- 14 Написать DDL таблицы Customers, должны быть поля id, firstName, LastName, email, phone. Добавить ограничения на поля (constraints) .
CREATE DOMAIN email AS TEXT
    CHECK ( VALUE ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$');

CREATE DOMAIN phone AS TEXT
    CHECK ( VALUE ~ '^[+][0-9]{1,15}$');

CREATE TABLE IF NOT EXISTS customers
(
    id
               BIGINT
        GENERATED
            ALWAYS AS
            IDENTITY
            (
            INCREMENT
                1
            START
                1
            MINVALUE
                1
            ) PRIMARY KEY,
    first_name TEXT         NOT NULL CHECK
        (
        first_name
            !=
        ''
        ),
    last_name  TEXT         NOT NULL CHECK
        (
        last_name
            !=
        ''
        ),
    email      email,
    phone      phone UNIQUE NOT NULL
);

-- 15.	Написать DDL таблицы Orders, должен быть id, customerId, quantity. Должен быть внешний ключ на таблицу customers + constraints
CREATE TABLE IF NOT EXISTS orders
(
    id
        BIGSERIAL,
    customer_id
        BIGINT,
    quantity
        INTEGER,
    CONSTRAINT
        orders_id
        PRIMARY
            KEY
            (
             id
                ),
    CONSTRAINT orders_quantity CHECK
        (
        quantity
            >=
        0
        ),
    FOREIGN KEY
        (
         customer_id
            ) REFERENCES customers
        (
         id
            )
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- 16 Написать 5 insert в эти таблицы
INSERT INTO customers (first_name, last_name, email, phone)
VALUES ('Nik', 'Nikantov', 'nik@gmail.com', '+375297775522'),
       ('Luk', 'Samsonou', 'luk@gmail.com', '+375336665235'),
       ('Igor', 'Egorov', 'igor@yandex.ru', '+375444444444'),
       ('Ivan', 'Ivanov', 'ivanov@outlook.com', '+375440075751'),
       ('Adam', 'Novikov', 'adam@yandex.by', '+375331234568');

INSERT INTO orders(customer_id, quantity)
VALUES ((SELECT customers.id FROM customers WHERE customers.phone = '+375297775522'), 10),
       ((SELECT customers.id FROM customers WHERE customers.phone = '+375336665235'), 143),
       ((SELECT customers.id FROM customers WHERE customers.phone = '+375444444444'), 12),
       ((SELECT customers.id FROM customers WHERE customers.phone = '+375440075751'), 1000),
       ((SELECT customers.id FROM customers WHERE customers.phone = '+375331234568'), 1043);

-- 17 Удалить таблицы
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS orders;
DROP DOMAIN IF EXISTS email;
DROP DOMAIN IF EXISTS phone;