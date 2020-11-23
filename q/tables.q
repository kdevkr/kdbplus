\d .table

addColumns:{[tbl;columns;types]
	.Q.ff[tbl] enlist (columns!types)}

addColumns[tbl;(enlist `new_cols);(enlist `)]
addColumns[tbl;(`new_col1`new_col2);`,1]