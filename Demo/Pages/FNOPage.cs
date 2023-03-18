using BoDi;
using HitachiQA.Driver;
using HitachiQA.Dynamics.FO.Pages;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Demo.Pages
{
    public class FNOPage : Dyn_BasePage
    {
        public FNOPage(ObjectContainer ObjectContainer) : base(ObjectContainer)
        {
            
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
    }
}
