create view active_flights_view as
select
    f.flight_id,
    f.flight_number,
    ac.model as aircraft_model,
    dep.airport_name as departure_airport,
    dep.city as departure_city,
    arr.airport_name as arrival_airport,
    arr.city as arrival_city,
    f.departure_time,
    f.arrival_time,
    f.status
from flights f
join aircraft ac on f.aircraft_id = ac.aircraft_id
join airports dep on f.departure_airport_id = dep.airport_id
join airports arr on f.arrival_airport_id = arr.airport_id
where f.status in ('scheduled', 'boarding');
