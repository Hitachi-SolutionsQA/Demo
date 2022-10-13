@NoBrowser
Feature: FileComparison
	Comparing files from FTP output


Scenario Outline: Compare Source file with FTP output
	Given Text file is loaded from Expected '<ExpectedFile>' file
	And FTP output is loaded from Actual '<ActualFile>' file
	When compared line for line
	Then files match as expected

Examples: 
	| ExpectedFile   | ActualFile     |
	| test1.txt      | test1.txt      |
