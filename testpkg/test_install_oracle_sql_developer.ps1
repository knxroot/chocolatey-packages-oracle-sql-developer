cd C:\Users\WDAGUtilityAccount\Desktop\chocolatey-oracle-sql-developer\manual\oracle-sql-developer
choco pack
choco install oracle-sql-developer -dv -s . --params "'/Username:<user> /Password:<pass>'"