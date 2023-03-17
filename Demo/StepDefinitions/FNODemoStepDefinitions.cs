using Demo.Pages;
using System;
using TechTalk.SpecFlow;

namespace Demo.StepDefinitions
{
    [Binding]
    public class FNODemoStepDefinitions
    {
        public FNOPage Page { get; set; }
        public FNODemoStepDefinitions(FNOPage Page)
        {
            this.Page = Page;  
        }
        [Then(@"user should be signed into FNO")]
        public void ThenUserShouldBeSignedIntoFNO() => GivenUserIsInFNO();

        [Given(@"user is in FNO")]
        public void GivenUserIsInFNO()
        {
            this.Page.GetElement("Finance and Operations").assertElementIsPresent();
        }

        [When(@"user creates a new timesheet")]
        public void WhenUserCreatesANewTimesheet()
        {
            this.Page.GetElement("Bank management").Click();
            this.Page.GetElement("All bank accounts").Click();
            this.Page.Grid.OpenGridRecord(0);

        }

        [Then(@"a new timesheet should be created")]
        public void ThenANewTimesheetShouldBeCreated()
        {
            Thread.Sleep(5000);
        }

    }
}
