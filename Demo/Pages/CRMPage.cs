using BoDi;
using HitachiQA.Driver;
using HitachiQA.Dynamics.FO.Pages;
using HitachiQA.Helpers;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Demo.Pages
{
    public class CRMPage : Dyn_BasePage
    {
        JSExecutor JSExecutor { get; set; }
        public WorkPlanIFrame WorkPlanIFrame { get; set; }
        public CRMPage(ObjectContainer ObjectContainer, JSExecutor executor, WorkPlanIFrame workPlanIFrame) : base(ObjectContainer)
        {
            JSExecutor = executor;
            WorkPlanIFrame = workPlanIFrame;
        }

        public Element GetElement(string text)
        {
            return this.Element($"//*[normalize-space(text())='{text}'] |" +
                                $"//*[@role='link'][descendant::*[text()='{text}']] |" +
                                $"//button[descendant::*[text()='{text}']]");
        }

        public Element GetLeftNavMdodule(string navItem)
        {
            this.Element("//*[@aria-label='Expand the navigation pane']").Click();
            return this.Element($"//*[@aria-label='{navItem}']");
        }

        public Element GetModuleByName(string moduleName)
        {
            return this.Element($"//*[@data-dyn-title='{moduleName}']");
        }

        public Element Scrollbar => Element("//*[@id=\"DashboardScrollView\"]");

        public new void ScrollToBottom()
        {
            var element = UserActions.FindElementWaitUntilPresent(Scrollbar.locator);
            JSExecutor.execute("arguments[0].scrollBy(0, 1500)", element);
        }



    }

    public class WorkPlanIFrame : Dyn_BasePage
    {
        public WorkPlanIFrame(ObjectContainer ObjectContainer) : base(ObjectContainer)
        {
            this.IFrameTitle = "IFRAME";
        }

        public Element Table => Element("//*[@id='workplaneditor'][./*[@id='EffPivot0_tableParent']]//table[./tbody/tr/td[contains(@class,'hsl-rowGroup') and not(contains(@class,'projectid'))]]");

        public Element GetCell(string rowNumber, string cellNumber)
        {
            var tableXPath = Table.locator.Locator.Criteria;
            return Element($"{tableXPath}/tbody/tr[{rowNumber}]/td[{cellNumber}]");
        }

        public Element GetTotalCell(string colNumber) => GetTotalCell(int.Parse(colNumber));

        public Element GetTotalCell(int colNumber)
        {
            return Element($"//*[@id='workplaneditor']//*[@class=\"dataTables_scrollFoot\"]//table/tfoot//tr/td[{colNumber - 2}]/div");
        }
    }
}
