using Demo.Pages;
using HitachiQA.Dynamics.FO.Pages;
using System;
using TechTalk.SpecFlow;

namespace Demo.StepDefinitions
{
    [Binding]
    public class CRMDemoStepDefinitions
    {
        public CRMPage Page { get; set; }
        public CRMDemoStepDefinitions(CRMPage Page)
        {
            this.Page = Page;
        }
        [Given(@"user landed in the CRM page")]
        public void GivenUserLandedInTheCRMPage()
        {
            Page.Element("Brand You Dashboard").assertElementIsPresent();
        }

        [Given(@"user enters the following values in the table")]
        public void GivenUserEntersTheFollowingValuesInTheTable(Table table)
        {
            throw new PendingStepException();
        }

        [Then(@"assert the following values in the table")]
        public void ThenAssertTheFollowingValuesInTheTable(Table table)
        {
            throw new PendingStepException();
        }

        [Then(@"assert row (.*) and column (.*) has red colored text")]
        public void ThenAssertRowAndColumnHasRedColoredText(int p0, int p1)
        {
            throw new PendingStepException();
        }

    }
}
