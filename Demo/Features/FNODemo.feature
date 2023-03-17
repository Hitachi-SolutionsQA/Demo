Feature: FNO demo
	Comparing files from FTP output


Scenario Outline: User can sign in 
	Then user should be signed into FNO
	

Scenario Outline: User can create a timesheet
	Given user is in FNO
	When user creates a new timesheet
	Then a new timesheet should be created
	
