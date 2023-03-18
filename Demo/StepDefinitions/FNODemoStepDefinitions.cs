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

        [Given(@"user selects '([^']*)' from left navigation")]
        public void GivenUserSelectsFromLeftNavigation(string leftNavItem)
        {
            Page.GetLeftNavMdodule(leftNavItem).Click();
        }

        [Given(@"user selects '([^']*)' Module")]
        public void GivenUserSelectsModule(string moduleName)
        {
            Page.GetModuleByName(moduleName).Click();
        }

        [Given(@"user selects '([^']*)' button")]
        public void GivenUserSelectsButton(string buttonText)
        {
            Page.GetElement(buttonText).Click();
        }

        [When(@"user creates new purchase order")]
        public void WhenUserCreatesNewPurchaseOrder()
        {
            Page.GetElement("New").Click();
            Thread.Sleep(500);
            Page.GetField("Vendor account").SetFieldValue("0001");
            Page.GetElementByControlName("OK").Click();
            Page.GetField("Item number").SetFieldValue("1000");
            Page.GetField("Site").SetFieldValue("4");
            Page.GetElement("Save").Click();
        }

        [Then(@"user validates purchase order saved")]
        public void ThenUserValidatesPurchaseOrderSaved()
        {
            //
        }
    }
}
