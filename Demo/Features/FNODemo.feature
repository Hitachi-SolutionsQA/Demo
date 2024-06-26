﻿Feature: FNO demo
	Scenarios testing FNO UI Functionality


Scenario: User can sign in 
	Then user should be signed into FNO
	
	@login
Scenario: User creates purchase order successfully 
	Given user is in FNO
	And user selects 'Modules' from left navigation
	And user selects 'Accounts payable' Module
	And user selects 'All purchase orders' button
	When user creates new purchase order
	Then user validates purchase order saved

	
