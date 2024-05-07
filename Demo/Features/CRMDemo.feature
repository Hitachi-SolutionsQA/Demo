Feature: CRMDemo

A short summary of the feature

@login
Scenario: Assert red colored text when total is above 40 hours
	Given user landed in the CRM page
	And user enters the following values in the table
	| RowIndex | ColumnIndex | value |
	| 2        | 4           | 41    |
	Then assert the following values in the table
	| RowIndex | ColumnIndex | value |
	| 2        | 4           | 41    |
	Then assert row 2 and column 4 has red colored text
