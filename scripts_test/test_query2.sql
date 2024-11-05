INSERT INTO staging_customer (customer_id, personal_id, country, year_of_birth, income_range, first_name, last_name)
	VALUES 
		(1, '3297172JZ','GERMANY', 2001, 'REPLACE_OLD', 'JESSICA_EMMA', 'RODRIGUEZ'),
		(199999999, '9999999XX','CANADA', 1990, 'REPLACE_OLD', 'JOSE', 'LALALA');

INSERT INTO staging_product (product_id, company, premium, product_category, product_detail)
	VALUES 
		(1, 'PRUDENTIAL', 109, 'REPLACE', 'REPLACE'),
		(999, 'TEST_1', 150, 'REPLACE', 'REPLACE'),
		(888, 'TEST_2.', 900, 'TEST_2', 'TEST_2');


EXEC IncrementalLoad_All_Tables;
