using Demo.StepDefinitions;
using HitachiQA.Helpers;
using Microsoft.Playwright;
using Microsoft.VisualStudio.TestPlatform.ObjectModel;
using Telerik.JustMock;
using Telerik.JustMock.Helpers;

namespace Demo.UnitTests
{
    [TestClass]
    public class CrmDemoTest
    {
        CRMDemoStepDefinitions StepDefinition { get; init; }
        public CrmDemoTest() {
            StepDefinition = Mock.Create <CRMDemoStepDefinitions>();
            StepDefinition.Data = new SharedData();

            Mock.Arrange(() => StepDefinition.Page.Locator(Arg.IsAny<string>(),null)).Returns(Mock.Create<ILocator>());
            Mock.Arrange(() => StepDefinition.Frame).Returns(Mock.Create<IFrameLocator>());


        }
        [DataTestMethod]
        [DataRow("41")]
        [DataRow("40")]
        [DataRow("39")]
        [DataRow("0")]
        [DataRow("")]
        [DataRow(null)]
        public async Task TestColumnTotalIsHandledCorrectly(string TotalColumnReturn)
        {
            var columnTotalLocatorMock = Mock.Create<ILocator>();
            Mock.Arrange(() => StepDefinition.Frame.Locator(Arg.IsAny<string>(), null)).Returns(columnTotalLocatorMock);

            var table = new Table("colIndex", "rowIndex", "value");
            table.AddRow("0", "1", "8");
            StepDefinition.Data.SetValue("matrix", "table", table);

            Mock.Arrange(() => columnTotalLocatorMock.TextContentAsync(null)).Returns(Task.FromResult<string?>(TotalColumnReturn)); // Return a value for testing
            

            if (TotalColumnReturn == "" || int.TryParse(TotalColumnReturn, out var n) && n <=40)
            {
                await StepDefinition.ThenColumnTotalShouldDisplayRedIfTotalGreaterThan();
            }
            else
            {
                await Assert.ThrowsExceptionAsync<AssertFailedException>(async ()=> await StepDefinition.ThenColumnTotalShouldDisplayRedIfTotalGreaterThan());
            }
        }
    }
}
