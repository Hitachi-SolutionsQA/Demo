using Demo.Pages;
using HitachiQA.Driver;
using HitachiQA.Dynamics.FO.Pages;
using System;
using TechTalk.SpecFlow;

namespace Demo.StepDefinitions
{
    [Binding]
    public class CRMDemoStepDefinitions
    {
        public CRMPage Page { get; set; }
        public UserActions UserActions { get; set; }

        public CRMDemoStepDefinitions(CRMPage Page, UserActions ua)
        {
            this.Page = Page;
            UserActions = ua;   
        }
        [Given(@"user landed in the CRM page")]
        public void GivenUserLandedInTheCRMPage()
        {
            Page.GetField("My Employee Profile").assertElementIsPresent();
        }

        [Given(@"user enters the following values in the table")]
        public void GivenUserEntersTheFollowingValuesInTheTable(Table table)
        {
            Page.ScrollToBottom();
            Page.WorkPlanIFrame.Table.assertElementIsPresent();

            foreach (var row in table.Rows)
            {
                var colIndex = row["ColumnIndex"];
                var rowIndex = row["RowIndex"];
                var value = row["value"];

                Page.WorkPlanIFrame.GetCell(rowIndex, colIndex).SetFieldValue(value);
            }

        }

        [Then(@"assert the following values in the table")]
        public void ThenAssertTheFollowingValuesInTheTable(Table table)
        {
            foreach (var row in table.Rows)
            {
                var colIndex = row["ColumnIndex"];
                var rowIndex = row["RowIndex"];
                var value = row["value"];

                var actualValue = Page.WorkPlanIFrame.GetCell(rowIndex, colIndex).GetFieldValue();
                actualValue.Should().Be(value);
            }
        }

        [Then(@"assert column '([^']*)' in the total row has red colored text")]
        public void ThenAssertColumnInTheTotalRowHasRedColoredText(int columnNumber)
        {
            var classes = Page.WorkPlanIFrame.GetTotalCell(columnNumber).GetAttribute("class");
            classes.Should().Contain("text-danger");
        }


    }
}
