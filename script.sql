-- PA03-online-store

-- Tables

create table customers (
    customer_id serial primary key,
    full_name varchar(100) not null,
    email varchar(100) unique not null,
    balance numeric(10,2) default 0
);

create table products (
    product_id serial primary key,
    product_name varchar(100) not null,
    price numeric(10,2) not null,
    stock_quantity int not null
);

create table orders (
    order_id serial primary key,
    customer_id int references customers(customer_id),
    order_date timestamp default current_timestamp,
    total_amount numeric(10,2) default 0
);

create table order_items (
    order_item_id serial primary key,
    order_id int references orders(order_id),
    product_id int references products(product_id),
    quantity int not null,
    price numeric(10,2) not null
);

create table order_log (
    log_id serial primary key,
    order_id int,
    customer_id int,
    action varchar(50),
    log_date timestamp default current_timestamp
);

-- Task 1
create or replace function calculate_order_total(p_order_id int)
returns numeric as $$
declare
	v_total numeric(10,2);
begin
	select coalesce(sum(quantity * price), 0)
	into v_total
	from order_items
	where order_id = p_order_id;

	return v_total;
end;
$$ language plpgsql;

-- Task 2
create or replace procedure create_order (p_customer_id int)
as $$
begin
	if not exists ( select 1 from customers where customer_id = p_customer_id) then
		raise exception 'Customer with ID % does not exist', p_customer_id;
	end if;

	insert into orders (customer_id, order_date, total_amount)
	values (p_customer_id, current_timestamp, 0);
end;
$$ language plpgsql;


-- Task 3
create or replace procedure add_product_to_order(
	p_order_id int,
	p_product_id int,
	p_quantity int
)
as $$
declare
	v_price numeric(10,2),
	v_stock int;
begin
	if p_quantity <= 0 then
		raise exception 'Quantity must be greater than zero';
	end if;

	if not exists (select 1 from orders where order_id = p_order_id) then
		raise exception 'Order with ID % does not exist', p_order_id;
	end if;

	select price, stock_quantity
	into v_price, v_stock
	from products
	where product_id = p_product_id;

	if not found then
		raise exception 'Product with ID % does not exist', p_product_id;
	end if;

	if v_stock < p_quantity then
		raise exception 'Not enough in stock for Product ID %. Available : %, Requested : %', p_product_id, v_stock, p_quantity;
	end if;

	insert into order_items (order_id, product_id, quantity, price)
	values (p_order_id, p_product_id, p_quantity, v_price);

	update products
	set stock_quantity = stock_quantity - p_quantity
	where product_id = p_product_id;
end;
$$ language plpgsql;

-- Task 4
create or replace function update_order_total()
returns trigger as $$
declare
	v_order_id int;
begin
	if tg_op = 'delete' then
		v_order_id := old.order_id;
	else
		v_order_id := new.order_id;
	end if;

	update orders
	set total_amount = calculate_order_total(v_order_id)
	where order_id = v_order_id;

	return new;
end;
$$ language plpgsql;

create trigger trg_update_order_total
after insert or update or delete on order_items
for each row
execute function update_order_total();

-- Task 5
create or replace function order_audit_log()
returns trigger as $$
begin
	insert into order_log (order_id, customer_id, action, log_date)
	values (new.order_id, new.customer_id, 'order_created', current_timestamp);

	return new;
end;
$$ language plpgsql;

create or replace trigger trg_order_audit_log
after insert on orders
for each row
execute function order_audit_log();

-- Task 6 : Testing

-- creating customer
insert into customers (full_name, email, balance)
values ('Anna Bulka', 'anna@example.com', 500.00);

-- creating product
insert into products (product_name, price, stock_quantity)
values ('PesPatron', 350.00, 50);

-- creating orders using procedure
call create_order(1);

-- adding products to order using procedure
call add_product_to_order(1,1,1);

-- checking for update
select order_id, total_amount from orders where order_id = 1;

-- checking for decrease
select product_name, stock_quantity from products where product_id = 1;

-- checking the log
select * from order_log;