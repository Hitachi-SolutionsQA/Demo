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
            return this.Element($"//*[normalize-space(text())='{text}']");
        }
    }
}
