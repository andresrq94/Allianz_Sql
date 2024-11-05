-- Insert Values for customers, products and sales

INSERT INTO staging_customer (customer_id, personal_id, country, year_of_birth, income_range, first_name, last_name)
	VALUES 
		(1, '3297172JZ','GERMANY', 2001, 'LOWER EARNER', 'JESSICA_EMMA', 'RODRIGUEZ'),
		(199999999, '9999999XX','CANADA', 1990, 'UPPER EARNER', 'JOSE', 'LALALA');

INSERT INTO staging_product (product_id, company, premium, product_category, product_detail)
	VALUES 
		(1, 'PRUDENTIAL', 109, 'INDIVIDUAL_HEALTH_INSURANCE', 'DISABILITY_INSURANCE'),
		(999, 'TEST_1', 150, 'TEST_1', 'TEST_1'),
		(888, 'TEST_2.', 300, 'TEST_2', 'TEST_2');

INSERT INTO staging_sales (customer_id, product_id, quantity, sale_date)
	VALUES 
		(101, 1, 2, '2024-10-10'),
		(102, 2, 1, '2024-10-11'),
		(103, 3, 5, '2024-10-12'),
		(104, 4, 3, '2024-10-13'),
		(64567, 6465, 4, '2024-10-14');

 -- Execute Stored Procedure
EXEC IncrementalLoad_All_Tables;





