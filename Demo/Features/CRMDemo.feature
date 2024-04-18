Feature: CRM demo
	Scenarios testing FNO UI Functionality


	@Playwright
Scenario: User creates purchase order successfully 
	Given user landed in CRM
	When user types the following values into the project matrix
	| colIndex | rowIndex | value |
	| 0        | 1        | 45    |
	Then column total should display red if total greater than 40

	
